import XCTest
@testable import FMIOPluginSDK

final class FMIOPluginSDKTests: XCTestCase {
    func testStandardCaps() throws {
        // Test that standard caps can be created
        let extractMetadata = FMIOStandardCaps.extractMetadataCap()
        XCTAssertNotNil(extractMetadata)
        XCTAssertEqual(extractMetadata.version, "1.0.0")
        
        let generateThumbnail = FMIOStandardCaps.generateThumbnailCap()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertEqual(generateThumbnail.version, "1.0.0")
        
        let extractOutline = FMIOStandardCaps.extractOutlineCap()
        XCTAssertNotNil(extractOutline)
        XCTAssertEqual(extractOutline.version, "1.0.0")
        
        let extractPages = FMIOStandardCaps.extractPagesCap()
        XCTAssertNotNil(extractPages)
        XCTAssertEqual(extractPages.version, "1.0.0")
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
}