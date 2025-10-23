//
//  LBVRPluginSDK.m
//  LBVR Plugin SDK for Objective-C
//
//  Unified capability-based plugin interface with standardized command-line calling
//

#import "include/LBVRPluginSDK.h"

// MARK: - Unified Plugin Registry

@implementation LBVRPluginRegistry {
    NSMutableDictionary<NSString *, LBVRPluginEntry *> *_plugins;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *_capabilityIndex;
}

+ (instancetype)sharedRegistry {
    static LBVRPluginRegistry *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LBVRPluginRegistry alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _plugins = [[NSMutableDictionary alloc] init];
        _capabilityIndex = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerPlugin:(NSString *)name
            binaryPath:(NSString *)binaryPath
          capabilities:(NSArray<NSString *> *)capabilities {
    
    LBVRPluginEntry *entry = [[LBVRPluginEntry alloc] initWithBinaryPath:binaryPath
                                                            capabilities:capabilities];
    
    // Update capability index
    for (NSString *capability in capabilities) {
        NSMutableArray<NSString *> *plugins = _capabilityIndex[capability];
        if (!plugins) {
            plugins = [[NSMutableArray alloc] init];
            _capabilityIndex[capability] = plugins;
        }
        [plugins addObject:name];
    }
    
    _plugins[name] = entry;
}

- (LBVRCapabilityCaller *)can:(NSString *)capability error:(NSError **)error {
    NSString *bestPlugin = [self findBestPluginForCapability:capability];
    if (!bestPlugin) {
        if (error) {
            *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Capability '%@' is not available in any registered plugin", capability]}];
        }
        return nil;
    }
    
    LBVRPluginEntry *plugin = _plugins[bestPlugin];
    if (!plugin) {
        if (error) {
            *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Plugin '%@' not found in registry", bestPlugin]}];
        }
        return nil;
    }
    
    LBVRCapabilityCaller *caller = [[LBVRCapabilityCaller alloc] init];
    caller.pluginName = bestPlugin;
    caller.capability = capability;
    caller.binaryPath = plugin.binaryPath;
    
    return caller;
}

- (NSArray<NSString *> *)listCapabilities {
    return [_capabilityIndex allKeys];
}

- (NSString *)findBestPluginForCapability:(NSString *)capability {
    NSArray<NSString *> *candidates = [self getCapabilityCandidates:capability];
    if (candidates.count == 0) {
        return nil;
    }
    
    NSString *bestPlugin = nil;
    NSInteger bestScore = -1;
    
    for (NSString *pluginName in candidates) {
        LBVRPluginEntry *plugin = _plugins[pluginName];
        NSInteger score = [self calculateCapabilityScore:plugin forCapability:capability];
        if (score > bestScore) {
            bestPlugin = pluginName;
            bestScore = score;
        }
    }
    
    return bestPlugin;
}

- (NSArray<NSString *> *)getCapabilityCandidates:(NSString *)capability {
    // Direct match
    NSArray<NSString *> *plugins = _capabilityIndex[capability];
    if (plugins) {
        return plugins;
    }
    
    // Try wildcard variations
    if ([capability containsString:@":"]) {
        NSArray<NSString *> *parts = [capability componentsSeparatedByString:@":"];
        if (parts.count == 2) {
            NSString *wildcardCapability = [NSString stringWithFormat:@"%@:*", parts[0]];
            NSArray<NSString *> *wildcardPlugins = _capabilityIndex[wildcardCapability];
            if (wildcardPlugins) {
                return wildcardPlugins;
            }
        }
    }
    
    return @[];
}

- (NSInteger)calculateCapabilityScore:(LBVRPluginEntry *)plugin forCapability:(NSString *)capability {
    NSInteger score = 0;
    
    // Add specificity score
    for (NSString *cap in plugin.capabilities) {
        if ([cap isEqualToString:capability]) {
            if ([cap containsString:@":"] && ![cap hasSuffix:@":*"]) {
                score += 20; // Exact file type match
            } else if ([cap hasSuffix:@":*"]) {
                score += 10; // Wildcard match
            } else {
                score += 5; // Operation-only match
            }
            break;
        }
    }
    
    return score;
}

@end

// MARK: - Capability Caller

@implementation LBVRCapabilityCaller

- (void)call:(NSArray *)args completion:(void (^)(LBVRResponseWrapper * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Convert capability to CLI flag
        NSString *operation = [self.capability componentsSeparatedByString:@":"][0];
        NSString *command = [NSString stringWithFormat:@"--%@", operation];
        
        // Build command arguments
        NSMutableArray<NSString *> *cmdArgs = [[NSMutableArray alloc] initWithObjects:command, nil];
        for (id arg in args) {
            [cmdArgs addObject:[NSString stringWithFormat:@"%@", arg]];
        }
        
        // Execute the plugin
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = self.binaryPath;
        task.arguments = cmdArgs;
        
        NSPipe *outputPipe = [NSPipe pipe];
        task.standardOutput = outputPipe;
        
        @try {
            [task launch];
            [task waitUntilExit];
            
            NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
            
            if (task.terminationStatus == 0) {
                LBVRResponseWrapper *response = [[LBVRResponseWrapper alloc] initWithData:outputData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(response, nil);
                });
            } else {
                NSError *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Plugin execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                                 code:1004
                                             userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Plugin execution exception"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
    });
}

@end

// MARK: - Response Wrapper

@implementation LBVRResponseWrapper

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        _data = [data copy];
    }
    return self;
}

