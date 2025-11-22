//
//  LBVRPluginSDK.h
//  LBVR Plugin SDK for Objective-C
//
//  Unified cap-based plugin interface with standardized command-line calling
//

#import <Foundation/Foundation.h>
#import "CapDef.h"
#import "CSPluginCaps.h"
#import "CSStandardCaps.h"
#import "LBVRStandardCaps.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - Unified Plugin Registry

@class LBVRPluginEntry;
@class LBVRCapCaller;
@class LBVRResponseWrapper;

@interface LBVRPluginRegistry : NSObject

+ (instancetype)sharedRegistry;
- (void)registerPlugin:(NSString *)name
            binaryPath:(NSString *)binaryPath
          caps:(NSArray<NSString *> *)caps;

- (LBVRCapCaller * _Nullable)can:(NSString *)cap error:(NSError **)error;
- (NSArray<NSString *> *)listCaps;

@end

// MARK: - Cap Caller

@interface LBVRCapCaller : NSObject

@property (nonatomic, strong) NSString *pluginName;
@property (nonatomic, strong) NSString *cap;
@property (nonatomic, strong) NSString *binaryPath;

- (void)call:(NSArray *)args stdinData:(NSData * _Nullable)stdinData completion:(void (^)(LBVRResponseWrapper * _Nullable response, NSError * _Nullable error))completion;

@end

// MARK: - Response Wrapper

@interface LBVRResponseWrapper : NSObject

@property (nonatomic, strong, readonly) NSData *data;

- (instancetype)initWithData:(NSData *)data;

// Type-safe deserialization methods
- (BOOL)asType:(Class)type result:(id _Nullable * _Nullable)result error:(NSError **)error;
- (NSString * _Nullable)asStringWithError:(NSError **)error;
- (NSData *)asBytes;
- (NSNumber * _Nullable)asIntWithError:(NSError **)error;
- (NSNumber * _Nullable)asBoolWithError:(NSError **)error;

@end

// MARK: - Plugin Entry

@interface LBVRPluginEntry : NSObject

@property (nonatomic, strong) NSString *binaryPath;
@property (nonatomic, strong) NSArray<NSString *> *caps;

- (instancetype)initWithBinaryPath:(NSString *)binaryPath
                      caps:(NSArray<NSString *> *)caps;

@end

// MARK: - Plugin Caps (now using formal cap SDK)
// Use CSPluginCaps from CapDef instead of the old string-based system

// MARK: - Plugin Manifest (for --manifest output)
// Re-export CSCapManifest as LBVRPluginManifest for backward compatibility

typedef CSCapManifest LBVRPluginManifest;

// Convenience constructors for plugins
@interface CSCapManifest (LBVRPluginSDK)

+ (instancetype)pluginWithName:(NSString *)name
                       version:(NSString *)version
                   description:(NSString *)description
                  caps:(NSArray<CSCap *> *)caps;

@end

// MARK: - Document Metadata (conforms to file-metadata.json schema)

@interface LBVRDocumentMetadata : NSObject
// Basic file info (required)
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) unsigned long long fileSizeBytes;
@property (nonatomic, assign) NSUInteger contentLength;
@property (nonatomic, strong) NSString *documentType;

// Authors and contributors (mutable arrays)
@property (nonatomic, strong) NSMutableArray<NSString *> *authors;
@property (nonatomic, strong) NSMutableArray<NSString *> *contributors;

// Extended metadata (mutable dictionary)
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *extendedMetadata;

// Optional fields
@property (nonatomic, strong, nullable) NSString *mimeType;
@property (nonatomic, strong, nullable) NSString *encoding;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *subject;
@property (nonatomic, strong, nullable) NSString *identifier;
@property (nonatomic, strong, nullable) NSString *language;
@property (nonatomic, strong, nullable) NSString *creator;
@property (nonatomic, strong, nullable) NSString *producer;
@property (nonatomic, strong, nullable) NSString *publisher;
@property (nonatomic, strong, nullable) NSDate *publicationDate;

// Dates (stored as strings)
@property (nonatomic, strong, nullable) NSString *creationDate;
@property (nonatomic, strong, nullable) NSString *modificationDate;

// Counts
@property (nonatomic, strong, nullable) NSNumber *pageCount;
@property (nonatomic, strong, nullable) NSNumber *chapterCount;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;

// Format versions
@property (nonatomic, strong, nullable) NSString *formatVersion;

// PDF-specific
@property (nonatomic, strong, nullable) NSString *pdfVersion;
@property (nonatomic, assign) BOOL hasForms;
@property (nonatomic, assign) BOOL isEncrypted;
@property (nonatomic, assign) NSUInteger attachmentCount;
@property (nonatomic, assign) BOOL isLinearized;

// EPUB-specific
@property (nonatomic, strong, nullable) NSString *epubVersion;
@property (nonatomic, strong, nullable) NSString *rights;
@property (nonatomic, assign) BOOL hasDrm;
@property (nonatomic, strong, nullable) NSString *thumbnailPath;

// Keywords (similar to authors/contributors)
@property (nonatomic, strong) NSMutableArray<NSString *> *keywords;

- (instancetype)initWithFilePath:(NSString *)filePath 
                   fileSizeBytes:(unsigned long long)fileSizeBytes 
                   contentLength:(NSUInteger)contentLength 
                    documentType:(NSString *)documentType;

- (void)addAuthor:(NSString *)author;
- (void)addContributor:(NSString *)contributor;
- (void)addKeyword:(NSString *)keyword;
@end

// MARK: - Document Outline (conforms to document-outline.json schema)

