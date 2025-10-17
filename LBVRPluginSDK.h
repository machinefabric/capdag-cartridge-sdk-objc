//
//  LBVRPluginSDK.h
//  LBVR Plugin SDK for Objective-C
//
//  Provides native Objective-C interface for LBVR plugins
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// MARK: - Plugin Capabilities

@interface LBVRPluginCapabilities : NSObject
@property (nonatomic, strong) NSArray<NSString *> *capabilities;
- (instancetype)initWithCapabilities:(NSArray<NSString *> *)capabilities;
- (BOOL)canHandleFileType:(NSString *)fileType;
- (BOOL)canPerformOperation:(NSString *)operation onFileType:(NSString *)fileType;
- (NSString * _Nullable)getMostSpecificCapability:(NSString *)operation forFileType:(NSString *)fileType;
@end

// MARK: - Plugin Priorities

typedef NS_ENUM(NSInteger, LBVRPluginPriority) {
    LBVRPluginPriorityOptional = 0,     // Can be disabled/removed
    LBVRPluginPriorityRecommended,      // Important but not critical
    LBVRPluginPriorityCritical,         // System-critical, cannot be disabled
};

// MARK: - Plugin Info

@interface LBVRPluginInfo : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *pluginDescription;
@property (nonatomic, assign) LBVRPluginPriority priority;
@property (nonatomic, strong) LBVRPluginCapabilities *capabilities;
@property (nonatomic, strong, nullable) NSString *author;

- (instancetype)initWithName:(NSString *)name 
                     version:(NSString *)version 
           pluginDescription:(NSString *)pluginDescription 
                    priority:(LBVRPluginPriority)priority
                capabilities:(LBVRPluginCapabilities *)capabilities;

+ (instancetype)pluginWithName:(NSString *)name
                       version:(NSString *)version
                   description:(NSString *)description
                  capabilities:(LBVRPluginCapabilities *)capabilities
                      priority:(LBVRPluginPriority)priority;
@end

// MARK: - Document Metadata (conforms to file-metadata.json schema)

@interface LBVRDocumentMetadata : NSObject
// Required fields
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) long long fileSizeBytes;
@property (nonatomic, assign) NSUInteger contentLength;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, strong) NSArray<NSString *> *authors;
@property (nonatomic, strong) NSArray<NSString *> *contributors;
@property (nonatomic, strong) NSArray<NSString *> *keywords;
@property (nonatomic, strong) NSDictionary<NSString *, id> *extendedMetadata;
@property (nonatomic, assign) BOOL hasForms;
@property (nonatomic, assign) BOOL isEncrypted;
@property (nonatomic, assign) NSUInteger attachmentCount;
@property (nonatomic, assign) BOOL isLinearized;
@property (nonatomic, assign) BOOL hasDRM;

// Optional fields
@property (nonatomic, strong, nullable) NSString *mimeType;
@property (nonatomic, strong, nullable) NSString *encoding;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *subject;
@property (nonatomic, strong, nullable) NSString *identifier;
@property (nonatomic, strong, nullable) NSString *language;
@property (nonatomic, strong, nullable) NSString *creator;
@property (nonatomic, strong, nullable) NSString *producer;
@property (nonatomic, strong, nullable) NSDate *creationDate;
@property (nonatomic, strong, nullable) NSDate *modificationDate;
@property (nonatomic, strong, nullable) NSNumber *pageCount;
@property (nonatomic, strong, nullable) NSNumber *chapterCount;
@property (nonatomic, strong, nullable) NSNumber *wordCount;
@property (nonatomic, strong, nullable) NSNumber *characterCount;
@property (nonatomic, strong, nullable) NSString *formatVersion;
@property (nonatomic, strong, nullable) NSString *pdfVersion;
@property (nonatomic, strong, nullable) NSString *epubVersion;
@property (nonatomic, strong, nullable) NSString *publisher;
@property (nonatomic, strong, nullable) NSDate *publicationDate;
@property (nonatomic, strong, nullable) NSString *rights;
@property (nonatomic, strong, nullable) NSString *thumbnailPath;

