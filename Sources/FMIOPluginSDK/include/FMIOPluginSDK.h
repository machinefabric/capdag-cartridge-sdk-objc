//
//  FMIOPluginSDK.h
//  FMIO Plugin SDK for Objective-C
//
//  Unified cap-based plugin interface with standardized command-line calling
//

#import <Foundation/Foundation.h>
#import "CapNs.h"
#import "CSPluginCaps.h"
#import "CSStandardCaps.h"
#import "FMIOStandardCaps.h"
#import "FMIORegistryManager.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - Unified Plugin Registry

@class FMIOPluginEntry;
@class FMIOPluginCapHost;

@interface FMIOPluginRegistry : NSObject

+ (instancetype)sharedRegistry;
- (void)registerPlugin:(NSString *)name
            binaryPath:(NSString *)binaryPath
          caps:(NSArray<NSString *> *)caps;

- (CSCapCaller * _Nullable)can:(NSString *)cap error:(NSError **)error;
- (CSCapCaller * _Nullable)can:(NSString *)cap;
- (NSArray<NSString *> *)listCaps;

@end

// MARK: - Plugin Cap Host

@interface FMIOPluginCapHost : NSObject <CSCapHost>
@property (nonatomic, strong) NSString *binaryPath;
- (instancetype)initWithBinaryPath:(NSString *)binaryPath;
@end

// MARK: - Plugin Entry

@interface FMIOPluginEntry : NSObject

@property (nonatomic, strong) NSString *binaryPath;
@property (nonatomic, strong) NSArray<NSString *> *caps;

- (instancetype)initWithBinaryPath:(NSString *)binaryPath
                      caps:(NSArray<NSString *> *)caps;

@end

// MARK: - Plugin Caps (now using formal cap SDK)
// Use CSPluginCaps from CapNs instead of the old string-based system

// MARK: - Plugin Manifest (for --manifest output)
// Re-export CSCapManifest as FMIOPluginManifest for backward compatibility

typedef CSCapManifest FMIOPluginManifest;

// Convenience constructors for plugins
@interface CSCapManifest (FMIOPluginSDK)

+ (instancetype)pluginWithName:(NSString *)name
                   description:(NSString *)description
                  caps:(NSArray<CSCap *> *)caps;

@end

// MARK: - Document Metadata (conforms to file-metadata.json schema)

@interface FMIODocumentMetadata : NSObject
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

@interface FMIOExtractionInfo : NSObject
@property (nonatomic, strong) NSString *extractorName;
@property (nonatomic, strong) NSString *extractorVersion;
@property (nonatomic, strong, nullable) NSDate *extractedAt;
@property (nonatomic, strong) NSArray<NSString *> *warnings;
- (instancetype)initWithExtractorName:(NSString *)extractorName 
                     extractorVersion:(NSString *)extractorVersion;
@end

@interface FMIOOutlineEntry : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, assign) NSUInteger page; // 1-indexed, 0 if no destination
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong) NSMutableArray<FMIOOutlineEntry *> *children;
- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level;
+ (instancetype)entryWithTitle:(NSString *)title level:(NSUInteger)level;
- (FMIOOutlineEntry *)withPage:(NSUInteger)page;
- (void)addChild:(FMIOOutlineEntry *)child;
@end

@interface FMIODocumentOutline : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSMutableArray<FMIOOutlineEntry *> *outlineEntries;
@property (nonatomic, assign) BOOL hasOutline;
@property (nonatomic, strong) FMIOExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages;
- (FMIODocumentOutline *)withTitle:(NSString *)title;
- (void)addEntry:(FMIOOutlineEntry *)entry;
@end

// MARK: - Document Pages (conforms to document-pages.json schema)

@interface FMIODocumentParagraph : NSObject
@property (nonatomic, assign) NSUInteger paragraphNumber; // 1-indexed
@property (nonatomic, strong) NSString *textContent;
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent;
@end

