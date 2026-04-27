# MACHFAB Cartridge SDK for Objective-C

A native Objective-C framework for building document processing cartridges for the MACHFAB system.

## Overview

The MACHFAB Cartridge SDK for Objective-C provides a complete framework for building document handlers that can extract metadata, outlines, pages, and generate thumbnails from various document formats. It conforms to the MACHFAB cartridge schemas and provides full compatibility with the MACHFAB ecosystem.

## Features

- OK **Schema Compliant**: Fully conforms to MACHFAB cartridge schemas
- OK **Async/Await Support**: Modern completion-handler based API
- OK **JSON Serialization**: Built-in JSON serialization for all data types
- OK **Type Safety**: Full Objective-C type safety with nullability annotations
- OK **Cartridge Management**: Built-in cartridge registration and discovery
- OK **Extensible**: Easy to extend for new document formats

## Installation

### Manual Installation

1. Clone or download the SDK:
```bash
git clone https://github.com/your-org/machfab-cartridge-sdk-objc.git
cd machfab-cartridge-sdk-objc
```

2. Build the SDK:
```bash
make build
```

3. Install system-wide (optional):
```bash
make install
```

### Include in Your Project

Add the header and link the static library:

```objc
#import "MACHFABCartridgeSDK.h"
// Link with: -lMACHFABCartridgeSDK -framework Foundation
```

## Quick Start

### 1. Implement a Document Handler

```objc
#import "MACHFABCartridgeSDK.h"

@interface HTMLDocumentHandler : NSObject <MACHFABDocumentHandler>
@end

@implementation HTMLDocumentHandler

- (NSString *)name {
    return @"HTML Document Handler";
}

- (NSString *)version {
    return @"1.0.0";
}

- (NSArray<NSString *> *)supportedExtensions {
    return @[@"html", @"htm"];
}

- (void)extractMetadata:(NSString *)filePath completion:(void (^)(MACHFABDocumentMetadata * _Nullable, NSError * _Nullable))completion {
    // Create extraction info
    MACHFABExtractionInfo *extractionInfo = [[MACHFABExtractionInfo alloc] 
        initWithExtractorName:@"HTML Handler" 
             extractorVersion:@"1.0.0"];
    
    // Get file info
    NSError *error;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] 
        attributesOfItemAtPath:filePath error:&error];
    
    if (error) {
        completion(nil, error);
        return;
    }
    
    long long fileSize = [[fileAttributes objectForKey:NSFileSize] longLongValue];
    
    // Create metadata
    MACHFABDocumentMetadata *metadata = [[MACHFABDocumentMetadata alloc] 
        initWithFilePath:filePath 
           fileSizeBytes:fileSize 
           contentLength:0 
            documentType:@"HTML"];
    
    // Set additional properties
    metadata.mediaUrn = @"media:subtype=html";
    metadata.title = @"HTML Document";
    
    completion(metadata, nil);
}

- (void)generateThumbnail:(NSString *)filePath 
                    width:(NSUInteger)width 
                   height:(NSUInteger)height 
               completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion {
    
    // Read HTML content
    NSError *error;
    NSString *htmlContent = [NSString stringWithContentsOfFile:filePath 
                                                      encoding:NSUTF8StringEncoding 
                                                         error:&error];
    if (error) {
        completion(nil, error);
        return;
    }
    
    // Use WebKit to render HTML to image
    // (Implementation would use WKWebView to render to NSImage, then convert to PNG)
    // For this example, we'll return a placeholder
    
    NSData *placeholderPNG = [@"placeholder" dataUsingEncoding:NSUTF8StringEncoding];
    completion(placeholderPNG, nil);
}

// Implement other required methods...

@end
```

### 2. Register Your Handler

```objc
// Register the handler
HTMLDocumentHandler *htmlHandler = [[HTMLDocumentHandler alloc] init];
[[MACHFABCartridgeManager sharedManager] registerHandler:htmlHandler 
                                  forFileExtensions:@[@"html", @"htm"]];

// Process a document
MACHFABCartridgeOutput *output = [[MACHFABCartridgeManager sharedManager] 
    processDocument:@"/path/to/document.html"];

if (output.success) {
    NSLog(@"Document processed successfully!");
    NSLog(@"Title: %@", output.metadata.title);
} else {
    NSLog(@"Error: %@", output.error);
}
```

### 3. JSON Serialization

```objc
// Serialize results to JSON
NSString *metadataJSON = [MACHFABJSONSerializer serializeMetadata:output.metadata];
NSString *outlineJSON = [MACHFABJSONSerializer serializeOutline:output.outline];
NSString *pagesJSON = [MACHFABJSONSerializer serializePages:output.pages];

// Full output serialization
NSString *outputJSON = [MACHFABJSONSerializer serializeCartridgeOutput:output];
```

## Architecture

### Core Classes

- **`MACHFABDocumentMetadata`**: Document metadata (conforms to `file-metadata.json` schema)
- **`MACHFABDocumentOutline`**: Document outline (conforms to `document-outline.json` schema)  
- **`MACHFABDisboundPage`**: Single page with text content (output is NSArray of these, conforms to `disbound-page.json` schema)
- **`MACHFABCartridgeOutput`**: Combined output from document processing
- **`MACHFABCartridgeManager`**: Central cartridge registration and management

### Protocol

- **`MACHFABDocumentHandler`**: Main protocol that document handlers must implement

### Helpers

- **`MACHFABJSONSerializer`**: JSON serialization utilities
- **`MACHFABExtractionInfo`**: Metadata about the extraction process

## Document Handler Protocol

All document handlers must implement the `MACHFABDocumentHandler` protocol:

### Required Methods

```objc
// Basic handler information
- (NSString *)name;
- (NSString *)version;  
- (NSArray<NSString *> *)supportedExtensions;

// Core functionality
- (void)extractMetadata:(NSString *)filePath completion:(void (^)(MACHFABDocumentMetadata *, NSError *))completion;
- (void)extractOutline:(NSString *)filePath completion:(void (^)(MACHFABDocumentOutline *, NSError *))completion;
- (void)disbind:(NSString *)filePath completion:(void (^)(NSArray<MACHFABDisboundPage *> *, NSError *))completion;
- (void)validateFile:(NSString *)filePath completion:(void (^)(BOOL, NSError *))completion;
- (void)getFileInfo:(NSString *)filePath completion:(void (^)(MACHFABFileInfo *, NSError *))completion;
- (void)generateThumbnail:(NSString *)filePath width:(NSUInteger)width height:(NSUInteger)height completion:(void (^)(NSData *, NSError *))completion;
```

### Optional Methods

```objc
// Default implementations provided
- (BOOL)canHandle:(NSString *)filePath;
- (MACHFABCartridgeCaps *)getCaps;
```

## Schema Compliance

This SDK fully conforms to the MACHFAB cartridge schemas:

- OK `file-metadata.json` - Document metadata structure
- OK `document-outline.json` - Document outline structure  
- OK `disbound-pages.json` - File chips with paragraphs
- OK `handler-interface.json` - Document handler interface requirements

## Building

```bash
# Build SDK
make build

# Clean build artifacts  
make clean

# Install system-wide
make install

# Run tests
make test
```

## Requirements

- macOS 10.12+
- Xcode 9.0+
- Foundation framework

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## Examples

See the `/examples` directory for complete working examples of document handlers for various formats.