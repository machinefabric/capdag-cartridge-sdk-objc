//
//  CSPluginCaps.h
//  Plugin caps collection
//
//  Manages a collection of caps with searching, matching, and querying functionality.
//

#import <Foundation/Foundation.h>
#import "CSCap.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Plugin caps collection
 */
@interface CSPluginCaps : NSObject <NSCopying, NSCoding>

/// Array of caps
@property (nonatomic, readonly) NSArray<CSCap *> *caps;

/**
 * Create a new empty caps collection
 * @return A new CSPluginCaps instance
 */
+ (instancetype)new;

/**
 * Create caps collection with an array of caps
 * @param caps Array of caps
 * @return A new CSPluginCaps instance
 */
+ (instancetype)capsWithArray:(NSArray<CSCap *> *)caps;

/**
 * Create caps collection from a dictionary representation
 * @param dictionary The dictionary containing caps data
 * @param error Pointer to NSError for error reporting
 * @return A new CSPluginCaps instance, or nil if parsing fails
 */
+ (instancetype)capsWithDictionary:(NSDictionary * _Nonnull)dictionary error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NAME(init(dictionary:error:));

/**
 * Add a cap to the collection
 * @param cap The cap to add
 */
- (void)addCap:(CSCap *)cap;

/**
 * Remove a cap from the collection
 * @param cap The cap to remove
 */
- (void)removeCap:(CSCap *)cap;

/**
 * Check if the plugin has a specific cap
 * @param capRequest The cap request string
 * @return YES if the plugin can handle the cap request
 */
- (BOOL)acceptsCap:(NSString *)capRequest;

/**
 * Get all cap URNs as strings
 * @return Array of cap URN strings
 */
- (NSArray<NSString *> *)capUrns;

/**
 * Find a cap by identifier
 * @param identifier The cap URN string
 * @return The cap or nil if not found
 */
- (nullable CSCap *)findCapWithUrn:(NSString *)identifier;

/**
 * Find the most specific cap that can handle a request
 * @param request The cap request string
 * @return The best matching cap or nil if none can handle the request
 */
- (nullable CSCap *)findBestCapForRequest:(NSString *)request;

/**
 * Get caps that have specific metadata
 * @param key The metadata key to search for
 * @param value The metadata value to match (nil to match any value)
 * @return Array of caps with the specified metadata
 */
- (NSArray<CSCap *> *)capsWithMetadataKey:(NSString *)key value:(nullable NSString *)value;

/**
 * Get all unique metadata keys across all caps
 * @return Array of unique metadata keys
 */
- (NSArray<NSString *> *)allMetadataKeys;

/**
 * Get caps by version
 * @param version The version to search for
 * @return Array of caps with the specified version
 */
- (NSArray<CSCap *> *)capsWithVersion:(NSString *)version;

/**
 * Get the count of caps
 * @return Number of caps in the collection
 */
- (NSUInteger)count;

/**
 * Check if the collection is empty
 * @return YES if the collection has no caps
 */
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END