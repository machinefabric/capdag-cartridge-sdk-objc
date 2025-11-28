// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FMIOPluginSDK",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        // The main plugin SDK library
        .library(
            name: "FMIOPluginSDK",
            targets: ["FMIOPluginSDK"]),
    ],
    dependencies: [
        // Depend on the cap definition package
        .package(path: "../capns-objc"),
    ],
    targets: [
        // The main plugin SDK target
        .target(
            name: "FMIOPluginSDK",
            dependencies: [
                .product(name: "CapNs", package: "capns-objc"),
            ],
            path: "Sources/FMIOPluginSDK",
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
            name: "FMIOPluginSDKTests",
            dependencies: ["FMIOPluginSDK"],
            path: "Tests/FMIOPluginSDKTests"
        ),
    ]
)