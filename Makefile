# Makefile for MACINA Cartridge SDK Objective-C
# This SDK now depends on capdag-objc for formal cap management

# Directories
CAP_SDK_DIR = ../capdag-objc
BUILD_DIR = build
DIST_DIR = dist

help:
	@echo "Usage: make <target>\n\n\
	  build\t\tBuild the MACINA Cartridge SDK with cap SDK integration\n\
	  build-capdag\tBuild only the cap SDK\n\
	  clean\t\tRemove built artifacts\n\
	  install\tInstall the library to system paths\n\
	  test\t\tRun tests for both SDKs\n\
	  example\tShow example usage\n\
	"

# Build both the cap SDK and the cartridge SDK
.PHONY: build
build: build-capdag build-cartridge-sdk

.PHONY: build-capdag
build-capdag:
	@echo "Building capdag-objc..."
	cd $(CAP_SDK_DIR) && swift build -c release

.PHONY: build-cartridge-sdk
build-cartridge-sdk: build-capdag
	@echo "Building machfab-cartridge-sdk-objc..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(DIST_DIR)
	
	# Copy cap SDK headers
	@cp -r $(CAP_SDK_DIR)/Sources/CapDAG/include/* $(DIST_DIR)/
	
	# Compile our cartridge SDK with cap SDK integration (now from Sources directory)
	/usr/bin/clang -c -o $(BUILD_DIR)/MACINACartridgeSDK.o Sources/MACINACartridgeSDK/MACINACartridgeSDK.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapDAG/include \
		-ISources/MACINACartridgeSDK/include \
		-fobjc-arc -fno-modules
	
	/usr/bin/clang -c -o $(BUILD_DIR)/MACINAStandardCaps.o Sources/MACINACartridgeSDK/MACINAStandardCaps.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapDAG/include \
		-ISources/MACINACartridgeSDK/include \
		-fobjc-arc -fno-modules
	
	/usr/bin/clang -c -o $(BUILD_DIR)/CSCartridgeCaps.o Sources/MACINACartridgeSDK/CSCartridgeCaps.m \
		-I$(DIST_DIR) \
		-I$(CAP_SDK_DIR)/Sources/CapDAG/include \
		-ISources/MACINACartridgeSDK/include \
		-fobjc-arc -fno-modules
	
	# Create static library with all object files including CapDAG
	ar rcs $(DIST_DIR)/libMACINACartridgeSDK.a $(BUILD_DIR)/*.o $(CAP_SDK_DIR)/.build/release/CapDAG.build/*.o
	
	# Copy cartridge SDK headers
	@cp Sources/MACINACartridgeSDK/include/*.h $(DIST_DIR)/
	@echo "OK MACINA Cartridge SDK built successfully with cap SDK integration in $(DIST_DIR)/"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)
	cd $(CAP_SDK_DIR) && swift package clean

.PHONY: install
install: build
	@echo "Installing MACINA Cartridge SDK with cap SDK..."
	sudo cp $(DIST_DIR)/libMACINACartridgeSDK.a /usr/local/lib/
	sudo cp $(DIST_DIR)/*.h /usr/local/include/
	@echo "OK MACINA Cartridge SDK installed to system paths"

.PHONY: test
test: build
	@echo "Testing cap SDK..."
	cd $(CAP_SDK_DIR) && swift test
	@echo "OK All tests passed"

.PHONY: example
example:
	@echo "Example cartridge integration with formal cap SDK:"
	@echo ""
	@echo "1. Add both SDKs to your project:"
	@echo "   #import \"CapDAG.h\""
	@echo "   #import \"MACINACartridgeSDK.h\""
	@echo ""
	@echo "2. Create formal cap definitions:"
	@echo "   NSError *error;"
	@echo "   CSCapUrn *capId = [CSCapUrn fromString:@\"extract-metadata:pdf\" error:&error];"
	@echo "   CSCap *cap = [CSCap capWithUrn:capId version:@\"1.0.0\"];";
	@echo ""
	@echo "3. Build cartridge caps collection:"
	@echo "   CSCartridgeCaps *caps = [CSCartridgeCaps new];"
	@echo "   [caps addCap:cap];"
	@echo ""
	@echo "4. Create cartridge manifest with formal caps:"
	@echo "   MACINACartridgeManifest *cartridgeManifest = [[MACINACartridgeManifest alloc]"
	@echo "       initWithName:@\"MyCartridge\""
	@echo "       version:@\"1.0.0\""
	@echo "       cartridgeDescription:@\"Example cartridge\""
	@echo "       caps:caps];"