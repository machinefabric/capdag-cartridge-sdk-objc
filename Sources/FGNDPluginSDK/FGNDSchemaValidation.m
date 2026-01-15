//
//  FGNDSchemaValidation.m
//  Schema validation extensions for FGND Plugin SDK
//
//  Provides convenience methods for creating schema-enabled capabilities
//  and standard schemas for document processing.
//
//  Updated to use spec ID-based mediaSpec system per capns modernization.
//  Schema validation now resolves spec IDs through the cap's mediaSpecs table.
//

#import "FGNDPluginSDK.h"

// Well-known spec IDs
static NSString * const kSpecIdStr = @"media:type=string;v=1";
static NSString * const kSpecIdInt = @"media:type=integer;v=1";
static NSString * const kSpecIdObj = @"media:type=object;v=1";
static NSString * const kSpecIdObjArray = @"media:type=object-array;v=1";

@implementation CSCapArgument (FGNDPluginSDK)

+ (instancetype)documentMetadataArgumentWithName:(NSString *)name
                                     description:(NSString *)description
                                         cliFlag:(NSString *)cliFlag
                                       mediaSpec:(NSString *)mediaSpec {
    // Create argument with spec ID (schema is in cap's mediaSpecs table)
    return [CSCapArgument argumentWithName:name
                                 mediaSpec:mediaSpec ?: kSpecIdObj
                             argDescription:description
                                   cliFlag:cliFlag
                                  position:nil
                                validation:nil
                              defaultValue:nil];
}

+ (instancetype)fileChipsArgumentWithName:(NSString *)name
                                  description:(NSString *)description
                                      cliFlag:(NSString *)cliFlag
                                    mediaSpec:(NSString *)mediaSpec {
    // Create argument with spec ID (schema is in cap's mediaSpecs table)
    return [CSCapArgument argumentWithName:name
                                 mediaSpec:mediaSpec ?: kSpecIdObjArray
                             argDescription:description
                                   cliFlag:cliFlag
                                  position:nil
                                validation:nil
                              defaultValue:nil];
}

@end

@implementation CSCapOutput (FGNDPluginSDK)

+ (instancetype)documentMetadataOutputWithMediaSpec:(NSString *)mediaSpec
                                        description:(NSString *)description {
    return [CSCapOutput outputWithMediaSpec:mediaSpec ?: kSpecIdObj
                                 validation:nil
                          outputDescription:description];
}

+ (instancetype)fileChipsOutputWithMediaSpec:(NSString *)mediaSpec
                                     description:(NSString *)description {
    return [CSCapOutput outputWithMediaSpec:mediaSpec ?: kSpecIdObjArray
                                 validation:nil
                          outputDescription:description];
}

+ (instancetype)documentOutlineOutputWithMediaSpec:(NSString *)mediaSpec
                                       description:(NSString *)description {
    return [CSCapOutput outputWithMediaSpec:mediaSpec ?: kSpecIdObj
                                 validation:nil
                          outputDescription:description];
}

@end

@implementation FGNDSchemaValidationHelper

+ (CSJSONSchemaValidator *)sharedValidator {
    static CSJSONSchemaValidator *_sharedValidator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedValidator = [CSJSONSchemaValidator validator];
    });
    return _sharedValidator;
}

+ (BOOL)validatePluginManifest:(FGNDPluginManifest *)manifest error:(NSError **)error {
    if (!manifest) {
        if (error) {
            *error = [NSError errorWithDomain:@"FGNDSchemaValidationError"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Plugin manifest is nil"}];
        }
        return NO;
    }

    // Validate that all caps in the manifest have proper media spec definitions
    for (CSCap *cap in manifest.caps) {
        // Check arguments - verify spec IDs can be resolved
        if (cap.arguments) {
            for (CSCapArgument *arg in cap.arguments.required) {
                if (![[self class] validateCapArgumentMediaSpec:arg cap:cap error:error]) {
                    return NO;
                }
            }
            for (CSCapArgument *arg in cap.arguments.optional) {
                if (![[self class] validateCapArgumentMediaSpec:arg cap:cap error:error]) {
                    return NO;
                }
            }
        }

        // Check output - verify spec ID can be resolved
        if (cap.output && ![[self class] validateCapOutputMediaSpec:cap.output cap:cap error:error]) {
            return NO;
        }
    }

    return YES;
}

/// Check if a spec ID is a well-known built-in (std:* namespace) that doesn't need declaration in mediaSpecs
+ (BOOL)isBuiltinSpecId:(NSString *)specId {
    // The "std:" namespace is reserved for well-known spec IDs defined by capns
    // These don't need to be declared in the cap's mediaSpecs table
    static NSSet<NSString *> *wellKnownSpecIds = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wellKnownSpecIds = [NSSet setWithArray:@[
            @"media:type=string;v=1",
            @"media:type=integer;v=1",
            @"media:type=number;v=1",
            @"media:type=boolean;v=1",
            @"media:type=object;v=1",
            @"media:type=binary;v=1",
            @"media:type=string-array;v=1",
            @"media:type=integer-array;v=1",
            @"media:type=number-array;v=1",
            @"media:type=boolean-array;v=1",
            @"media:type=object-array;v=1",
        ]];
    });
    return [wellKnownSpecIds containsObject:specId];
}

