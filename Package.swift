// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FGRNDPluginSDK",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        // The main plugin SDK library
        .library(
            name: "FGRNDPluginSDK",
            targets: ["FGRNDPluginSDK"]),
    ],
    dependencies: [
        // Depend on the cap definition package
        .package(path: "../capns-objc"),
    ],
    targets: [
        // The main plugin SDK target
        .target(
            name: "FGRNDPluginSDK",
            dependencies: [
                .product(name: "CapNs", package: "capns-objc"),
            ],
            path: "Sources/FGRNDPluginSDK",
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
            name: "FGRNDPluginSDKTests",
            dependencies: ["FGRNDPluginSDK"],
            path: "Tests/FGRNDPluginSDKTests"
        ),
    ]
)