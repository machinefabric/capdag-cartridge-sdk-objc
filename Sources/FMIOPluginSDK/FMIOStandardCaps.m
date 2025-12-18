//
//  FMIOStandardCaps.m
//  Standard cap definitions implementation
//

#import "include/FMIOStandardCaps.h"

@implementation FMIOStandardCaps

+ (CSCap *)extractMetadataCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:action=extract;target=metadata" error:&error];
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
        argType:CSArgumentTypeString
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
        argType:CSArgumentTypeString
        argDescription:@"Write output to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];
    
    CSCapOutput *output = [CSCapOutput 
        outputWithType:CSOutputTypeObject
        schemaRef:@"file-metadata.json"
        contentType:@"application/json"
        validation:nil
        outputDescription:@"Structured metadata including file properties, document properties, and format-specific metadata"];
    
    return [CSCap 
        capWithUrn:capUrn
        title:@"Extract Document Metadata"
        category:@"Document Processing"
        command:command
        description:@"Extract document metadata including title, author, creation date, file size, and other properties"
        metadata:@{}
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (CSCap *)generateThumbnailCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:action=generate;output=binary;target=thumbnail" error:&error];
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
        argType:CSArgumentTypeString
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
        argType:CSArgumentTypeInteger
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
        argType:CSArgumentTypeInteger
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
        argType:CSArgumentTypeString
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
        argType:CSArgumentTypeInteger
        argDescription:@"Page number to generate thumbnail from (1-based, default: 1)"
        cliFlag:@"--page"
        position:nil
        validation:pageValidation
        defaultValue:@1];
    [arguments addOptionalArgument:pageArg];
    
    CSCapOutput *output = [CSCapOutput 
        outputWithType:CSOutputTypeBinary
        schemaRef:nil
        contentType:@"image/png"
        validation:nil
        outputDescription:@"PNG image data representing a thumbnail of the document"];
    
    return [CSCap 
        capWithUrn:capUrn
        title:@"Generate Thumbnail"
        category:@"Document Processing"
        command:command
        description:@"Generate a thumbnail image preview of the document"
        metadata:@{}
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (CSCap *)extractOutlineCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:action=extract;target=outline" error:&error];
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
        argType:CSArgumentTypeString
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
        argType:CSArgumentTypeInteger
        argDescription:@"Maximum outline depth to extract (1-10)"
        cliFlag:@"--max-depth"
        position:nil
        validation:maxDepthValidation
        defaultValue:nil];
    [arguments addOptionalArgument:maxDepthArg];
    
    // Optional include_order_indexes argument
    CSCapArgument *includeOrderIndexesArg = [CSCapArgument 
        argumentWithName:@"include_order_indexes"
        argType:CSArgumentTypeBoolean
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
        argType:CSArgumentTypeString
        argDescription:@"Write output to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];
    
    CSCapOutput *output = [CSCapOutput 
        outputWithType:CSOutputTypeObject
        schemaRef:@"document-outline.json"
        contentType:@"application/json"
        validation:nil
        outputDescription:@"Hierarchical document outline with section titles and optional page numbers"];
    
    return [CSCap 
        capWithUrn:capUrn
        title:@"Extract Document Outline"
        category:@"Document Processing"
        command:command
        description:@"Extract document outline/table of contents with hierarchical structure"
        metadata:@{}
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (CSCap *)extractPagesCap {
    NSError *error;
    CSCapUrn *capUrn = [CSCapUrn fromString:@"cap:action=extract;target=pages" error:&error];
    if (!capUrn) {
        @throw [NSException exceptionWithName:@"InvalidCapUrn" 
                                       reason:@"Failed to create cap URN for extract-pages"
                                     userInfo:nil];
    }
    
    NSString *command = @"extract-pages";
    
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
        argType:CSArgumentTypeString
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
        argType:CSArgumentTypeString
        argDescription:@"Write output to specified file instead of stdout"
        cliFlag:@"--output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];
    
    // Optional page_range argument
    CSArgumentValidation *pageRangeValidation = [CSArgumentValidation 
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"^\\d+(-\\d*)?$"
        allowedValues:nil];
    
    CSCapArgument *pageRangeArg = [CSCapArgument 
        argumentWithName:@"page_range"
        argType:CSArgumentTypeString
        argDescription:@"Page range to extract (e.g., '1-5' or '10-')"
        cliFlag:@"--page-range"
        position:nil
        validation:pageRangeValidation
        defaultValue:nil];
    [arguments addOptionalArgument:pageRangeArg];
    
    CSCapOutput *output = [CSCapOutput 
        outputWithType:CSOutputTypeObject
        schemaRef:@"document-pages.json"
        contentType:@"application/json"
        validation:nil
        outputDescription:@"Document pages with text content organized by pages and paragraphs"];
    
    return [CSCap 
        capWithUrn:capUrn
        title:@"Extract Document Pages"
        category:@"Document Processing"
        command:command
        description:@"Extract document pages with text content organized by pages and paragraphs"
        metadata:@{}
        arguments:arguments
        output:output
        acceptsStdin:YES
        metadataJSON:nil];
}

+ (NSArray<CSCap *> *)allStandardCaps {
    return @[
        [self extractMetadataCap],
        [self generateThumbnailCap],
        [self extractOutlineCap],
        [self extractPagesCap]
    ];
}

+ (nullable CSCap *)standardCapWithName:(NSString *)name {
    if ([name isEqualToString:@"extract-metadata"]) {
        return [self extractMetadataCap];
    } else if ([name isEqualToString:@"generate-thumbnail"]) {
        return [self generateThumbnailCap];
    } else if ([name isEqualToString:@"extract-outline"]) {
        return [self extractOutlineCap];
    } else if ([name isEqualToString:@"extract-pages"]) {
        return [self extractPagesCap];
    }
    return nil;
}

+ (nullable CSCap *)standardCapWithUrn:(NSString *)urnString {
    if ([urnString isEqualToString:@"cap:action=extract;target=metadata"]) {
        return [self extractMetadataCap];
    } else if ([urnString isEqualToString:@"cap:action=generate;output=binary;target=thumbnail"]) {
        return [self generateThumbnailCap];
    } else if ([urnString isEqualToString:@"cap:action=extract;target=outline"]) {
        return [self extractOutlineCap];
    } else if ([urnString isEqualToString:@"cap:action=extract;target=pages"]) {
        return [self extractPagesCap];
    }
    return nil;
}

+ (CSCap *)extractMetadataCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self extractMetadataCap];
    
    NSMutableArray<CSCap *> *caps = [NSMutableArray array];
    
    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *newUrnString = [NSString stringWithFormat:@"cap:action=extract;ext=%@;target=metadata", fileType];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn" 
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }
        
        CSCap *cap = [CSCap 
            capWithUrn:newId
            title:baseCap.title
            category:baseCap.category
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
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
        NSString *newUrnString = [NSString stringWithFormat:@"cap:action=generate;ext=%@;output=binary;target=thumbnail", fileType];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn" 
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }
        
        CSCap *cap = [CSCap 
            capWithUrn:newId
            title:baseCap.title
            category:baseCap.category
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
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
        NSString *newUrnString = [NSString stringWithFormat:@"cap:action=extract;ext=%@;target=outline", fileType];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn" 
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }
        
        CSCap *cap = [CSCap 
            capWithUrn:newId
            title:baseCap.title
            category:baseCap.category
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
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

+ (CSCap *)extractPagesCapSubbedWith:(NSArray<NSString *> *)fileTypes {
    CSCap *baseCap = [self extractPagesCap];
    
    NSMutableArray<CSCap *> *caps = [NSMutableArray array];
    
    for (NSString *fileType in fileTypes) {
        NSError *error;
        NSString *newUrnString = [NSString stringWithFormat:@"cap:action=extract;ext=%@;target=pages", fileType];
        CSCapUrn *newId = [CSCapUrn fromString:newUrnString error:&error];
        if (!newId) {
            @throw [NSException exceptionWithName:@"InvalidCapUrn" 
                                           reason:[NSString stringWithFormat:@"Failed to create cap URN for %@", newUrnString]
                                         userInfo:nil];
        }
        
        CSCap *cap = [CSCap 
            capWithUrn:newId
            title:baseCap.title
            category:baseCap.category
            command:baseCap.command
            description:baseCap.capDescription
            metadata:baseCap.metadata
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
                                       reason:@"extractPagesCapSubbedWith should only be called with a single file type"
                                     userInfo:nil];
    }
}

+ (NSArray<CSCap *> *)allStandardCapsSubbedWith:(NSArray<NSString *> *)fileTypes {
    NSMutableArray<CSCap *> *allCaps = [NSMutableArray array];
    
    for (NSString *fileType in fileTypes) {
        [allCaps addObject:[self extractMetadataCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self generateThumbnailCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self extractOutlineCapSubbedWith:@[fileType]]];
        [allCaps addObject:[self extractPagesCapSubbedWith:@[fileType]]];
    }
    
    return allCaps;
}

@end