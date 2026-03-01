//
//  MACINARegistryManager.h
//  MACINAPluginSDK
//
//  Registry integration for plugin cap validation
//

#import <Foundation/Foundation.h>
#import "CapDAG.h"
#import "MACINAStandardCaps.h"

@class CSCap;

NS_ASSUME_NONNULL_BEGIN

/**
 * Registry manager for plugin cap validation against canonical definitions
 */
@interface MACINARegistryManager : NSObject

/**
 * Create a new registry manager
 */
+ (instancetype)manager;

/**
 * Validate all caps in a plugin against canonical definitions
 * @param caps Array of caps to validate
 * @param completion Completion handler with array of validation errors (empty if all valid)
 */
- (void)validatePluginCaps:(NSArray<CSCap *> *)caps completion:(void (^)(NSArray<NSError *> *errors))completion;

/**
 * Create a cap from its canonical registry definition
 * @param urn The cap URN
 * @param completion Completion handler with cap or error
 */
- (void)createCanonicalCap:(NSString *)urn completion:(void (^)(CSCap * _Nullable cap, NSError * _Nullable error))completion;

/**
 * Check if a cap URN has a canonical definition
 * @param urn The cap URN to check
 * @param completion Completion handler with boolean result
 */
- (void)isCapCanonical:(NSString *)urn completion:(void (^)(BOOL isCanonical))completion;

@end

/**
 * Enhanced standard caps with registry integration
 */
@interface MACINAStandardCaps (Registry)

/**
 * Get a standard cap by URN with canonical validation
 * @param urnString The cap URN string
 * @param completion Completion handler with cap or error
 */
+ (void)standardCapWithUrnCanonical:(NSString *)urnString completion:(void (^)(CSCap * _Nullable cap, NSError * _Nullable error))completion;

/**
 * Validate all standard caps against the registry
 * @param completion Completion handler with validation result
 */
+ (void)validateStandardCaps:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END