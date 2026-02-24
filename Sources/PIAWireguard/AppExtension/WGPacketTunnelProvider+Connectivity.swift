//
//  WGPacketTunnelProvider+Connectivity.swift
//  PIAWireguard
//
//  Created by Jose Antonio Blaya Garcia on 26/02/2020.
//  Copyright © 2020 Private Internet Access, Inc.
//
//  This file is part of the Private Internet Access iOS Client.
//
//  The Private Internet Access iOS Client is free software: you can redistribute it and/or
//  modify it under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  The Private Internet Access iOS Client is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
//  details.
//
//  You should have received a copy of the GNU General Public License along with the Private
//  Internet Access iOS Client.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import NetworkExtension
import os.log
import __PIAWireGuardNative

extension WGPacketTunnelProvider {

    // MARK: - Connectivity Phase

    /// Represents the two-phase dead-tunnel detection state machine.
    enum ConnectivityPhase {
        /// Phase 1: periodic RX byte monitoring to detect a stalled tunnel.
        case monitoringBytes
        /// Phase 2: pinger is active; RX bytes are checked to confirm the server is unreachable.
        case monitoringPings
    }

    // MARK: - Public Entry Point

    /// Starts Phase 1 of dead-tunnel detection: periodic RX byte monitoring.
    /// Called once the tunnel is established.
    func configureNetworkActivityListener() {
        DispatchQueue.main.async {
            if self.connectivityTimer == nil {
                self.scheduleTimer(for: .monitoringBytes)
            }
        }
    }

    // MARK: - Phase Handlers

    /// Phase 1 — RX byte monitoring.
    ///
    /// Every tick, compares the current RX byte count against the previous reading:
    /// - Bytes changed → traffic is flowing normally; reset the counter and stay in Phase 1.
    /// - Bytes unchanged → the tunnel looks stalled; increment the counter.
    ///   Once `wireGuardMaxConnectionAttempts` consecutive flat readings are reached,
    ///   switch to Phase 2 (ping monitoring) to confirm the server is truly unreachable.
    private func checkNetworkActivity() {
        let currentRxBytes = self.latestWireGuardSettings.rx_bytes

        self.updateSettings()

        if currentRxBytes == self.latestWireGuardSettings.rx_bytes {
            if wireGuardConnectionAttempts < wireGuardMaxConnectionAttempts {
                wg_log(.info, message: "Bytes not updated, retrying in 10 seconds")
                wireGuardConnectionAttempts += 1
            } else {
                wg_log(.info, message: "Max number of attempts to check if the tunnel is alive reached. We start to send pings now")
                wireGuardConnectionAttempts = 0
                scheduleTimer(for: .monitoringPings)
            }
        } else {
            wg_log(.info, message: "Bytes updated, retrying in 10 seconds")
            wireGuardConnectionAttempts = 0
        }
    }

    /// Phase 2 — Ping + RX byte monitoring.
    ///
    /// The pinger is already sending packets in the background (started by `scheduleTimer(for: .monitoringPings)`).
    /// Every tick, checks RX bytes only:
    /// - RX bytes changed → actual traffic got through; server is alive. Stop the pinger,
    ///   switch back to Phase 1.
    /// - RX bytes unchanged → server is not responding; increment the counter.
    ///   Once `wireGuardMaxConnectionAttempts` consecutive flat readings are reached,
    ///   kill the tunnel with `.connectivityCheckFailed` so the app can trigger a server failover.
    ///
    /// Note: TX bytes are intentionally ignored here. WireGuard continuously sends handshake
    /// initiations while trying to reconnect, which keeps bumping TX even when the server is
    /// completely unreachable. Checking TX would reset the counter and cause an infinite loop.
    private func checkPingActivity() {
        let currentRxBytes = self.latestWireGuardSettings.rx_bytes

        self.updateSettings()

        if currentRxBytes == self.latestWireGuardSettings.rx_bytes {
            if wireGuardConnectionAttempts < wireGuardMaxConnectionAttempts {
                wg_log(.info, message: "Sending pings every 2 seconds and rx bytes not updated, retrying in 10 seconds")
                wireGuardConnectionAttempts += 1
            } else {
                wg_log(.info, message: "Max number of attempts to check if the tunnel is alive reached. Stopping the tunnel now")
                wireGuardConnectionAttempts = 0
                cancelTunnelWithError(PacketTunnelProviderError.connectivityCheckFailed)
            }
        } else {
            wg_log(.info, message: "RX bytes updated. We start to check the bytes as normal every 10 seconds")
            wireGuardConnectionAttempts = 0
            pinger?.stop()
            scheduleTimer(for: .monitoringBytes)
        }
    }

    // MARK: - Timer Management

    /// Invalidates the current connectivity timer, transitions to the given phase,
    /// and creates a new closure-based timer for it. Starts the pinger when entering
    /// `.monitoringPings` and stops it (via the caller) when returning to `.monitoringBytes`.
    private func scheduleTimer(for phase: ConnectivityPhase) {
        connectivityTimer?.invalidate()
        connectivityPhase = phase

        switch phase {
        case .monitoringBytes:
            connectivityTimer = Timer.scheduledTimer(
                withTimeInterval: connectivityInterval,
                repeats: true
            ) { [weak self] _ in
                self?.checkNetworkActivity()
            }

        case .monitoringPings:
            connectivityTimer = Timer.scheduledTimer(
                withTimeInterval: pingCheckInterval,
                repeats: true
            ) { [weak self] _ in
                self?.checkPingActivity()
            }
            pinger?.start()
        }

        connectivityTimer?.tolerance = 5
    }
}
