//
//  LBVRPluginSDK.h
//  LBVR Plugin SDK for Objective-C
//
//  Unified capability-based plugin interface with standardized command-line calling
//

#import <Foundation/Foundation.h>
#import "CapDef.h"
#import "CSPluginCapabilities.h"
#import "CSStandardCapabilities.h"
#import "LBVRStandardCapabilities.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - Unified Plugin Registry

@class LBVRPluginEntry;
@class LBVRCapabilityCaller;
@class LBVRResponseWrapper;

@interface LBVRPluginRegistry : NSObject

+ (instancetype)sharedRegistry;
- (void)registerPlugin:(NSString *)name
            binaryPath:(NSString *)binaryPath
          capabilities:(NSArray<NSString *> *)capabilities;

- (LBVRCapabilityCaller * _Nullable)can:(NSString *)capability error:(NSError **)error;
- (NSArray<NSString *> *)listCapabilities;

@end

// MARK: - Capability Caller

@interface LBVRCapabilityCaller : NSObject

@property (nonatomic, strong) NSString *pluginName;
@property (nonatomic, strong) NSString *capability;
@property (nonatomic, strong) NSString *binaryPath;

- (void)call:(NSArray *)args completion:(void (^)(LBVRResponseWrapper * _Nullable response, NSError * _Nullable error))completion;

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
@property (nonatomic, strong) NSArray<NSString *> *capabilities;

- (instancetype)initWithBinaryPath:(NSString *)binaryPath
                      capabilities:(NSArray<NSString *> *)capabilities;

@end

// MARK: - Plugin Capabilities (now using formal capability SDK)
// Use CSPluginCapabilities from CapDef instead of the old string-based system

// MARK: - Plugin Manifest (for --manifest output)

@interface LBVRPluginManifest : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *pluginDescription;
@property (nonatomic, strong) CSPluginCapabilities *capabilities;  // Now using formal capability SDK
@property (nonatomic, strong, nullable) NSString *author;

- (instancetype)initWithName:(NSString *)name 
                     version:(NSString *)version 
           pluginDescription:(NSString *)pluginDescription 
                capabilities:(CSPluginCapabilities *)capabilities;

+ (instancetype)pluginWithName:(NSString *)name
                       version:(NSString *)version
                   description:(NSString *)description
                capabilities:(CSPluginCapabilities *)capabilities;

+ (instancetype)manifestWithDictionary:(NSDictionary * _Nonnull)dictionary error:(NSError * _Nullable * _Nullable)error NS_SWIFT_NAME(init(dictionary:error:));

- (LBVRPluginManifest *)withAuthor:(NSString *)author;
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

@interface LBVRTocEntry : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, assign) NSUInteger page; // 1-indexed, 0 if no destination
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong) NSMutableArray<LBVRTocEntry *> *children;
- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level;
+ (instancetype)entryWithTitle:(NSString *)title level:(NSUInteger)level;
- (LBVRTocEntry *)withPage:(NSUInteger)page;
- (void)addChild:(LBVRTocEntry *)child;
@end

@interface LBVRDocumentOutline : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSMutableArray<LBVRTocEntry *> *tocEntries;
@property (nonatomic, assign) BOOL hasOutline;
@property (nonatomic, strong) LBVRExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages;
- (LBVRDocumentOutline *)withTitle:(NSString *)title;
- (void)addEntry:(LBVRTocEntry *)entry;
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
@property (nonatomic, strong) NSMutableArray<LBVRDocumentParagraph *> *paragraphs;
@property (nonatomic, strong, nullable) NSString *sourceRef;
- (instancetype)initWithPageNumber:(NSUInteger)pageNumber;
- (void)addParagraph:(LBVRDocumentParagraph *)paragraph;
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
 * Get plugin manifest including capabilities
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

// MARK: - Standardized Capabilities

@interface LBVRStandardizedCapabilities : NSObject

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

+ (NSString *)capabilityToFlag:(NSString *)capability;
+ (NSArray<NSString *> *)buildCommandArgs:(NSString *)capability args:(NSArray *)args;
+ (void)executePlugin:(NSString *)binaryPath 
                 args:(NSArray<NSString *> *)args
           completion:(void (^)(NSData * _Nullable output, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END