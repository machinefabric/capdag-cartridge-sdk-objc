//
//  MACINACartridgeSDK.m
//  MACINA Cartridge SDK for Objective-C
//
//  Unified cap-based cartridge interface with standardized command-line calling
//

#import "include/MACINACartridgeSDK.h"

// MARK: - Cartridge Manifest Category

@implementation CSCapManifest (MACINACartridgeSDK)

+ (instancetype)cartridgeWithName:(NSString *)name
                   description:(NSString *)description
                  caps:(NSArray<CSCap *> *)caps {
    CSCapGroup *defaultGroup = [[CSCapGroup alloc] initWithName:@"default"
                                                          caps:caps
                                                   adapterUrns:@[]];
    return [CSCapManifest manifestWithName:name
                                   version:@"1.0.0"
                               description:description
                                 capGroups:@[defaultGroup]];
}

@end

// MARK: - Standardized Caps

@implementation MACINAStandardizedCaps

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

@implementation MACINACLIHelper

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

+ (void)executeCartridge:(NSString *)binaryPath
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
                NSError *error = [NSError errorWithDomain:@"MACINACartridgeSDK"
                                                     code:1003
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Cartridge execution failed"}];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
        } @catch (NSException *exception) {
            NSError *error = [NSError errorWithDomain:@"MACINACartridgeSDK"
                                                 code:1004
                                             userInfo:@{NSLocalizedDescriptionKey: exception.reason ?: @"Cartridge execution exception"}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
        }
    });
}

@end

// MARK: - Extraction Info

@implementation MACINAExtractionInfo

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

@implementation MACINADocumentMetadata

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

@implementation MACINADocumentOutline

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

- (MACINADocumentOutline *)withTitle:(NSString *)title {
    self.title = [title copy];
    return self;
}

- (void)addEntry:(MACINAOutlineEntry *)entry {
    [_outlineEntries addObject:entry];
    _hasOutline = YES;
}

@end

@implementation MACINAOutlineEntry

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

- (MACINAOutlineEntry *)withPage:(NSUInteger)page {
    self.page = page;
    return self;
}

- (void)addChild:(MACINAOutlineEntry *)child {
    [_children addObject:child];
}

@end


@implementation MACINADocumentParagraph

- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent {
    self = [super init];
    if (self) {
        _paragraphNumber = paragraphNumber;
        _textContent = [textContent copy];
    }
    return self;
}

@end

@implementation MACINADisboundPage

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

@implementation MACINAQuickMetadata
@end

@implementation MACINAFileInfo

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

@implementation MACINAProcessingResult

+ (instancetype)successWithData:(id)data {
    MACINAProcessingResult *result = [[MACINAProcessingResult alloc] init];
    result.success = YES;
    result.data = data;
    return result;
}

+ (instancetype)failureWithError:(NSString *)error {
    MACINAProcessingResult *result = [[MACINAProcessingResult alloc] init];
    result.success = NO;
    result.error = error;
    return result;
}

@end
