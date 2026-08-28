// version: 1.134.2
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CapDAGCartridgeSDK",
    platforms: [
        .macOS(.v13),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "CapDAGCartridgeSDK",
            targets: ["CapDAGCartridgeSDK"]),
        // Swift-only utilities (PromptStrategy, classifyPrompt, …)
        // shipped as a sibling of the ObjC core. SwiftPM does not
        // support mixed ObjC + Swift sources in a single target,
        // so these live in their own target that depends on the
        // ObjC core where it needs to. Cartridges that want both
        // import both products.
        .library(
            name: "CapDAGCartridgeSDKSwift",
            targets: ["CapDAGCartridgeSDKSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/machinefabric/capdag-objc.git", from: "1.450.2"),
    ],
    targets: [
        .target(
            name: "CapDAGCartridgeSDK",
            dependencies: [
                .product(name: "CapDAG", package: "capdag-objc"),
                .product(name: "Bifaci", package: "capdag-objc"),
            ],
            path: "Sources/CapDAGCartridgeSDK",
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
            name: "CapDAGCartridgeSDKSwift",
            dependencies: [],
            path: "Sources/CapDAGCartridgeSDKSwift"
        ),

        .testTarget(
            name: "CapDAGCartridgeSDKTests",
            dependencies: ["CapDAGCartridgeSDK", "CapDAGCartridgeSDKSwift"],
            path: "Tests/CapDAGCartridgeSDKTests"
        ),
    ]
)
