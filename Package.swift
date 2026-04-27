// version: 0.91.569
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MachFabCartridgeSDK",
    platforms: [
        .macOS(.v13),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "MachFabCartridgeSDK",
            targets: ["MachFabCartridgeSDK"]),
    ],
    dependencies: [
        .package(path: "../capdag-objc"),
    ],
    targets: [
        .target(
            name: "MachFabCartridgeSDK",
            dependencies: [
                .product(name: "CapDAG", package: "capdag-objc"),
                .product(name: "Bifaci", package: "capdag-objc"),
            ],
            path: "Sources/MachFabCartridgeSDK",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("OBJC_OLD_DISPATCH_PROTOTYPES", to: "0"),
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
            ]
        ),

        .testTarget(
            name: "MachFabCartridgeSDKTests",
            dependencies: ["MachFabCartridgeSDK"],
            path: "Tests/MachFabCartridgeSDKTests"
        ),
    ]
)
