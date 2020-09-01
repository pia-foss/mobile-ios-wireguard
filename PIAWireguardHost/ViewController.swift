//
//  ViewController.swift
//  PIAWireguard
//
//  Created by Jose Antonio Blaya Garcia on 04/02/2020.
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

import UIKit
import PIAWireguard
import Alamofire
import TweetNacl

class WGServerResponse: Decodable {
    
    var status: String
    var server_key: String
    var server_port: Int
    var peer_ip: String
    var peer_pubkey: String
    var dns_servers: [String]
    var server_ip: String

}

class ViewController: UIViewController, URLSessionDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let keys = try! NaclBox.keyPair()
        let wgPublicKey = keys.publicKey

        let params = ["pubkey": wgPublicKey.base64EncodedString(),
                      "pt": "c91477e9d3f3e5135262fe404fd1878e339900f0677885f9803b8f3bb8bc10cb00960c06a2d899c390d45a80fc72f48791540bcb30bf16ed9e8b62dc7436d194"]

        let serverAddress = "103.2.196.171"
        let baseUrl = URL(string: "https://\(serverAddress):1337/addKey")!

        let url = URL(string: "https://\(serverAddress):1337/addKey?pubkey=\(wgPublicKey.base64EncodedString())&pt=c91477e9d3f3e5135262fe404fd1878e339900f0677885f9803b8f3bb8bc10cb00960c06a2d899c390d45a80fc72f48791540bcb30bf16ed9e8b62dc7436d194")!

        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)

        let task = session.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
        }

        task.resume()

    }

    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
        {
            
            //SERVER TRUST SETTINGS
            let serverTrust = challenge.protectionSpace.serverTrust

            //GET SERVER CERTIFICATE
            let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust!, 0)
            
            var serverCommonName: CFString!
            SecCertificateCopyCommonName(serverCertificate!, &serverCommonName)
            //TODO Compare this value with the CN from the region response

            let paths = Set([".der"].map { fileExtension in
                Bundle.main.paths(forResourcesOfType: fileExtension, inDirectory: nil)
            }.joined())

            let path = paths.first!
            let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData
            let caRef = SecCertificateCreateWithData(nil, certificateData!)

            //ARRAY OF CA CERTIFICATES
            let caArray = [caRef] as CFArray
            
            //SET DEFAULT SSL POLICY
            let policy = SecPolicyCreateSSL(true, nil)
            var trust: SecTrust!
            
            //Creates a trust management object based on certificates and policies
            let result = SecTrustCreateWithCertificates([serverCertificate!] as CFArray, policy, &trust)

            //SET CA and SET TRUST OBJECT BETWEEN THE CA AND THE TRUST OBJECT FROM THE SERVER CERTIFICATE
            let anchorStatus = SecTrustSetAnchorCertificates(trust!, caArray)
            //SecTrustSetAnchorCertificatesOnly(serverTrust!, false) // also allow regular CAs.

            //EVALUATE REQUEST
            SecTrustEvaluateAsyncWithError(trust!, .global()) { (trust, success, error) in
                
                print(trust)
                print(success)
                print(error)
                
                return challenge.sender!.use(URLCredential(trust: trust), for: challenge)

            }

        }

        // Bad dog
        return challenge.sender!.cancel(challenge)
        
      }
      
}
