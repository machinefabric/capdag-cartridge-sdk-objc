// version: 0.67.12065
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FGNDPluginSDK",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        // The main plugin SDK library
        .library(
            name: "FGNDPluginSDK",
            targets: ["FGNDPluginSDK"]),
        // CBOR protocol library
        .library(
            name: "CapNsCbor",
            targets: ["CapNsCborWrapper"]),
    ],
    dependencies: [
        // Depend on the cap definition package
        .package(path: "../capns-objc"),
    ],
    targets: [
        // The main plugin SDK target
        .target(
            name: "FGNDPluginSDK",
            dependencies: [
                .product(name: "CapNs", package: "capns-objc"),
            ],
            path: "Sources/FGNDPluginSDK",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("OBJC_OLD_DISPATCH_PROTOTYPES", to: "0"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
            ]
        ),
        
        // Wrapper target that re-exports CapNsCbor
        .target(
            name: "CapNsCborWrapper",
            dependencies: [
                .product(name: "CapNsCbor", package: "capns-objc"),
            ],
            path: "Sources/CapNsCborWrapper"
        ),

        // Tests target
        .testTarget(
            name: "FGNDPluginSDKTests",
            dependencies: ["FGNDPluginSDK"],
            path: "Tests/FGNDPluginSDKTests"
        ),
    ]
)