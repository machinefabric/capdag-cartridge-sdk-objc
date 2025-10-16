//
//  LBVRPluginSDK.m
//  LBVR Plugin SDK for Objective-C
//

#import "LBVRPluginSDK.h"

// MARK: - Plugin Capabilities

@implementation LBVRPluginCapabilities

- (instancetype)initWithCapabilities:(NSArray<NSString *> *)capabilities {
    self = [super init];
    if (self) {
        _capabilities = [capabilities copy];
    }
    return self;
}

@end

// MARK: - Plugin Info

@implementation LBVRPluginInfo

- (instancetype)initWithName:(NSString *)name 
                     version:(NSString *)version 
           pluginDescription:(NSString *)pluginDescription 
                  pluginType:(LBVRPluginType)pluginType
                    priority:(LBVRPluginPriority)priority
                  extensions:(nullable NSArray<NSString *> *)extensions
            serviceEndpoints:(nullable NSArray<NSString *> *)serviceEndpoints
                capabilities:(LBVRPluginCapabilities *)capabilities {
    self = [super init];
    if (self) {
        _name = [name copy];
        _version = [version copy];
        _pluginDescription = [pluginDescription copy];
        _pluginType = pluginType;
        _priority = priority;
        _extensions = [extensions copy] ?: @[];
        _serviceEndpoints = [serviceEndpoints copy];
        _capabilities = capabilities;
        _systemCritical = (priority == LBVRPluginPriorityCritical);
    }
    return self;
}

+ (instancetype)documentHandlerWithName:(NSString *)name
                                version:(NSString *)version
                            description:(NSString *)description
                             extensions:(NSArray<NSString *> *)extensions
                           capabilities:(LBVRPluginCapabilities *)capabilities {
    return [[self alloc] initWithName:name
                              version:version
                    pluginDescription:description
                           pluginType:LBVRPluginTypeDocumentHandler
                             priority:LBVRPluginPriorityOptional
                           extensions:extensions
                     serviceEndpoints:nil
                         capabilities:capabilities];
}

+ (instancetype)systemServiceWithName:(NSString *)name
                              version:(NSString *)version
                          description:(NSString *)description
                      serviceEndpoints:(NSArray<NSString *> *)serviceEndpoints
                          capabilities:(LBVRPluginCapabilities *)capabilities
                              priority:(LBVRPluginPriority)priority {
    return [[self alloc] initWithName:name
                              version:version
                    pluginDescription:description
                           pluginType:LBVRPluginTypeSystemService
                             priority:priority
                           extensions:nil
                     serviceEndpoints:serviceEndpoints
                         capabilities:capabilities];
}

+ (instancetype)modelServiceWithName:(NSString *)name
                             version:(NSString *)version
                         description:(NSString *)description
                     serviceEndpoints:(NSArray<NSString *> *)serviceEndpoints
                         capabilities:(LBVRPluginCapabilities *)capabilities
                             priority:(LBVRPluginPriority)priority {
    return [[self alloc] initWithName:name
                              version:version
                    pluginDescription:description
                           pluginType:LBVRPluginTypeModelService
                             priority:priority
                           extensions:nil
                     serviceEndpoints:serviceEndpoints
                         capabilities:capabilities];
}

+ (instancetype)embeddingServiceWithName:(NSString *)name
                                 version:(NSString *)version
                             description:(NSString *)description
                         serviceEndpoints:(NSArray<NSString *> *)serviceEndpoints
                             capabilities:(LBVRPluginCapabilities *)capabilities
                                 priority:(LBVRPluginPriority)priority {
    return [[self alloc] initWithName:name
                              version:version
                    pluginDescription:description
                           pluginType:LBVRPluginTypeEmbeddingService
                             priority:priority
                           extensions:nil
                     serviceEndpoints:serviceEndpoints
                         capabilities:capabilities];
}

@end

// MARK: - Document Metadata

@implementation LBVRDocumentMetadata

