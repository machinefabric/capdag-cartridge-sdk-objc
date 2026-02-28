//
//  MACINAStandardCaps.m
//  Standard cap definitions implementation
//
//  Updated to use spec ID-based mediaSpec system per capns modernization.
//  All types are expressed via spec IDs (e.g., "media:string") which resolve
//  via the mediaSpecs table.
//

#import "include/MACINAStandardCaps.h"

// Well-known spec IDs (built-in primitives)
static NSString * const kSpecIdStr = @"media:string";
static NSString * const kSpecIdInt = @"media:integer";
static NSString * const kSpecIdNum = @"media:number";
static NSString * const kSpecIdBool = @"media:boolean";
static NSString * const kSpecIdObj = @"media:object";
static NSString * const kSpecIdBinary = @"media:binary";

// Custom spec IDs for document processing outputs (used in mediaSpecs tables)
static NSString * const kSpecIdFileMetadata = @"media:file-metadata";
static NSString * const kSpecIdThumbnailImage = @"media:thumbnail-image";
static NSString * const kSpecIdDocumentOutline = @"media:document-outline";
static NSString * const kSpecIdDisboundPage = @"media:disbound-page";

@implementation MACINAStandardCaps

#pragma mark - Spec ID Helper Functions

/// Get the input spec ID for a given file extension
/// - PDF files: media:
/// - Text files (md, rst, log, txt): media:string
+ (NSString *)inputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdBinary;
    }
    return kSpecIdStr;
}

/// Get the output spec ID for extract-metadata by extension
/// - PDF files: media:extract-metadata-output (has full schema)
/// - Text files: media:object (generic JSON object)
+ (NSString *)extractMetadataOutputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdFileMetadata;
    }
    return kSpecIdObj;
}

/// Get the output spec ID for extract-outline by extension
/// - PDF files: media:extract-outline-output (has full schema)
/// - Text files: media:object (generic JSON object)
+ (NSString *)extractOutlineOutputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdDocumentOutline;
    }
    return kSpecIdObj;
}

/// Get the output spec ID for disbind by extension
/// - PDF files: media:disbound-page (has full schema, output is array)
/// - Text files: media:object (generic JSON object)
+ (NSString *)disboundPageSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdDisboundPage;
    }
    return kSpecIdObj;
}

#pragma mark - Media Specs Arrays

/// Build media specs array for extract-metadata cap
+ (NSArray<NSDictionary *> *)extractMetadataMediaSpecs {
    return @[
        @{
            @"urn": kSpecIdFileMetadata,
            @"media_type": @"application/json",
            @"profile_uri": @"https://capns.org/schema/file-metadata"
        }
    ];
}

/// Build media specs array for generate-thumbnail cap
+ (NSArray<NSDictionary *> *)generateThumbnailMediaSpecs {
    return @[
        @{
            @"urn": kSpecIdThumbnailImage,
            @"media_type": @"image/png",
            @"profile_uri": @"https://capns.org/schema/thumbnail-image"
        }
    ];
}

/// Build media specs array for extract-outline cap
+ (NSArray<NSDictionary *> *)extractOutlineMediaSpecs {
    return @[
        @{
            @"urn": kSpecIdDocumentOutline,
            @"media_type": @"application/json",
            @"profile_uri": @"https://capns.org/schema/document-outline"
        }
    ];
}

/// Build media specs array for disbind cap
+ (NSArray<NSDictionary *> *)grindMediaSpecs {
    return @[
        @{
            @"urn": kSpecIdDisboundPage,
            @"media_type": @"application/json",
            @"profile_uri": @"https://capns.org/schema/disbound-page"
        }
    ];
}

#pragma mark - Standard Caps