- (BOOL)asType:(Class)type result:(id _Nullable *)result error:(NSError **)error {
    @try {
        NSError *jsonError;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&jsonError];
        if (jsonError) {
            if (error) *error = jsonError;
            return NO;
        }
        
        if (result) *result = jsonObject;
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                         code:1005
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Type conversion failed"}];
        }
        return NO;
    }
}

- (NSString *)asStringWithError:(NSError **)error {
    NSString *result = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    if (!result && error) {
        *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                     code:1006
                                 userInfo:@{NSLocalizedDescriptionKey: @"Failed to convert data to string"}];
    }
    return result;
}

- (NSData *)asBytes {
    return self.data;
}

- (NSNumber *)asIntWithError:(NSError **)error {
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&jsonError];
    if (jsonError) {
        if (error) *error = jsonError;
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)jsonObject;
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                     code:1007
                                 userInfo:@{NSLocalizedDescriptionKey: @"Data is not a number"}];
    }
    return nil;
}

- (NSNumber *)asBoolWithError:(NSError **)error {
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&jsonError];
    if (jsonError) {
        if (error) *error = jsonError;
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)jsonObject;
    }
    
    if (error) {
        *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                     code:1008
                                 userInfo:@{NSLocalizedDescriptionKey: @"Data is not a boolean"}];
    }
    return nil;
}

@end

// MARK: - Plugin Entry

@implementation LBVRPluginEntry

- (instancetype)initWithBinaryPath:(NSString *)binaryPath
                      capabilities:(NSArray<NSString *> *)capabilities {
    self = [super init];
    if (self) {
        _binaryPath = [binaryPath copy];
        _capabilities = [capabilities copy];
    }
    return self;
}

@end

// MARK: - Plugin Manifest

@implementation LBVRPluginManifest

- (instancetype)initWithName:(NSString *)name
                     version:(NSString *)version
           pluginDescription:(NSString *)pluginDescription
                capabilities:(CSPluginCapabilities *)capabilities {
    self = [super init];
    if (self) {
        _name = [name copy];
        _version = [version copy];
        _pluginDescription = [pluginDescription copy];
        _capabilities = capabilities;
    }
    return self;
}

