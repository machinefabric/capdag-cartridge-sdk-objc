# Makefile for MACINA Plugin SDK Objective-C
# This SDK now depends on capns-objc for formal cap management

# Directories
CAP_SDK_DIR = ../capns-objc
BUILD_DIR = build
DIST_DIR = dist

help:
	@echo "Usage: make <target>\n\n\
	  build\t\tBuild the MACINA Plugin SDK with cap SDK integration\n\
	  build-capns\tBuild only the cap SDK\n\
	  clean\t\tRemove built artifacts\n\
	  install\tInstall the library to system paths\n\
	  test\t\tRun tests for both SDKs\n\
	  example\tShow example usage\n\
	"

# Build both the cap SDK and the plugin SDK
.PHONY: build
build: build-capns build-plugin-sdk

.PHONY: build-capns
build-capns:
	@echo "Building capns-objc..."
	cd $(CAP_SDK_DIR) && swift build -c release

.PHONY: build-plugin-sdk
build-plugin-sdk: build-capns
	@echo "Building macina-plugin-sdk-objc..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(DIST_DIR)
	
	# Copy cap SDK headers
	@cp -r $(CAP_SDK_DIR)/Sources/CapNs/include/* $(DIST_DIR)/
	
	# Compile our plugin SDK with cap SDK integration (now from Sources directory)
	/usr/bin/clang -c -o $(BUILD_DIR)/MACINAPluginSDK.o Sources/MACINAPluginSDK/MACINAPluginSDK.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapNs/include \
		-ISources/MACINAPluginSDK/include \
		-fobjc-arc -fno-modules
	
	/usr/bin/clang -c -o $(BUILD_DIR)/MACINAStandardCaps.o Sources/MACINAPluginSDK/MACINAStandardCaps.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapNs/include \
		-ISources/MACINAPluginSDK/include \
		-fobjc-arc -fno-modules
	
	/usr/bin/clang -c -o $(BUILD_DIR)/CSPluginCaps.o Sources/MACINAPluginSDK/CSPluginCaps.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapNs/include \
		-ISources/MACINAPluginSDK/include \
		-fobjc-arc -fno-modules
	
	# Create static library with all object files including CapNs
	ar rcs $(DIST_DIR)/libMACINAPluginSDK.a $(BUILD_DIR)/*.o $(CAP_SDK_DIR)/.build/release/CapNs.build/*.o
	
	# Copy plugin SDK headers
	@cp Sources/MACINAPluginSDK/include/*.h $(DIST_DIR)/
	@echo "OK MACINA Plugin SDK built successfully with cap SDK integration in $(DIST_DIR)/"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)
	cd $(CAP_SDK_DIR) && swift package clean

.PHONY: install
install: build
	@echo "Installing MACINA Plugin SDK with cap SDK..."
	sudo cp $(DIST_DIR)/libMACINAPluginSDK.a /usr/local/lib/
	sudo cp $(DIST_DIR)/*.h /usr/local/include/
	@echo "OK MACINA Plugin SDK installed to system paths"

.PHONY: test
test: build
	@echo "Testing cap SDK..."
	cd $(CAP_SDK_DIR) && swift test
	@echo "OK All tests passed"

.PHONY: example
example:
	@echo "Example plugin integration with formal cap SDK:"
	@echo ""
	@echo "1. Add both SDKs to your project:"
	@echo "   #import \"CapNs.h\""
	@echo "   #import \"MACINAPluginSDK.h\""
	@echo ""
	@echo "2. Create formal cap definitions:"
	@echo "   NSError *error;"
	@echo "   CSCapUrn *capId = [CSCapUrn fromString:@\"extract-metadata:pdf\" error:&error];"
	@echo "   CSCap *cap = [CSCap capWithUrn:capId version:@\"1.0.0\"];";
	@echo ""
	@echo "3. Build plugin caps collection:"
	@echo "   CSPluginCaps *caps = [CSPluginCaps new];"
	@echo "   [caps addCap:cap];"
	@echo ""
	@echo "4. Create plugin manifest with formal caps:"
	@echo "   MACINAPluginManifest *pluginManifest = [[MACINAPluginManifest alloc]"
	@echo "       initWithName:@\"MyPlugin\""
	@echo "       version:@\"1.0.0\""
	@echo "       pluginDescription:@\"Example plugin\""
	@echo "       caps:caps];"