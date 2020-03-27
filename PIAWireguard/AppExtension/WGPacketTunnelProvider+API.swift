//
//  WGPacketTunnelProvider+API.swift
//  PIAWireguard
//  
//  Created by Jose Antonio Blaya Garcia on 27/02/2020.
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
import Network
import NetworkExtension
import os.log
import __PIAWireGuardNative
import Alamofire
import TweetNacl

@available(iOS 12.0, *)
public extension WGPacketTunnelProvider {
    
    func addPublicKeyToServer(serverAddress: String,
                              withCompletionHandler startTunnelCompletionHandler: @escaping (Error?) -> Void) {
        
        guard let piaToken = self.providerConfiguration[PIAWireguardConfiguration.Keys.token] as? String else {
            let msg = "WGPacketTunnel: pia auth token not found"
            self.stopTunnel(withMessage: msg)
            return
        }
        guard let dnsServers = self.providerConfiguration[PIAWireguardConfiguration.Keys.dnsServers] as? [String] else {
            let msg = "WGPacketTunnel: dnsServer not found"
            self.stopTunnel(withMessage: msg)
            return
        }
        guard let ping = self.providerConfiguration[PIAWireguardConfiguration.Keys.ping] as? String else {
            let msg = "WGPacketTunnel: ping server not found"
            self.stopTunnel(withMessage: msg)
            return
        }
                
        //Generate private key
        let keys = try! NaclBox.keyPair()
        wgPublicKey = keys.publicKey
        wgPrivateKey = keys.secretKey
        
        let baseUrl = WGClientEndpoint.addKey(serverAddress: serverAddress,
                                              port: PIAWireguardConstants.remotePort).url
        
        let params = [PIAWireguardConstants.API.publicKeyParameter: wgPublicKey.base64EncodedString(),
                      PIAWireguardConstants.API.authTokenParameter: piaToken]

        _ = Alamofire.request(baseUrl, method: .get, parameters: params, encoding: URLEncoding.default).response { (response) in
            if let error = response.error {
                let msg = "WGPacketTunnel: request resulted in a error: \(error.localizedDescription)"
                self.stopTunnel(withMessage: msg)
            } else if let data = response.data {
                
                if let serverResponse = try? JSONDecoder().decode(WGServerResponse.self, from: data) {
                    
                    self.serverIPAddress = serverResponse.server_ip
                    guard !self.serverIPAddress.isEmpty else {
                        let msg = "WGPacketTunnel: Remote address not found"
                        self.stopTunnel(withMessage: msg)
                        return
                    }

                    wg_log(.info, staticMessage: "Configuring network settings")
                    
                    self.setTunnelNetworkSettings(self.generateNetworkSettings(withDnsServer: dnsServers,
                                                                               andServerResponse: serverResponse)) { (error) in
                        if let error = error {
                            wg_log(.info, staticMessage: "WGPacketTunnel: could not set network settings")
                            wg_log(.error, message: error.localizedDescription)
                            self.stopTunnel(with: .configurationFailed, completionHandler: {})
                        } else {
                            
                            self.networkMonitor = NWPathMonitor()
                            self.networkMonitor!.pathUpdateHandler = self.pathUpdate
                            self.networkMonitor!.start(queue: DispatchQueue(label: "NetworkMonitor"))

                            let fileDescriptor = (self.packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32) ?? -1
                            if fileDescriptor < 0 {
                                let msg = "WGPacketTunnel: could not determine file descriptor"
                                self.stopTunnel(withMessage: msg)
                                return
                            }
                            
                            var ifnameSize = socklen_t(IFNAMSIZ)
                            let ifnamePtr = UnsafeMutablePointer<CChar>.allocate(capacity: Int(ifnameSize))
                            ifnamePtr.initialize(repeating: 0, count: Int(ifnameSize))
                            if getsockopt(fileDescriptor, 2 /* SYSPROTO_CONTROL */, 2 /* UTUN_OPT_IFNAME */, ifnamePtr, &ifnameSize) == 0 {
                                self.ifname = String(cString: ifnamePtr)
                            }
                            ifnamePtr.deallocate()
                            wg_log(.info, message: "Tunnel interface is \(self.ifname ?? "unknown")")

                            self.pinger = SwiftyPing(host: ping, configuration: PingConfiguration(interval: self.pingInterval, with: 5), queue: DispatchQueue.global())

                            let wgConfig = self.uapiConfiguration(serverResponse: serverResponse)
                            let handle = wgConfig.withGoString { return wgTurnOn($0, fileDescriptor) }
                            if handle < 0 {
                                wg_log(.info, staticMessage: "WGPacketTunnel: could not start backend")
                                startTunnelCompletionHandler(PacketTunnelProviderError.couldNotStartBackend)
                                return
                            }
                            
                            self.handle = handle
                            self.updateSettings()
                            self.configureNetworkActivityListener()

                            startTunnelCompletionHandler(nil)

                        }
                    }
                    
                } else {
                    let msg = "WGPacketTunnel: unable to parse data: \(String(data: data, encoding: .utf8) ?? data.description) ourKey: \(self.wgPublicKey.base64EncodedString())"
                    self.stopTunnel(withMessage: msg)
                }
            } else {
                let msg = "WGPacketTunnel: no data to parse. Response code was: \(String(describing: response.response?.statusCode))"
                self.stopTunnel(withMessage: msg)
            }
        }

    }

}