@interface LBVRExtractionInfo : NSObject
@property (nonatomic, strong) NSString *extractorName;
@property (nonatomic, strong) NSString *extractorVersion;
@property (nonatomic, strong, nullable) NSDate *extractedAt;
@property (nonatomic, strong) NSArray<NSString *> *warnings;
- (instancetype)initWithExtractorName:(NSString *)extractorName 
                     extractorVersion:(NSString *)extractorVersion;
@end

@interface LBVROutlineEntry : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, assign) NSUInteger page; // 1-indexed, 0 if no destination
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong) NSMutableArray<LBVROutlineEntry *> *children;
- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level;
+ (instancetype)entryWithTitle:(NSString *)title level:(NSUInteger)level;
- (LBVROutlineEntry *)withPage:(NSUInteger)page;
- (void)addChild:(LBVROutlineEntry *)child;
@end

@interface LBVRDocumentOutline : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSMutableArray<LBVROutlineEntry *> *outlineEntries;
@property (nonatomic, assign) BOOL hasOutline;
@property (nonatomic, strong) LBVRExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages;
- (LBVRDocumentOutline *)withTitle:(NSString *)title;
- (void)addEntry:(LBVROutlineEntry *)entry;
@end

// MARK: - Document Pages (conforms to document-pages.json schema)

@interface LBVRDocumentParagraph : NSObject
@property (nonatomic, assign) NSUInteger paragraphNumber; // 1-indexed
@property (nonatomic, strong) NSString *textContent;
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent;
@end

@interface LBVRDocumentPage : NSObject
@property (nonatomic, assign) NSUInteger pageNumber; // 1-indexed
@property (nonatomic, strong) NSString *textContent;
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
- (instancetype)initWithPageNumber:(NSUInteger)pageNumber;
- (instancetype)initWithPageNumber:(NSUInteger)pageNumber textContent:(NSString *)textContent;
- (void)setTextContent:(NSString *)textContent;
@end

@interface LBVRDocumentPages : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSMutableArray<LBVRDocumentPage *> *pages;
@property (nonatomic, strong) LBVRExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType;
- (LBVRDocumentPages *)withTitle:(NSString *)title;
- (void)addPage:(LBVRDocumentPage *)page;
@end

// MARK: - File Info (for quick file information)

@interface LBVRQuickMetadata : NSObject
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *author;
@property (nonatomic, strong, nullable) NSNumber *pageCount;
@end

@interface LBVRFileInfo : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong, nullable) LBVRQuickMetadata *quickMetadata;
- (instancetype)initWithPath:(NSString *)path 
                        size:(unsigned long long)size 
                documentType:(NSString *)documentType 
                     isValid:(BOOL)isValid;
@end

// MARK: - Document Handler Protocol

@class LBVRProcessingResult;

/**
 * Document handler protocol that defines the contract for document processing plugins
 */
@protocol LBVRDocumentHandler <NSObject>

/**
 * Get plugin manifest including caps
 * @return Plugin manifest
 */
- (LBVRPluginManifest *)getPluginManifest;

/**
 * Extract metadata from a document
 * @param filePath Path to the document file
 * @return Processing result with metadata
 */
- (LBVRProcessingResult *)extractMetadata:(NSString *)filePath;

/**
 * Extract outline/table of contents from a document
 * @param filePath Path to the document file
 * @return Processing result with outline
 */
- (LBVRProcessingResult *)extractOutline:(NSString *)filePath;

/**
 * Extract pages with text content from a document
 * @param filePath Path to the document file
 * @return Processing result with document pages
 */
- (LBVRProcessingResult *)extractPages:(NSString *)filePath;

/**
 * Generate thumbnail image from a document
 * @param filePath Path to the document file
 * @param width Thumbnail width in pixels
 * @param height Thumbnail height in pixels
 * @param page Page number to generate thumbnail from (1-based)
 * @return Processing result with thumbnail data
 */
- (LBVRProcessingResult *)generateThumbnail:(NSString *)filePath width:(NSInteger)width height:(NSInteger)height page:(NSInteger)page;

@end

// MARK: - Processing Result

@interface LBVRProcessingResult : NSObject

@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSString *error;
@property (nonatomic, strong, nullable) NSNumber *processingTimeMs;
@property (nonatomic, strong, nullable) LBVRFileInfo *fileInfo;

+ (instancetype)successWithData:(id)data;
+ (instancetype)failureWithError:(NSString *)error NS_SWIFT_NAME(failure(withError:));

@end

// MARK: - Standardized Caps

@interface LBVRStandardizedCaps : NSObject

@property (class, nonatomic, strong, readonly) NSString *extractMetadata;
@property (class, nonatomic, strong, readonly) NSString *extractOutline;
@property (class, nonatomic, strong, readonly) NSString *extractPages;
@property (class, nonatomic, strong, readonly) NSString *generateThumbnail;
@property (class, nonatomic, strong, readonly) NSString *validateFile;

@end

// MARK: - JSON Serialization Helpers

@interface LBVRJSONSerializer : NSObject

+ (NSString * _Nullable)serializePluginManifest:(LBVRPluginManifest *)pluginManifest;
+ (NSString * _Nullable)serializeToJSON:(id)object;
+ (id _Nullable)deserializeFromJSON:(NSString *)jsonString error:(NSError **)error;

@end

// MARK: - CLI Helper

@interface LBVRCLIHelper : NSObject

+ (NSString *)capToFlag:(NSString *)cap;
+ (NSArray<NSString *> *)buildCommandArgs:(NSString *)cap args:(NSArray *)args;
+ (void)executePlugin:(NSString *)binaryPath 
                 args:(NSArray<NSString *> *)args
           completion:(void (^)(NSData * _Nullable output, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END