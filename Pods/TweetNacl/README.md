# TweetNacl
[TweetNaCl](http://tweetnacl.cr.yp.to) wrapper, written in Swift

[![Build Status](https://travis-ci.org/bitmark-inc/tweetnacl-swiftwrap.svg?branch=master)](https://travis-ci.org/bitmark-inc/tweetnacl-swiftwrap) [![codecov](https://codecov.io/gh/bitmark-inc/tweetnacl-swiftwrap/branch/master/graph/badge.svg)](https://codecov.io/gh/bitmark-inc/tweetnacl-swiftwrap)

## Requirements
- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 9.0+
- Swift 4.0+

## Installation

### CocoaPods
[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1+ is required to build TweetNacl 1.0+.

To integrate TweetNacl into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'TweetNacl', '~> 1.0.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate TweetNacl into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "bitmark-inc/tweetnacl-swiftwrap" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `TweetNacl.framework` into your Xcode project.

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but TweetNacl does support its use on supported platforms. 

Once you have your Swift package set up, adding TweetNacl as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .Package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", majorVersion: 1)
]
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate TweetNacl into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

  ```bash
  $ git init
  ```

- Add TweetNacl as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

  ```bash
  $ git submodule add https://github.com/bitmark-inc/tweetnacl-swiftwrap.git
  ```

- Open the new `TweetNacl` folder, and drag the `TweetNacl.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `TweetNacl.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `TweetNacl.xcodeproj` folders each with two different versions of the `TweetNacl.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `TweetNacl.framework`.

- Select the top `TweetNacl.framework` for iOS and the bottom one for OS X.

    > You can verify which one you selected by inspecting the build log for your project. The build target for `TweetNacl` will be listed as either `TweetNacl-iOS`, `TweetNacl-macOS`, `TweetNacl-tvOS` or `TweetNacl-watchOS`.

- And that's it!

  > The `TweetNacl.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

---

## Usage
All API functions accept and return [Data](https://developer.apple.com/documentation/foundation/data).

### Public-key authenticated encryption (box)

Implements *curve25519-xsalsa20-poly1305*.

#### NaclBox.keyPair()

Generates a new random key pair for box and returns it as an object with
`publicKey` and `secretKey` members:

    {
       publicKey: ...,  // Data with 32-byte public key
       secretKey: ...   // Data with 32-byte secret key
    }


#### NaclBox.keyPair(fromSecretKey:)

Returns a key pair for box with public key corresponding to the given secret
key.

#### NaclBox.box(message, nonce, theirPublicKey, mySecretKey)

Encrypt and authenticates message using peer's public key, our secret key, and
the given nonce, which must be unique for each distinct message for a key pair.

#### NaclBox.open(box, nonce, theirPublicKey, mySecretKey)

Authenticates and decrypts the given box with peer's public key, our secret
key, and the given nonce.

Returns the original message, or `false` if authentication fails.

#### NaclBox.before(theirPublicKey, mySecretKey)

Returns a precomputed shared key which can be used in `NaclBox.after` and
`NaclBox.open.after`.

#### NaclBox.after(message, nonce, sharedKey)

Same as `NaclBox`, but uses a shared key precomputed with `NaclBox.before`.

#### NaclBox.open.after(box, nonce, sharedKey)

Same as `NaclBox.open`, but uses a shared key precomputed with `NaclBox.before`.

#### NaclBox.publicKeyLength = 32

Length of public key in bytes.

#### NaclBox.secretKeyLength = 32

Length of secret key in bytes.

#### NaclBox.sharedKeyLength = 32

Length of precomputed shared key in bytes.

#### NaclBox.nonceLength = 24

Length of nonce in bytes.

#### NaclBox.overheadLength = 16

Length of overhead added to box compared to original message.


### Secret-key authenticated encryption (secretbox)

Implements *xsalsa20-poly1305*.

#### NaclSecretBox.secretBox(message, nonce, key)

Encrypt and authenticates message using the key and the nonce. The nonce must
be unique for each distinct message for this key.

Returns an encrypted and authenticated message.

#### NaclSecretBox.open(box, nonce, key)

Authenticates and decrypts the given secret box using the key and the nonce.

Returns the original message, or `false` if authentication fails.

#### NaclSecretBox.keyLength = 32

Length of key in bytes.

#### NaclSecretBox.nonceLength = 24

Length of nonce in bytes.

#### NaclSecretBox.overheadLength = 16

Length of overhead added to secret box compared to original message.


### Scalar multiplication

Implements [e25519](http://ed25519.cr.yp.to).

#### NaclScalarMult(n, p)

Multiplies an integer `n` by a group element `p` and returns the resulting
group element.

#### NaclScalarMult.base(n)

Multiplies an integer `n` by a standard group element and returns the resulting
group element.

#### NaclScalarMult.scalarLength = 32

Length of scalar in bytes.

#### NaclScalarMult.groupElementLength = 32

Length of group element in bytes.


### Signatures

Implements [ed25519](http://ed25519.cr.yp.to).

#### NaclSign.keyPair()

Generates new random key pair for signing and returns it as an object with
`publicKey` and `secretKey` members:

    {
       publicKey: ...,  // Data with 32-byte public key
       secretKey: ...   // Data with 64-byte secret key
    }

#### NaclSign.keyPair.fromSecretKey(secretKey)

Returns a signing key pair with public key corresponding to the given
64-byte secret key. The secret key must have been generated by
`NaclSign.KeyPair` or `NaclSign.KeyPair.fromSeed`.

#### NaclSign.keyPair.fromSeed(seed)

Returns a new signing key pair generated deterministically from a 32-byte seed.
The seed must contain enough entropy to be secure. This method is not
recommended for general use: instead, use `NaclSign.KeyPair` to generate a new
key pair from a random seed.

#### NaclSign(message, secretKey)

Signs the message using the secret key and returns a signed message.

#### NaclSign.open(signedMessage, publicKey)

Verifies the signed message and returns the message without signature.

Returns `nil` if verification failed.

#### NaclSign.detached(message, secretKey)

Signs the message using the secret key and returns a signature.

#### NaclSign.detached.verify(message, signature, publicKey)

Verifies the signature for the message and returns `true` if verification
succeeded or `false` if it failed.

#### NaclSign.publicKeyLength = 32

Length of signing public key in bytes.

#### NaclSign.secretKeyLength = 64

Length of signing secret key in bytes.

#### NaclSign.seedLength = 32

Length of seed for `NaclSign.KeyPair.keyPair(fromSeed:` in bytes.

#### NaclSign.signatureLength = 64

Length of signature in bytes.



# License

Copyright (c) 2014-2015 Bitmark Inc (support@bitmark.com).

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.