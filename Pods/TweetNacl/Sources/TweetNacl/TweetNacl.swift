//
//  Tweetnacl.swift
//  TweetnaclSwift
//
//  Created by Anh Nguyen on 12/9/16.
//  Copyright © 2016 Bitmark. All rights reserved.
//

import Foundation
import CTweetNacl

struct NaclUtil {
    
    public enum NaclUtilError: Error {
        case badKeySize
        case badNonceSize
        case badPublicKeySize
        case badSecretKeySize
        case internalError
    }
    
    static func checkLengths(key: Data, nonce: Data) throws {
        if key.count != crypto_secretbox_KEYBYTES {
            throw(NaclUtilError.badKeySize)
        }
        
        if nonce.count != crypto_secretbox_NONCEBYTES {
            throw NaclUtilError.badNonceSize
        }
    }
    
    static func checkBoxLength(publicKey: Data, secretKey: Data) throws {
        if publicKey.count != crypto_box_PUBLICKEYBYTES {
            throw(NaclUtilError.badPublicKeySize)
        }
        
        if secretKey.count != crypto_box_SECRETKEYBYTES {
            throw(NaclUtilError.badSecretKeySize)
        }
    }
    
    public static func randomBytes(length: Int) throws -> Data {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes {
            return SecRandomCopyBytes(kSecRandomDefault, length, $0)
        }
        guard result == errSecSuccess else {
            throw(NaclUtilError.internalError)
        }
        
        return data
    }
    
