//
//  CSPluginCaps.m
//  Plugin caps collection implementation
//

#import "include/CSPluginCaps.h"
#import "CSCapMatcher.h"

@interface CSPluginCaps ()
@property (nonatomic, strong) NSMutableArray<CSCap *> *mutableCaps;
@end

@implementation CSPluginCaps

+ (instancetype)new {
    return [self capsWithArray:@[]];
}

+ (instancetype)capsWithArray:(NSArray<CSCap *> *)caps {
    CSPluginCaps *instance = [[CSPluginCaps alloc] init];
    instance.mutableCaps = [caps mutableCopy];
    return instance;
}

+ (instancetype)capsWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    NSArray *capsArray = dictionary[@"caps"];
    if (!capsArray) {
        if (error) {
            *error = [NSError errorWithDomain:@"CSPluginCapsError"
                                         code:1006
                                     userInfo:@{NSLocalizedDescriptionKey: @"Missing caps array in dictionary"}];
        }
        return nil;
    }
    
    NSMutableArray<CSCap *> *caps = [NSMutableArray array];
    for (NSDictionary *capDict in capsArray) {
        CSCap *cap = [CSCap capWithDictionary:capDict error:error];
        if (!cap) {
            return nil;
        }
        [caps addObject:cap];
    }
    
    return [self capsWithArray:caps];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableCaps = [NSMutableArray array];
    }
    return self;
}

- (NSArray<CSCap *> *)caps {
    return [self.mutableCaps copy];
}

- (void)addCap:(CSCap *)cap {
    if (cap) {
        [self.mutableCaps addObject:cap];
    }
}

- (void)removeCap:(CSCap *)cap {
    [self.mutableCaps removeObject:cap];
}

- (BOOL)canHandleCap:(NSString *)capRequest {
    for (CSCap *cap in self.mutableCaps) {
        if ([cap matchesRequest:capRequest]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<NSString *> *)capUrns {
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (CSCap *cap in self.mutableCaps) {
        [identifiers addObject:[cap urnString]];
    }
    return identifiers;
}

- (nullable CSCap *)findCapWithUrn:(NSString *)identifier {
    NSError *error;
    CSCapUrn *searchId = [CSCapUrn fromString:identifier error:&error];
    if (!searchId) return nil;
    
    for (CSCap *cap in self.mutableCaps) {
        if ([cap.capUrn isEqual:searchId]) {
            return cap;
        }
    }
    return nil;
}

- (nullable CSCap *)findBestCapForRequest:(NSString *)request {
    NSError *error;
    CSCapUrn *requestId = [CSCapUrn fromString:request error:&error];
    if (!requestId) return nil;
    
    NSMutableArray<CSCapUrn *> *capUrns = [NSMutableArray array];
    for (CSCap *cap in self.mutableCaps) {
        [capUrns addObject:cap.capUrn];
    }
    
    CSCapUrn *bestId = [CSCapMatcher findBestMatchInCaps:capUrns forRequest:requestId];
    if (!bestId) return nil;
    
    for (CSCap *cap in self.mutableCaps) {
        if ([cap.capUrn isEqual:bestId]) {
            return cap;
        }
    }
    return nil;
}

- (NSArray<CSCap *> *)capsWithMetadataKey:(NSString *)key value:(nullable NSString *)value {
    NSMutableArray<CSCap *> *matches = [NSMutableArray array];
    
    for (CSCap *cap in self.mutableCaps) {
        if (value) {
            NSString *metadataValue = [cap metadataForKey:key];
            if ([metadataValue isEqualToString:value]) {
                [matches addObject:cap];
            }
        } else {
            if ([cap hasMetadataForKey:key]) {
                [matches addObject:cap];
            }
        }
    }
    
    return matches;
}

- (NSArray<NSString *> *)allMetadataKeys {
    NSMutableSet<NSString *> *keys = [NSMutableSet set];
    
    for (CSCap *cap in self.mutableCaps) {
        [keys addObjectsFromArray:[cap.metadata allKeys]];
    }
    
    return [[keys allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray<CSCap *> *)capsWithVersion:(NSString *)version {
    NSMutableArray<CSCap *> *matches = [NSMutableArray array];
    
    for (CSCap *cap in self.mutableCaps) {
        if ([cap.version isEqualToString:version]) {
            [matches addObject:cap];
        }
    }
    
    return matches;
}

- (NSUInteger)count {
    return self.mutableCaps.count;
}

- (BOOL)isEmpty {
    return self.mutableCaps.count == 0;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CSPluginCaps(count: %lu, caps: %@)", 
            (unsigned long)self.count, self.caps];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[CSPluginCaps class]]) return NO;
    
    CSPluginCaps *other = (CSPluginCaps *)object;
    return [self.caps isEqualToArray:other.caps];
}

- (NSUInteger)hash {
    return [self.caps hash];
}

- (id)copyWithZone:(NSZone *)zone {
    return [CSPluginCaps capsWithArray:self.caps];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.caps forKey:@"caps"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    NSArray<CSCap *> *caps = [coder decodeObjectOfClass:[NSArray class] forKey:@"caps"];
    if (!caps) return nil;
    
    return [CSPluginCaps capsWithArray:caps];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end