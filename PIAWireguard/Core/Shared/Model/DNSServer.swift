// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation
import Network

@available(iOS 12.0, *)
public struct DNSServer {
    let address: IPAddress

    public init(address: IPAddress) {
        self.address = address
    }
}

@available(iOS 12.0, *)
extension DNSServer: Equatable {
    public static func == (lhs: DNSServer, rhs: DNSServer) -> Bool {
        return lhs.address.rawValue == rhs.address.rawValue
    }
}

@available(iOS 12.0, *)
extension DNSServer {
    public var stringRepresentation: String {
        return "\(address)"
    }

    public init?(from addressString: String) {
        if let addr = IPv4Address(addressString) {
            address = addr
        } else if let addr = IPv6Address(addressString) {
            address = addr
        } else {
            return nil
        }
    }
}