+ (CSCap *)extractMetadataCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:in=\"media:textable\";op=extract;out=\"media:record;textable\";target=metadata" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for extract-metadata"
                                     userInfo:nil];
    }

    NSString *command = @"extract-metadata";

    NSMutableArray<CSCapArg *> *args = [NSMutableArray array];

    // Required file_path argument
    CSArgSource *stdinSource = [CSArgSource stdinSourceWithMediaUrn:kSpecIdStr];
    CSArgSource *pos0 = [CSArgSource positionSource:0];
    CSCapArg *filePathArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                            required:YES
                                             sources:@[stdinSource, pos0]
                                      argDescription:@"Path to the document file to process"
                                        defaultValue:nil];
    [args addObject:filePathArg];

    // Optional output argument
    CSArgSource *flagOut = [CSArgSource cliFlagSource:@"--output"];
    CSCapArg *outputArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                           required:NO
                                            sources:@[flagOut]
                                     argDescription:@"Write output to specified file instead of stdout"
                                       defaultValue:nil];
    [args addObject:outputArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaUrn:kSpecIdFileMetadata
        outputDescription:@"Structured metadata including file properties, document properties, and format-specific metadata"];

    return [CSCap
        capWithUrn:capUrn
        title:@"Extract Document Metadata"
        command:command
        description:@"Extract document metadata including title, author, creation date, file size, and other properties"
        metadata:@{}
        mediaSpecs:[self extractMetadataMediaSpecs]
                args:args
              output:output
        metadataJSON:nil];
}

+ (CSCap *)generateThumbnailCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:in=media:void;op=generate;out=media:;target=thumbnail" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for generate-thumbnail"
                                     userInfo:nil];
    }

    NSString *command = @"generate-thumbnail";
    NSArray<CSCapArg *> *args = @[];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaUrn:kSpecIdThumbnailImage
        outputDescription:@"PNG image data representing a thumbnail of the document"];

    return [CSCap
        capWithUrn:capUrn
        title:@"Generate Thumbnail"
        command:command
        description:@"Generate a thumbnail image preview of the document"
        metadata:@{}
        mediaSpecs:[self generateThumbnailMediaSpecs]
                args:args
              output:output
        metadataJSON:nil];
}

+ (CSCap *)extractOutlineCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:in=\"media:textable\";op=extract;out=\"media:record;textable\";target=outline" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for extract-outline"
                                     userInfo:nil];
    }

    NSString *command = @"extract-outline";

    NSMutableArray<CSCapArg *> *args = [NSMutableArray array];

    // Required file path argument via stdin or position 0
    CSArgSource *stdinSource = [CSArgSource stdinSourceWithMediaUrn:kSpecIdStr];
    CSArgSource *pos0 = [CSArgSource positionSource:0];
    CSCapArg *filePathArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                             required:YES
                                              sources:@[stdinSource, pos0]
                                       argDescription:@"Path to the document file to process"
                                         defaultValue:nil];
    [args addObject:filePathArg];

    // Optional max_depth argument via cli_flag
    CSArgSource *flagMaxDepth = [CSArgSource cliFlagSource:@"--max-depth"];
    CSCapArg *maxDepthArg = [CSCapArg argWithMediaUrn:kSpecIdInt
                                            required:NO
                                             sources:@[flagMaxDepth]
                                      argDescription:@"Maximum outline depth to extract (1-10)"
                                        defaultValue:nil];
    [args addObject:maxDepthArg];

    // Optional include_order_indexes argument via cli_flag, default YES
    CSArgSource *flagInclude = [CSArgSource cliFlagSource:@"--include-order-indexes"];
    CSCapArg *includeOrderIndexesArg = [CSCapArg argWithMediaUrn:kSpecIdBool
                                                       required:NO
                                                        sources:@[flagInclude]
                                                 argDescription:@"Include page numbers in the outline (default: true)"
                                                   defaultValue:@YES];
    [args addObject:includeOrderIndexesArg];

    // Optional output path argument via cli_flag
    CSArgSource *flagOut = [CSArgSource cliFlagSource:@"--output"];
    CSCapArg *outputArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                           required:NO
                                            sources:@[flagOut]
                                     argDescription:@"Write output to specified file instead of stdout"
                                       defaultValue:nil];
    [args addObject:outputArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaUrn:kSpecIdDocumentOutline
        outputDescription:@"Hierarchical document outline with section titles and optional page numbers"];

    return [CSCap capWithUrn:capUrn
                        title:@"Extract Document Outline"
                      command:command
                  description:@"Extract document outline/table of contents with hierarchical structure"
                     metadata:@{}
                   mediaSpecs:[self extractOutlineMediaSpecs]
                         args:args
                       output:output
                 metadataJSON:nil];
}

