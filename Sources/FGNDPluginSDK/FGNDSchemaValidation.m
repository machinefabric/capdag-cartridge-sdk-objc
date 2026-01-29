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
static NSString * const kSpecIdStr = @"media:string";
static NSString * const kSpecIdInt = @"media:integer";
static NSString * const kSpecIdObj = @"media:object";
static NSString * const kSpecIdObjArray = @"media:object-array";

@implementation CSCapArg (FGNDPluginSDK)

+ (instancetype)documentMetadataArgWithMediaUrn:(NSString *)mediaUrn
                                        required:(BOOL)required
                                         sources:(NSArray<CSArgSource *> *)sources
                                   argDescription:(NSString *)description {
    return [CSCapArg argWithMediaUrn:mediaUrn ?: kSpecIdObj
                             required:required
                              sources:sources
                       argDescription:description
                         defaultValue:nil];
}

+ (instancetype)disboundPagesArgWithMediaUrn:(NSString *)mediaUrn
                                 required:(BOOL)required
                                  sources:(NSArray<CSArgSource *> *)sources
                            argDescription:(NSString *)description {
    return [CSCapArg argWithMediaUrn:mediaUrn ?: kSpecIdObjArray
                             required:required
                              sources:sources
                       argDescription:description
                         defaultValue:nil];
}

@end

@implementation CSCapOutput (FGNDPluginSDK)

+ (instancetype)documentMetadataOutputWithMediaUrn:(NSString *)mediaUrn
                                       description:(NSString *)description {
    return [CSCapOutput outputWithMediaUrn:mediaUrn ?: kSpecIdObj
                          outputDescription:description];
}

+ (instancetype)disboundPagesOutputWithMediaUrn:(NSString *)mediaUrn
                                   description:(NSString *)description {
    return [CSCapOutput outputWithMediaUrn:mediaUrn ?: kSpecIdObjArray
                          outputDescription:description];
}

+ (instancetype)documentOutlineOutputWithMediaUrn:(NSString *)mediaUrn
                                         description:(NSString *)description {
    return [CSCapOutput outputWithMediaUrn:mediaUrn ?: kSpecIdObj
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
        // Check arguments - verify media URNs can be resolved
        for (CSCapArg *arg in cap.args) {
            if (![[self class] validateCapArgMediaUrn:arg cap:cap error:error]) {
                return NO;
            }
        }

        // Check output - verify spec ID can be resolved
        if (cap.output && ![[self class] validateCapOutputMediaUrn:cap.output cap:cap error:error]) {
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
            @"media:string",
            @"media:integer",
            @"media:number",
            @"media:boolean",
            @"media:object",
            @"media:binary",
            @"media:string-array",
            @"media:integer-array",
            @"media:number-array",
            @"media:boolean-array",
            @"media:object-array",
        ]];
    });
    return [wellKnownSpecIds containsObject:specId];
}

+ (BOOL)validateCapArgMediaUrn:(CSCapArg *)argument cap:(CSCap *)cap error:(NSError **)error {
    NSString *specId = argument.mediaUrn;

    // Built-in spec IDs don't need to be declared in mediaSpecs
    if ([self isBuiltinSpecId:specId]) {
        return YES;
    }

    // Custom spec IDs must be declared in the cap's mediaSpecs table
    if (!cap.mediaSpecs[specId]) {
        if (error) {
            NSString *message = [NSString stringWithFormat:@"Argument uses media URN '%@' which is not declared in mediaSpecs",
                               specId];
            *error = [NSError errorWithDomain:@"FGNDSchemaValidationError"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return NO;
    }

    return YES;
}

+ (BOOL)validateCapOutputMediaUrn:(CSCapOutput *)output cap:(CSCap *)cap error:(NSError **)error {
    NSString *specId = output.mediaUrn;

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

+ (NSDictionary *)standardDisboundPagesSchema {
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
