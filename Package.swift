// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PIAWireguard",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "PIAWireguard", targets: ["WireGuardKit", "PIAWireguardGo", "WireGuardKitC"])
    ],
    dependencies: [.package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", .exact("1.1.0"))],
    targets: [
        .target(
            name: "WireGuardKit",
            dependencies: ["WireGuardKitC", .product(name: "TweetNacl", package: "tweetnacl-swiftwrap")]
        ),
        .target(
            name: "WireGuardKitC",
            dependencies: [],
            publicHeadersPath: "."
        ),
        .binaryTarget(
            name: "PIAWireguardGo",
            path: "PIAWireguardGo.xcframework"
        ),
//        .target(
//            name: "WireGuardKitGo",
//            dependencies: [],
//            exclude: [
//                "goruntime-boottime-over-monotonic.diff",
//                "go.mod",
//                "go.sum",
//                "api-apple.go",
//                "Makefile"
//            ],
//            publicHeadersPath: ".",
//            linkerSettings: [.linkedLibrary("wg-go")]
//        )
    ]
)
