import XCTest
@testable import MACINAPluginSDK
@testable import CapDAG

final class MACINAPluginSDKTests: XCTestCase {
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
    
    func testPluginCaps() throws {
        // Test that plugin caps collection works
        let caps = CSPluginCaps()
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
    
    func testCapDAGIntegration() throws {
        // Test that we can use CSCapCaller and CSResponseWrapper from capdag-objc
        let registry = MACINAPluginRegistry.shared()
        
        // Register a dummy plugin for testing
        registry.registerPlugin("test-plugin", 
                               binaryPath: "/bin/echo", 
                               caps: ["extract-metadata"])
        
        // Test that we can get a CSCapCaller
        let caller = registry.can("extract-metadata")
        XCTAssertNotNil(caller)
    }
    
    func testManifestWithoutVersion() throws {
        // Test creating manifest without explicit version parameter
        let caps = MACINAStandardCaps.allStandardCaps()
        let manifest = CSCapManifest.plugin(withName: "test-plugin",
                                          description: "Test plugin",
                                          caps: caps)
        
        XCTAssertNotNil(manifest)
        XCTAssertEqual(manifest.name, "test-plugin")
        XCTAssertEqual(manifest.version, "1.0.0")  // Should default to 1.0.0
        XCTAssertEqual(manifest.manifestDescription, "Test plugin")
        XCTAssertEqual(manifest.caps.count, caps.count)
    }
}