- (instancetype)initWithFilePath:(NSString *)filePath 
                   fileSizeBytes:(long long)fileSizeBytes 
                   contentLength:(NSUInteger)contentLength 
                    documentType:(NSString *)documentType;
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

@interface LBVROutlineItem : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, strong, nullable) NSNumber *page; // 1-indexed, nil if no destination
@property (nonatomic, strong, nullable) NSString *sourceRef;
@property (nonatomic, strong) NSArray<LBVROutlineItem *> *children;
- (instancetype)initWithTitle:(NSString *)title level:(NSUInteger)level;
- (void)addChild:(LBVROutlineItem *)child;
@end

@interface LBVRDocumentOutline : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *documentTitle;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSArray<LBVROutlineItem *> *entries;
@property (nonatomic, assign) BOOL hasOutline;
@property (nonatomic, strong) LBVRExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages 
                     extractionInfo:(LBVRExtractionInfo *)extractionInfo;
- (void)addEntry:(LBVROutlineItem *)entry;
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
@property (nonatomic, strong) NSArray<LBVRDocumentParagraph *> *paragraphs;
@property (nonatomic, strong, nullable) NSString *sourceRef;
- (instancetype)initWithPageNumber:(NSUInteger)pageNumber;
- (void)addParagraph:(LBVRDocumentParagraph *)paragraph;
@end

@interface LBVRDocumentPages : NSObject
@property (nonatomic, strong) NSString *sourceFile;
@property (nonatomic, strong, nullable) NSString *documentTitle;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) NSUInteger totalPages;
@property (nonatomic, strong) NSArray<LBVRDocumentPage *> *pages;
@property (nonatomic, strong) LBVRExtractionInfo *extractionInfo;
- (instancetype)initWithSourceFile:(NSString *)sourceFile 
                      documentType:(NSString *)documentType 
                        totalPages:(NSUInteger)totalPages 
                     extractionInfo:(LBVRExtractionInfo *)extractionInfo;
- (void)addPage:(LBVRDocumentPage *)page;
@end

// MARK: - Plugin Output

@interface LBVRPluginOutput : NSObject
@property (nonatomic, strong, nullable) LBVRDocumentMetadata *metadata;
@property (nonatomic, strong, nullable) LBVRDocumentOutline *outline;
@property (nonatomic, strong, nullable) LBVRDocumentPages *pages;
@property (nonatomic, strong, nullable) NSData *thumbnailData;
@property (nonatomic, strong, nullable) NSString *error;
@property (nonatomic, assign) BOOL success;

+ (instancetype)successWithMetadata:(nullable LBVRDocumentMetadata *)metadata
                            outline:(nullable LBVRDocumentOutline *)outline
                              pages:(nullable LBVRDocumentPages *)pages
                      thumbnailData:(nullable NSData *)thumbnailData;

+ (instancetype)failureWithError:(NSString *)error;
@end

// MARK: - File Info (for quick file information)

@interface LBVRQuickMetadata : NSObject
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *author;
@property (nonatomic, strong, nullable) NSNumber *pageCount;
@end

@interface LBVRFileInfo : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) long long size;
@property (nonatomic, strong) NSString *documentType;
@property (nonatomic, assign) BOOL isValid;
@property (nonatomic, strong, nullable) LBVRQuickMetadata *quickMetadata;
- (instancetype)initWithPath:(NSString *)path 
                        size:(long long)size 
                documentType:(NSString *)documentType 
                     isValid:(BOOL)isValid;
@end

// MARK: - Plugin Protocols

// Base protocol for all plugins
@protocol LBVRPlugin <NSObject>
@required
- (NSString *)name;
- (NSString *)version;
- (LBVRPluginPriority)priority;
- (LBVRPluginCapabilities *)getCapabilities;

@optional
- (LBVRPluginInfo *)getPluginInfo;
@end

// MARK: - Document Handler Protocol (conforms to handler-interface.json schema)

@protocol LBVRDocumentHandler <LBVRPlugin>

