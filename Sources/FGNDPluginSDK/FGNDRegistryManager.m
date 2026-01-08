//
//  FGNDRegistryManager.m
//  FGNDPluginSDK
//
//  Registry integration for plugin cap validation
//

#import "FGNDRegistryManager.h"
#import "FGNDStandardCaps.h"

@interface FGNDRegistryManager ()
@property (nonatomic, strong) CSCapRegistry *registry;
@end

@implementation FGNDRegistryManager

+ (instancetype)manager {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _registry = [[CSCapRegistry alloc] init];
    }
    return self;
}

- (void)validatePluginCaps:(NSArray<CSCap *> *)caps completion:(void (^)(NSArray<NSError *> *))completion {
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray<NSError *> *errors = [NSMutableArray array];
    
    for (CSCap *cap in caps) {
        dispatch_group_enter(group);
        
        [self.registry validateCap:cap completion:^(NSError *error) {
            if (error) {
                @synchronized (errors) {
                    [errors addObject:error];
                }
            }
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        completion([errors copy]);
    });
}

- (void)createCanonicalCap:(NSString *)urn completion:(void (^)(CSCap * _Nullable, NSError * _Nullable))completion {
    [self.registry getCapWithUrn:urn completion:completion];
}

- (void)isCapCanonical:(NSString *)urn completion:(void (^)(BOOL))completion {
    [self.registry getCapWithUrn:urn completion:^(CSCap *cap, NSError *error) {
        completion(cap != nil);
    }];
}

@end

@implementation FGNDStandardCaps (Registry)

+ (void)standardCapWithUrnCanonical:(NSString *)urnString completion:(void (^)(CSCap * _Nullable, NSError * _Nullable))completion {
    // First try to get from local standard caps
    CSCap *localCap = [self standardCapWithUrn:urnString];
    
    if (localCap) {
        // Validate against registry if available
        FGNDRegistryManager *manager = [FGNDRegistryManager manager];
        [manager.registry validateCap:localCap completion:^(NSError *error) {
            if (error) {
                NSLog(@"Warning: Local cap validation failed: %@", error);
            }
            // Return local cap even if registry validation fails
            completion(localCap, nil);
        }];
        return;
    }
    
    // Try to get from registry
    FGNDRegistryManager *manager = [FGNDRegistryManager manager];
    [manager createCanonicalCap:urnString completion:completion];
}

+ (void)validateStandardCaps:(void (^)(NSError * _Nullable))completion {
    FGNDRegistryManager *manager = [FGNDRegistryManager manager];
    
    NSArray<NSString *> *standardUrns = @[
        @"cap:op=extract;target=metadata;",
        @"cap:op=generate;output=binary;target=thumbnail;",
        @"cap:op=extract;target=outline;",
        @"cap:op=extract;target=pages"
    ];
    
    NSMutableArray<CSCap *> *caps = [NSMutableArray array];
    
    for (NSString *urn in standardUrns) {
        CSCap *cap = [self standardCapWithUrn:urn];
        if (cap) {
            [caps addObject:cap];
        }
    }
    
    [manager validatePluginCaps:caps completion:^(NSArray<NSError *> *errors) {
        if (errors.count > 0) {
            NSError *combinedError = [NSError errorWithDomain:@"FGNDStandardCapsValidationError"
                                                         code:4001
                                                     userInfo:@{
                                                         NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Standard caps validation failed with %lu errors", (unsigned long)errors.count],
                                                         @"ValidationErrors": errors
                                                     }];
            completion(combinedError);
        } else {
            completion(nil);
        }
    }];
}

@end