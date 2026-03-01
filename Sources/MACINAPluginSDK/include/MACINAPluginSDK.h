//
//  MACINAPluginSDK.h
//  MACINA Plugin SDK for Objective-C
//
//  Unified cap-based plugin interface with standardized command-line calling
//

#import <Foundation/Foundation.h>
#import "CapDAG.h"
#import "CSPluginCaps.h"
#import "CSStandardCaps.h"
#import "MACINAStandardCaps.h"
#import "MACINARegistryManager.h"

NS_ASSUME_NONNULL_BEGIN

// MARK: - Unified Plugin Registry

@class MACINAPluginEntry;
@class MACINAPluginCapSet;

@interface MACINAPluginRegistry : NSObject

+ (instancetype)sharedRegistry;
- (void)registerPlugin:(NSString *)name
            binaryPath:(NSString *)binaryPath
          caps:(NSArray<NSString *> *)caps;

- (CSCapCaller * _Nullable)can:(NSString *)cap error:(NSError **)error;
- (CSCapCaller * _Nullable)can:(NSString *)cap;
- (NSArray<NSString *> *)listCaps;

@end

// MARK: - Plugin Cap Host

@interface MACINAPluginCapSet : NSObject <CSCapSet>
@property (nonatomic, strong) NSString *binaryPath;
- (instancetype)initWithBinaryPath:(NSString *)binaryPath;
@end

// MARK: - Plugin Entry

@interface MACINAPluginEntry : NSObject

@property (nonatomic, strong) NSString *binaryPath;
@property (nonatomic, strong) NSArray<NSString *> *caps;

- (instancetype)initWithBinaryPath:(NSString *)binaryPath
                      caps:(NSArray<NSString *> *)caps;

@end

// MARK: - Plugin Caps (now using formal cap SDK)
// Use CSPluginCaps from CapDAG instead of the old string-based system

// MARK: - Plugin Manifest (for --manifest output)
// Re-export CSCapManifest as MACINAPluginManifest for backward compatibility

typedef CSCapManifest MACINAPluginManifest;

// Convenience constructors for plugins
@interface CSCapManifest (MACINAPluginSDK)

+ (instancetype)pluginWithName:(NSString *)name
                   description:(NSString *)description
                  caps:(NSArray<CSCap *> *)caps;

@end

// MARK: - Document Metadata (conforms to file-metadata.json schema)

@interface MACINADocumentMetadata : NSObject
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
@property (nonatomic, strong, nullable) NSString *mediaUrn;
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

@interface MACINAExtractionInfo : NSObject
@property (nonatomic, strong) NSString *extractorName;
@property (nonatomic, strong) NSString *extractorVersion;
@property (nonatomic, strong, nullable) NSDate *extractedAt;
@property (nonatomic, strong) NSArray<NSString *> *warnings;
- (instancetype)initWithExtractorName:(NSString *)extractorName 
                     extractorVersion:(NSString *)extractorVersion;
@end

@interface MACINAOutlineEntry : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, assign) NSUInteger page; // 1-indexed, 0 if no destination
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong) NSMutableArray<MACINAOutlineEntry *> *children;
- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level;
+ (instancetype)entryWithTitle:(NSString *)title level:(NSUInteger)level;
- (MACINAOutlineEntry *)withPage:(NSUInteger)page;
- (void)addChild:(MACINAOutlineEntry *)child;
@end

@interface MACINADocumentOutline : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSMutableArray<MACINAOutlineEntry *> *outlineEntries;
@property (nonatomic, assign) BOOL hasOutline;
@property (nonatomic, strong) MACINAExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages;
- (MACINADocumentOutline *)withTitle:(NSString *)title;
- (void)addEntry:(MACINAOutlineEntry *)entry;
@end

// MARK: - File Chips (conforms to disbound-pages.json schema)

@interface MACINADocumentParagraph : NSObject
@property (nonatomic, assign) NSUInteger paragraphNumber; // 1-indexed
@property (nonatomic, strong) NSString *textContent;
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
- (instancetype)initWithParagraphNumber:(NSUInteger)paragraphNumber textContent:(NSString *)textContent;
@end

@interface MACINADisboundPage : NSObject
@property (nonatomic, assign) NSUInteger orderIndex; // 1-indexed
@property (nonatomic, strong) NSString *textContent;
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
- (instancetype)initWithOrderIndex:(NSUInteger)orderIndex;
- (instancetype)initWithOrderIndex:(NSUInteger)orderIndex textContent:(NSString *)textContent;
- (void)setTextContent:(NSString *)textContent;
@end


// MARK: - File Info (for quick file information)

@interface MACINAQuickMetadata : NSObject
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *author;
@property (nonatomic, strong, nullable) NSNumber *pageCount;
@end

@interface MACINAFileInfo : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong, nullable) MACINAQuickMetadata *quickMetadata;
- (instancetype)initWithPath:(NSString *)path 
                        size:(unsigned long long)size 
                documentType:(NSString *)documentType 
                     isValid:(BOOL)isValid;
@end

// MARK: - Document Handler Protocol

@class MACINAProcessingResult;

/**
 * Document handler protocol that defines the contract for document processing plugins
 */
@protocol MACINADocumentHandler <NSObject>

/**
 * Get plugin manifest including caps
 * @return Plugin manifest
 */
- (MACINAPluginManifest *)getPluginManifest;

/**
 * Extract metadata from a document
 * @param filePath Path to the document file
 * @return Processing result with metadata
 */
- (MACINAProcessingResult *)extractMetadata:(NSString *)filePath;

