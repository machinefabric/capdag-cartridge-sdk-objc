# CapDAG Cartridge SDK for Swift and Objective-C

This public Swift package contains the Apple-platform mirrors of CapDAG cartridge helpers. It is intentionally small: CapDAG supplies the URN and Bifaci runtime APIs, while this package supplies cartridge-level collections and prompt preparation shared with the Rust SDK.

## Add the package

```swift
dependencies: [
    .package(
        url: "https://github.com/machinefabric/capdag-cartridge-sdk-objc.git",
        from: "1.115.647"
    )
]
```

Import the product you need:

```swift
import CapDAGCartridgeSDK
import CapDAGCartridgeSDKSwift
```

`CapDAGCartridgeSDK` depends on the `CapDAG` and `Bifaci` products from `capdag-objc`. `CapDAGCartridgeSDKSwift` contains Swift-only prompt helpers.

## API reference

### `CSCartridgeCaps`

`CSCartridgeCaps` is an ordered, secure-codable collection of `CSCap` values. `addCap(_:)` appends a cap, `caps` returns the ordered values, and `capUrns()` returns their URN strings. Parse returned strings with `CSCapUrn`; do not compare or route tagged URNs as raw strings.

### Prompt preparation

`RefinedDims`, `PromptStrategy`, `classifyPrompt`, and `DEFAULT_SYSTEM_PROMPT` mirror the Rust SDK's `prompt` module. A recognized chat-template dimension produces a chat-templated strategy; an absent or unknown template conservatively produces a raw prompt. Base models receive no synthetic system turn.

## Verify changes

```bash
swift test
```

Changes to mirrored prompt behavior must be applied to the Rust SDK and pinned by the corresponding substantive numbered tests. Language-neutral runtime behavior belongs to the [CapDAG specification](../../capdag/docs/01-overview.md).
