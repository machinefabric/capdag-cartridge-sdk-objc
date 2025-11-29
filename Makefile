# Makefile for FMIO Plugin SDK Objective-C
# This SDK now depends on capns-objc for formal cap management

# Directories
CAP_SDK_DIR = ../capns-objc
BUILD_DIR = build
DIST_DIR = dist

help:
	@echo "Usage: make <target>\n\n\
	  build\t\tBuild the FMIO Plugin SDK with cap SDK integration\n\
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
	@echo "Building fmio-plugin-sdk-objc..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(DIST_DIR)
	
	# Copy cap SDK headers
	@cp -r $(CAP_SDK_DIR)/Sources/CapNs/include/* $(DIST_DIR)/
	
	# Compile our plugin SDK with cap SDK integration (now from Sources directory)
	/usr/bin/clang -c -o $(BUILD_DIR)/FMIOPluginSDK.o Sources/FMIOPluginSDK/FMIOPluginSDK.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapNs/include \
		-ISources/FMIOPluginSDK/include \
		-fobjc-arc -fno-modules
	
	/usr/bin/clang -c -o $(BUILD_DIR)/FMIOStandardCaps.o Sources/FMIOPluginSDK/FMIOStandardCaps.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapNs/include \
		-ISources/FMIOPluginSDK/include \
		-fobjc-arc -fno-modules
	
	/usr/bin/clang -c -o $(BUILD_DIR)/CSPluginCaps.o Sources/FMIOPluginSDK/CSPluginCaps.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapNs/include \
		-ISources/FMIOPluginSDK/include \
		-fobjc-arc -fno-modules
	
	# Create static library with all object files including CapNs
	ar rcs $(DIST_DIR)/libFMIOPluginSDK.a $(BUILD_DIR)/*.o $(CAP_SDK_DIR)/.build/release/CapNs.build/*.o
	
	# Copy plugin SDK headers
	@cp Sources/FMIOPluginSDK/include/*.h $(DIST_DIR)/
	@echo "✅ FMIO Plugin SDK built successfully with cap SDK integration in $(DIST_DIR)/"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)
	cd $(CAP_SDK_DIR) && swift package clean

.PHONY: install
install: build
	@echo "Installing FMIO Plugin SDK with cap SDK..."
	sudo cp $(DIST_DIR)/libFMIOPluginSDK.a /usr/local/lib/
	sudo cp $(DIST_DIR)/*.h /usr/local/include/
	@echo "✅ FMIO Plugin SDK installed to system paths"

.PHONY: test
test: build
	@echo "Testing cap SDK..."
	cd $(CAP_SDK_DIR) && swift test
	@echo "✅ All tests passed"

.PHONY: example
example:
	@echo "Example plugin integration with formal cap SDK:"
	@echo ""
	@echo "1. Add both SDKs to your project:"
	@echo "   #import \"CapNs.h\""
	@echo "   #import \"FMIOPluginSDK.h\""
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
	@echo "   FMIOPluginManifest *pluginManifest = [[FMIOPluginManifest alloc]"
	@echo "       initWithName:@\"MyPlugin\""
	@echo "       version:@\"1.0.0\""
	@echo "       pluginDescription:@\"Example plugin\""
	@echo "       caps:caps];"