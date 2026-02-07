//
//  MACINAStandardCaps.h
//  Standard cap definitions with arguments
//
//  This provides the standard cap definitions used across
//  all MACINA plugins, including their formal argument specifications.
//

#import <Foundation/Foundation.h>
#import "CapNs.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Standard cap factory methods
 */
@interface MACINAStandardCaps : NSObject

/**
 * Create the standard extract-metadata cap with full argument definition
 * @return A fully configured extract-metadata cap
 */
+ (CSCap *)extractMetadataCap;

/**
 * Create the standard generate-thumbnail cap with full argument definition
 * @return A fully configured generate-thumbnail cap
 */
+ (CSCap *)generateThumbnailCap;

/**
 * Create the standard extract-outline cap with full argument definition
 * @return A fully configured extract-outline cap
 */
+ (CSCap *)extractOutlineCap;

/**
 * Create the standard grind cap with full argument definition
 * @return A fully configured grind cap
 */
+ (CSCap *)disbindCap;

/**
 * Get all standard caps
 * @return An array of all standard caps
 */
+ (NSArray<CSCap *> *)allStandardCaps;

/**
 * Get a standard cap by name
 * @param name The cap name (e.g., "extract-metadata", "grind")
 * @return The cap or nil if not found
 */
+ (nullable CSCap *)standardCapWithName:(NSString *)name;

/**
 * Get a standard cap by cap URN string
 * @param urnString The cap URN string (e.g., "cap:op=extract;target=metadata;", "cap:op=extract;target=pages")
 * @return The cap or nil if not found
 */
+ (nullable CSCap *)standardCapWithUrn:(NSString *)urnString;

/**
 * Create extract-metadata cap subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"html", @"htm"])
 * @return Extract-metadata cap subbed with file type metadata
 */
+ (CSCap *)extractMetadataCapSubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Create generate-thumbnail cap subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"md", @"markdown"])
 * @return Generate-thumbnail cap subbed with file type metadata
 */
+ (CSCap *)generateThumbnailCapSubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Create extract-outline cap subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"pdf"])
 * @return Extract-outline cap subbed with file type metadata
 */
+ (CSCap *)extractOutlineCapSubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Create grind cap subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"txt"])
 * @return Extract-pages cap subbed with file type metadata
 */
+ (CSCap *)disbindCapSubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Get all standard caps subbed with file types
 * @param fileTypes Array of supported file extensions
 * @return Array of all standard caps subbed with file type metadata
 */
+ (NSArray<CSCap *> *)allStandardCapsSubbedWith:(NSArray<NSString *> *)fileTypes;

@end

NS_ASSUME_NONNULL_END