/**
 * Extract outline/table of contents from a document
 * @param filePath Path to the document file
 * @return Processing result with outline
 */
- (MACINAProcessingResult *)extractOutline:(NSString *)filePath;

/**
 * Grind with text content from a document
 * @param filePath Path to the document file
 * @return Processing result with file chips
 */
- (MACINAProcessingResult *)grind:(NSString *)filePath;

/**
 * Generate thumbnail image from a document
 * @param filePath Path to the document file
 * @param width Thumbnail width in pixels
 * @param height Thumbnail height in pixels
 * @param page Page number to generate thumbnail from (1-based)
 * @return Processing result with thumbnail data
 */
- (MACINAProcessingResult *)generateThumbnail:(NSString *)filePath width:(NSInteger)width height:(NSInteger)height page:(NSInteger)page;

@end

// MARK: - Processing Result

@interface MACINAProcessingResult : NSObject

@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong, nullable) id data;
@property (nonatomic, strong, nullable) NSString *error;
@property (nonatomic, strong, nullable) NSNumber *processingTimeMs;
@property (nonatomic, strong, nullable) MACINAFileInfo *fileInfo;

+ (instancetype)successWithData:(id)data;
+ (instancetype)failureWithError:(NSString *)error NS_SWIFT_NAME(failure(withError:));

@end

// MARK: - Standardized Caps

@interface MACINAStandardizedCaps : NSObject

@property (class, nonatomic, strong, readonly) NSString *extractMetadata;
@property (class, nonatomic, strong, readonly) NSString *extractOutline;
@property (class, nonatomic, strong, readonly) NSString *grind;
@property (class, nonatomic, strong, readonly) NSString *generateThumbnail;
@property (class, nonatomic, strong, readonly) NSString *validateFile;

@end


// MARK: - CLI Helper

@interface MACINACLIHelper : NSObject

+ (NSString *)capToFlag:(NSString *)cap;
+ (NSArray<NSString *> *)buildCommandArgs:(NSString *)cap args:(NSArray *)args;
+ (void)executePlugin:(NSString *)binaryPath 
                 args:(NSArray<NSString *> *)args
           completion:(void (^)(NSData * _Nullable output, NSError * _Nullable error))completion;

@end

// MARK: - Schema-Enabled Cap Constructors

/**
 * Extension to CSCapArg for plugin-specific helpers
 */
@interface CSCapArg (MACINAPluginSDK)

/**
 * Create a document metadata argument using the new args+sources model
 * @param mediaUrn Media URN identifier (e.g., media:file-metadata;textable;record)
 * @param required Whether the argument is required
 * @param sources Array of CSArgSource specifying how the argument can be provided
 * @param description Human-readable description
 */
+ (instancetype)documentMetadataArgWithMediaUrn:(NSString *)mediaUrn
                                        required:(BOOL)required
                                         sources:(NSArray<CSArgSource *> *)sources
                                   argDescription:(NSString *)description;

/**
 * Create a disbound page argument using the new args+sources model
 * @param mediaUrn Media URN identifier (e.g., media:disbound-page;textable;list)
 * @param required Whether the argument is required
 * @param sources Array of CSArgSource specifying how the argument can be provided
 * @param description Human-readable description
 */
+ (instancetype)disboundPageArgWithMediaUrn:(NSString *)mediaUrn
                                   required:(BOOL)required
                                    sources:(NSArray<CSArgSource *> *)sources
                             argDescription:(NSString *)description;

@end

/**
 * Extension to CSCapOutput helpers with media URN
 */
@interface CSCapOutput (MACINAPluginSDK)

/**
 * Create an object output with embedded JSON schema for document metadata
 * @param schema JSON schema for validation
 * @param description Output description
 * @return A new CSCapOutput instance configured for document metadata
 */
+ (instancetype)documentMetadataOutputWithMediaUrn:(NSString *)mediaUrn
                                       description:(NSString *)description;

/**
 * Create an array output with embedded JSON schema for disbound pages
 * @param mediaUrn Media URN identifier
 * @param description Output description
 * @return A new CSCapOutput instance configured for disbound pages array
 */
+ (instancetype)disboundPageOutputWithMediaUrn:(NSString *)mediaUrn
                                   description:(NSString *)description;

/**
 * Create an object output with embedded JSON schema for document outline
 * @param schema JSON schema for validation
 * @param description Output description
 * @return A new CSCapOutput instance configured for document outline
 */
+ (instancetype)documentOutlineOutputWithMediaUrn:(NSString *)mediaUrn
                                      description:(NSString *)description;

@end

/**
 * Schema validation utility for plugins
 */
@interface MACINASchemaValidationHelper : NSObject

/**
 * Shared schema validator instance with standard resolver
 */
+ (CSJSONSchemaValidator *)sharedValidator;

/**
 * Validate plugin manifest against cap schema requirements
 * @param manifest The plugin manifest to validate
 * @param error Pointer to NSError for error reporting
 * @return YES if validation succeeds, NO if it fails
 */
+ (BOOL)validatePluginManifest:(MACINAPluginManifest *)manifest error:(NSError **)error;

/**
 * Get standard document metadata schema
 * @return Standard JSON schema for document metadata
 */
+ (NSDictionary *)standardDocumentMetadataSchema;

/**
 * Get standard disbound page schema
 * @return Standard JSON schema for disbound page
 */
+ (NSDictionary *)standardDisboundPageSchema;

/**
 * Get standard document outline schema
 * @return Standard JSON schema for document outline
 */
+ (NSDictionary *)standardDocumentOutlineSchema;

@end

NS_ASSUME_NONNULL_END
