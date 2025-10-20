import XCTest
@testable import LBVRPluginSDK

final class LBVRPluginSDKTests: XCTestCase {
    func testStandardCapabilities() throws {
        // Test that standard capabilities can be created
        let extractMetadata = LBVRStandardCapabilities.extractMetadataCapability()
        XCTAssertNotNil(extractMetadata)
        XCTAssertEqual(extractMetadata.version, "1.0.0")
        
        let generateThumbnail = LBVRStandardCapabilities.generateThumbnailCapability()
        XCTAssertNotNil(generateThumbnail)
        XCTAssertEqual(generateThumbnail.version, "1.0.0")
        
        let extractOutline = LBVRStandardCapabilities.extractOutlineCapability()
        XCTAssertNotNil(extractOutline)
        XCTAssertEqual(extractOutline.version, "1.0.0")
        
        let extractText = LBVRStandardCapabilities.extractTextCapability()
        XCTAssertNotNil(extractText)
        XCTAssertEqual(extractText.version, "1.0.0")
    }
    
    func testPluginCapabilities() throws {
        // Test that plugin capabilities collection works
        let capabilities = CSPluginCapabilities()
        XCTAssertNotNil(capabilities)
        XCTAssertTrue(capabilities.isEmpty())
        
        let extractMetadata = LBVRStandardCapabilities.extractMetadataCapability()
        capabilities.addCapability(extractMetadata)
        XCTAssertFalse(capabilities.isEmpty())
        XCTAssertEqual(capabilities.count(), 1)
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