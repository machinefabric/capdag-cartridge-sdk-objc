//
//  CSStandardCaps.h
//  Standard cap definitions with arguments
//
//  This provides the standard cap definitions used across
//  all LBVR plugins, including their formal argument specifications.
//

#import <Foundation/Foundation.h>
#import "CSCap.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Standard cap factory methods
 */
@interface CSStandardCaps : NSObject

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
 * Create the standard extract-pages cap with full argument definition
 * @return A fully configured extract-pages cap
 */
+ (CSCap *)extractPagesCap;

/**
 * Get all standard caps
 * @return An array of all standard caps
 */
+ (NSArray<CSCap *> *)allStandardCaps;

/**
 * Get a standard cap by name
 * @param name The cap name (e.g., "extract-metadata")
 * @return The cap or nil if not found
 */
+ (nullable CSCap *)standardCapWithName:(NSString *)name;

/**
 * Get a standard cap by cap ID string
 * @param idString The cap ID string (e.g., "action=extract;target=metadata;")
 * @return The cap or nil if not found
 */
+ (nullable CSCap *)standardCapWithId:(NSString *)idString;

@end

NS_ASSUME_NONNULL_END