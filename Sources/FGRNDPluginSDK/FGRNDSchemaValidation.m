//
//  FGRNDSchemaValidation.m
//  Schema validation extensions for FGRND Plugin SDK
//
//  Provides convenience methods for creating schema-enabled capabilities
//  and standard schemas for document processing.
//

#import "FGRNDPluginSDK.h"

@implementation CSCapArgument (FGRNDPluginSDK)

+ (instancetype)documentMetadataArgumentWithName:(NSString *)name
                                     description:(NSString *)description
                                         cliFlag:(NSString *)cliFlag
                                          schema:(NSDictionary *)schema {
    return [CSCapArgument argumentWithName:name
                                   argType:CSArgumentTypeObject
                             argDescription:description
                                   cliFlag:cliFlag
                                    schema:schema];
}

+ (instancetype)documentPagesArgumentWithName:(NSString *)name
                                  description:(NSString *)description
                                      cliFlag:(NSString *)cliFlag
                                       schema:(NSDictionary *)schema {
    return [CSCapArgument argumentWithName:name
                                   argType:CSArgumentTypeArray
                             argDescription:description
                                   cliFlag:cliFlag
                                    schema:schema];
}

@end

@implementation CSCapOutput (FGRNDPluginSDK)

+ (instancetype)documentMetadataOutputWithSchema:(NSDictionary *)schema
                                     description:(NSString *)description {
    return [CSCapOutput outputWithType:CSOutputTypeObject
                                 schema:schema
                      outputDescription:description];
}

+ (instancetype)documentPagesOutputWithSchema:(NSDictionary *)schema
                                  description:(NSString *)description {
    return [CSCapOutput outputWithType:CSOutputTypeArray
                                 schema:schema
                      outputDescription:description];
}

+ (instancetype)documentOutlineOutputWithSchema:(NSDictionary *)schema
                                    description:(NSString *)description {
    return [CSCapOutput outputWithType:CSOutputTypeObject
                                 schema:schema
                      outputDescription:description];
}

@end

@implementation FGRNDSchemaValidationHelper

+ (CSJSONSchemaValidator *)sharedValidator {
    static CSJSONSchemaValidator *_sharedValidator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedValidator = [CSJSONSchemaValidator validator];
    });
    return _sharedValidator;
}

+ (BOOL)validatePluginManifest:(FGRNDPluginManifest *)manifest error:(NSError **)error {
    if (!manifest) {
        if (error) {
            *error = [NSError errorWithDomain:@"FGRNDSchemaValidationError"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Plugin manifest is nil"}];
        }
        return NO;
    }
    
    // Validate that all caps in the manifest have proper schema definitions for structured types
    for (CSCap *cap in manifest.caps) {
        // Check arguments
        if (cap.arguments) {
            for (CSCapArgument *arg in cap.arguments.required) {
                if (![[self class] validateCapArgumentSchemaDefinition:arg error:error]) {
                    return NO;
                }
            }
            for (CSCapArgument *arg in cap.arguments.optional) {
                if (![[self class] validateCapArgumentSchemaDefinition:arg error:error]) {
                    return NO;
                }
            }
        }
        
        // Check output
        if (cap.output && ![[self class] validateCapOutputSchemaDefinition:cap.output error:error]) {
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL)validateCapArgumentSchemaDefinition:(CSCapArgument *)argument error:(NSError **)error {
    // For object and array types, require schema or schemaRef
    if ((argument.argType == CSArgumentTypeObject || argument.argType == CSArgumentTypeArray)) {
        if (!argument.schema && !argument.schemaRef) {
            if (error) {
                NSString *message = [NSString stringWithFormat:@"Argument '%@' of type '%@' requires schema or schemaRef",
                                   argument.name, argument.argType == CSArgumentTypeObject ? @"object" : @"array"];
                *error = [NSError errorWithDomain:@"FGRNDSchemaValidationError"
                                             code:1002
                                         userInfo:@{NSLocalizedDescriptionKey: message}];
            }
            return NO;
        }
    }
    return YES;
}

+ (BOOL)validateCapOutputSchemaDefinition:(CSCapOutput *)output error:(NSError **)error {
    // For object and array types, require schema or schemaRef
    if ((output.outputType == CSOutputTypeObject || output.outputType == CSOutputTypeArray)) {
        if (!output.schema && !output.schemaRef) {
            if (error) {
                NSString *message = [NSString stringWithFormat:@"Output of type '%@' requires schema or schemaRef",
                                   output.outputType == CSOutputTypeObject ? @"object" : @"array"];
                *error = [NSError errorWithDomain:@"FGRNDSchemaValidationError"
                                             code:1003
                                         userInfo:@{NSLocalizedDescriptionKey: message}];
            }
            return NO;
        }
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

+ (NSDictionary *)standardDocumentPagesSchema {
    return @{
        @"$schema": @"http://json-schema.org/draft-07/schema#",
        @"type": @"object",
        @"title": @"Document Pages Schema",
        @"description": @"Standard schema for document pages extraction",
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
                @"description": @"Array of document pages",
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