+ (CSCap *)disbindCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:in=\"media:textable\";op=extract;out=\"media:list;textable\";target=pages" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for grind"
                                     userInfo:nil];
    }

    NSString *command = @"grind";
    NSMutableArray<CSCapArg *> *args = [NSMutableArray array];

    // Required file_path argument
    CSArgSource *stdinSource2 = [CSArgSource stdinSourceWithMediaUrn:kSpecIdStr];
    CSArgSource *pos02 = [CSArgSource positionSource:0];
    CSCapArg *filePathArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                             required:YES
                                              sources:@[stdinSource2, pos02]
                                       argDescription:@"Path to the document file to process"
                                         defaultValue:nil];
    [args addObject:filePathArg];

    // Optional output argument
    CSArgSource *flagOut2 = [CSArgSource cliFlagSource:@"--output"];
    CSCapArg *outputArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                           required:NO
                                            sources:@[flagOut2]
                                     argDescription:@"Write output to specified file instead of stdout"
                                       defaultValue:nil];
    [args addObject:outputArg];

    // Optional index_range argument
    CSArgSource *flagIndexRange = [CSArgSource cliFlagSource:@"--index-range"];
    CSCapArg *indexRangeArg = [CSCapArg argWithMediaUrn:kSpecIdStr
                                              required:NO
                                               sources:@[flagIndexRange]
                                        argDescription:@"Index Range to extract (e.g., '1-5' or '10-')"
                                          defaultValue:nil];
    [args addObject:indexRangeArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaUrn:kSpecIdDisboundPage
        outputDescription:@"Array of disbound pages with text content"];

    return [CSCap capWithUrn:capUrn
                        title:@"Extract File Chips"
                      command:command
                  description:@"Extract file chips with text content organized by pages and paragraphs"
                     metadata:@{}
                   mediaSpecs:[self grindMediaSpecs]
                         args:args
                       output:output
                 metadataJSON:nil];
}

#pragma mark - Collection Methods

+ (NSArray<CSCap *> *)allStandardCaps {
    return @[
        [self extractMetadataCap],
        [self generateThumbnailCap],
        [self extractOutlineCap],
        [self disbindCap]
    ];
}

+ (nullable CSCap *)standardCapWithName:(NSString *)name {
    if ([name isEqualToString:@"extract-metadata"]) {
        return [self extractMetadataCap];
    } else if ([name isEqualToString:@"generate-thumbnail"]) {
        return [self generateThumbnailCap];
    } else if ([name isEqualToString:@"extract-outline"]) {
        return [self extractOutlineCap];
    } else if ([name isEqualToString:@"grind"]) {
        return [self disbindCap];
    }
    return nil;
}

+ (nullable CSCap *)standardCapWithUrn:(NSString *)urnString {
    if ([urnString isEqualToString:@"cap:op=extract;target=metadata"]) {
        return [self extractMetadataCap];
    } else if ([urnString isEqualToString:@"cap:op=generate;output=binary;target=thumbnail"]) {
        return [self generateThumbnailCap];
    } else if ([urnString isEqualToString:@"cap:op=extract;target=outline"]) {
        return [self extractOutlineCap];
    } else if ([urnString isEqualToString:@"cap:op=extract;target=pages"]) {
        return [self disbindCap];
    }
    return nil;
}

#pragma mark - File Type Substitution

+ (CSCap *)extractMetadataCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self extractMetadataCap];

    NSMutableArray<CSCap *> *caps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *inSpecId = [self inputSpecIdForExt:fileType];
        NSString *outSpecId = [self extractMetadataOutputSpecIdForExt:fileType];
        NSString *newUrnString = [NSString stringWithFormat:@"cap:ext=%@;in=%@;op=extract_metadata;out=%@",
                                  fileType, inSpecId, outSpecId];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }

        CSCap *cap = [CSCap capWithUrn:newId
                                  title:baseCap.title
                                command:baseCap.command
                            description:baseCap.capDescription
                               metadata:baseCap.metadata
                             mediaSpecs:baseCap.mediaSpecs
                                   args:baseCap.args
                                 output:baseCap.output
                           metadataJSON:baseCap.metadataJSON];
        [caps addObject:cap];
    }

    // Return first cap for single file type, or throw if multiple
    if (caps.count == 1) {
        return caps[0];
    } else {
        @throw [NSException exceptionWithName:@"MultipleFileTypes"
                                       reason:@"extractMetadataCapSubbedWith should only be called with a single file type"
                                     userInfo:nil];
    }
}

