// version: 0.80.12908
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MACINAPluginSDK",
    platforms: [
        .macOS(.v13),
        .iOS(.v14)
    ],
    products: [
        // The main plugin SDK library
        .library(
            name: "MACINAPluginSDK",
            targets: ["MACINAPluginSDK"]),
    ],
    dependencies: [
        // Depend on the cap definition package
        .package(path: "../capns-objc"),
    ],
    targets: [
        // The main plugin SDK target
        .target(
            name: "MACINAPluginSDK",
            dependencies: [
                .product(name: "CapNs", package: "capns-objc"),
                .product(name: "Bifaci", package: "capns-objc"),
            ],
            path: "Sources/MACINAPluginSDK",
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
            name: "MACINAPluginSDKTests",
            dependencies: ["MACINAPluginSDK"],
            path: "Tests/MACINAPluginSDKTests"
        ),
    ]
)
