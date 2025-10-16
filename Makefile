help:
	@echo "Usage: make <target>\n\n\
	  build\t\tBuild the LBVR Plugin SDK static library\n\
	  clean\t\tRemove built artifacts\n\
	  install\tInstall the library to system paths\n\
	"

.PHONY: build
build:
	@echo "Creating dist directory..."
	@mkdir -p dist
	@echo "Building LBVR Plugin SDK static library..."
	clang -c -o dist/LBVRPluginSDK.o LBVRPluginSDK.m -framework Foundation
	ar rcs dist/libLBVRPluginSDK.a dist/LBVRPluginSDK.o
	@echo "Copying header file..."
	cp LBVRPluginSDK.h dist/
	@echo "✅ LBVR Plugin SDK built successfully in dist/"

.PHONY: clean
clean:
	rm -rf dist

.PHONY: install
install: build
	@echo "Installing LBVR Plugin SDK..."
	sudo cp dist/libLBVRPluginSDK.a /usr/local/lib/
	sudo cp dist/LBVRPluginSDK.h /usr/local/include/
	@echo "✅ LBVR Plugin SDK installed to system paths"

.PHONY: test
test: build
	@echo "Building and running SDK tests..."
	clang -o dist/test_sdk test_sdk.m dist/libLBVRPluginSDK.a -framework Foundation
	./dist/test_sdk