    public static func hash(message: Data) throws -> Data {
        var hash = Data(count: crypto_hash_BYTES)
        let r = hash.withUnsafeMutableBytes { (hashPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return message.withUnsafeBytes({ (messagePointer: UnsafePointer<UInt8>) -> Int32 in
                return CTweetNacl.crypto_hash_sha512_tweet(hashPointer, messagePointer, UInt64(message.count))
            })
        }
        
        if r != 0 {
            throw(NaclUtilError.internalError)
        }
        
        return hash
    }
    
    public static func verify(x: Data, y: Data) throws -> Bool {
        if x.count == 0 || y.count == 0 {
            throw NaclUtilError.badKeySize
        }
        
        if x.count != y.count {
            throw NaclUtilError.badKeySize
        }
        
        let r = x.withUnsafeBytes { (xPointer: UnsafePointer<UInt8>) -> Int32 in
            return y.withUnsafeBytes({ (yPointer: UnsafePointer<UInt8>) -> Int32 in
                return CTweetNacl.crypto_verify_32_tweet(xPointer, yPointer)
            })
        }
        
        return r == 0
    }
    
    public static func encodeBase64(data: Data) -> String {
        return data.base64EncodedString()
    }
    
    public static func decodeBase64(string: String) -> Data? {
        return Data(base64Encoded: string)
    }
}

fileprivate struct NaclWrapper {
    public enum NaclWrapperError: Error {
        case invalidParameters
        case internalError
        case creationFailed
    }
    
    fileprivate static func crypto_box_keypair(secretKey sk: Data) throws -> (publicKey: Data, secretKey: Data) {
        var pk = Data(count: crypto_box_SECRETKEYBYTES)
        
        let result = pk.withUnsafeMutableBytes({ (pkPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return sk.withUnsafeBytes({ (skPointer: UnsafePointer<UInt8>) -> Int32 in
                return CTweetNacl.crypto_scalarmult_curve25519_tweet_base(pkPointer, skPointer)
            })
        })
        
        if result != 0 {
            throw NaclWrapperError.internalError
        }
        
        return (pk, sk)
    }
    
    fileprivate static func crypto_sign_keypair() throws -> (publicKey: Data, secretKey: Data) {
        let sk = try NaclUtil.randomBytes(length: crypto_sign_SECRETKEYBYTES)
        
        return try crypto_sign_keypair_seeded(secretKey: sk)
    }
    
    fileprivate static func crypto_sign_keypair_seeded(secretKey: Data) throws -> (publicKey: Data, secretKey: Data) {
        var pk = Data(count: crypto_sign_PUBLICKEYBYTES)
        var sk = Data(count: crypto_sign_SECRETKEYBYTES)
        sk.replaceSubrange(0..<crypto_sign_PUBLICKEYBYTES, with: secretKey.subdata(in: 0..<crypto_sign_PUBLICKEYBYTES))
        
        let result = pk.withUnsafeMutableBytes({ (pkPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return sk.withUnsafeMutableBytes({ (skPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
                return CTweetNacl.crypto_sign_ed25519_tweet_keypair(pkPointer, skPointer)
            })
        })
        
        if result != 0 {
            throw NaclWrapperError.internalError
        }
        
        return (pk, sk)
    }
}

public struct NaclSecretBox {
    public enum NaclSecretBoxError: Error {
        case invalidParameters
        case internalError
        case creationFailed
    }
    
    public static func secretBox(message: Data, nonce: Data, key: Data) throws -> Data {
        try NaclUtil.checkLengths(key: key, nonce: nonce)
        
        var m = Data(count: crypto_secretbox_ZEROBYTES + message.count)
        m.replaceSubrange(crypto_secretbox_ZEROBYTES..<m.count, with: message)
        
        var c = Data(count: m.count)
        
        let result = c.withUnsafeMutableBytes { (cPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return m.withUnsafeBytes({ (mPointer: UnsafePointer<UInt8>) -> Int32 in
                return nonce.withUnsafeBytes({ (noncePointer: UnsafePointer<UInt8>) -> Int32 in
                    return key.withUnsafeBytes({ (keyPointer: UnsafePointer<UInt8>) -> Int32 in
                        return CTweetNacl.crypto_secretbox_xsalsa20poly1305_tweet(cPointer, mPointer, UInt64(m.count), noncePointer, keyPointer)
                    })
                })
            })
        }
        
        if result != 0 {
            throw NaclSecretBoxError.internalError
        }
        return c.subdata(in: crypto_secretbox_BOXZEROBYTES..<c.count)
    }
    
    public static func open(box: Data, nonce: Data, key: Data) throws -> Data {
        try NaclUtil.checkLengths(key: key, nonce: nonce)
        
        // Fill data
        var c = Data(count: crypto_secretbox_BOXZEROBYTES + box.count)
        c.replaceSubrange(crypto_secretbox_BOXZEROBYTES..<c.count, with: box)
        
        var m = Data(count: c.count)
        
        let result = m.withUnsafeMutableBytes { (mPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return c.withUnsafeBytes({ (cPointer: UnsafePointer<UInt8>) -> Int32 in
                return nonce.withUnsafeBytes({ (noncePointer: UnsafePointer<UInt8>) -> Int32 in
                    return key.withUnsafeBytes({ (keyPointer: UnsafePointer<UInt8>) -> Int32 in
                        return CTweetNacl.crypto_secretbox_xsalsa20poly1305_tweet_open(mPointer, cPointer, UInt64(c.count), noncePointer, keyPointer)
                    })
                })
            })
        }
        
        if result != 0 {
            throw(NaclSecretBoxError.creationFailed)
        }
        
        return m.subdata(in: crypto_secretbox_ZEROBYTES..<c.count)
    }
}

public struct NaclScalarMult {
    public enum NaclScalarMultError: Error {
        case invalidParameters
        case internalError
        case creationFailed
    }
    
    public static func scalarMult(n: Data, p: Data) throws -> Data {
        if n.count != crypto_scalarmult_SCALARBYTES {
            throw(NaclScalarMultError.invalidParameters)
        }
        
        if p.count != crypto_scalarmult_BYTES {
            throw(NaclScalarMultError.invalidParameters)
        }
        
        var q = Data(count: crypto_scalarmult_BYTES)
        
        let result = q.withUnsafeMutableBytes { (qPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return n.withUnsafeBytes({ (nPointer: UnsafePointer<UInt8>) -> Int32 in
                return p.withUnsafeBytes({ (pPointer: UnsafePointer<UInt8>) -> Int32 in
                    return CTweetNacl.crypto_scalarmult_curve25519_tweet(qPointer, nPointer, pPointer)
                })
            })
        }
        
        if result != 0 {
            throw(NaclScalarMultError.creationFailed)
        }
        
        return q
    }
    
    public static func base(n: Data) throws -> Data {
        if n.count != crypto_scalarmult_SCALARBYTES {
            throw(NaclScalarMultError.invalidParameters)
        }
        
        var q = Data(count: crypto_scalarmult_BYTES)
        
        let result = q.withUnsafeMutableBytes { (qPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return n.withUnsafeBytes({ (nPointer: UnsafePointer<UInt8>) -> Int32 in
                return CTweetNacl.crypto_scalarmult_curve25519_tweet_base(qPointer, nPointer)
            })
        }
        
        if result != 0 {
            throw(NaclScalarMultError.creationFailed)
        }
        
        return q
    }
}

public struct NaclBox {
    
    public enum NaclBoxError: Error {
        case invalidParameters
        case internalError
        case creationFailed
    }
    
    public static func box(message: Data, nonce: Data, publicKey: Data, secretKey: Data) throws -> Data {
        let key = try before(publicKey: publicKey, secretKey: secretKey)
        return try NaclSecretBox.secretBox(message: message, nonce: nonce, key: key)
    }
    
    public static func before(publicKey: Data, secretKey: Data) throws -> Data {
        try NaclUtil.checkBoxLength(publicKey: publicKey, secretKey: secretKey)
        
        var k = Data(count: crypto_box_BEFORENMBYTES)
        
        let result = k.withUnsafeMutableBytes { (kPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return publicKey.withUnsafeBytes({ (pkPointer: UnsafePointer<UInt8>) -> Int32 in
                return secretKey.withUnsafeBytes({ (skPointer: UnsafePointer<UInt8>) -> Int32 in
                    return CTweetNacl.crypto_box_curve25519xsalsa20poly1305_tweet_beforenm(kPointer, pkPointer, skPointer)
                })
            })
        }
        
        if result != 0 {
            throw(NaclBoxError.creationFailed)
        }
        
        return k
    }
    
    public static func open(message: Data, nonce: Data, publicKey: Data, secretKey: Data) throws -> Data {
        let k = try before(publicKey: publicKey, secretKey: secretKey)
        return try NaclSecretBox.open(box: message, nonce: nonce, key: k)
    }
    
    public static func keyPair() throws -> (publicKey: Data, secretKey: Data) {
        let sk = try NaclUtil.randomBytes(length: crypto_box_SECRETKEYBYTES)
        
        return try NaclWrapper.crypto_box_keypair(secretKey: sk)
    }
    
    public static func keyPair(fromSecretKey sk: Data) throws -> (publicKey: Data, secretKey: Data) {
        if sk.count != crypto_sign_SECRETKEYBYTES {
            throw(NaclBoxError.invalidParameters)
        }
        
        return try NaclWrapper.crypto_box_keypair(secretKey: sk)
    }
}

public struct NaclSign {
    
    public enum NaclSignError: Error {
        case invalidParameters
        case internalError
        case creationFailed
    }
    
    public static func sign(message: Data, secretKey: Data) throws -> Data {
        if secretKey.count != crypto_sign_SECRETKEYBYTES {
            throw(NaclSignError.invalidParameters)
        }
        
        var signedMessage = Data(count: crypto_sign_BYTES + message.count)
        
        let tmpLength = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        
        let result = signedMessage.withUnsafeMutableBytes { (signedMessagePointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return message.withUnsafeBytes({ (messagePointer: UnsafePointer<UInt8>) -> Int32 in
                return secretKey.withUnsafeBytes({ (secretKeyPointer: UnsafePointer<UInt8>) -> Int32 in
                    return CTweetNacl.crypto_sign_ed25519_tweet(signedMessagePointer, tmpLength, messagePointer, UInt64(message.count), secretKeyPointer)
                })
            })
        }
        
        if result != 0 {
            throw NaclSignError.internalError
        }
        
        return signedMessage
    }
    
    public static func signOpen(signedMessage: Data, publicKey: Data) throws -> Data {
        if publicKey.count != crypto_sign_PUBLICKEYBYTES {
            throw(NaclSignError.invalidParameters)
        }
        
        var tmp = Data(count: signedMessage.count)
        let tmpLength = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        
        let result = tmp.withUnsafeMutableBytes { (tmpPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return signedMessage.withUnsafeBytes({ (signMessagePointer: UnsafePointer<UInt8>) -> Int32 in
                return publicKey.withUnsafeBytes({ (publicKeyPointer: UnsafePointer<UInt8>) -> Int32 in
                    return CTweetNacl.crypto_sign_ed25519_tweet_open(tmpPointer, tmpLength, signMessagePointer, UInt64(signedMessage.count), publicKeyPointer)
                })
            })
        }
        
        if result != 0 {
            throw(NaclSignError.creationFailed)
        }
        
        return tmp
    }
    
    public static func signDetached(message: Data, secretKey: Data) throws -> Data {
        let signedMessage = try sign(message: message, secretKey: secretKey)
        
        let sig = signedMessage.subdata(in: 0..<crypto_sign_BYTES)
        
        return sig as Data
    }
    
    public static func signDetachedVerify(message: Data, sig: Data, publicKey: Data) throws -> Bool {
        if sig.count != crypto_sign_BYTES {
            throw(NaclSignError.invalidParameters)
        }
        
        if publicKey.count != crypto_sign_PUBLICKEYBYTES {
            throw(NaclSignError.invalidParameters)
        }
        
        var sm = Data()
        
        var m = Data(count: crypto_sign_BYTES + message.count)
        
        sm.append(sig )
        sm.append(message)
        
        let tmpLength = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        
        let result = m.withUnsafeMutableBytes { (mPointer: UnsafeMutablePointer<UInt8>) -> Int32 in
            return sm.withUnsafeBytes({ (smPointer: UnsafePointer<UInt8>) -> Int32 in
                return publicKey.withUnsafeBytes({ (publicKeyPointer: UnsafePointer<UInt8>) -> Int32 in
                    return CTweetNacl.crypto_sign_ed25519_tweet_open(mPointer, tmpLength, smPointer, UInt64(sm.count), publicKeyPointer)
                })
            })
        }
        
        return result == 0
    }
    
    public struct KeyPair {
        public static func keyPair() throws -> (publicKey: Data, secretKey: Data) {
            return try NaclWrapper.crypto_sign_keypair()
        }
        
        public static func keyPair(fromSecretKey secretKey: Data) throws -> (publicKey: Data, secretKey: Data) {
            if secretKey.count != crypto_sign_SECRETKEYBYTES {
                throw(NaclSignError.invalidParameters)
            }
            
            let pk = secretKey.subdata(in: crypto_sign_PUBLICKEYBYTES..<crypto_sign_SECRETKEYBYTES)
            
            return (pk, secretKey)
        }
        
        public static func keyPair(fromSeed seed: Data) throws -> (publicKey: Data, secretKey: Data) {
            if seed.count != 32 {
                throw(NaclSignError.invalidParameters)
            }
            
            return try NaclWrapper.crypto_sign_keypair_seeded(secretKey: seed)
        }
    }
}