+ (BOOL)validateCapArgumentMediaSpec:(CSCapArgument *)argument cap:(CSCap *)cap error:(NSError **)error {
    NSString *specId = argument.mediaSpec;

    // Built-in spec IDs don't need to be declared in mediaSpecs
    if ([self isBuiltinSpecId:specId]) {
        return YES;
    }

    // Custom spec IDs must be declared in the cap's mediaSpecs table
    if (!cap.mediaSpecs[specId]) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"Argument '%@' uses spec ID '%@' which is not declared in mediaSpecs",
                               argument.name, specId];
            *error = [NSError errorWithDomain:@"FGNDSchemaValidationError"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return NO;
    }

    return YES;
}

+ (BOOL)validateCapOutputMediaSpec:(CSCapOutput *)output cap:(CSCap *)cap error:(NSError **)error {
    NSString *specId = output.mediaSpec;

    // Built-in spec IDs don't need to be declared in mediaSpecs
    if ([self isBuiltinSpecId:specId]) {
        return YES;
    }

    // Custom spec IDs must be declared in the cap's mediaSpecs table
    if (!cap.mediaSpecs[specId]) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"Output uses spec ID '%@' which is not declared in mediaSpecs",
                               specId];
            *error = [NSError errorWithDomain:@"FGNDSchemaValidationError"
                                         code:1003
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return NO;
    }

    return YES;
}

+ (NSDictionary *)standardDocumentMetadataSchema {
    return @{
        @"$schema": @"http://json-schema.org/draft-07/schema#",
        @"type": @"object",
        @"title": @"Document Metadata Schema",
        @"description": @"Standard schema for document metadata extraction",
        @"properties": @{
            @"filePath": @{
                @"type": @"string",
                @"description": @"Path to the document file"
            },
            @"fileSizeBytes": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"File size in bytes"
            },
            @"contentLength": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Content length"
            },
            @"documentType": @{
                @"type": @"string",
                @"enum": @[@"pdf", @"epub", @"docx", @"txt", @"md", @"html"],
                @"description": @"Type of document"
            },
            @"title": @{
                @"type": @"string",
                @"description": @"Document title"
            },
            @"authors": @{
                @"type": @"array",
                @"items": @{@"type": @"string"},
                @"description": @"Document authors"
            },
            @"contributors": @{
                @"type": @"array",
                @"items": @{@"type": @"string"},
                @"description": @"Document contributors"
            },
            @"keywords": @{
                @"type": @"array",
                @"items": @{@"type": @"string"},
                @"description": @"Document keywords/tags"
            },
            @"pageCount": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Number of pages"
            },
            @"wordCount": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Number of words"
            },
            @"characterCount": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Number of characters"
            },
            @"language": @{
                @"type": @"string",
                @"pattern": @"^[a-z]{2}(-[A-Z]{2})?$",
                @"description": @"Document language (ISO 639-1)"
            },
            @"creationDate": @{
                @"type": @"string",
                @"format": @"date-time",
                @"description": @"Document creation date"
            },
            @"modificationDate": @{
                @"type": @"string",
                @"format": @"date-time",
                @"description": @"Document modification date"
            },
            @"extendedMetadata": @{
                @"type": @"object",
                @"description": @"Additional format-specific metadata",
                @"additionalProperties": @YES
            }
        },
        @"required": @[@"filePath", @"fileSizeBytes", @"contentLength", @"documentType"],
        @"additionalProperties": @NO
    };
}

