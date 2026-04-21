import XCTest
@testable import MACINACartridgeSDK
@testable import CapDAG

final class MACINACartridgeSDKTests: XCTestCase {
    func testStandardCaps() throws {
        // Test that standard caps can be created
        let extractMetadata = MACINAStandardCaps.extractMetadataCap()
        XCTAssertNotNil(extractMetadata)
        XCTAssertNotNil(extractMetadata.command)
        
        let generateThumbnail = MACINAStandardCaps.generateThumbnailCap()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertNotNil(generateThumbnail.command)
        
        let extractOutline = MACINAStandardCaps.extractOutlineCap()
        XCTAssertNotNil(extractOutline)
        XCTAssertNotNil(extractOutline.command)
        
        let disbind = MACINAStandardCaps.disbindCap()
        XCTAssertNotNil(disbind)
        XCTAssertNotNil(disbind.command)
    }
    
    func testCartridgeCaps() throws {
        // Test that cartridge caps collection works
        let caps = CSCartridgeCaps()
        XCTAssertNotNil(caps)
        XCTAssertTrue(caps.isEmpty())
        
        let extractMetadata = MACINAStandardCaps.extractMetadataCap()
        caps.addCap(extractMetadata)
        XCTAssertFalse(caps.isEmpty())
        XCTAssertEqual(caps.count(), 1)
    }
    
    func testProcessingResult() throws {
        // Test processing result creation
        let successResult = MACINAProcessingResult.success(withData: "test data")
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.data as? String, "test data")
        XCTAssertNil(successResult.error)
        
        let failureResult = MACINAProcessingResult.failure(withError: "test error")
        XCTAssertFalse(failureResult.success)
        XCTAssertNil(failureResult.data)
        XCTAssertEqual(failureResult.error, "test error")
    }
    
    func testManifestWithoutVersion() throws {
        // Test creating manifest without explicit version parameter
        let caps = MACINAStandardCaps.allStandardCaps()
        let manifest = CSCapManifest.cartridge(withName: "test-cartridge",
                                          description: "Test cartridge",
                                          caps: caps)
        
        XCTAssertNotNil(manifest)
        XCTAssertEqual(manifest.name, "test-cartridge")
        XCTAssertEqual(manifest.version, "1.0.0")  // Should default to 1.0.0
        XCTAssertEqual(manifest.manifestDescription, "Test cartridge")
        XCTAssertEqual(manifest.caps.count, caps.count)
    }
}