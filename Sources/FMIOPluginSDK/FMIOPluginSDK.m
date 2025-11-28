//
//  FMIOPluginSDK.m
//  FMIO Plugin SDK for Objective-C
//
//  Unified cap-based plugin interface with standardized command-line calling
//

#import "include/FMIOPluginSDK.h"

// MARK: - Unified Plugin Registry

@implementation FMIOPluginRegistry {
    NSMutableDictionary<NSString *, FMIOPluginEntry *> *_plugins;
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *_capIndex;
}

+ (instancetype)sharedRegistry {
    static FMIOPluginRegistry *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FMIOPluginRegistry alloc] init];
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
    
    FMIOPluginEntry *entry = [[FMIOPluginEntry alloc] initWithBinaryPath:binaryPath
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

- (FMIOCapCaller *)can:(NSString *)cap error:(NSError **)error {
    NSString *bestPlugin = [self findBestPluginForCap:cap];
    if (!bestPlugin) {
        if (error) {
            *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Cap '%@' is not available in any registered plugin", cap]}];
        }
        return nil;
    }
    
    FMIOPluginEntry *plugin = _plugins[bestPlugin];
    if (!plugin) {
        if (error) {
            *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Plugin '%@' not found in registry", bestPlugin]}];
        }
        return nil;
    }
    
    FMIOCapCaller *caller = [[FMIOCapCaller alloc] init];
    caller.pluginName = bestPlugin;
    caller.cap = cap;
    caller.binaryPath = plugin.binaryPath;
    
    return caller;
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
        FMIOPluginEntry *plugin = _plugins[pluginName];
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

- (NSInteger)calculateCapScore:(FMIOPluginEntry *)plugin forCap:(NSString *)cap {
    NSInteger score = 0;
    
    // Add specificity score
    for (NSString *cap in plugin.caps) {
        if ([cap isEqualToString:cap]) {
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

// MARK: - Cap Caller

@implementation FMIOCapCaller

- (void)call:(NSArray *)args stdinData:(NSData * _Nullable)stdinData completion:(void (^)(FMIOResponseWrapper * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Convert cap to CLI flag
        NSString *operation = [self.cap componentsSeparatedByString:@":"][0];
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
                FMIOResponseWrapper *response = [[FMIOResponseWrapper alloc] initWithData:outputData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(response, nil);
                });
            } else {
                NSError *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Plugin execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"FMIOPluginSDK"
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

@implementation FMIOResponseWrapper

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
            *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                         code:1005
                                     userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Type conversion failed"}];
        }
        return NO;
    }
}

- (NSString *)asStringWithError:(NSError **)error {
    NSString *result = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    if (!result && error) {
        *error = [NSError errorWithDomain:@"FMIOPluginSDK"
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
        *error = [NSError errorWithDomain:@"FMIOPluginSDK"
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
        *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                     code:1008
                                 userInfo:@{NSLocalizedDescriptionKey: @"Data is not a boolean"}];
    }
    return nil;
}

@end

// MARK: - Plugin Entry

@implementation FMIOPluginEntry

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

@implementation CSCapManifest (FMIOPluginSDK)

+ (instancetype)pluginWithName:(NSString *)name
                       version:(NSString *)version
                   description:(NSString *)description
                  caps:(NSArray<CSCap *> *)caps {
    return [CSCapManifest manifestWithName:name
                                           version:version
                                       description:description
                                      caps:caps];
}

@end

// MARK: - Standardized Caps

@implementation FMIOStandardizedCaps

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

@implementation FMIOCLIHelper

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
                NSError *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Plugin execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"FMIOPluginSDK"
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

@implementation FMIOExtractionInfo

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

@implementation FMIODocumentMetadata

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

@implementation FMIODocumentOutline

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

- (FMIODocumentOutline *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addEntry:(FMIOOutlineEntry *)entry {
    [_outlineEntries addObject:entry];
    _hasOutline = YES;
}

@end

@implementation FMIOOutlineEntry

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

- (FMIOOutlineEntry *)withPage:(NSUInteger)page {
    self.page = page;
    return self;
}

- (void)addChild:(FMIOOutlineEntry *)child {
    [_children addObject:child];
}

@end

@implementation FMIODocumentPages

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

- (FMIODocumentPages *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addPage:(FMIODocumentPage *)page {
    [_pages addObject:page];
    _totalPages = _pages.count;
}

@end

@implementation FMIODocumentParagraph

- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent {
    self = [super init];
    if (self) {
        _paragraphNumber = paragraphNumber;
        _textContent = [textContent copy];
    }
    return self;
}

@end

@implementation FMIODocumentPage

- (instancetype)initWithPageNumber:(NSUInteger)pageNumber {
    self = [super init];
    if (self) {
        _pageNumber = pageNumber;
        _textContent = @"";
    }
    return self;
}

- (instancetype)initWithPageNumber:(NSUInteger)pageNumber textContent:(NSString *)textContent {
    self = [super init];
    if (self) {
        _pageNumber = pageNumber;
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

@implementation FMIOQuickMetadata
@end

@implementation FMIOFileInfo

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

@implementation FMIOJSONSerializer

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
    if ([object isKindOfClass:[FMIODocumentMetadata class]]) {
        return [self documentMetadataToDict:(FMIODocumentMetadata *)object];
    }
    
    if ([object isKindOfClass:[FMIODocumentOutline class]]) {
        return [self documentOutlineToDict:(FMIODocumentOutline *)object];
    }
    
    if ([object isKindOfClass:[FMIODocumentPages class]]) {
        return [self documentPagesToDict:(FMIODocumentPages *)object];
    }
    
    if ([object isKindOfClass:[FMIOOutlineEntry class]]) {
        return [self outlineEntryToDict:(FMIOOutlineEntry *)object];
    }
    
    if ([object isKindOfClass:[FMIODocumentPage class]]) {
        return [self documentPageToDict:(FMIODocumentPage *)object];
    }
    
    if ([object isKindOfClass:[FMIODocumentParagraph class]]) {
        return [self documentParagraphToDict:(FMIODocumentParagraph *)object];
    }
    
    if ([object isKindOfClass:[FMIOExtractionInfo class]]) {
        return [self extractionInfoToDict:(FMIOExtractionInfo *)object];
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

+ (NSDictionary *)documentMetadataToDict:(FMIODocumentMetadata *)metadata {
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

+ (NSDictionary *)documentOutlineToDict:(FMIODocumentOutline *)outline {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (outline.sourceFile) dict[@"sourceFile"] = outline.sourceFile;
    if (outline.documentType) dict[@"documentType"] = outline.documentType;
    dict[@"totalPages"] = @(outline.totalPages);
    dict[@"hasOutline"] = @(outline.hasOutline);
    if (outline.title) dict[@"title"] = outline.title;
    
    if (outline.outlineEntries && outline.outlineEntries.count > 0) {
        NSMutableArray *entriesArray = [[NSMutableArray alloc] init];
        for (FMIOOutlineEntry *entry in outline.outlineEntries) {
            [entriesArray addObject:[self outlineEntryToDict:entry]];
        }
        dict[@"outlineEntries"] = entriesArray;
    }
    
    if (outline.extractionInfo) {
        dict[@"extractionInfo"] = [self extractionInfoToDict:outline.extractionInfo];
    }
    
    return dict;
}

+ (NSDictionary *)documentPagesToDict:(FMIODocumentPages *)pages {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (pages.sourceFile) dict[@"sourceFile"] = pages.sourceFile;
    if (pages.documentType) dict[@"documentType"] = pages.documentType;
    dict[@"totalPages"] = @(pages.totalPages);
    if (pages.title) dict[@"title"] = pages.title;
    
    if (pages.pages && pages.pages.count > 0) {
        NSMutableArray *pagesArray = [[NSMutableArray alloc] init];
        for (FMIODocumentPage *page in pages.pages) {
            [pagesArray addObject:[self documentPageToDict:page]];
        }
        dict[@"pages"] = pagesArray;
    }
    
    if (pages.extractionInfo) {
        dict[@"extractionInfo"] = [self extractionInfoToDict:pages.extractionInfo];
    }
    
    return dict;
}

+ (NSDictionary *)outlineEntryToDict:(FMIOOutlineEntry *)entry {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (entry.title) dict[@"title"] = entry.title;
    dict[@"level"] = @(entry.level);
    if (entry.page > 0) dict[@"page"] = @(entry.page);
    if (entry.sourceRef) dict[@"sourceRef"] = entry.sourceRef;
    
    if (entry.children && entry.children.count > 0) {
        NSMutableArray *childrenArray = [[NSMutableArray alloc] init];
        for (FMIOOutlineEntry *child in entry.children) {
            [childrenArray addObject:[self outlineEntryToDict:child]];
        }
        dict[@"children"] = childrenArray;
    }
    
    return dict;
}

+ (NSDictionary *)documentPageToDict:(FMIODocumentPage *)page {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"page_number"] = @(page.pageNumber);
    if (page.textContent) dict[@"text_content"] = page.textContent;
    if (page.sourceRef) dict[@"source_ref"] = page.sourceRef;
    if (page.wordCount) dict[@"word_count"] = page.wordCount;
    if (page.characterCount) dict[@"character_count"] = page.characterCount;
    
    return dict;
}

+ (NSDictionary *)documentParagraphToDict:(FMIODocumentParagraph *)paragraph {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"paragraphNumber"] = @(paragraph.paragraphNumber);
    if (paragraph.textContent) dict[@"textContent"] = paragraph.textContent;
    if (paragraph.sourceRef) dict[@"sourceRef"] = paragraph.sourceRef;
    if (paragraph.wordCount) dict[@"wordCount"] = paragraph.wordCount;
    if (paragraph.characterCount) dict[@"characterCount"] = paragraph.characterCount;
    
    return dict;
}

+ (NSDictionary *)extractionInfoToDict:(FMIOExtractionInfo *)info {
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

+ (NSString *)serializePluginManifest:(FMIOPluginManifest *)pluginManifest {
    if (!pluginManifest) return nil;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"name"] = pluginManifest.name ?: @"unknown";
    dict[@"version"] = pluginManifest.version ?: @"unknown";
    dict[@"description"] = pluginManifest.manifestDescription ?: @"";
    
    if (pluginManifest.author) {
        dict[@"author"] = pluginManifest.author;
    }
    
    // Handle caps - expecting CSCap objects only
    NSMutableArray *capsArray = [[NSMutableArray alloc] init];
    if (pluginManifest.caps) {
        for (CSCap *cap in pluginManifest.caps) {
            NSMutableDictionary *capDict = [[NSMutableDictionary alloc] init];
            
            // Basic cap info
            capDict[@"id"] = [cap urnString];
            capDict[@"version"] = cap.version;
            capDict[@"command"] = cap.command;
            capDict[@"description"] = cap.capDescription;
            
            // Add metadata (including file types)
            if (cap.metadata && cap.metadata.count > 0) {
                capDict[@"metadata"] = cap.metadata;
            }
            
            // Add arguments info
            if (cap.arguments && !cap.arguments.isEmpty) {
                NSMutableDictionary *argumentsDict = [[NSMutableDictionary alloc] init];
                if (cap.arguments.required.count > 0) {
                    NSMutableArray *requiredArgs = [[NSMutableArray alloc] init];
                    for (CSCapArgument *arg in cap.arguments.required) {
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
                if (cap.arguments.optional.count > 0) {
                    NSMutableArray *optionalArgs = [[NSMutableArray alloc] init];
                    for (CSCapArgument *arg in cap.arguments.optional) {
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
                capDict[@"arguments"] = argumentsDict;
            }
            
            // Add output info
            if (cap.output) {
                NSMutableDictionary *outputDict = [[NSMutableDictionary alloc] init];
                outputDict[@"type"] = [self outputTypeStringFromEnum:cap.output.type];
                outputDict[@"description"] = cap.output.outputDescription;
                if (cap.output.contentType) {
                    outputDict[@"content_type"] = cap.output.contentType;
                }
                if (cap.output.schemaRef) {
                    outputDict[@"schema_ref"] = cap.output.schemaRef;
                }
                capDict[@"output"] = outputDict;
            }
            
            [capsArray addObject:capDict];
        }
    }
    // Wrap caps array in caps object to match reference implementation
    dict[@"caps"] = @{@"caps": capsArray};
    
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
            *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                         code:1009
                                     userInfo:@{NSLocalizedDescriptionKey: @"JSON string is nil"}];
        }
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        if (error) {
            *error = [NSError errorWithDomain:@"FMIOPluginSDK"
                                         code:1010
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to convert string to data"}];
        }
        return nil;
    }
    
    return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
}

@end

// MARK: - Processing Result Implementation

@implementation FMIOProcessingResult

+ (instancetype)successWithData:(id)data {
    FMIOProcessingResult *result = [[FMIOProcessingResult alloc] init];
    result.success = YES;
    result.data = data;
    return result;
}

+ (instancetype)failureWithError:(NSString *)error {
    FMIOProcessingResult *result = [[FMIOProcessingResult alloc] init];
    result.success = NO;
    result.error = error;
    return result;
}

@end