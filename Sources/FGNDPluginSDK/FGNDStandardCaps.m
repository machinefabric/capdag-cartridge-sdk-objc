//
//  FGNDStandardCaps.m
//  Standard cap definitions implementation
//
//  Updated to use spec ID-based mediaSpec system per capns modernization.
//  All types are expressed via spec IDs (e.g., "std:str.v1") which resolve
//  via the mediaSpecs table.
//

#import "include/FGNDStandardCaps.h"

// Well-known spec IDs (built-in primitives)
static NSString * const kSpecIdStr = @"std:str.v1";
static NSString * const kSpecIdInt = @"std:int.v1";
static NSString * const kSpecIdNum = @"std:num.v1";
static NSString * const kSpecIdBool = @"std:bool.v1";
static NSString * const kSpecIdObj = @"std:obj.v1";
static NSString * const kSpecIdBinary = @"std:binary.v1";

// Output spec IDs for PDF document processing (with full schemas)
static NSString * const kSpecIdExtractMetadataOutput = @"capns:extract-metadata-output.v1";
static NSString * const kSpecIdExtractOutlineOutput = @"capns:extract-outline-output.v1";
static NSString * const kSpecIdGrindOutput = @"capns:grind-output.v1";

// Custom spec IDs for document processing outputs (used in mediaSpecs tables)
static NSString * const kSpecIdFileMetadata = @"fgnd:file-metadata.v1";
static NSString * const kSpecIdThumbnailImage = @"fgnd:thumbnail-image.v1";
static NSString * const kSpecIdDocumentOutline = @"fgnd:document-outline.v1";
static NSString * const kSpecIdGroundChips = @"fgnd:file-chips.v1";

@implementation FGNDStandardCaps

#pragma mark - Spec ID Helper Functions

/// Get the input spec ID for a given file extension
/// - PDF files: std:binary.v1
/// - Text files (md, rst, log, txt): std:str.v1
+ (NSString *)inputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdBinary;
    }
    return kSpecIdStr;
}

/// Get the output spec ID for extract-metadata by extension
/// - PDF files: capns:extract-metadata-output.v1 (has full schema)
/// - Text files: std:obj.v1 (generic JSON object)
+ (NSString *)extractMetadataOutputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdExtractMetadataOutput;
    }
    return kSpecIdObj;
}

/// Get the output spec ID for extract-outline by extension
/// - PDF files: capns:extract-outline-output.v1 (has full schema)
/// - Text files: std:obj.v1 (generic JSON object)
+ (NSString *)extractOutlineOutputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdExtractOutlineOutput;
    }
    return kSpecIdObj;
}

/// Get the output spec ID for grind by extension
/// - PDF files: capns:grind-output.v1 (has full schema)
/// - Text files: std:obj.v1 (generic JSON object)
+ (NSString *)grindOutputSpecIdForExt:(NSString *)ext {
    if ([ext isEqualToString:@"pdf"]) {
        return kSpecIdGrindOutput;
    }
    return kSpecIdObj;
}

#pragma mark - Media Specs Tables

/// Build media specs table for extract-metadata cap
+ (NSDictionary<NSString *, id> *)extractMetadataMediaSpecs {
    return @{
        kSpecIdFileMetadata: @{
            @"media_type": @"application/json",
            @"profile_uri": @"https://capns.org/schema/file-metadata"
        }
    };
}

/// Build media specs table for generate-thumbnail cap
+ (NSDictionary<NSString *, id> *)generateThumbnailMediaSpecs {
    return @{
        kSpecIdThumbnailImage: @"image/png; profile=https://capns.org/schema/thumbnail-image"
    };
}

/// Build media specs table for extract-outline cap
+ (NSDictionary<NSString *, id> *)extractOutlineMediaSpecs {
    return @{
        kSpecIdDocumentOutline: @{
            @"media_type": @"application/json",
            @"profile_uri": @"https://capns.org/schema/document-outline"
        }
    };
}