@required
// Core functionality
- (void)extractMetadata:(NSString *)filePath completion:(void (^)(LBVRDocumentMetadata * _Nullable metadata, NSError * _Nullable error))completion;
- (void)extractOutline:(NSString *)filePath completion:(void (^)(LBVRDocumentOutline * _Nullable outline, NSError * _Nullable error))completion;
- (void)extractPages:(NSString *)filePath completion:(void (^)(LBVRDocumentPages * _Nullable pages, NSError * _Nullable error))completion;
- (void)validateFile:(NSString *)filePath completion:(void (^)(BOOL isValid, NSError * _Nullable error))completion;
- (void)getFileInfo:(NSString *)filePath completion:(void (^)(LBVRFileInfo * _Nullable fileInfo, NSError * _Nullable error))completion;
- (void)generateThumbnail:(NSString *)filePath width:(NSUInteger)width height:(NSUInteger)height completion:(void (^)(NSData * _Nullable thumbnailData, NSError * _Nullable error))completion;

@optional
// Optional methods with defaults
- (BOOL)canHandle:(NSString *)filePath; // Default: checks capabilities against file type

@end

// MARK: - Model Service Protocol

@protocol LBVRModelService <LBVRPlugin>

@required
// Model management
- (void)listAvailableModels:(void (^)(NSArray<NSString *> * _Nullable models, NSError * _Nullable error))completion;
- (void)downloadModel:(NSString *)modelName completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)loadModel:(NSString *)modelName completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)unloadModel:(NSString *)modelName completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)getModelStatus:(NSString *)modelName completion:(void (^)(NSString * _Nullable status, NSError * _Nullable error))completion;

@optional
// Model operations
- (void)deleteModel:(NSString *)modelName completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)getModelInfo:(NSString *)modelName completion:(void (^)(NSDictionary * _Nullable info, NSError * _Nullable error))completion;

@end

// MARK: - Embedding Service Protocol

@protocol LBVREmbeddingService <LBVRPlugin>

@required
// Embedding generation
- (void)generateEmbeddings:(NSArray<NSString *> *)texts completion:(void (^)(NSArray<NSArray<NSNumber *> *> * _Nullable embeddings, NSError * _Nullable error))completion;
- (void)getEmbeddingDimensions:(void (^)(NSInteger dimensions, NSError * _Nullable error))completion;

@optional
// Advanced embedding operations
- (void)generateContextualEmbeddings:(NSString *)text context:(NSString *)context completion:(void (^)(NSArray<NSNumber *> * _Nullable embedding, NSError * _Nullable error))completion;
- (void)computeSimilarity:(NSArray<NSNumber *> *)embedding1 embedding2:(NSArray<NSNumber *> *)embedding2 completion:(void (^)(double similarity, NSError * _Nullable error))completion;

@end

// MARK: - System Service Protocol

@protocol LBVRSystemService <LBVRPlugin>

@required
// Service lifecycle
- (void)startService:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)stopService:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)getServiceStatus:(void (^)(NSString * _Nullable status, NSError * _Nullable error))completion;

@optional
// Service management
- (void)restartService:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)getServiceHealth:(void (^)(NSDictionary * _Nullable health, NSError * _Nullable error))completion;

@end

// MARK: - Plugin Manager

@interface LBVRPluginManager : NSObject

+ (instancetype)sharedManager;
- (void)registerHandler:(id<LBVRDocumentHandler>)handler;
- (id<LBVRDocumentHandler> _Nullable)handlerForFilePath:(NSString *)filePath;
- (id<LBVRDocumentHandler> _Nullable)bestHandlerForOperation:(NSString *)operation fileType:(NSString *)fileType;
- (LBVRPluginOutput *)processDocument:(NSString *)filePath;

@end

// MARK: - JSON Serialization Helpers

@interface LBVRJSONSerializer : NSObject

+ (NSString * _Nullable)serializeMetadata:(LBVRDocumentMetadata *)metadata;
+ (NSString * _Nullable)serializeOutline:(LBVRDocumentOutline *)outline;
+ (NSString * _Nullable)serializePages:(LBVRDocumentPages *)pages;
+ (NSString * _Nullable)serializePluginOutput:(LBVRPluginOutput *)output;
+ (NSString * _Nullable)serializePluginInfo:(LBVRPluginInfo *)pluginInfo;

@end

NS_ASSUME_NONNULL_END