//
//  LBVRStandardCapabilities.m
//  Standard capability definitions implementation
//

#import "include/LBVRStandardCapabilities.h"

@implementation LBVRStandardCapabilities

+ (CSCapability *)extractMetadataCapability {
    NSError *error;
    CSCapabilityId *capabilityId = [CSCapabilityId fromString:@"document:extract:metadata" error:&error];
    if (!capabilityId) {
        @throw [NSException exceptionWithName:@"InvalidCapabilityID" 
                                       reason:@"Failed to create capability ID for extract-metadata"
                                     userInfo:nil];
    }
    
    NSString *command = @"extract-metadata";
    
    CSCapabilityArguments *arguments = [CSCapabilityArguments arguments];
    
    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation 
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];
    
    CSCapabilityArgument *filePathArg = [CSCapabilityArgument 
        argumentWithName:@"file_path"
        type:CSArgumentTypeString
        description:@"Path to the document file to process"
        cliFlag:nil
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
    
    CSCapabilityArgument *outputArg = [CSCapabilityArgument 
        argumentWithName:@"output"
        type:CSArgumentTypeString
        description:@"Write output to specified file instead of stdout"
        cliFlag:@"output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];
    
    CSCapabilityOutput *output = [CSCapabilityOutput 
        outputWithType:CSOutputTypeObject
        schemaRef:@"file-metadata.json"
        contentType:@"application/json"
        validation:nil
        description:@"Structured metadata including file properties, document properties, and format-specific metadata"];
    
    return [CSCapability 
        capabilityWithId:capabilityId
        version:@"1.0.0"
        description:@"Extract document metadata including title, author, creation date, file size, and other properties"
        metadata:@{}
        command:command
        arguments:arguments
        output:output];
}

+ (CSCapability *)generateThumbnailCapability {
    NSError *error;
    CSCapabilityId *capabilityId = [CSCapabilityId fromString:@"document:generate:thumbnail" error:&error];
    if (!capabilityId) {
        @throw [NSException exceptionWithName:@"InvalidCapabilityID" 
                                       reason:@"Failed to create capability ID for generate-thumbnail"
                                     userInfo:nil];
    }
    
    NSString *command = @"generate-thumbnail";
    
    CSCapabilityArguments *arguments = [CSCapabilityArguments arguments];
    
    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation 
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];
    
    CSCapabilityArgument *filePathArg = [CSCapabilityArgument 
        argumentWithName:@"file_path"
        type:CSArgumentTypeString
        description:@"Path to the document file to process"
        cliFlag:nil
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
    
    CSCapabilityArgument *widthArg = [CSCapabilityArgument 
        argumentWithName:@"width"
        type:CSArgumentTypeInteger
        description:@"Width of the thumbnail in pixels"
        cliFlag:@"width"
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
    
    CSCapabilityArgument *heightArg = [CSCapabilityArgument 
        argumentWithName:@"height"
        type:CSArgumentTypeInteger
        description:@"Height of the thumbnail in pixels"
        cliFlag:@"height"
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
    
    CSCapabilityArgument *outputArg = [CSCapabilityArgument 
        argumentWithName:@"output"
        type:CSArgumentTypeString
        description:@"Write thumbnail to specified file instead of stdout"
        cliFlag:@"output"
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
    
    CSCapabilityArgument *pageArg = [CSCapabilityArgument 
        argumentWithName:@"page"
        type:CSArgumentTypeInteger
        description:@"Page number to generate thumbnail from (1-based, default: 1)"
        cliFlag:@"page"
        position:nil
        validation:pageValidation
        defaultValue:@1];
    [arguments addOptionalArgument:pageArg];
    
    CSCapabilityOutput *output = [CSCapabilityOutput 
        outputWithType:CSOutputTypeBinary
        schemaRef:nil
        contentType:@"image/png"
        validation:nil
        description:@"PNG image data representing a thumbnail of the document"];
    
    return [CSCapability 
        capabilityWithId:capabilityId
        version:@"1.0.0"
        description:@"Generate a thumbnail image preview of the document"
        metadata:@{}
        command:command
        arguments:arguments
        output:output];
}

+ (CSCapability *)extractOutlineCapability {
    NSError *error;
    CSCapabilityId *capabilityId = [CSCapabilityId fromString:@"document:extract:outline" error:&error];
    if (!capabilityId) {
        @throw [NSException exceptionWithName:@"InvalidCapabilityID" 
                                       reason:@"Failed to create capability ID for extract-outline"
                                     userInfo:nil];
    }
    
    NSString *command = @"extract-outline";
    
    CSCapabilityArguments *arguments = [CSCapabilityArguments arguments];
    
    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation 
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];
    
    CSCapabilityArgument *filePathArg = [CSCapabilityArgument 
        argumentWithName:@"file_path"
        type:CSArgumentTypeString
        description:@"Path to the document file to process"
        cliFlag:nil
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
    
    CSCapabilityArgument *maxDepthArg = [CSCapabilityArgument 
        argumentWithName:@"max_depth"
        type:CSArgumentTypeInteger
        description:@"Maximum outline depth to extract (1-10)"
        cliFlag:@"max-depth"
        position:nil
        validation:maxDepthValidation
        defaultValue:nil];
    [arguments addOptionalArgument:maxDepthArg];
    
    // Optional include_page_numbers argument
    CSCapabilityArgument *includePageNumbersArg = [CSCapabilityArgument 
        argumentWithName:@"include_page_numbers"
        type:CSArgumentTypeBoolean
        description:@"Include page numbers in the outline (default: true)"
        cliFlag:@"include-page-numbers"
        position:nil
        validation:nil
        defaultValue:@YES];
    [arguments addOptionalArgument:includePageNumbersArg];
    
    // Optional output argument
    CSArgumentValidation *outputValidation = [CSArgumentValidation 
        validationWithMin:nil
        max:nil
        minLength:nil
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];
    
    CSCapabilityArgument *outputArg = [CSCapabilityArgument 
        argumentWithName:@"output"
        type:CSArgumentTypeString
        description:@"Write output to specified file instead of stdout"
        cliFlag:@"output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];
    
    CSCapabilityOutput *output = [CSCapabilityOutput 
        outputWithType:CSOutputTypeObject
        schemaRef:@"document-outline.json"
        contentType:@"application/json"
        validation:nil
        description:@"Hierarchical document outline with section titles and optional page numbers"];
    
    return [CSCapability 
        capabilityWithId:capabilityId
        version:@"1.0.0"
        description:@"Extract document outline/table of contents with hierarchical structure"
        metadata:@{}
        command:command
        arguments:arguments
        output:output];
}

+ (CSCapability *)extractPagesCapability {
    NSError *error;
    CSCapabilityId *capabilityId = [CSCapabilityId fromString:@"document:extract:pages" error:&error];
    if (!capabilityId) {
        @throw [NSException exceptionWithName:@"InvalidCapabilityID" 
                                       reason:@"Failed to create capability ID for extract-pages"
                                     userInfo:nil];
    }
    
    NSString *command = @"extract-pages";
    
    CSCapabilityArguments *arguments = [CSCapabilityArguments arguments];
    
    // Required file_path argument
    CSArgumentValidation *filePathValidation = [CSArgumentValidation 
        validationWithMin:nil
        max:nil
        minLength:@1
        maxLength:nil
        pattern:@"^[^\\0]+$"
        allowedValues:nil];
    
    CSCapabilityArgument *filePathArg = [CSCapabilityArgument 
        argumentWithName:@"file_path"
        type:CSArgumentTypeString
        description:@"Path to the document file to process"
        cliFlag:nil
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
    
    CSCapabilityArgument *outputArg = [CSCapabilityArgument 
        argumentWithName:@"output"
        type:CSArgumentTypeString
        description:@"Write output to specified file instead of stdout"
        cliFlag:@"output"
        position:nil
        validation:outputValidation
        defaultValue:nil];
    [arguments addOptionalArgument:outputArg];
    
    CSCapabilityOutput *output = [CSCapabilityOutput 
        outputWithType:CSOutputTypeObject
        schemaRef:@"document-pages.json"
        contentType:@"application/json"
        validation:nil
        description:@"Document pages with text content organized by pages and paragraphs"];
    
    return [CSCapability 
        capabilityWithId:capabilityId
        version:@"1.0.0"
        description:@"Extract document pages with text content organized by pages and paragraphs"
        metadata:@{}
        command:command
        arguments:arguments
        output:output];
}

+ (NSArray<CSCapability *> *)allStandardCapabilities {
    return @[
        [self extractMetadataCapability],
        [self generateThumbnailCapability],
        [self extractOutlineCapability],
        [self extractPagesCapability]
    ];
}

+ (nullable CSCapability *)standardCapabilityWithName:(NSString *)name {
    if ([name isEqualToString:@"extract-metadata"]) {
        return [self extractMetadataCapability];
    } else if ([name isEqualToString:@"generate-thumbnail"]) {
        return [self generateThumbnailCapability];
    } else if ([name isEqualToString:@"extract-outline"]) {
        return [self extractOutlineCapability];
    } else if ([name isEqualToString:@"extract-pages"]) {
        return [self extractPagesCapability];
    }
    return nil;
}

+ (nullable CSCapability *)standardCapabilityWithId:(NSString *)idString {
    if ([idString isEqualToString:@"document:extract:metadata"]) {
        return [self extractMetadataCapability];
    } else if ([idString isEqualToString:@"document:generate:thumbnail"]) {
        return [self generateThumbnailCapability];
    } else if ([idString isEqualToString:@"document:extract:outline"]) {
        return [self extractOutlineCapability];
    } else if ([idString isEqualToString:@"document:extract:pages"]) {
        return [self extractPagesCapability];
    }
    return nil;
}

@end