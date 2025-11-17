//
//  LBVRStandardCapabilities.h
//  Standard capability definitions with arguments
//
//  This provides the standard capability definitions used across
//  all LBVR plugins, including their formal argument specifications.
//

#import <Foundation/Foundation.h>
#import "CapDef.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Standard capability factory methods
 */
@interface LBVRStandardCapabilities : NSObject

/**
 * Create the standard extract-metadata capability with full argument definition
 * @return A fully configured extract-metadata capability
 */
+ (CSCapability *)extractMetadataCapability;

/**
 * Create the standard generate-thumbnail capability with full argument definition
 * @return A fully configured generate-thumbnail capability
 */
+ (CSCapability *)generateThumbnailCapability;

/**
 * Create the standard extract-outline capability with full argument definition
 * @return A fully configured extract-outline capability
 */
+ (CSCapability *)extractOutlineCapability;

/**
 * Create the standard extract-pages capability with full argument definition
 * @return A fully configured extract-pages capability
 */
+ (CSCapability *)extractPagesCapability;

/**
 * Get all standard capabilities
 * @return An array of all standard capabilities
 */
+ (NSArray<CSCapability *> *)allStandardCapabilities;

/**
 * Get a standard capability by name
 * @param name The capability name (e.g., "extract-metadata", "extract-pages")
 * @return The capability or nil if not found
 */
+ (nullable CSCapability *)standardCapabilityWithName:(NSString *)name;

/**
 * Get a standard capability by capability ID string
 * @param idString The capability ID string (e.g., "action=extract;target=metadata;type=document", "action=extract;target=pages;type=document")
 * @return The capability or nil if not found
 */
+ (nullable CSCapability *)standardCapabilityWithId:(NSString *)idString;

/**
 * Create extract-metadata capability subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"html", @"htm"])
 * @return Extract-metadata capability subbed with file type metadata
 */
+ (CSCapability *)extractMetadataCapabilitySubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Create generate-thumbnail capability subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"md", @"markdown"])
 * @return Generate-thumbnail capability subbed with file type metadata
 */
+ (CSCapability *)generateThumbnailCapabilitySubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Create extract-outline capability subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"pdf"])
 * @return Extract-outline capability subbed with file type metadata
 */
+ (CSCapability *)extractOutlineCapabilitySubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Create extract-pages capability subbed with file types
 * @param fileTypes Array of supported file extensions (e.g., @[@"txt"])
 * @return Extract-pages capability subbed with file type metadata
 */
+ (CSCapability *)extractPagesCapabilitySubbedWith:(NSArray<NSString *> *)fileTypes;

/**
 * Get all standard capabilities subbed with file types
 * @param fileTypes Array of supported file extensions
 * @return Array of all standard capabilities subbed with file type metadata
 */
+ (NSArray<CSCapability *> *)allStandardCapabilitiesSubbedWith:(NSArray<NSString *> *)fileTypes;

@end

NS_ASSUME_NONNULL_END