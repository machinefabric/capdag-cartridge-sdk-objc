# Makefile for LBVR Plugin SDK Objective-C
# This SDK now depends on capability-sdk-objc for formal capability management

# Directories
CAPABILITY_SDK_DIR = ../capability-sdk-objc
BUILD_DIR = build
DIST_DIR = dist

help:
	@echo "Usage: make <target>\n\n\
	  build\t\tBuild the LBVR Plugin SDK with capability SDK integration\n\
	  build-capability-sdk\tBuild only the capability SDK\n\
	  clean\t\tRemove built artifacts\n\
	  install\tInstall the library to system paths\n\
	  test\t\tRun tests for both SDKs\n\
	  example\tShow example usage\n\
	"

# Build both the capability SDK and the plugin SDK
.PHONY: build
build: build-capability-sdk build-plugin-sdk

.PHONY: build-capability-sdk
build-capability-sdk:
	@echo "Building capability-sdk-objc..."
	cd $(CAPABILITY_SDK_DIR) && swift build -c release

.PHONY: build-plugin-sdk
build-plugin-sdk: build-capability-sdk
	@echo "Building lbvr-plugin-sdk-objc..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(DIST_DIR)
	
	# Copy capability SDK headers
	@cp -r $(CAPABILITY_SDK_DIR)/Sources/CapabilitySDK/include/* $(DIST_DIR)/
	
	# Compile our plugin SDK with capability SDK integration
	clang -c -o $(BUILD_DIR)/LBVRPluginSDK.o LBVRPluginSDK.m \
		-I$(DIST_DIR) \
		-I$(CAPABILITY_SDK_DIR)/Sources/CapabilitySDK/include \
		-fobjc-arc -fmodules
	
	# Create static library
	ar rcs $(DIST_DIR)/libLBVRPluginSDK.a $(BUILD_DIR)/LBVRPluginSDK.o
	
	# Copy plugin SDK headers
	@cp LBVRPluginSDK.h $(DIST_DIR)/
	@echo "✅ LBVR Plugin SDK built successfully with capability SDK integration in $(DIST_DIR)/"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)
	cd $(CAPABILITY_SDK_DIR) && swift package clean

.PHONY: install
install: build
	@echo "Installing LBVR Plugin SDK with capability SDK..."
	sudo cp $(DIST_DIR)/libLBVRPluginSDK.a /usr/local/lib/
	sudo cp $(DIST_DIR)/*.h /usr/local/include/
	@echo "✅ LBVR Plugin SDK installed to system paths"

.PHONY: test
test: build
	@echo "Testing capability SDK..."
	cd $(CAPABILITY_SDK_DIR) && swift test
	@echo "✅ All tests passed"

.PHONY: example
example:
	@echo "Example plugin integration with formal capability SDK:"
	@echo ""
	@echo "1. Add both SDKs to your project:"
	@echo "   #import \"CapabilitySDK.h\""
	@echo "   #import \"LBVRPluginSDK.h\""
	@echo ""
	@echo "2. Create formal capability definitions:"
	@echo "   NSError *error;"
	@echo "   CSCapabilityId *capId = [CSCapabilityId fromString:@\"extract-metadata:pdf\" error:&error];"
	@echo "   CSCapability *capability = [CSCapability capabilityWithId:capId version:@\"1.0.0\"];"
	@echo ""
	@echo "3. Build plugin capabilities collection:"
	@echo "   CSPluginCapabilities *capabilities = [CSPluginCapabilities new];"
	@echo "   [capabilities addCapability:capability];"
	@echo ""
	@echo "4. Create plugin info with formal capabilities:"
	@echo "   LBVRPluginInfo *pluginInfo = [[LBVRPluginInfo alloc]"
	@echo "       initWithName:@\"MyPlugin\""
	@echo "       version:@\"1.0.0\""
	@echo "       pluginDescription:@\"Example plugin\""
	@echo "       capabilities:capabilities];"