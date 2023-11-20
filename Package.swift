// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireGuardKit",
    platforms: [
        .iOS(.v12)
//        .tvOS(.v17)
    ],
    products: [
        .library(name: "WireGuardKit", targets: ["WireGuardKit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WireGuardKit",
            dependencies: ["WireGuardKitGo", "WireGuardKitC"]
        ),
        .target(
            name: "WireGuardKitC",
            dependencies: [],
            publicHeadersPath: "."
        ),
        .target(
            name: "WireGuardKitGo",
            dependencies: [],
            exclude: [
                "goruntime-boottime-over-monotonic.diff",
                "go.mod",
                "go.sum",
                "api-apple.go",
                "Makefile"
            ],
            publicHeadersPath: ".",
            linkerSettings: [.linkedLibrary("wg-go")]
        )
    ]
)


//let package = Package(
//    name: "PIAWireguard",
//    platforms: [
//      .iOS(.v12), .tvOS(.v17)
//    ],
//    products: [
//        .library(
//            name: "PIAWireguard", 
//            targets: [
//                "PIAWireguard",
//                "PIAWireguardC",
//                "PIAWireguardGo",
//            ]
//        ),
//    ],
//    dependencies: [
//        .package(url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git", .exact("1.1.0")),
//        .package(url: "https://github.com/Alamofire/Alamofire.git", .exact("5.0.1")),
//
//    ],
//    targets: [
//        .target(
//            name: "PIAWireguard", 
//            dependencies: [
//                "PIAWireguardC",
//                "Alamofire",
//                .product(name: "TweetNacl", package: "tweetnacl-swiftwrap"),
//            ],
//            resources: [
//                .process("Resources")
//            ]
//        ),
//        .target(
//            name: "PIAWireguardC", 
//            dependencies: [ ]
//        ),
//        .binaryTarget(
//            name: "PIAWireguardGo",
//            path: "PIAWireguardGo.xcframework"
//        ),
//    ]
//)