+ (CSCap *)generateThumbnailCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self generateThumbnailCap];

    NSMutableArray<CSCap *> *caps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *inSpecId = [self inputSpecIdForExt:fileType];
        // Thumbnail output is always binary (media:binary)
        NSString *newUrnString = [NSString stringWithFormat:@"cap:ext=%@;in=%@;op=generate_thumbnail;out=media:binary",
                                  fileType, inSpecId];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }

        CSCap *cap = [CSCap capWithUrn:newId
                                  title:baseCap.title
                                command:baseCap.command
                            description:baseCap.capDescription
                               metadata:baseCap.metadata
                             mediaSpecs:baseCap.mediaSpecs
                                   args:baseCap.args
                                 output:baseCap.output
                           metadataJSON:baseCap.metadataJSON];
        [caps addObject:cap];
    }

    // Return first cap for single file type, or throw if multiple
    if (caps.count == 1) {
        return caps[0];
    } else {
        @throw [NSException exceptionWithName:@"MultipleFileTypes"
                                       reason:@"generateThumbnailCapSubbedWith should only be called with a single file type"
                                     userInfo:nil];
    }
}

+ (CSCap *)extractOutlineCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self extractOutlineCap];

    NSMutableArray<CSCap *> *caps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *inSpecId = [self inputSpecIdForExt:fileType];
        NSString *outSpecId = [self extractOutlineOutputSpecIdForExt:fileType];
        NSString *newUrnString = [NSString stringWithFormat:@"cap:ext=%@;in=%@;op=extract_outline;out=%@",
                                  fileType, inSpecId, outSpecId];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }

        CSCap *cap = [CSCap capWithUrn:newId
                                  title:baseCap.title
                                command:baseCap.command
                            description:baseCap.capDescription
                               metadata:baseCap.metadata
                             mediaSpecs:baseCap.mediaSpecs
                                   args:baseCap.args
                                 output:baseCap.output
                           metadataJSON:baseCap.metadataJSON];
        [caps addObject:cap];
    }

    // Return first cap for single file type, or throw if multiple
    if (caps.count == 1) {
        return caps[0];
    } else {
        @throw [NSException exceptionWithName:@"MultipleFileTypes"
                                       reason:@"extractOutlineCapSubbedWith should only be called with a single file type"
                                     userInfo:nil];
    }
}

+ (CSCap *)disbindCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self disbindCap];

    NSMutableArray<CSCap *> *caps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *inSpecId = [self inputSpecIdForExt:fileType];
        NSString *outSpecId = [self disboundPageSpecIdForExt:fileType];
        NSString *newUrnString = [NSString stringWithFormat:@"cap:ext=%@;in=%@;op=grind;out=%@",
                                  fileType, inSpecId, outSpecId];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }

        CSCap *cap = [CSCap capWithUrn:newId
                                  title:baseCap.title
                                command:baseCap.command
                            description:baseCap.capDescription
                               metadata:baseCap.metadata
                             mediaSpecs:baseCap.mediaSpecs
                                   args:baseCap.args
                                 output:baseCap.output
                           metadataJSON:baseCap.metadataJSON];
        [caps addObject:cap];
    }

    // Return first cap for single file type, or throw if multiple
    if (caps.count == 1) {
        return caps[0];
    } else {
        @throw [NSException exceptionWithName:@"MultipleFileTypes"
                                       reason:@"disbindCapSubbedWith should only be called with a single file type"
                                     userInfo:nil];
    }
}

+ (NSArray<CSCap *> *)allStandardCapsSubbedWith:(NSArray<NSString *> *)fileTypes {
    NSMutableArray<CSCap *> *allCaps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        [allCaps addObject:[self extractMetadataCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self generateThumbnailCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self extractOutlineCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self disbindCapSubbedWith:@[fileType]]];
    }

    return allCaps;
}

@end