@interface FMIODocumentPage : NSObject
@property (nonatomic, assign) NSUInteger pageNumber; // 1-indexed
@property (nonatomic, strong) NSString *textContent;
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
- (instancetype)initWithPageNumber:(NSUInteger)pageNumber;
- (instancetype)initWithPageNumber:(NSUInteger)pageNumber textContent:(NSString *)textContent;
- (void)setTextContent:(NSString *)textContent;
@end

@interface FMIODocumentPages : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSMutableArray<FMIODocumentPage *> *pages;
@property (nonatomic, strong) FMIOExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType;
- (FMIODocumentPages *)withTitle:(NSString *)title;
- (void)addPage:(FMIODocumentPage *)page;
@end

// MARK: - File Info (for quick file information)

@interface FMIOQuickMetadata : NSObject
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *author;
@property (nonatomic, strong, nullable) NSNumber *pageCount;
@end

@interface FMIOFileInfo : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong, nullable) FMIOQuickMetadata *quickMetadata;
- (instancetype)initWithPath:(NSString *)path 
                        size:(unsigned long long)size 
                documentType:(NSString *)documentType 
                     isValid:(BOOL)isValid;
@end

// MARK: - Document Handler Protocol

@class FMIOProcessingResult;

/**
 * Document handler protocol that defines the contract for document processing plugins
 */
@protocol FMIODocumentHandler <NSObject>

/**
 * Get plugin manifest including caps
 * @return Plugin manifest
 */
- (FMIOPluginManifest *)getPluginManifest;

/**
 * Extract metadata from a document
 * @param filePath Path to the document file
 * @return Processing result with metadata
 */
- (FMIOProcessingResult *)extractMetadata:(NSString *)filePath;

/**
 * Extract outline/table of contents from a document
 * @param filePath Path to the document file
 * @return Processing result with outline
 */
- (FMIOProcessingResult *)extractOutline:(NSString *)filePath;

/**
 * Extract pages with text content from a document
 * @param filePath Path to the document file
 * @return Processing result with document pages
 */
- (FMIOProcessingResult *)extractPages:(NSString *)filePath;

/**
 * Generate thumbnail image from a document
 * @param filePath Path to the document file
 * @param width Thumbnail width in pixels
 * @param height Thumbnail height in pixels
 * @param page Page number to generate thumbnail from (1-based)
 * @return Processing result with thumbnail data
 */
- (FMIOProcessingResult *)generateThumbnail:(NSString *)filePath width:(NSInteger)width height:(NSInteger)height page:(NSInteger)page;

@end

// MARK: - Processing Result

@interface FMIOProcessingResult : NSObject

@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSString *error;
@property (nonatomic, strong, nullable) NSNumber *processingTimeMs;
@property (nonatomic, strong, nullable) FMIOFileInfo *fileInfo;

+ (instancetype)successWithData:(id)data;
+ (instancetype)failureWithError:(NSString *)error NS_SWIFT_NAME(failure(withError:));

@end

// MARK: - Standardized Caps

@interface FMIOStandardizedCaps : NSObject

@property (class, nonatomic, strong, readonly) NSString *extractMetadata;
@property (class, nonatomic, strong, readonly) NSString *extractOutline;
@property (class, nonatomic, strong, readonly) NSString *extractPages;
@property (class, nonatomic, strong, readonly) NSString *generateThumbnail;
@property (class, nonatomic, strong, readonly) NSString *validateFile;

@end

// MARK: - JSON Serialization Helpers

@interface FMIOJSONSerializer : NSObject

+ (NSString * _Nullable)serializePluginManifest:(FMIOPluginManifest *)pluginManifest;
+ (NSString * _Nullable)serializeToJSON:(id)object;
+ (id _Nullable)deserializeFromJSON:(NSString *)jsonString error:(NSError **)error;

@end

// MARK: - CLI Helper

@interface FMIOCLIHelper : NSObject

+ (NSString *)capToFlag:(NSString *)cap;
+ (NSArray<NSString *> *)buildCommandArgs:(NSString *)cap args:(NSArray *)args;
+ (void)executePlugin:(NSString *)binaryPath 
                 args:(NSArray<NSString *> *)args
           completion:(void (^)(NSData * _Nullable output, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END