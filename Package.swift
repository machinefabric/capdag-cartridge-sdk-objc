// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LBVRPluginSDK",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        // The main plugin SDK library
        .library(
            name: "LBVRPluginSDK",
            targets: ["LBVRPluginSDK"]),
    ],
    dependencies: [
        // Depend on the capability definition package
        .package(path: "../capdef-objc"),
    ],
    targets: [
        // The main plugin SDK target
        .target(
            name: "LBVRPluginSDK",
            dependencies: [
                .product(name: "CapDef", package: "capdef-objc"),
            ],
            path: "Sources/LBVRPluginSDK",
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
            name: "LBVRPluginSDKTests",
            dependencies: ["LBVRPluginSDK"],
            path: "Tests/LBVRPluginSDKTests"
        ),
    ]
)