+ (instancetype)pluginWithName:(NSString *)name
                       version:(NSString *)version
                   description:(NSString *)description
                  capabilities:(CSPluginCapabilities *)capabilities {
    return [[self alloc] initWithName:name
                              version:version
                    pluginDescription:description
                         capabilities:capabilities];
}

- (LBVRPluginManifest *)withAuthor:(NSString *)author {
    self.author = [author copy];
    return self;
}

@end

// MARK: - Standardized Capabilities

@implementation LBVRStandardizedCapabilities

+ (NSString *)extractMetadata {
    return @"extract-metadata";
}

+ (NSString *)extractOutline {
    return @"extract-outline";
}

+ (NSString *)extractPages {
    return @"extract-pages";
}

+ (NSString *)generateThumbnail {
    return @"generate-thumbnail";
}

+ (NSString *)validateFile {
    return @"validate-file";
}

@end

// MARK: - CLI Helper

@implementation LBVRCLIHelper

+ (NSString *)capabilityToFlag:(NSString *)capability {
    NSString *operation = [capability componentsSeparatedByString:@":"][0];
    return [NSString stringWithFormat:@"--%@", operation];
}

+ (NSArray<NSString *> *)buildCommandArgs:(NSString *)capability args:(NSArray *)args {
    NSMutableArray<NSString *> *cmdArgs = [[NSMutableArray alloc] init];
    
    [cmdArgs addObject:[self capabilityToFlag:capability]];
    
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
                NSError *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Plugin execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"LBVRPluginSDK"
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

@implementation LBVRExtractionInfo

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

@implementation LBVRDocumentMetadata

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

@implementation LBVRDocumentOutline

- (instancetype)initWithSourceFile:(NSString *)sourceFile
                       documentType:(NSString *)documentType
                         totalPages:(NSUInteger)totalPages {
    self = [super init];
    if (self) {
        _sourceFile = [sourceFile copy];
        _documentType = [documentType copy];
        _totalPages = totalPages;
        _tocEntries = [[NSMutableArray alloc] init];
        _hasOutline = NO;
    }
    return self;
}

- (LBVRDocumentOutline *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addEntry:(LBVRTocEntry *)entry {
    [_tocEntries addObject:entry];
    _hasOutline = YES;
}

@end

@implementation LBVRTocEntry

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

- (LBVRTocEntry *)withPage:(NSUInteger)page {
    self.page = page;
    return self;
}

- (void)addChild:(LBVRTocEntry *)child {
    [_children addObject:child];
}

@end

@implementation LBVRDocumentPages

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

- (LBVRDocumentPages *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addPage:(LBVRDocumentPage *)page {
    [_pages addObject:page];
    _totalPages = _pages.count;
}

@end

@implementation LBVRDocumentParagraph

- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent {
    self = [super init];
    if (self) {
        _paragraphNumber = paragraphNumber;
        _textContent = [textContent copy];
    }
    return self;
}

@end

@implementation LBVRDocumentPage

- (instancetype)initWithPageNumber:(NSUInteger)pageNumber {
    self = [super init];
    if (self) {
        _pageNumber = pageNumber;
        _paragraphs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addParagraph:(LBVRDocumentParagraph *)paragraph {
    [_paragraphs addObject:paragraph];
}

@end

// MARK: - File Info

@implementation LBVRQuickMetadata
@end

@implementation LBVRFileInfo

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

// MARK: - JSON Serialization Helpers

@implementation LBVRJSONSerializer

+ (NSString *)serializeToJSON:(id)object {
    if (!object) return nil;
    
    // Convert custom objects to dictionary representation
    id jsonObject = [self convertToJSONObject:object];
    if (!jsonObject) return nil;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        fprintf(stderr, "Error: JSON serialization failed: %s\n", error.localizedDescription.UTF8String);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (id)convertToJSONObject:(id)object {
    if (!object) return nil;
    
    // Handle basic JSON-serializable types
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]] ||
        [object isKindOfClass:[NSNull class]]) {
        return object;
    }
    
    // Handle NSDate objects that might have slipped through
    if ([object isKindOfClass:[NSDate class]]) {
        return [self dateToString:(NSDate *)object];
    }
    
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        for (id item in (NSArray *)object) {
            id convertedItem = [self convertToJSONObject:item];
            if (convertedItem) {
                [result addObject:convertedItem];
            }
        }
        return result;
    }
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
        for (id key in [(NSDictionary *)object allKeys]) {
            id value = [(NSDictionary *)object objectForKey:key];
            id convertedValue = [self convertToJSONObject:value];
            if (convertedValue) {
                result[key] = convertedValue;
            }
        }
        return result;
    }
    
    // Handle custom objects
    if ([object isKindOfClass:[LBVRDocumentMetadata class]]) {
        return [self documentMetadataToDict:(LBVRDocumentMetadata *)object];
    }
    
    if ([object isKindOfClass:[LBVRDocumentOutline class]]) {
        return [self documentOutlineToDict:(LBVRDocumentOutline *)object];
    }
    
    if ([object isKindOfClass:[LBVRDocumentPages class]]) {
        return [self documentPagesToDict:(LBVRDocumentPages *)object];
    }
    
    if ([object isKindOfClass:[LBVRTocEntry class]]) {
        return [self tocEntryToDict:(LBVRTocEntry *)object];
    }
    
    if ([object isKindOfClass:[LBVRDocumentPage class]]) {
        return [self documentPageToDict:(LBVRDocumentPage *)object];
    }
    
    if ([object isKindOfClass:[LBVRDocumentParagraph class]]) {
        return [self documentParagraphToDict:(LBVRDocumentParagraph *)object];
    }
    
    if ([object isKindOfClass:[LBVRExtractionInfo class]]) {
        return [self extractionInfoToDict:(LBVRExtractionInfo *)object];
    }
    
    // For unknown types, try to convert safely
    if ([object respondsToSelector:@selector(description)]) {
        @try {
            NSString *desc = [object description];
            return desc ? desc : @"<unknown>";
        } @catch (NSException *exception) {
            return @"<error>";
        }
    }
    
    return @"<null>";
}

+ (NSDictionary *)documentMetadataToDict:(LBVRDocumentMetadata *)metadata {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (metadata.filePath) dict[@"file_path"] = metadata.filePath;
    if (metadata.filePath) dict[@"file_name"] = [metadata.filePath lastPathComponent];
    dict[@"file_size_bytes"] = @(metadata.fileSizeBytes);
    dict[@"content_length"] = @(metadata.contentLength);
    if (metadata.documentType) dict[@"document_type"] = metadata.documentType;
    if (metadata.mimeType) dict[@"mime_type"] = metadata.mimeType;
    if (metadata.encoding) dict[@"encoding"] = metadata.encoding;
    if (metadata.title) dict[@"title"] = metadata.title;
    // Always include these arrays, even if empty, for Rust SDK compatibility
    dict[@"authors"] = metadata.authors ? [self convertToJSONObject:metadata.authors] : @[];
    dict[@"contributors"] = metadata.contributors ? [self convertToJSONObject:metadata.contributors] : @[];
    dict[@"keywords"] = metadata.keywords ? [self convertToJSONObject:metadata.keywords] : @[];
    if (metadata.subject) dict[@"subject"] = metadata.subject;
    if (metadata.identifier) dict[@"identifier"] = metadata.identifier;
    if (metadata.creator) dict[@"creator"] = metadata.creator;
    if (metadata.producer) dict[@"producer"] = metadata.producer;
    if (metadata.publisher) dict[@"publisher"] = metadata.publisher;
    if (metadata.creationDate) dict[@"creation_date"] = metadata.creationDate;
    if (metadata.modificationDate) dict[@"modification_date"] = metadata.modificationDate;
    if (metadata.publicationDate) dict[@"publication_date"] = [self dateToString:metadata.publicationDate];
    if (metadata.wordCount) dict[@"word_count"] = metadata.wordCount;
    if (metadata.characterCount) dict[@"character_count"] = metadata.characterCount;
    if (metadata.pageCount) dict[@"page_count"] = metadata.pageCount;
    if (metadata.chapterCount) dict[@"chapter_count"] = metadata.chapterCount;
    if (metadata.language) dict[@"language"] = metadata.language;
    if (metadata.formatVersion) dict[@"format_version"] = metadata.formatVersion;
    if (metadata.pdfVersion) dict[@"pdf_version"] = metadata.pdfVersion;
    if (metadata.epubVersion) dict[@"epub_version"] = metadata.epubVersion;
    if (metadata.rights) dict[@"rights"] = metadata.rights;
    if (metadata.thumbnailPath) dict[@"thumbnail_path"] = metadata.thumbnailPath;
    dict[@"has_forms"] = @(metadata.hasForms);
    dict[@"is_encrypted"] = @(metadata.isEncrypted);
    dict[@"attachment_count"] = @(metadata.attachmentCount);
    dict[@"is_linearized"] = @(metadata.isLinearized);
    dict[@"has_drm"] = @(metadata.hasDrm);
    // Always include extended_metadata, even if empty, for Rust SDK compatibility
    dict[@"extended_metadata"] = metadata.extendedMetadata ? [self convertToJSONObject:metadata.extendedMetadata] : @{};
    
    return dict;
}

+ (NSDictionary *)documentOutlineToDict:(LBVRDocumentOutline *)outline {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (outline.sourceFile) dict[@"sourceFile"] = outline.sourceFile;
    if (outline.documentType) dict[@"documentType"] = outline.documentType;
    dict[@"totalPages"] = @(outline.totalPages);
    dict[@"hasOutline"] = @(outline.hasOutline);
    if (outline.title) dict[@"title"] = outline.title;
    
    if (outline.tocEntries && outline.tocEntries.count > 0) {
        NSMutableArray *entriesArray = [[NSMutableArray alloc] init];
        for (LBVRTocEntry *entry in outline.tocEntries) {
            [entriesArray addObject:[self tocEntryToDict:entry]];
        }
        dict[@"tocEntries"] = entriesArray;
    }
    
    if (outline.extractionInfo) {
        dict[@"extractionInfo"] = [self extractionInfoToDict:outline.extractionInfo];
    }
    
    return dict;
}

+ (NSDictionary *)documentPagesToDict:(LBVRDocumentPages *)pages {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (pages.sourceFile) dict[@"sourceFile"] = pages.sourceFile;
    if (pages.documentType) dict[@"documentType"] = pages.documentType;
    dict[@"totalPages"] = @(pages.totalPages);
    if (pages.title) dict[@"title"] = pages.title;
    
    if (pages.pages && pages.pages.count > 0) {
        NSMutableArray *pagesArray = [[NSMutableArray alloc] init];
        for (LBVRDocumentPage *page in pages.pages) {
            [pagesArray addObject:[self documentPageToDict:page]];
        }
        dict[@"pages"] = pagesArray;
    }
    
    if (pages.extractionInfo) {
        dict[@"extractionInfo"] = [self extractionInfoToDict:pages.extractionInfo];
    }
    
    return dict;
}

+ (NSDictionary *)tocEntryToDict:(LBVRTocEntry *)entry {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (entry.title) dict[@"title"] = entry.title;
    dict[@"level"] = @(entry.level);
    if (entry.page > 0) dict[@"page"] = @(entry.page);
    if (entry.sourceRef) dict[@"sourceRef"] = entry.sourceRef;
    
    if (entry.children && entry.children.count > 0) {
        NSMutableArray *childrenArray = [[NSMutableArray alloc] init];
        for (LBVRTocEntry *child in entry.children) {
            [childrenArray addObject:[self tocEntryToDict:child]];
        }
        dict[@"children"] = childrenArray;
    }
    
    return dict;
}

+ (NSDictionary *)documentPageToDict:(LBVRDocumentPage *)page {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"pageNumber"] = @(page.pageNumber);
    if (page.sourceRef) dict[@"sourceRef"] = page.sourceRef;
    
    if (page.paragraphs && page.paragraphs.count > 0) {
        NSMutableArray *paragraphsArray = [[NSMutableArray alloc] init];
        for (LBVRDocumentParagraph *paragraph in page.paragraphs) {
            [paragraphsArray addObject:[self documentParagraphToDict:paragraph]];
        }
        dict[@"paragraphs"] = paragraphsArray;
    }
    
    return dict;
}

