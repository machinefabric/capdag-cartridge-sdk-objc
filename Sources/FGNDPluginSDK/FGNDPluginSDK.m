//
//  FGNDPluginSDK.m
//  FGND Plugin SDK for Objective-C
//
//  Unified cap-based plugin interface with standardized command-line calling
//

#import "include/FGNDPluginSDK.h"

// MARK: - Unified Plugin Registry

@implementation FGNDPluginRegistry {
    NSMutableDictionary<NSString *, FGNDPluginEntry *> *_plugins;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *_capIndex;
}

+ (instancetype)sharedRegistry {
    static FGNDPluginRegistry *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FGNDPluginRegistry alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _plugins = [[NSMutableDictionary alloc] init];
        _capIndex = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerPlugin:(NSString *)name
            binaryPath:(NSString *)binaryPath
          caps:(NSArray<NSString *> *)caps {
    
    FGNDPluginEntry *entry = [[FGNDPluginEntry alloc] initWithBinaryPath:binaryPath
                                                            caps:caps];
    
    // Update cap index
    for (NSString *cap in caps) {
        NSMutableArray<NSString *> *plugins = _capIndex[cap];
        if (!plugins) {
            plugins = [[NSMutableArray alloc] init];
            _capIndex[cap] = plugins;
        }
        [plugins addObject:name];
    }
    
    _plugins[name] = entry;
}

- (CSCapCaller *)can:(NSString *)cap error:(NSError **)error {
    NSString *bestPlugin = [self findBestPluginForCap:cap];
    if (!bestPlugin) {
        if (error) {
            *error = [NSError errorWithDomain:@"FGNDPluginSDK"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Cap '%@' is not available in any registered plugin", cap]}];
        }
        return nil;
    }
    
    FGNDPluginEntry *plugin = _plugins[bestPlugin];
    if (!plugin) {
        if (error) {
            *error = [NSError errorWithDomain:@"FGNDPluginSDK"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Plugin '%@' not found in registry", bestPlugin]}];
        }
        return nil;
    }
    
    // Create a cap host adapter for the plugin binary
    FGNDPluginCapSet *capSet = [[FGNDPluginCapSet alloc] initWithBinaryPath:plugin.binaryPath];
    
    // Get cap definition (for now, create a basic one - in production this would come from registry)
    CSCap *capDefinition = [self createBasicCapDefinitionForCap:cap];
    
    return [CSCapCaller callerWithCap:cap capSet:capSet capDefinition:capDefinition];
}

- (CSCapCaller *)can:(NSString *)cap {
    return [self can:cap error:nil];
}

- (NSArray<NSString *> *)listCaps {
    return [_capIndex allKeys];
}

- (NSString *)findBestPluginForCap:(NSString *)cap {
    NSArray<NSString *> *candidates = [self getCapCandidates:cap];
    if (candidates.count == 0) {
        return nil;
    }
    
    NSString *bestPlugin = nil;
    NSInteger bestScore = -1;
    
    for (NSString *pluginName in candidates) {
        FGNDPluginEntry *plugin = _plugins[pluginName];
        NSInteger score = [self calculateCapScore:plugin forCap:cap];
        if (score > bestScore) {
            bestPlugin = pluginName;
            bestScore = score;
        }
    }
    
    return bestPlugin;
}

- (NSArray<NSString *> *)getCapCandidates:(NSString *)cap {
    // Direct match
    NSArray<NSString *> *plugins = _capIndex[cap];
    if (plugins) {
        return plugins;
    }
    
    // Try wildcard variations
    if ([cap containsString:@":"]) {
        NSArray<NSString *> *parts = [cap componentsSeparatedByString:@":"];
        if (parts.count == 2) {
            NSString *wildcardCap = [NSString stringWithFormat:@"%@:*", parts[0]];
            NSArray<NSString *> *wildcardPlugins = _capIndex[wildcardCap];
            if (wildcardPlugins) {
                return wildcardPlugins;
            }
        }
    }
    
    return @[];
}

- (NSInteger)calculateCapScore:(FGNDPluginEntry *)plugin forCap:(NSString *)cap {
    NSInteger score = 0;
    
    // Add specificity score
    for (NSString *pluginCap in plugin.caps) {
        if ([pluginCap isEqualToString:cap]) {
            if ([pluginCap containsString:@":"] && ![pluginCap hasSuffix:@":*"]) {
                score += 20; // Exact file type match
            } else if ([pluginCap hasSuffix:@":*"]) {
                score += 10; // Wildcard match
            } else {
                score += 5; // Operation-only match
            }
            break;
        }
    }
    
    return score;
}

- (CSCap *)createBasicCapDefinitionForCap:(NSString *)cap {
    // For now, create a basic cap definition - in production this would come from registry
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:[cap lowercaseString] error:&error];
    if (!capUrn) {
        // Fallback to basic cap URN
        capUrn = [CSCapUrn fromString:@"cap:op=generic;" error:nil];
    }

    // Args are empty by default (new model uses args array)
    NSArray<CSCapArg *> *args = @[];

    // Use media URN for output - media:object is a well-known built-in
    CSCapOutput *output = [CSCapOutput outputWithMediaUrn:@"media:object"
                                        outputDescription:@"Generic plugin output"];

    return [CSCap capWithUrn:capUrn
                       title:@"Generic Plugin Capability"
                     command:[cap componentsSeparatedByString:@":"][0]
                 description:@"Generic plugin capability"
                    metadata:@{}
                  mediaSpecs:@{}  // Built-in media URNs don't need declaration
                          args:args
                        output:output
                  metadataJSON:nil];
}

@end

// MARK: - Plugin Cap Host Implementation

@implementation FGNDPluginCapSet

- (instancetype)initWithBinaryPath:(NSString *)binaryPath {
    self = [super init];
    if (self) {
        _binaryPath = [binaryPath copy];
    }
    return self;
}

- (void)executeCap:(NSString *)cap
    positionalArgs:(NSArray *)positionalArgs
         namedArgs:(NSArray *)namedArgs
         stdinData:(NSData * _Nullable)stdinData
        completion:(void (^)(CSResponseWrapper * _Nullable response, NSError * _Nullable error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Convert cap to CLI flag
        NSString *operation = [cap componentsSeparatedByString:@":"][0];
        NSString *command = [NSString stringWithFormat:@"--%@", operation];
        
        // Build command arguments
        NSMutableArray<NSString *> *cmdArgs = [[NSMutableArray alloc] initWithObjects:command, nil];
        
        // Add positional args
        for (id arg in positionalArgs) {
            [cmdArgs addObject:[NSString stringWithFormat:@"%@", arg]];
        }
        
        // Add named args (these would typically be formatted as --flag value)
        for (id arg in namedArgs) {
            [cmdArgs addObject:[NSString stringWithFormat:@"%@", arg]];
        }
        
        // Execute the plugin
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = self.binaryPath;
        task.arguments = cmdArgs;
        
        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        
        // Set up stdin if provided
        if (stdinData) {
            NSPipe *inputPipe = [NSPipe pipe];
            task.standardInput = inputPipe;
            
            // Write stdin data in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSFileHandle *stdinHandle = [inputPipe fileHandleForWriting];
                [stdinHandle writeData:stdinData];
                [stdinHandle closeFile];
            });
        }
        
        @try {
            [task launch];
            [task waitUntilExit];
            
            NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            
            if (task.terminationStatus == 0) {
                CSResponseWrapper *response = [CSResponseWrapper responseWithData:outputData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(response, nil);
                });
            } else {
                NSError *error = [NSError errorWithDomain:@"FGNDPluginSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Plugin execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"FGNDPluginSDK"
                                                 code:1004
                                             userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Plugin execution exception"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
    });
}

@end



// MARK: - Plugin Entry

@implementation FGNDPluginEntry

- (instancetype)initWithBinaryPath:(NSString *)binaryPath
                      caps:(NSArray<NSString *> *)caps {
    self = [super init];
    if (self) {
        _binaryPath = [binaryPath copy];
        _caps = [caps copy];
    }
    return self;
}

@end

// MARK: - Plugin Manifest Category

@implementation CSCapManifest (FGNDPluginSDK)

+ (instancetype)pluginWithName:(NSString *)name
                   description:(NSString *)description
                  caps:(NSArray<CSCap *> *)caps {
    return [CSCapManifest manifestWithName:name
                                   version:@"1.0.0"
                               description:description
                                      caps:caps];
}

@end

// MARK: - Standardized Caps

@implementation FGNDStandardizedCaps

+ (NSString *)extractMetadata {
    return @"extract-metadata";
}

+ (NSString *)extractOutline {
    return @"extract-outline";
}

+ (NSString *)grind {
    return @"grind";
}

+ (NSString *)generateThumbnail {
    return @"generate-thumbnail";
}

+ (NSString *)validateFile {
    return @"validate-file";
}

@end

// MARK: - CLI Helper

@implementation FGNDCLIHelper

+ (NSString *)capToFlag:(NSString *)cap {
    NSString *operation = [cap componentsSeparatedByString:@":"][0];
    return [NSString stringWithFormat:@"--%@", operation];
}

+ (NSArray<NSString *> *)buildCommandArgs:(NSString *)cap args:(NSArray *)args {
    NSMutableArray<NSString *> *cmdArgs = [[NSMutableArray alloc] init];
    
    [cmdArgs addObject:[self capToFlag:cap]];
    
    for (id arg in args) {
        [cmdArgs addObject:[NSString stringWithFormat:@"%@", arg]];
    }
    
    
    
    return [cmdArgs copy];
}

+ (void)executePlugin:(NSString *)binaryPath
                 args:(NSArray<NSString *> *)args
           completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = binaryPath;
        task.arguments = args;
        
        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        
        @try {
            [task launch];
            [task waitUntilExit];
            
            NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            
            if (task.terminationStatus == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(outputData, nil);
                });
            } else {
                NSError *error = [NSError errorWithDomain:@"FGNDPluginSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Plugin execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"FGNDPluginSDK"
                                                 code:1004
                                             userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Plugin execution exception"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
    });
}

