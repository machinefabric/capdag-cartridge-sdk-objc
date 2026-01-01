import XCTest
@testable import FGRNDPluginSDK
@testable import CapNs

final class FGRNDPluginSDKTests: XCTestCase {
    func testStandardCaps() throws {
        // Test that standard caps can be created
        let extractMetadata = FGRNDStandardCaps.extractMetadataCap()
        XCTAssertNotNil(extractMetadata)
        XCTAssertNotNil(extractMetadata.command)
        
        let generateThumbnail = FGRNDStandardCaps.generateThumbnailCap()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertNotNil(generateThumbnail.command)
        
        let extractOutline = FGRNDStandardCaps.extractOutlineCap()
        XCTAssertNotNil(extractOutline)
        XCTAssertNotNil(extractOutline.command)
        
        let extractPages = FGRNDStandardCaps.extractPagesCap()
        XCTAssertNotNil(extractPages)
        XCTAssertNotNil(extractPages.command)
    }
    
    func testPluginCaps() throws {
        // Test that plugin caps collection works
        let caps = CSPluginCaps()
        XCTAssertNotNil(caps)
        XCTAssertTrue(caps.isEmpty())
        
        let extractMetadata = FGRNDStandardCaps.extractMetadataCap()
        caps.addCap(extractMetadata)
        XCTAssertFalse(caps.isEmpty())
        XCTAssertEqual(caps.count(), 1)
    }
    
    func testProcessingResult() throws {
        // Test processing result creation
        let successResult = FGRNDProcessingResult.success(withData: "test data")
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.data as? String, "test data")
        XCTAssertNil(successResult.error)
        
        let failureResult = FGRNDProcessingResult.failure(withError: "test error")
        XCTAssertFalse(failureResult.success)
        XCTAssertNil(failureResult.data)
        XCTAssertEqual(failureResult.error, "test error")
    }
    
    func testCapNsIntegration() throws {
        // Test that we can use CSCapCaller and CSResponseWrapper from capns-objc
        let registry = FGRNDPluginRegistry.shared()
        
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
        let caps = FGRNDStandardCaps.allStandardCaps()
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