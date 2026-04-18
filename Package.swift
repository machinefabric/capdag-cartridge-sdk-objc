// version: 0.88.528
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MACINACartridgeSDK",
    platforms: [
        .macOS(.v13),
        .iOS(.v14)
    ],
    products: [
        // The main cartridge SDK library
        .library(
            name: "MACINACartridgeSDK",
            targets: ["MACINACartridgeSDK"]),
    ],
    dependencies: [
        // Depend on the cap definition package
        .package(path: "../capdag-objc"),
    ],
    targets: [
        // The main cartridge SDK target
        .target(
            name: "MACINACartridgeSDK",
            dependencies: [
                .product(name: "CapDAG", package: "capdag-objc"),
                .product(name: "Bifaci", package: "capdag-objc"),
            ],
            path: "Sources/MACINACartridgeSDK",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("OBJC_OLD_DISPATCH_PROTOTYPES", to: "0"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
            ]
        ),

        // Tests target
        .testTarget(
            name: "MACINACartridgeSDKTests",
            dependencies: ["MACINACartridgeSDK"],
            path: "Tests/MACINACartridgeSDKTests"
        ),
    ]
)
