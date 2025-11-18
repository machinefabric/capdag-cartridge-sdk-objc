import XCTest
@testable import LBVRPluginSDK

final class LBVRPluginSDKTests: XCTestCase {
    func testStandardCaps() throws {
        // Test that standard caps can be created
        let extractMetadata = LBVRStandardCaps.extractMetadataCap()
        XCTAssertNotNil(extractMetadata)
        XCTAssertEqual(extractMetadata.version, "1.0.0")
        
        let generateThumbnail = LBVRStandardCaps.generateThumbnailCap()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertEqual(generateThumbnail.version, "1.0.0")
        
        let extractOutline = LBVRStandardCaps.extractOutlineCap()
        XCTAssertNotNil(extractOutline)
        XCTAssertEqual(extractOutline.version, "1.0.0")
        
        let extractPages = LBVRStandardCaps.extractPagesCap()
        XCTAssertNotNil(extractPages)
        XCTAssertEqual(extractPages.version, "1.0.0")
    }
    
    func testPluginCaps() throws {
        // Test that plugin caps collection works
        let caps = CSPluginCaps()
        XCTAssertNotNil(caps)
        XCTAssertTrue(caps.isEmpty())
        
        let extractMetadata = LBVRStandardCaps.extractMetadataCap()
        caps.addCap(extractMetadata)
        XCTAssertFalse(caps.isEmpty())
        XCTAssertEqual(caps.count(), 1)
    }
    
    func testProcessingResult() throws {
        // Test processing result creation
        let successResult = LBVRProcessingResult.success(withData: "test data")
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.data as? String, "test data")
        XCTAssertNil(successResult.error)
        
        let failureResult = LBVRProcessingResult.failure(withError: "test error")
        XCTAssertFalse(failureResult.success)
        XCTAssertNil(failureResult.data)
        XCTAssertEqual(failureResult.error, "test error")
    }
}