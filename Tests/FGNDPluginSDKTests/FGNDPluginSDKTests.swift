import XCTest
@testable import FGNDPluginSDK
@testable import CapNs

final class FGNDPluginSDKTests: XCTestCase {
    func testStandardCaps() throws {
        // Test that standard caps can be created
        let extractMetadata = FGNDStandardCaps.extractMetadataCap()
        XCTAssertNotNil(extractMetadata)
        XCTAssertNotNil(extractMetadata.command)
        
        let generateThumbnail = FGNDStandardCaps.generateThumbnailCap()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertNotNil(generateThumbnail.command)
        
        let extractOutline = FGNDStandardCaps.extractOutlineCap()
        XCTAssertNotNil(extractOutline)
        XCTAssertNotNil(extractOutline.command)
        
        let extractPages = FGNDStandardCaps.extractPagesCap()
        XCTAssertNotNil(extractPages)
        XCTAssertNotNil(extractPages.command)
    }
    
    func testPluginCaps() throws {
        // Test that plugin caps collection works
        let caps = CSPluginCaps()
        XCTAssertNotNil(caps)
        XCTAssertTrue(caps.isEmpty())
        
        let extractMetadata = FGNDStandardCaps.extractMetadataCap()
        caps.addCap(extractMetadata)
        XCTAssertFalse(caps.isEmpty())
        XCTAssertEqual(caps.count(), 1)
    }
    
    func testProcessingResult() throws {
        // Test processing result creation
        let successResult = FGNDProcessingResult.success(withData: "test data")
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.data as? String, "test data")
        XCTAssertNil(successResult.error)
        
        let failureResult = FGNDProcessingResult.failure(withError: "test error")
        XCTAssertFalse(failureResult.success)
        XCTAssertNil(failureResult.data)
        XCTAssertEqual(failureResult.error, "test error")
    }
    
    func testCapNsIntegration() throws {
        // Test that we can use CSCapCaller and CSResponseWrapper from capns-objc
        let registry = FGNDPluginRegistry.shared()
        
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
        let caps = FGNDStandardCaps.allStandardCaps()
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