+ (NSDictionary *)documentParagraphToDict:(LBVRDocumentParagraph *)paragraph {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"paragraphNumber"] = @(paragraph.paragraphNumber);
    if (paragraph.textContent) dict[@"textContent"] = paragraph.textContent;
    if (paragraph.sourceRef) dict[@"sourceRef"] = paragraph.sourceRef;
    if (paragraph.wordCount) dict[@"wordCount"] = paragraph.wordCount;
    if (paragraph.characterCount) dict[@"characterCount"] = paragraph.characterCount;
    
    return dict;
}

+ (NSDictionary *)extractionInfoToDict:(LBVRExtractionInfo *)info {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (info.extractorName) dict[@"extractorName"] = info.extractorName;
    if (info.extractorVersion) dict[@"extractorVersion"] = info.extractorVersion;
    if (info.extractedAt) dict[@"extractedAt"] = [self dateToString:info.extractedAt];
    if (info.warnings) dict[@"warnings"] = info.warnings;
    
    return dict;
}

+ (NSString *)dateToString:(NSDate *)date {
    if (!date) return nil;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    return [formatter stringFromDate:date];
}

+ (NSString *)argumentTypeStringFromEnum:(CSArgumentType)type {
    switch (type) {
        case CSArgumentTypeString:
            return @"string";
        case CSArgumentTypeInteger:
            return @"integer";
        case CSArgumentTypeNumber:
            return @"number";
        case CSArgumentTypeBoolean:
            return @"boolean";
        case CSArgumentTypeArray:
            return @"array";
        case CSArgumentTypeObject:
            return @"object";
        case CSArgumentTypeBinary:
            return @"binary";
        default:
            return @"string";
    }
}