- (instancetype)initWithFilePath:(NSString *)filePath 
                   fileSizeBytes:(long long)fileSizeBytes 
                   contentLength:(NSUInteger)contentLength 
                    documentType:(NSString *)documentType {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        _fileSizeBytes = fileSizeBytes;
        _contentLength = contentLength;
        _documentType = [documentType copy];
        
        // Initialize required arrays
        _authors = @[];
        _contributors = @[];
        _keywords = @[];
        _extendedMetadata = @{};
        
        // Initialize required booleans
        _hasForms = NO;
        _isEncrypted = NO;
        _isLinearized = NO;
        _hasDRM = NO;
        _attachmentCount = 0;
    }
    return self;
}

@end

// MARK: - Extraction Info

@implementation LBVRExtractionInfo

- (instancetype)initWithExtractorName:(NSString *)extractorName 
                     extractorVersion:(NSString *)extractorVersion {
    self = [super init];
    if (self) {
        _extractorName = [extractorName copy];
        _extractorVersion = [extractorVersion copy];
        _warnings = @[];
        _extractedAt = [NSDate date];
    }
    return self;
}

@end

// MARK: - Document Outline

@implementation LBVROutlineItem

- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level {
    self = [super init];
    if (self) {
        _title = [title copy];
        _level = level;
        _children = @[];
    }
    return self;
}

- (void)addChild:(LBVROutlineItem *)child {
    NSMutableArray *mutableChildren = [self.children mutableCopy];
    [mutableChildren addObject:child];
    self.children = [mutableChildren copy];
}

@end

@implementation LBVRDocumentOutline

- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages 
                     extractionInfo:(LBVRExtractionInfo *)extractionInfo {
    self = [super init];
    if (self) {
        _sourceFile = [sourceFile copy];
        _documentType = [documentType copy];
        _totalPages = totalPages;
        _extractionInfo = extractionInfo;
        _entries = @[];
        _hasOutline = NO;
    }
    return self;
}

- (void)addEntry:(LBVROutlineItem *)entry {
    NSMutableArray *mutableEntries = [self.entries mutableCopy];
    [mutableEntries addObject:entry];
    self.entries = [mutableEntries copy];
    self.hasOutline = YES;
}

@end

// MARK: - Document Pages

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
        _paragraphs = @[];
    }
    return self;
}

- (void)addParagraph:(LBVRDocumentParagraph *)paragraph {
    NSMutableArray *mutableParagraphs = [self.paragraphs mutableCopy];
    [mutableParagraphs addObject:paragraph];
    self.paragraphs = [mutableParagraphs copy];
}

@end

@implementation LBVRDocumentPages

- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages 
                     extractionInfo:(LBVRExtractionInfo *)extractionInfo {
    self = [super init];
    if (self) {
        _sourceFile = [sourceFile copy];
        _documentType = [documentType copy];
        _totalPages = totalPages;
        _extractionInfo = extractionInfo;
        _pages = @[];
    }
    return self;
}

- (void)addPage:(LBVRDocumentPage *)page {
    NSMutableArray *mutablePages = [self.pages mutableCopy];
    [mutablePages addObject:page];
    self.pages = [mutablePages copy];
}

@end

// MARK: - File Info

@implementation LBVRQuickMetadata
@end

@implementation LBVRFileInfo

- (instancetype)initWithPath:(NSString *)path 
                        size:(long long)size 
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

// MARK: - Plugin Output

@implementation LBVRPluginOutput

+ (instancetype)successWithMetadata:(nullable LBVRDocumentMetadata *)metadata
                            outline:(nullable LBVRDocumentOutline *)outline
                              pages:(nullable LBVRDocumentPages *)pages
                      thumbnailData:(nullable NSData *)thumbnailData {
    LBVRPluginOutput *output = [[LBVRPluginOutput alloc] init];
    output.success = YES;
    output.metadata = metadata;
    output.outline = outline;
    output.pages = pages;
    output.thumbnailData = thumbnailData;
    output.error = nil;
    return output;
}

+ (instancetype)failureWithError:(NSString *)error {
    LBVRPluginOutput *output = [[LBVRPluginOutput alloc] init];
    output.success = NO;
    output.error = [error copy];
    output.metadata = nil;
    output.outline = nil;
    output.pages = nil;
    output.thumbnailData = nil;
    return output;
}

@end

// MARK: - Plugin Manager

@implementation LBVRPluginManager {
    NSMutableDictionary<NSString *, id<LBVRDocumentHandler>> *_handlers;
}

