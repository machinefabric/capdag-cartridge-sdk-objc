# Swift/ObjC Test Catalog

**Total Tests:** 9

**Numbered Tests:** 0

**Unnumbered Tests:** 9

**Numbered Tests Missing Descriptions:** 0

**Numbering Mismatches:** 0

All numbered test numbers are unique.

This catalog lists all tests in the Swift/ObjC codebase.

| Test # | Function Name | Description | File |
|--------|---------------|-------------|------|
| | | | |
| unnumbered | `testAbsentTemplateRoutesToRaw` | / **Core regression guard.** Empty `chat_template` means a / base / completion model — the cartridge MUST NOT / chat-template the input. Routing the other way (raw model / into chat-template rendering) would corrupt the completion. | Tests/MachFabCartridgeSDKTests/PromptTests.swift:52 |
| unnumbered | `testAddCapRoundTripUrnViaTaggedPredicates` | / Round-trip: adding a CSCap produces a urn string that parses back to a / CSCapUrn whose `accepts(_:)` predicate holds against itself / (reflexivity of the accepts relation). | Tests/MachFabCartridgeSDKTests/MachFabCartridgeSDKTests.swift:27 |
| unnumbered | `testCopyIsIndependent` | / Copy is independent: mutating the original must not affect the copy. / Regression-guards against a shared mutable backing array. | Tests/MachFabCartridgeSDKTests/MachFabCartridgeSDKTests.swift:70 |
| unnumbered | `testDefaultSystemPromptIsTaskAgnostic` | / `DEFAULT_SYSTEM_PROMPT` must remain task-agnostic — biases / toward code / summarisation / translation would silently / derail unrelated downstream uses. Mirrors the parallel test / in the Rust SDK so drift between the two literals is caught. | Tests/MachFabCartridgeSDKTests/PromptTests.swift:100 |
| unnumbered | `testInsertionOrderPreserved` | / Insertion order is preserved in both `caps` and `capUrns`. | Tests/MachFabCartridgeSDKTests/MachFabCartridgeSDKTests.swift:46 |
| unnumbered | `testJinjaTemplateRoutesToChatTemplated` |  | Tests/MachFabCartridgeSDKTests/PromptTests.swift:20 |
| unnumbered | `testShortNameTemplateRoutesToChatTemplated` |  | Tests/MachFabCartridgeSDKTests/PromptTests.swift:34 |
| unnumbered | `testUnknownChatTemplateTagRoutesToRaw` |  | Tests/MachFabCartridgeSDKTests/PromptTests.swift:83 |
| unnumbered | `testWhitespaceOnlySystemPromptDropped` |  | Tests/MachFabCartridgeSDKTests/PromptTests.swift:65 |
---

## Unnumbered Tests

The following tests are cataloged but do not currently participate in numeric test indexing.

- `testAbsentTemplateRoutesToRaw` — Tests/MachFabCartridgeSDKTests/PromptTests.swift:52
- `testAddCapRoundTripUrnViaTaggedPredicates` — Tests/MachFabCartridgeSDKTests/MachFabCartridgeSDKTests.swift:27
- `testCopyIsIndependent` — Tests/MachFabCartridgeSDKTests/MachFabCartridgeSDKTests.swift:70
- `testDefaultSystemPromptIsTaskAgnostic` — Tests/MachFabCartridgeSDKTests/PromptTests.swift:100
- `testInsertionOrderPreserved` — Tests/MachFabCartridgeSDKTests/MachFabCartridgeSDKTests.swift:46
- `testJinjaTemplateRoutesToChatTemplated` — Tests/MachFabCartridgeSDKTests/PromptTests.swift:20
- `testShortNameTemplateRoutesToChatTemplated` — Tests/MachFabCartridgeSDKTests/PromptTests.swift:34
- `testUnknownChatTemplateTagRoutesToRaw` — Tests/MachFabCartridgeSDKTests/PromptTests.swift:83
- `testWhitespaceOnlySystemPromptDropped` — Tests/MachFabCartridgeSDKTests/PromptTests.swift:65

---

*Generated from Swift/ObjC source tree*
*Total tests: 9*
*Total numbered tests: 0*
*Total unnumbered tests: 9*
*Total numbered tests missing descriptions: 0*
*Total numbering mismatches: 0*