+ (NSString *)outputTypeStringFromEnum:(CSOutputType)type {
    switch (type) {
        case CSOutputTypeString:
            return @"string";
        case CSOutputTypeInteger:
            return @"integer";
        case CSOutputTypeNumber:
            return @"number";
        case CSOutputTypeBoolean:
            return @"boolean";
        case CSOutputTypeArray:
            return @"array";
        case CSOutputTypeObject:
            return @"object";
        case CSOutputTypeBinary:
            return @"binary";
        default:
            return @"object";
    }
}

+ (NSString *)serializePluginManifest:(LBVRPluginManifest *)pluginManifest {
    if (!pluginManifest) return nil;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"name"] = pluginManifest.name ?: @"unknown";
    dict[@"version"] = pluginManifest.version ?: @"unknown";
    dict[@"description"] = pluginManifest.pluginDescription ?: @"";
    
    if (pluginManifest.author) {
        dict[@"author"] = pluginManifest.author;
    }
    
    // Handle capabilities - expecting CSCapability objects only
    NSMutableArray *capabilitiesArray = [[NSMutableArray alloc] init];
    if (pluginManifest.capabilities && pluginManifest.capabilities.capabilities) {
        for (CSCapability *capability in pluginManifest.capabilities.capabilities) {
            NSMutableDictionary *capabilityDict = [[NSMutableDictionary alloc] init];
            
            // Basic capability info
            capabilityDict[@"id"] = [capability idString];
            capabilityDict[@"version"] = capability.version;
            capabilityDict[@"command"] = capability.command;
            capabilityDict[@"description"] = capability.capabilityDescription;
            
            // Add metadata (including file types)
            if (capability.metadata && capability.metadata.count > 0) {
                capabilityDict[@"metadata"] = capability.metadata;
            }
            
            // Add arguments info
            if (capability.arguments && !capability.arguments.isEmpty) {
                NSMutableDictionary *argumentsDict = [[NSMutableDictionary alloc] init];
                if (capability.arguments.required.count > 0) {
                    NSMutableArray *requiredArgs = [[NSMutableArray alloc] init];
                    for (CSCapabilityArgument *arg in capability.arguments.required) {
                        NSMutableDictionary *argDict = [@{
                            @"name": arg.name,
                            @"type": [self argumentTypeStringFromEnum:arg.type],
                            @"description": arg.argumentDescription,
                            @"cli_flag": arg.cliFlag
                        } mutableCopy];
                        if (arg.position) {
                            argDict[@"position"] = arg.position;
                        }
                        [requiredArgs addObject:argDict];
                    }
                    argumentsDict[@"required"] = requiredArgs;
                }
                if (capability.arguments.optional.count > 0) {
                    NSMutableArray *optionalArgs = [[NSMutableArray alloc] init];
                    for (CSCapabilityArgument *arg in capability.arguments.optional) {
                        NSMutableDictionary *argDict = [@{
                            @"name": arg.name,
                            @"type": [self argumentTypeStringFromEnum:arg.type],
                            @"description": arg.argumentDescription,
                            @"cli_flag": arg.cliFlag
                        } mutableCopy];
                        if (arg.defaultValue) {
                            argDict[@"default"] = arg.defaultValue;
                        }
                        [optionalArgs addObject:argDict];
                    }
                    argumentsDict[@"optional"] = optionalArgs;
                }
                capabilityDict[@"arguments"] = argumentsDict;
            }
            
            // Add output info
            if (capability.output) {
                NSMutableDictionary *outputDict = [[NSMutableDictionary alloc] init];
                outputDict[@"type"] = [self outputTypeStringFromEnum:capability.output.type];
                outputDict[@"description"] = capability.output.outputDescription;
                if (capability.output.contentType) {
                    outputDict[@"content_type"] = capability.output.contentType;
                }
                if (capability.output.schemaRef) {
                    outputDict[@"schema_ref"] = capability.output.schemaRef;
                }
                capabilityDict[@"output"] = outputDict;
            }
            
            [capabilitiesArray addObject:capabilityDict];
        }
    }
    // Wrap capabilities array in capabilities object to match reference implementation
    dict[@"capabilities"] = @{@"capabilities": capabilitiesArray};
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonError) {
        fprintf(stderr, "Error: JSON serialization failed: %s\n", jsonError.localizedDescription.UTF8String);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (id)deserializeFromJSON:(NSString *)jsonString error:(NSError **)error {
    if (!jsonString) {
        if (error) {
            *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                         code:1009
                                     userInfo:@{NSLocalizedDescriptionKey: @"JSON string is nil"}];
        }
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        if (error) {
            *error = [NSError errorWithDomain:@"LBVRPluginSDK"
                                         code:1010
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to convert string to data"}];
        }
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
}

@end

// MARK: - Processing Result Implementation

@implementation LBVRProcessingResult

+ (instancetype)successWithData:(id)data {
    LBVRProcessingResult *result = [[LBVRProcessingResult alloc] init];
    result.success = YES;
    result.data = data;
    return result;
}

+ (instancetype)failureWithError:(NSString *)error {
    LBVRProcessingResult *result = [[LBVRProcessingResult alloc] init];
    result.success = NO;
    result.error = error;
    return result;
}

@end