+ (instancetype)sharedManager {
    static LBVRPluginManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LBVRPluginManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _handlers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerHandler:(id<LBVRDocumentHandler>)handler forFileExtensions:(NSArray<NSString *> *)extensions {
    for (NSString *extension in extensions) {
        NSString *lowercaseExtension = [extension lowercaseString];
        _handlers[lowercaseExtension] = handler;
    }
}

- (id<LBVRDocumentHandler>)handlerForFilePath:(NSString *)filePath {
    NSString *extension = [[filePath pathExtension] lowercaseString];
    return _handlers[extension];
}

- (LBVRPluginOutput *)processDocument:(NSString *)filePath {
    id<LBVRDocumentHandler> handler = [self handlerForFilePath:filePath];
    if (!handler) {
        return [LBVRPluginOutput failureWithError:[NSString stringWithFormat:@"No handler found for file: %@", filePath]];
    }
    
    __block LBVRPluginOutput *result = nil;
    __block BOOL completed = NO;
    
    // Use async methods but wait for completion (simplified for this API)
    [handler extractMetadata:filePath completion:^(LBVRDocumentMetadata *metadata, NSError *error) {
        if (error) {
            result = [LBVRPluginOutput failureWithError:error.localizedDescription];
            completed = YES;
            return;
        }
        
        // Try to get outline, pages, and thumbnail
        __block LBVRDocumentOutline *outline = nil;
        __block LBVRDocumentPages *pages = nil;
        __block NSData *thumbnailData = nil;
        __block NSInteger pendingOperations = 3;
        
        void (^checkCompletion)(void) = ^{
            pendingOperations--;
            if (pendingOperations == 0) {
                result = [LBVRPluginOutput successWithMetadata:metadata outline:outline pages:pages thumbnailData:thumbnailData];
                completed = YES;
            }
        };
        
        [handler extractOutline:filePath completion:^(LBVRDocumentOutline *outlineResult, NSError *outlineError) {
            if (!outlineError) outline = outlineResult;
            checkCompletion();
        }];
        
        [handler extractPages:filePath completion:^(LBVRDocumentPages *pagesResult, NSError *pagesError) {
            if (!pagesError) pages = pagesResult;
            checkCompletion();
        }];
        
        [handler generateThumbnail:filePath width:200 height:200 completion:^(NSData *thumbnailResult, NSError *thumbnailError) {
            if (!thumbnailError) thumbnailData = thumbnailResult;
            checkCompletion();
        }];
    }];
    
    // Simple synchronous wait (not recommended for production)
    while (!completed) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    
    return result;
}

@end

// MARK: - JSON Serialization Helpers

@implementation LBVRJSONSerializer

+ (NSString *)serializeMetadata:(LBVRDocumentMetadata *)metadata {
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    // Required fields
    dict[@"file_path"] = metadata.filePath;
    dict[@"file_size_bytes"] = @(metadata.fileSizeBytes);
    dict[@"content_length"] = @(metadata.contentLength);
    dict[@"document_type"] = metadata.documentType;
    dict[@"authors"] = metadata.authors;
    dict[@"contributors"] = metadata.contributors;
    dict[@"keywords"] = metadata.keywords;
    dict[@"extended_metadata"] = metadata.extendedMetadata;
    dict[@"has_forms"] = @(metadata.hasForms);
    dict[@"is_encrypted"] = @(metadata.isEncrypted);
    dict[@"attachment_count"] = @(metadata.attachmentCount);
    dict[@"is_linearized"] = @(metadata.isLinearized);
    dict[@"has_drm"] = @(metadata.hasDRM);
    
    // Optional fields
    if (metadata.mimeType) dict[@"mime_type"] = metadata.mimeType;
    if (metadata.encoding) dict[@"encoding"] = metadata.encoding;
    if (metadata.title) dict[@"title"] = metadata.title;
    if (metadata.subject) dict[@"subject"] = metadata.subject;
    if (metadata.identifier) dict[@"identifier"] = metadata.identifier;
    if (metadata.language) dict[@"language"] = metadata.language;
    if (metadata.creator) dict[@"creator"] = metadata.creator;
    if (metadata.producer) dict[@"producer"] = metadata.producer;
    if (metadata.pageCount) dict[@"page_count"] = metadata.pageCount;
    if (metadata.chapterCount) dict[@"chapter_count"] = metadata.chapterCount;
    if (metadata.wordCount) dict[@"word_count"] = metadata.wordCount;
    if (metadata.characterCount) dict[@"character_count"] = metadata.characterCount;
    if (metadata.formatVersion) dict[@"format_version"] = metadata.formatVersion;
    if (metadata.pdfVersion) dict[@"pdf_version"] = metadata.pdfVersion;
    if (metadata.epubVersion) dict[@"epub_version"] = metadata.epubVersion;
    if (metadata.publisher) dict[@"publisher"] = metadata.publisher;
    if (metadata.rights) dict[@"rights"] = metadata.rights;
    if (metadata.thumbnailPath) dict[@"thumbnail_path"] = metadata.thumbnailPath;
    
    if (metadata.creationDate) {
        dict[@"creation_date"] = [self dateToISO8601String:metadata.creationDate];
    }
    if (metadata.modificationDate) {
        dict[@"modification_date"] = [self dateToISO8601String:metadata.modificationDate];
    }
    if (metadata.publicationDate) {
        dict[@"publication_date"] = [self dateToISO8601String:metadata.publicationDate];
    }
    
    return [self dictionaryToJSONString:dict];
}

+ (NSString *)serializeOutline:(LBVRDocumentOutline *)outline {
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    dict[@"source_file"] = outline.sourceFile;
    if (outline.documentTitle) dict[@"document_title"] = outline.documentTitle;
    dict[@"document_type"] = outline.documentType;
    dict[@"total_pages"] = @(outline.totalPages);
    dict[@"has_outline"] = @(outline.hasOutline);
    
    NSMutableArray *entriesArray = [@[] mutableCopy];
    for (LBVROutlineItem *entry in outline.entries) {
        [entriesArray addObject:[self outlineItemToDictionary:entry]];
    }
    dict[@"entries"] = entriesArray;
    
    dict[@"extraction_info"] = [self extractionInfoToDictionary:outline.extractionInfo];
    
    return [self dictionaryToJSONString:dict];
}

+ (NSString *)serializePages:(LBVRDocumentPages *)pages {
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    dict[@"source_file"] = pages.sourceFile;
    if (pages.documentTitle) dict[@"document_title"] = pages.documentTitle;
    dict[@"document_type"] = pages.documentType;
    dict[@"total_pages"] = @(pages.totalPages);
    
    NSMutableArray *pagesArray = [@[] mutableCopy];
    for (LBVRDocumentPage *page in pages.pages) {
        NSMutableDictionary *pageDict = [@{
            @"page_number": @(page.pageNumber)
        } mutableCopy];
        
        if (page.sourceRef) pageDict[@"source_ref"] = page.sourceRef;
        
        NSMutableArray *paragraphsArray = [@[] mutableCopy];
        for (LBVRDocumentParagraph *paragraph in page.paragraphs) {
            NSMutableDictionary *paragraphDict = [@{
                @"paragraph_number": @(paragraph.paragraphNumber),
                @"text_content": paragraph.textContent
            } mutableCopy];
            
            if (paragraph.sourceRef) paragraphDict[@"source_ref"] = paragraph.sourceRef;
            if (paragraph.wordCount) paragraphDict[@"word_count"] = paragraph.wordCount;
            if (paragraph.characterCount) paragraphDict[@"character_count"] = paragraph.characterCount;
            
            [paragraphsArray addObject:paragraphDict];
        }
        pageDict[@"paragraphs"] = paragraphsArray;
        
        [pagesArray addObject:pageDict];
    }
    dict[@"pages"] = pagesArray;
    
    dict[@"extraction_info"] = [self extractionInfoToDictionary:pages.extractionInfo];
    
    return [self dictionaryToJSONString:dict];
}

+ (NSString *)serializePluginOutput:(LBVRPluginOutput *)output {
    NSMutableDictionary *dict = [@{
        @"success": @(output.success)
    } mutableCopy];
    
    if (output.error) {
        dict[@"error"] = output.error;
    }
    
    if (output.metadata) {
        NSString *metadataJSON = [self serializeMetadata:output.metadata];
        if (metadataJSON) {
            dict[@"metadata"] = [NSJSONSerialization JSONObjectWithData:[metadataJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }
    }
    
    if (output.outline) {
        NSString *outlineJSON = [self serializeOutline:output.outline];
        if (outlineJSON) {
            dict[@"outline"] = [NSJSONSerialization JSONObjectWithData:[outlineJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }
    }
    
    if (output.pages) {
        NSString *pagesJSON = [self serializePages:output.pages];
        if (pagesJSON) {
            dict[@"pages"] = [NSJSONSerialization JSONObjectWithData:[pagesJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }
    }
    
    if (output.thumbnailData) {
        dict[@"thumbnailData"] = [output.thumbnailData base64EncodedStringWithOptions:0];
    }
    
    return [self dictionaryToJSONString:dict];
}

+ (NSString *)serializePluginInfo:(LBVRPluginInfo *)pluginInfo {
    NSMutableDictionary *dict = [@{
        @"name": pluginInfo.name,
        @"version": pluginInfo.version,
        @"description": pluginInfo.pluginDescription,
        @"plugin_type": [self pluginTypeToString:pluginInfo.pluginType],
        @"priority": [self pluginPriorityToString:pluginInfo.priority],
        @"system_critical": @(pluginInfo.systemCritical),
        @"capabilities": @{
            @"capabilities": pluginInfo.capabilities.capabilities
        }
    } mutableCopy];
    
    // Add extensions for document handlers
    if (pluginInfo.pluginType == LBVRPluginTypeDocumentHandler && pluginInfo.extensions.count > 0) {
        dict[@"extensions"] = pluginInfo.extensions;
    }
    
    // Add service endpoints for service plugins
    if (pluginInfo.serviceEndpoints) {
        dict[@"service_endpoints"] = pluginInfo.serviceEndpoints;
    }
    
    if (pluginInfo.author) {
        dict[@"author"] = pluginInfo.author;
    }
    
    return [self dictionaryToJSONString:dict];
}

+ (NSString *)pluginTypeToString:(LBVRPluginType)pluginType {
    switch (pluginType) {
        case LBVRPluginTypeDocumentHandler:
            return @"document_handler";
        case LBVRPluginTypeModelService:
            return @"model_service";
        case LBVRPluginTypeEmbeddingService:
            return @"embedding_service";
        case LBVRPluginTypeSystemService:
            return @"system_service";
        default:
            return @"unknown";
    }
}

+ (NSString *)pluginPriorityToString:(LBVRPluginPriority)priority {
    switch (priority) {
        case LBVRPluginPriorityOptional:
            return @"optional";
        case LBVRPluginPriorityRecommended:
            return @"recommended";
        case LBVRPluginPriorityCritical:
            return @"critical";
        default:
            return @"optional";
    }
}

// MARK: - Private Helper Methods

+ (NSDictionary *)outlineItemToDictionary:(LBVROutlineItem *)item {
    NSMutableDictionary *dict = [@{
        @"title": item.title,
        @"level": @(item.level),
        @"children": @[]
    } mutableCopy];
    
    if (item.page) dict[@"page"] = item.page;
    if (item.sourceRef) dict[@"source_ref"] = item.sourceRef;
    
    if (item.children.count > 0) {
        NSMutableArray *childrenArray = [@[] mutableCopy];
        for (LBVROutlineItem *child in item.children) {
            [childrenArray addObject:[self outlineItemToDictionary:child]];
        }
        dict[@"children"] = childrenArray;
    }
    
    return dict;
}

+ (NSDictionary *)extractionInfoToDictionary:(LBVRExtractionInfo *)info {
    NSMutableDictionary *dict = [@{
        @"extractor_name": info.extractorName,
        @"extractor_version": info.extractorVersion,
        @"warnings": info.warnings
    } mutableCopy];
    
    if (info.extractedAt) {
        dict[@"extracted_at"] = [self dateToISO8601String:info.extractedAt];
    }
    
    return dict;
}

+ (NSString *)dateToISO8601String:(NSDate *)date {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return [formatter stringFromDate:date];
}

+ (NSString *)dictionaryToJSONString:(NSDictionary *)dictionary {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"JSON serialization error: %@", error.localizedDescription);
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end