+ (NSDictionary *)standardGroundChipsSchema {
    return @{
        @"$schema": @"http://json-schema.org/draft-07/schema#",
        @"type": @"object",
        @"title": @"File Chips Schema",
        @"description": @"Standard schema for file chips extraction",
        @"properties": @{
            @"sourceFile": @{
                @"type": @"string",
                @"description": @"Source document file path"
            },
            @"title": @{
                @"type": @"string",
                @"description": @"Document title"
            },
            @"documentType": @{
                @"type": @"string",
                @"enum": @[@"pdf", @"epub", @"docx", @"txt", @"md", @"html"],
                @"description": @"Type of document"
            },
            @"totalPages": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Total number of pages"
            },
            @"pages": @{
                @"type": @"array",
                @"description": @"Array of file chips",
                @"items": @{
                    @"type": @"object",
                    @"properties": @{
                        @"orderIndex": @{
                            @"type": @"integer",
                            @"minimum": @1,
                            @"description": @"Page number (1-indexed)"
                        },
                        @"textContent": @{
                            @"type": @"string",
                            @"description": @"Extracted text content"
                        },
                        @"sourceRef": @{
                            @"type": @"string",
                            @"description": @"Reference to source location"
                        },
                        @"wordCount": @{
                            @"type": @"integer",
                            @"minimum": @0,
                            @"description": @"Number of words on this page"
                        },
                        @"characterCount": @{
                            @"type": @"integer",
                            @"minimum": @0,
                            @"description": @"Number of characters on this page"
                        }
                    },
                    @"required": @[@"orderIndex", @"textContent"],
                    @"additionalProperties": @NO
                }
            },
            @"extractionInfo": @{
                @"type": @"object",
                @"properties": @{
                    @"extractorName": @{
                        @"type": @"string",
                        @"description": @"Name of the extraction plugin"
                    },
                    @"extractorVersion": @{
                        @"type": @"string",
                        @"description": @"Version of the extraction plugin"
                    },
                    @"extractedAt": @{
                        @"type": @"string",
                        @"format": @"date-time",
                        @"description": @"Timestamp of extraction"
                    },
                    @"warnings": @{
                        @"type": @"array",
                        @"items": @{@"type": @"string"},
                        @"description": @"Extraction warnings"
                    }
                },
                @"required": @[@"extractorName", @"extractorVersion"],
                @"additionalProperties": @NO
            }
        },
        @"required": @[@"sourceFile", @"documentType", @"totalPages", @"pages", @"extractionInfo"],
        @"additionalProperties": @NO
    };
}

+ (NSDictionary *)standardDocumentOutlineSchema {
    // Define the outline entry schema recursively
    NSDictionary *outlineEntrySchema = @{
        @"type": @"object",
        @"properties": @{
            @"title": @{
                @"type": @"string",
                @"description": @"Outline entry title"
            },
            @"level": @{
                @"type": @"integer",
                @"minimum": @1,
                @"description": @"Hierarchical level (1 = top level)"
            },
            @"page": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Page number (1-indexed, 0 if no destination)"
            },
            @"sourceRef": @{
                @"type": @"string",
                @"description": @"Reference to source location"
            }
        },
        @"required": @[@"title", @"level"],
        @"additionalProperties": @NO
    };

    return @{
        @"$schema": @"http://json-schema.org/draft-07/schema#",
        @"type": @"object",
        @"title": @"Document Outline Schema",
        @"description": @"Standard schema for document outline extraction",
        @"properties": @{
            @"sourceFile": @{
                @"type": @"string",
                @"description": @"Source document file path"
            },
            @"title": @{
                @"type": @"string",
                @"description": @"Document title"
            },
            @"documentType": @{
                @"type": @"string",
                @"enum": @[@"pdf", @"epub", @"docx", @"txt", @"md", @"html"],
                @"description": @"Type of document"
            },
            @"totalPages": @{
                @"type": @"integer",
                @"minimum": @0,
                @"description": @"Total number of pages"
            },
            @"hasOutline": @{
                @"type": @"boolean",
                @"description": @"Whether the document has an outline"
            },
            @"outlineEntries": @{
                @"type": @"array",
                @"description": @"Array of outline entries",
                @"items": outlineEntrySchema
            },
            @"extractionInfo": @{
                @"type": @"object",
                @"properties": @{
                    @"extractorName": @{
                        @"type": @"string",
                        @"description": @"Name of the extraction plugin"
                    },
                    @"extractorVersion": @{
                        @"type": @"string",
                        @"description": @"Version of the extraction plugin"
                    },
                    @"extractedAt": @{
                        @"type": @"string",
                        @"format": @"date-time",
                        @"description": @"Timestamp of extraction"
                    },
                    @"warnings": @{
                        @"type": @"array",
                        @"items": @{@"type": @"string"},
                        @"description": @"Extraction warnings"
                    }
                },
                @"required": @[@"extractorName", @"extractorVersion"],
                @"additionalProperties": @NO
            }
        },
        @"required": @[@"sourceFile", @"documentType", @"totalPages", @"hasOutline", @"outlineEntries", @"extractionInfo"],
        @"additionalProperties": @NO
    };
}

@end
