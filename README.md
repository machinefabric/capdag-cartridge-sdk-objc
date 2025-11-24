# FMIO Plugin SDK for Objective-C

A native Objective-C framework for building document processing plugins for the FMIO system.

## Overview

The FMIO Plugin SDK for Objective-C provides a complete framework for building document handlers that can extract metadata, outlines, pages, and generate thumbnails from various document formats. It conforms to the FMIO plugin schemas and provides full compatibility with the FMIO ecosystem.

## Features

- ✅ **Schema Compliant**: Fully conforms to FMIO plugin schemas
- ✅ **Async/Await Support**: Modern completion-handler based API
- ✅ **JSON Serialization**: Built-in JSON serialization for all data types
- ✅ **Type Safety**: Full Objective-C type safety with nullability annotations
- ✅ **Plugin Management**: Built-in plugin registration and discovery
- ✅ **Extensible**: Easy to extend for new document formats

## Installation

### Manual Installation

1. Clone or download the SDK:
```bash
git clone https://github.com/your-org/fmio-plugin-sdk-objc.git
cd fmio-plugin-sdk-objc
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
#import "FMIOPluginSDK.h"
// Link with: -lFMIOPluginSDK -framework Foundation
```

## Quick Start

### 1. Implement a Document Handler

```objc
#import "FMIOPluginSDK.h"

@interface HTMLDocumentHandler : NSObject <FMIODocumentHandler>
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

- (void)extractMetadata:(NSString *)filePath completion:(void (^)(FMIODocumentMetadata * _Nullable, NSError * _Nullable))completion {
    // Create extraction info
    FMIOExtractionInfo *extractionInfo = [[FMIOExtractionInfo alloc] 
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
    FMIODocumentMetadata *metadata = [[FMIODocumentMetadata alloc] 
        initWithFilePath:filePath 
           fileSizeBytes:fileSize 
           contentLength:0 
            documentType:@"HTML"];
    
    // Set additional properties
    metadata.mimeType = @"text/html";
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
[[FMIOPluginManager sharedManager] registerHandler:htmlHandler 
                                  forFileExtensions:@[@"html", @"htm"]];

// Process a document
FMIOPluginOutput *output = [[FMIOPluginManager sharedManager] 
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
NSString *metadataJSON = [FMIOJSONSerializer serializeMetadata:output.metadata];
NSString *outlineJSON = [FMIOJSONSerializer serializeOutline:output.outline];
NSString *pagesJSON = [FMIOJSONSerializer serializePages:output.pages];

// Full output serialization
NSString *outputJSON = [FMIOJSONSerializer serializePluginOutput:output];
```

## Architecture

### Core Classes

- **`FMIODocumentMetadata`**: Document metadata (conforms to `file-metadata.json` schema)
- **`FMIODocumentOutline`**: Document outline (conforms to `document-outline.json` schema)  
- **`FMIODocumentPages`**: Document pages with paragraphs (conforms to `document-pages.json` schema)
- **`FMIOPluginOutput`**: Combined output from document processing
- **`FMIOPluginManager`**: Central plugin registration and management

### Protocol

- **`FMIODocumentHandler`**: Main protocol that document handlers must implement

### Helpers

- **`FMIOJSONSerializer`**: JSON serialization utilities
- **`FMIOExtractionInfo`**: Metadata about the extraction process

## Document Handler Protocol

All document handlers must implement the `FMIODocumentHandler` protocol:

### Required Methods

```objc
// Basic handler information
- (NSString *)name;
- (NSString *)version;  
- (NSArray<NSString *> *)supportedExtensions;

// Core functionality
- (void)extractMetadata:(NSString *)filePath completion:(void (^)(FMIODocumentMetadata *, NSError *))completion;
- (void)extractOutline:(NSString *)filePath completion:(void (^)(FMIODocumentOutline *, NSError *))completion;
- (void)extractPages:(NSString *)filePath completion:(void (^)(FMIODocumentPages *, NSError *))completion;
- (void)validateFile:(NSString *)filePath completion:(void (^)(BOOL, NSError *))completion;
- (void)getFileInfo:(NSString *)filePath completion:(void (^)(FMIOFileInfo *, NSError *))completion;
- (void)generateThumbnail:(NSString *)filePath width:(NSUInteger)width height:(NSUInteger)height completion:(void (^)(NSData *, NSError *))completion;
```

### Optional Methods

```objc
// Default implementations provided
- (BOOL)canHandle:(NSString *)filePath;
- (FMIOPluginCaps *)getCaps;
```

## Schema Compliance

This SDK fully conforms to the FMIO plugin schemas:

- ✅ `file-metadata.json` - Document metadata structure
- ✅ `document-outline.json` - Document outline structure  
- ✅ `document-pages.json` - Document pages with paragraphs
- ✅ `handler-interface.json` - Document handler interface requirements

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