/// Build media specs table for grind cap
+ (NSDictionary<NSString *, id> *)grindMediaSpecs {
    return @{
        kSpecIdGroundChips: @{
            @"media_type": @"application/json",
            @"profile_uri": @"https://capns.org/schema/file-chips"
        }
    };
}

#pragma mark - Standard Caps

+ (CSCap *)extractMetadataCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:op=extract;target=metadata" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for extract-metadata"
                                     userInfo:nil];
    }

    NSString *command = @"extract-metadata";

    CSCapArguments *arguments = [CSCapArguments arguments];

    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *filePathArg = [CSCapArgument
        argumentWithName:@"file_path"
        mediaSpec:kSpecIdStr
        argDescription:@"Path to the document file to process"
        cliFlag:@"file_path"
        position:@0
        validation:filePathValidation
        defaultValue:nil];
    [arguments addRequiredArgument:filePathArg];

    // Optional output argument
    CSArgumentValidation *outputValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *outputArg = [CSCapArgument
        argumentWithName:@"output"
        mediaSpec:kSpecIdStr
        argDescription:@"Write output to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaSpec:kSpecIdFileMetadata
        validation:nil
        outputDescription:@"Structured metadata including file properties, document properties, and format-specific metadata"];

    return [CSCap
        capWithUrn:capUrn
        title:@"Extract Document Metadata"
        command:command
        description:@"Extract document metadata including title, author, creation date, file size, and other properties"
        metadata:@{}
        mediaSpecs:[self extractMetadataMediaSpecs]
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (CSCap *)generateThumbnailCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:op=generate;output=binary;target=thumbnail" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for generate-thumbnail"
                                     userInfo:nil];
    }

    NSString *command = @"generate-thumbnail";

    CSCapArguments *arguments = [CSCapArguments arguments];

    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *filePathArg = [CSCapArgument
        argumentWithName:@"file_path"
        mediaSpec:kSpecIdStr
        argDescription:@"Path to the document file to process"
        cliFlag:@"file_path"
        position:@0
        validation:filePathValidation
        defaultValue:nil];
    [arguments addRequiredArgument:filePathArg];

    // Optional width argument
    CSArgumentValidation *widthValidation = [CSArgumentValidation
        validationWithMin:@50.0
        max:@2000.0
        minLength:nil
        maxLength:nil
        pattern:nil
        allowedValues:nil];

    CSCapArgument *widthArg = [CSCapArgument
        argumentWithName:@"width"
        mediaSpec:kSpecIdInt
        argDescription:@"Width of the thumbnail in pixels"
        cliFlag:@"--width"
        position:nil
        validation:widthValidation
        defaultValue:@200];
    [arguments addOptionalArgument:widthArg];

    // Optional height argument
    CSArgumentValidation *heightValidation = [CSArgumentValidation
        validationWithMin:@50.0
        max:@2000.0
        minLength:nil
        maxLength:nil
        pattern:nil
        allowedValues:nil];

    CSCapArgument *heightArg = [CSCapArgument
        argumentWithName:@"height"
        mediaSpec:kSpecIdInt
        argDescription:@"Height of the thumbnail in pixels"
        cliFlag:@"--height"
        position:nil
        validation:heightValidation
        defaultValue:@300];
    [arguments addOptionalArgument:heightArg];

    // Optional output argument
    CSArgumentValidation *outputValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"\\.(png|jpg|jpeg)$"
        allowedValues:nil];

    CSCapArgument *outputArg = [CSCapArgument
        argumentWithName:@"output"
        mediaSpec:kSpecIdStr
        argDescription:@"Write thumbnail to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];

    // Optional page argument
    CSArgumentValidation *pageValidation = [CSArgumentValidation
        validationWithMin:@1.0
        max:nil
        minLength:nil
        maxLength:nil
        pattern:nil
        allowedValues:nil];

    CSCapArgument *pageArg = [CSCapArgument
        argumentWithName:@"page"
        mediaSpec:kSpecIdInt
        argDescription:@"Page number to generate thumbnail from (1-based, default: 1)"
        cliFlag:@"--page"
        position:nil
        validation:pageValidation
        defaultValue:@1];
    [arguments addOptionalArgument:pageArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaSpec:kSpecIdThumbnailImage
        validation:nil
        outputDescription:@"PNG image data representing a thumbnail of the document"];

    return [CSCap
        capWithUrn:capUrn
        title:@"Generate Thumbnail"
        command:command
        description:@"Generate a thumbnail image preview of the document"
        metadata:@{}
        mediaSpecs:[self generateThumbnailMediaSpecs]
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (CSCap *)extractOutlineCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:op=extract;target=outline" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for extract-outline"
                                     userInfo:nil];
    }

    NSString *command = @"extract-outline";

    CSCapArguments *arguments = [CSCapArguments arguments];

    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *filePathArg = [CSCapArgument
        argumentWithName:@"file_path"
        mediaSpec:kSpecIdStr
        argDescription:@"Path to the document file to process"
        cliFlag:@"file_path"
        position:@0
        validation:filePathValidation
        defaultValue:nil];
    [arguments addRequiredArgument:filePathArg];

    // Optional max_depth argument
    CSArgumentValidation *maxDepthValidation = [CSArgumentValidation
        validationWithMin:@1.0
        max:@10.0
        minLength:nil
        maxLength:nil
        pattern:nil
        allowedValues:nil];

    CSCapArgument *maxDepthArg = [CSCapArgument
        argumentWithName:@"max_depth"
        mediaSpec:kSpecIdInt
        argDescription:@"Maximum outline depth to extract (1-10)"
        cliFlag:@"--max-depth"
        position:nil
        validation:maxDepthValidation
        defaultValue:nil];
    [arguments addOptionalArgument:maxDepthArg];

    // Optional include_order_indexes argument
    CSCapArgument *includeOrderIndexesArg = [CSCapArgument
        argumentWithName:@"include_order_indexes"
        mediaSpec:kSpecIdBool
        argDescription:@"Include page numbers in the outline (default: true)"
        cliFlag:@"--include-order-indexes"
        position:nil
        validation:nil
        defaultValue:@YES];
    [arguments addOptionalArgument:includeOrderIndexesArg];

    // Optional output argument
    CSArgumentValidation *outputValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *outputArg = [CSCapArgument
        argumentWithName:@"output"
        mediaSpec:kSpecIdStr
        argDescription:@"Write output to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaSpec:kSpecIdDocumentOutline
        validation:nil
        outputDescription:@"Hierarchical document outline with section titles and optional page numbers"];

    return [CSCap
        capWithUrn:capUrn
        title:@"Extract Document Outline"
        command:command
        description:@"Extract document outline/table of contents with hierarchical structure"
        metadata:@{}
        mediaSpecs:[self extractOutlineMediaSpecs]
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (CSCap *)grindCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:op=extract;target=pages" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                       reason:@"Failed to create cap URN for grind"
                                     userInfo:nil];
    }

    NSString *command = @"grind";

    CSCapArguments *arguments = [CSCapArguments arguments];

    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *filePathArg = [CSCapArgument
        argumentWithName:@"file_path"
        mediaSpec:kSpecIdStr
        argDescription:@"Path to the document file to process"
        cliFlag:@"file_path"
        position:@0
        validation:filePathValidation
        defaultValue:nil];
    [arguments addRequiredArgument:filePathArg];

    // Optional output argument
    CSArgumentValidation *outputValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];

    CSCapArgument *outputArg = [CSCapArgument
        argumentWithName:@"output"
        mediaSpec:kSpecIdStr
        argDescription:@"Write output to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];

    // Optional index_range argument
    CSArgumentValidation *indexRangeValidation = [CSArgumentValidation
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"^\\d+(-\\d*)?$"
        allowedValues:nil];

    CSCapArgument *indexRangeArg = [CSCapArgument
        argumentWithName:@"index_range"
        mediaSpec:kSpecIdStr
        argDescription:@"Index Range to extract (e.g., '1-5' or '10-')"
        cliFlag:@"--index-range"
        position:nil
        validation:indexRangeValidation
        defaultValue:nil];
    [arguments addOptionalArgument:indexRangeArg];

    CSCapOutput *output = [CSCapOutput
        outputWithMediaSpec:kSpecIdGroundChips
        validation:nil
        outputDescription:@"File chips with text content organized by pages and paragraphs"];

    return [CSCap
        capWithUrn:capUrn
        title:@"Extract File Chips"
        command:command
        description:@"Extract file chips with text content organized by pages and paragraphs"
        metadata:@{}
        mediaSpecs:[self grindMediaSpecs]
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

#pragma mark - Collection Methods

+ (NSArray<CSCap *> *)allStandardCaps {
    return @[
        [self extractMetadataCap],
        [self generateThumbnailCap],
        [self extractOutlineCap],
        [self grindCap]
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
        return [self grindCap];
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
        return [self grindCap];
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

        CSCap *cap = [CSCap
            capWithUrn:newId
            title:baseCap.title
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
            mediaSpecs:baseCap.mediaSpecs
            arguments:baseCap.arguments
            output:baseCap.output
            acceptsStdin:baseCap.acceptsStdin
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
        // Thumbnail output is always binary (std:binary.v1)
        NSString *newUrnString = [NSString stringWithFormat:@"cap:ext=%@;in=%@;op=generate_thumbnail;out=std:binary.v1",
                                  fileType, inSpecId];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }

        CSCap *cap = [CSCap
            capWithUrn:newId
            title:baseCap.title
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
            mediaSpecs:baseCap.mediaSpecs
            arguments:baseCap.arguments
            output:baseCap.output
            acceptsStdin:baseCap.acceptsStdin
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

        CSCap *cap = [CSCap
            capWithUrn:newId
            title:baseCap.title
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
            mediaSpecs:baseCap.mediaSpecs
            arguments:baseCap.arguments
            output:baseCap.output
            acceptsStdin:baseCap.acceptsStdin
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

+ (CSCap *)grindCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self grindCap];

    NSMutableArray<CSCap *> *caps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *inSpecId = [self inputSpecIdForExt:fileType];
        NSString *outSpecId = [self grindOutputSpecIdForExt:fileType];
        NSString *newUrnString = [NSString stringWithFormat:@"cap:ext=%@;in=%@;op=grind;out=%@",
                                  fileType, inSpecId, outSpecId];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn"
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }

        CSCap *cap = [CSCap
            capWithUrn:newId
            title:baseCap.title
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
            mediaSpecs:baseCap.mediaSpecs
            arguments:baseCap.arguments
            output:baseCap.output
            acceptsStdin:baseCap.acceptsStdin
            metadataJSON:baseCap.metadataJSON];
        [caps addObject:cap];
    }

    // Return first cap for single file type, or throw if multiple
    if (caps.count == 1) {
        return caps[0];
    } else {
        @throw [NSException exceptionWithName:@"MultipleFileTypes"
                                       reason:@"grindCapSubbedWith should only be called with a single file type"
                                     userInfo:nil];
    }
}

+ (NSArray<CSCap *> *)allStandardCapsSubbedWith:(NSArray<NSString *> *)fileTypes {
    NSMutableArray<CSCap *> *allCaps = [NSMutableArray array];

    for (NSString *fileType in fileTypes) {
        [allCaps addObject:[self extractMetadataCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self generateThumbnailCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self extractOutlineCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self grindCapSubbedWith:@[fileType]]];
    }

    return allCaps;
}

@end