@end

// MARK: - Extraction Info

@implementation FGNDExtractionInfo

- (instancetype)initWithExtractorName:(NSString *)extractorName extractorVersion:(NSString *)extractorVersion {
    self = [super init];
    if (self) {
        _extractorName = [extractorName copy];
        _extractorVersion = [extractorVersion copy];
        _extractedAt = [NSDate date];
        _warnings = @[];
    }
    return self;
}

@end

// MARK: - Document Metadata (schemas remain the same)

@implementation FGNDDocumentMetadata

- (instancetype)initWithFilePath:(NSString *)filePath
                   fileSizeBytes:(unsigned long long)fileSizeBytes
                   contentLength:(NSUInteger)contentLength
                    documentType:(NSString *)documentType {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        _fileSizeBytes = fileSizeBytes;
        _contentLength = contentLength;
        _documentType = [documentType copy];
        _authors = [[NSMutableArray alloc] init];
        _contributors = [[NSMutableArray alloc] init];
        _keywords = [[NSMutableArray alloc] init];
        _extendedMetadata = [[NSMutableDictionary alloc] init];
        _hasForms = NO;
        _isEncrypted = NO;
        _attachmentCount = 0;
        _isLinearized = NO;
        _hasDrm = NO;
    }
    return self;
}

- (void)addAuthor:(NSString *)author {
    [_authors addObject:[author copy]];
}

