# Swift/ObjC Test Catalog

**Total Tests:** 9

**Numbered Tests:** 9

**Unnumbered Tests:** 0

**Numbered Tests Missing Descriptions:** 0

**Numbering Mismatches:** 0

All numbered test numbers are unique.

This catalog lists all tests in the Swift/ObjC codebase.

| Test # | Function Name | Description | File |
|--------|---------------|-------------|------|
| test0001 | `test0001_AddCapRoundTripUrnViaTaggedPredicates` | / Round-trip: adding a CSCap produces a urn string that parses back to a / CSCapUrn whose `accepts(_:)` predicate holds against itself / (reflexivity of the accepts relation). | Tests/CapDAGCartridgeSDKTests/CapDAGCartridgeSDKTests.swift:27 |
| test0002 | `test0002_InsertionOrderPreserved` | / Insertion order is preserved in both `caps` and `capUrns`. | Tests/CapDAGCartridgeSDKTests/CapDAGCartridgeSDKTests.swift:46 |
| test0003 | `test0003_CopyIsIndependent` | / Copy is independent: mutating the original must not affect the copy. / Regression-guards against a shared mutable backing array. | Tests/CapDAGCartridgeSDKTests/CapDAGCartridgeSDKTests.swift:70 |
| test0004 | `test0004_JinjaTemplateRoutesToChatTemplated` | TEST0004: Jinja template routes to chat templated | Tests/CapDAGCartridgeSDKTests/PromptTests.swift:21 |
| test0005 | `test0005_ShortNameTemplateRoutesToChatTemplated` | TEST0005: Short name template routes to chat templated | Tests/CapDAGCartridgeSDKTests/PromptTests.swift:36 |
| test0006 | `test0006_AbsentTemplateRoutesToRaw` | / **Core regression guard.** Empty `chat_template` means a / base / completion model — the cartridge MUST NOT / chat-template the input. Routing the other way (raw model / into chat-template rendering) would corrupt the completion. | Tests/CapDAGCartridgeSDKTests/PromptTests.swift:54 |
| test0007 | `test0007_WhitespaceOnlySystemPromptDropped` | TEST0007: Whitespace only system prompt dropped | Tests/CapDAGCartridgeSDKTests/PromptTests.swift:68 |
| test0008 | `test0008_UnknownChatTemplateTagRoutesToRaw` | TEST0008: Unknown chat template tag routes to raw | Tests/CapDAGCartridgeSDKTests/PromptTests.swift:87 |
| test0009 | `test0009_DefaultSystemPromptIsTaskAgnostic` | / `DEFAULT_SYSTEM_PROMPT` must remain task-agnostic — biases / toward code / summarisation / translation would silently / derail unrelated downstream uses. Mirrors the parallel test / in the Rust SDK so drift between the two literals is caught. | Tests/CapDAGCartridgeSDKTests/PromptTests.swift:104 |
---

*Generated from Swift/ObjC source tree*
*Total tests: 9*
*Total numbered tests: 9*
*Total unnumbered tests: 0*
*Total numbered tests missing descriptions: 0*
*Total numbering mismatches: 0*
