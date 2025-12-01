import XCTest
@testable import FMIOPluginSDK
@testable import CapNs

final class FMIOPluginSDKTests: XCTestCase {
    func testStandardCaps() throws {
        // Test that standard caps can be created
        let extractMetadata = FMIOStandardCaps.extractMetadataCap()
        XCTAssertNotNil(extractMetadata)
        XCTAssertNotNil(extractMetadata.command)
        
        let generateThumbnail = FMIOStandardCaps.generateThumbnailCap()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertNotNil(generateThumbnail.command)
        
        let extractOutline = FMIOStandardCaps.extractOutlineCap()
        XCTAssertNotNil(extractOutline)
        XCTAssertNotNil(extractOutline.command)
        
        let extractPages = FMIOStandardCaps.extractPagesCap()
        XCTAssertNotNil(extractPages)
        XCTAssertNotNil(extractPages.command)
    }
    
    func testPluginCaps() throws {
        // Test that plugin caps collection works
        let caps = CSPluginCaps()
        XCTAssertNotNil(caps)
        XCTAssertTrue(caps.isEmpty())
        
        let extractMetadata = FMIOStandardCaps.extractMetadataCap()
        caps.addCap(extractMetadata)
        XCTAssertFalse(caps.isEmpty())
        XCTAssertEqual(caps.count(), 1)
    }
    
    func testProcessingResult() throws {
        // Test processing result creation
        let successResult = FMIOProcessingResult.success(withData: "test data")
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.data as? String, "test data")
        XCTAssertNil(successResult.error)
        
        let failureResult = FMIOProcessingResult.failure(withError: "test error")
        XCTAssertFalse(failureResult.success)
        XCTAssertNil(failureResult.data)
        XCTAssertEqual(failureResult.error, "test error")
    }
    
    func testCapNsIntegration() throws {
        // Test that we can use CSCapCaller and CSResponseWrapper from capns-objc
        let registry = FMIOPluginRegistry.shared()
        
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
        let caps = FMIOStandardCaps.allStandardCaps()
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