- (void)addContributor:(NSString *)contributor {
    [_contributors addObject:[contributor copy]];
}

- (void)addKeyword:(NSString *)keyword {
    [_keywords addObject:[keyword copy]];
}

@end

@implementation FGNDDocumentOutline

- (instancetype)initWithSourceFile:(NSString *)sourceFile
                       documentType:(NSString *)documentType
                         totalPages:(NSUInteger)totalPages {
    self = [super init];
    if (self) {
        _sourceFile = [sourceFile copy];
        _documentType = [documentType copy];
        _totalPages = totalPages;
        _outlineEntries = [[NSMutableArray alloc] init];
        _hasOutline = NO;
    }
    return self;
}

- (FGNDDocumentOutline *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addEntry:(FGNDOutlineEntry *)entry {
    [_outlineEntries addObject:entry];
    _hasOutline = YES;
}

@end

@implementation FGNDOutlineEntry

- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level {
    self = [super init];
    if (self) {
        _title = [title copy];
        _level = level;
        _children = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype)entryWithTitle:(NSString *)title level:(NSUInteger)level {
    return [[self alloc] initWithTitle:title level:level];
}

- (FGNDOutlineEntry *)withPage:(NSUInteger)page {
    self.page = page;
    return self;
}

- (void)addChild:(FGNDOutlineEntry *)child {
    [_children addObject:child];
}

@end

@implementation FGNDDisboundPages

- (instancetype)initWithSourceFile:(NSString *)sourceFile
                       documentType:(NSString *)documentType {
    self = [super init];
    if (self) {
        _sourceFile = [sourceFile copy];
        _documentType = [documentType copy];
        _pages = [[NSMutableArray alloc] init];
        _totalPages = 0;
    }
    return self;
}

- (FGNDDisboundPages *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addPage:(FGNDDisboundPage *)page {
    [_pages addObject:page];
    _totalPages = _pages.count;
}

@end

@implementation FGNDDocumentParagraph

- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent {
    self = [super init];
    if (self) {
        _paragraphNumber = paragraphNumber;
        _textContent = [textContent copy];
    }
    return self;
}

@end

@implementation FGNDDisboundPage

- (instancetype)initWithOrderIndex:(NSUInteger)orderIndex {
    self = [super init];
    if (self) {
        _orderIndex = orderIndex;
        _textContent = @"";
    }
    return self;
}

- (instancetype)initWithOrderIndex:(NSUInteger)orderIndex textContent:(NSString *)textContent {
    self = [super init];
    if (self) {
        _orderIndex = orderIndex;
        _textContent = [textContent copy];
        [self updateWordAndCharacterCounts];
    }
    return self;
}

- (void)setTextContent:(NSString *)textContent {
    _textContent = [textContent copy];
    [self updateWordAndCharacterCounts];
}

- (void)updateWordAndCharacterCounts {
    // Count words
    NSArray<NSString *> *words = [_textContent componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray<NSString *> *nonEmptyWords = [[NSMutableArray alloc] init];
    for (NSString *word in words) {
        NSString *trimmed = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [nonEmptyWords addObject:trimmed];
        }
    }
    _wordCount = @(nonEmptyWords.count);
    _characterCount = @(_textContent.length);
}

@end

// MARK: - File Info

@implementation FGNDQuickMetadata
@end

@implementation FGNDFileInfo

- (instancetype)initWithPath:(NSString *)path
                        size:(unsigned long long)size
                documentType:(NSString *)documentType
                     isValid:(BOOL)isValid {
    self = [super init];
    if (self) {
        _path = [path copy];
        _size = size;
        _documentType = [documentType copy];
        _isValid = isValid;
    }
    return self;
}

@end


// MARK: - Processing Result Implementation

@implementation FGNDProcessingResult

+ (instancetype)successWithData:(id)data {
    FGNDProcessingResult *result = [[FGNDProcessingResult alloc] init];
    result.success = YES;
    result.data = data;
    return result;
}

+ (instancetype)failureWithError:(NSString *)error {
    FGNDProcessingResult *result = [[FGNDProcessingResult alloc] init];
    result.success = NO;
    result.error = error;
    return result;
}

@end
