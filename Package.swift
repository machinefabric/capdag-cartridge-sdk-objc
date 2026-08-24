// version: 1.124.3
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
        // Swift-only utilities (PromptStrategy, classifyPrompt, …)
        // shipped as a sibling of the ObjC core. SwiftPM does not
        // support mixed ObjC + Swift sources in a single target,
        // so these live in their own target that depends on the
        // ObjC core where it needs to. Cartridges that want both
        // import both products.
        .library(
            name: "MachFabCartridgeSDKSwift",
            targets: ["MachFabCartridgeSDKSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/machinefabric/capdag-objc.git", from: "1.438.20"),
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

        .target(
            name: "MachFabCartridgeSDKSwift",
            dependencies: [],
            path: "Sources/MachFabCartridgeSDKSwift"
        ),

        .testTarget(
            name: "MachFabCartridgeSDKTests",
            dependencies: ["MachFabCartridgeSDK", "MachFabCartridgeSDKSwift"],
            path: "Tests/MachFabCartridgeSDKTests"
        ),
    ]
)
