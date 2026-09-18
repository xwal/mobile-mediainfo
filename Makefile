MEDIAINFO_NAME     	:= MediaInfoLib-25.04
MEDIAINFO_SRC_NAME 	:= v25.04
ZEN_NAME   			:= ZenLib-0.4.41
ZEN_SRC_NAME       	:= v0.4.41

SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
IOS_DEPLOY_TGT="12.0"

MOBILE_MEDIAINFO_SRC = $(shell pwd)
MEDIAINFO_SRC = $(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Project/GNU/Library
ZEN_SRC = $(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Project/GNU/Library

MOBILE_MEDIAINFO_FRAMEWORK_DIR = $(shell pwd)/mobile-mediainfo/Frameworks/

# MediaInfoLib ThirdParty include paths
MEDIAINFO_THIRDPARTY_INCLUDES = -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source \
	-I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/tinyxml2 \
	-I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/aes-gladman \
	-I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/md5 \
	-I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/sha1-gladman \
	-I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/sha2-gladman

libmediainfofiles = libmediainfo.a
libzenfiles = libzen.a

# Build folder names
FOLDER_IOS_ARM64 = ios-arm64
FOLDER_SIM_ARM64 = sim-arm64
FOLDER_SIM_X64 = sim-x86_64

.PHONY : all
all : libzen libmediainfo
	@echo "✅ Build complete! XCFrameworks are in: $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)"

#######################
# ZenLib XCFramework
#######################
.PHONY : libzen
libzen : $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/ZenLib.xcframework

$(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/ZenLib.xcframework : zenlib-ios-arm64 zenlib-sim-arm64 zenlib-sim-x86_64
	@echo "📦 Creating ZenLib.xcframework..."
	rm -rf $@
	@# Merge simulator libs into fat library (arm64 + x86_64)
	mkdir -p $(ZEN_SRC)/sim-universal/lib
	cp -r $(ZEN_SRC)/$(FOLDER_SIM_ARM64)/include $(ZEN_SRC)/sim-universal/
	xcrun lipo -create \
		$(ZEN_SRC)/$(FOLDER_SIM_ARM64)/lib/$(libzenfiles) \
		$(ZEN_SRC)/$(FOLDER_SIM_X64)/lib/$(libzenfiles) \
		-output $(ZEN_SRC)/sim-universal/lib/$(libzenfiles)
	xcrun xcodebuild -create-xcframework \
		-library $(ZEN_SRC)/$(FOLDER_IOS_ARM64)/lib/$(libzenfiles) \
		-headers $(ZEN_SRC)/$(FOLDER_IOS_ARM64)/include \
		-library $(ZEN_SRC)/sim-universal/lib/$(libzenfiles) \
		-headers $(ZEN_SRC)/sim-universal/include \
		-output $@
	@echo "✅ ZenLib.xcframework created"

# Download and prepare ZenLib
.PHONY : zenlib-prepare
zenlib-prepare :
	@if [ ! -f "$(ZEN_SRC)/configure" ]; then \
		echo "📥 Downloading ZenLib..."; \
		curl -L https://github.com/MediaArea/ZenLib/archive/$(ZEN_SRC_NAME).tar.gz | tar -xpf-; \
		echo "🔧 Running autogen.sh..."; \
		cd $(ZEN_SRC) && ./autogen.sh; \
	fi

# ZenLib iOS arm64
.PHONY : zenlib-ios-arm64
zenlib-ios-arm64 : zenlib-prepare
	@echo "🔨 Building ZenLib for ios-arm64..."
	@# Clean source to avoid cross-contamination
	find $(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source -name "*.o" -delete 2>/dev/null || true
	find $(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source -name "*.lo" -delete 2>/dev/null || true
	find $(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source -type d -name ".libs" -exec rm -rf {} + 2>/dev/null || true
	rm -rf $(ZEN_SRC)/$(FOLDER_IOS_ARM64)
	mkdir -p $(ZEN_SRC)/$(FOLDER_IOS_ARM64)
	cd $(ZEN_SRC)/$(FOLDER_IOS_ARM64) && \
	SDKROOT="$(SDK_IPHONEOS_PATH)" \
	CFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONEOS_PATH) -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" \
	CPPFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONEOS_PATH) -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" \
	CXXFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONEOS_PATH) -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source -Wno-deprecated-register" \
	LDFLAGS="-arch arm64 -isysroot $(SDK_IPHONEOS_PATH)" \
	../configure --host=aarch64-apple-darwin --prefix=$(ZEN_SRC)/$(FOLDER_IOS_ARM64) --enable-static --disable-shared
	cd $(ZEN_SRC)/$(FOLDER_IOS_ARM64) && $(MAKE) -j8 && $(MAKE) install
	@echo "✅ ZenLib ios-arm64 done"

# ZenLib Simulator arm64 (Apple Silicon)
.PHONY : zenlib-sim-arm64
zenlib-sim-arm64 : zenlib-ios-arm64
	@echo "🔨 Building ZenLib for sim-arm64..."
	@# Clean previous build to clear shared Source/.libs directory
	-cd $(ZEN_SRC)/$(FOLDER_IOS_ARM64) && $(MAKE) clean 2>/dev/null || true
	rm -rf $(ZEN_SRC)/$(FOLDER_SIM_ARM64)
	mkdir -p $(ZEN_SRC)/$(FOLDER_SIM_ARM64)
	cd $(ZEN_SRC)/$(FOLDER_SIM_ARM64) && \
	SDKROOT="$(SDK_IPHONESIMULATOR_PATH)" \
	CFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" \
	CPPFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" \
	CXXFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source -Wno-deprecated-register" \
	LDFLAGS="-arch arm64 -isysroot $(SDK_IPHONESIMULATOR_PATH)" \
	../configure --host=aarch64-apple-darwin --prefix=$(ZEN_SRC)/$(FOLDER_SIM_ARM64) --enable-static --disable-shared
	cd $(ZEN_SRC)/$(FOLDER_SIM_ARM64) && $(MAKE) -j8 && $(MAKE) install
	@echo "✅ ZenLib sim-arm64 done"

# ZenLib Simulator x86_64 (Intel)
.PHONY : zenlib-sim-x86_64
zenlib-sim-x86_64 : zenlib-sim-arm64
	@echo "🔨 Building ZenLib for sim-x86_64..."
	@# Clean previous build to clear shared Source/.libs directory
	-cd $(ZEN_SRC)/$(FOLDER_SIM_ARM64) && $(MAKE) clean 2>/dev/null || true
	rm -rf $(ZEN_SRC)/$(FOLDER_SIM_X64)
	mkdir -p $(ZEN_SRC)/$(FOLDER_SIM_X64)
	cd $(ZEN_SRC)/$(FOLDER_SIM_X64) && \
	SDKROOT="$(SDK_IPHONESIMULATOR_PATH)" \
	CFLAGS="-Qunused-arguments -arch x86_64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" \
	CPPFLAGS="-Qunused-arguments -arch x86_64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" \
	CXXFLAGS="-Qunused-arguments -arch x86_64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source -Wno-deprecated-register" \
	LDFLAGS="-arch x86_64 -isysroot $(SDK_IPHONESIMULATOR_PATH)" \
	../configure --host=x86_64-apple-darwin --prefix=$(ZEN_SRC)/$(FOLDER_SIM_X64) --enable-static --disable-shared
	cd $(ZEN_SRC)/$(FOLDER_SIM_X64) && $(MAKE) -j8 && $(MAKE) install
	@echo "✅ ZenLib sim-x86_64 done"

#######################
# MediaInfoLib XCFramework
#######################
.PHONY : libmediainfo
libmediainfo : $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/MediaInfoLib.xcframework

$(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/MediaInfoLib.xcframework : mediainfo-ios-arm64 mediainfo-sim-arm64 mediainfo-sim-x86_64
	@echo "📦 Creating MediaInfoLib.xcframework..."
	rm -rf $@
	mkdir -p $(MEDIAINFO_SRC)/sim-universal/lib
	cp -r $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64)/include $(MEDIAINFO_SRC)/sim-universal/
	
	@# Patch headers to include wchar.h for Swift/C compatibility (fixes 'Unknown type name wchar_t')
	@echo "🔧 Patching headers to include wchar.h..."
	sed -i '' 's/#include <limits.h>/#include <limits.h>\n#include <wchar.h>/' $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64)/include/MediaInfoDLL/MediaInfoDLL_Static.h
	sed -i '' 's/#include <limits.h>/#include <limits.h>\n#include <wchar.h>/' $(MEDIAINFO_SRC)/sim-universal/include/MediaInfoDLL/MediaInfoDLL_Static.h

	xcrun lipo -create \
		$(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64)/lib/$(libmediainfofiles) \
		$(MEDIAINFO_SRC)/$(FOLDER_SIM_X64)/lib/$(libmediainfofiles) \
		-output $(MEDIAINFO_SRC)/sim-universal/lib/$(libmediainfofiles)
	xcrun xcodebuild -create-xcframework \
		-library $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64)/lib/$(libmediainfofiles) \
		-headers $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64)/include \
		-library $(MEDIAINFO_SRC)/sim-universal/lib/$(libmediainfofiles) \
		-headers $(MEDIAINFO_SRC)/sim-universal/include \
		-output $@
	@# Create module.modulemap for Swift import support
	@echo 'module MediaInfoLib { header "MediaInfoDLL/MediaInfoDLL_Static.h" export * }' > $@/ios-arm64/Headers/module.modulemap
	@echo 'module MediaInfoLib { header "MediaInfoDLL/MediaInfoDLL_Static.h" export * }' > $@/ios-arm64_x86_64-simulator/Headers/module.modulemap
	@echo "✅ MediaInfoLib.xcframework created"

# Download and prepare MediaInfoLib
.PHONY : mediainfo-prepare
mediainfo-prepare : libzen
	@if [ ! -f "$(MEDIAINFO_SRC)/configure" ]; then \
		echo "📥 Downloading MediaInfoLib..."; \
		curl -L https://github.com/MediaArea/MediaInfoLib/archive/$(MEDIAINFO_SRC_NAME).tar.gz | tar -xpf-; \
		echo "🔧 Running autogen.sh..."; \
		cd $(MEDIAINFO_SRC) && ./autogen.sh; \
	fi

# MediaInfoLib iOS arm64
.PHONY : mediainfo-ios-arm64
mediainfo-ios-arm64 : mediainfo-prepare
	@echo "🔨 Building MediaInfoLib for ios-arm64..."
	find $(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source -name "*.o" -delete 2>/dev/null || true
	find $(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source -name "*.lo" -delete 2>/dev/null || true
	find $(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source -type d -name ".libs" -exec rm -rf {} + 2>/dev/null || true
	rm -rf $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64)
	mkdir -p $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64)
	cd $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64) && \
	PKG_CONFIG_PATH="$(ZEN_SRC)/$(FOLDER_IOS_ARM64)/lib/pkgconfig" \
	SDKROOT="$(SDK_IPHONEOS_PATH)" \
	CFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONEOS_PATH) -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES)" \
	CPPFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONEOS_PATH) -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES)" \
	CXXFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONEOS_PATH) -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES) -Wno-deprecated-register" \
	LDFLAGS="-arch arm64 -isysroot $(SDK_IPHONEOS_PATH)" \
	../configure --host=aarch64-apple-darwin --prefix=$(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64) --enable-static --disable-shared
	cd $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64) && $(MAKE) -j8 && $(MAKE) install
	@echo "✅ MediaInfoLib ios-arm64 done"

# MediaInfoLib Simulator arm64
.PHONY : mediainfo-sim-arm64
mediainfo-sim-arm64 : mediainfo-ios-arm64
	@echo "🔨 Building MediaInfoLib for sim-arm64..."
	@# Clean previous build to clear shared Source/.libs directory
	-cd $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64) && $(MAKE) clean 2>/dev/null || true
	rm -rf $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64)
	mkdir -p $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64)
	cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64) && \
	PKG_CONFIG_PATH="$(ZEN_SRC)/$(FOLDER_SIM_ARM64)/lib/pkgconfig" \
	SDKROOT="$(SDK_IPHONESIMULATOR_PATH)" \
	CFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES)" \
	CPPFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES)" \
	CXXFLAGS="-Qunused-arguments -arch arm64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES) -Wno-deprecated-register" \
	LDFLAGS="-arch arm64 -isysroot $(SDK_IPHONESIMULATOR_PATH)" \
	../configure --host=aarch64-apple-darwin --prefix=$(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64) --enable-static --disable-shared
	cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64) && $(MAKE) -j8 && $(MAKE) install
	@echo "✅ MediaInfoLib sim-arm64 done"

# MediaInfoLib Simulator x86_64
.PHONY : mediainfo-sim-x86_64
mediainfo-sim-x86_64 : mediainfo-sim-arm64
	@echo "🔨 Building MediaInfoLib for sim-x86_64..."
	@# Clean previous build to clear shared Source/.libs directory
	-cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64) && $(MAKE) clean 2>/dev/null || true
	rm -rf $(MEDIAINFO_SRC)/$(FOLDER_SIM_X64)
	mkdir -p $(MEDIAINFO_SRC)/$(FOLDER_SIM_X64)
	cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_X64) && \
	PKG_CONFIG_PATH="$(ZEN_SRC)/$(FOLDER_SIM_X64)/lib/pkgconfig" \
	SDKROOT="$(SDK_IPHONESIMULATOR_PATH)" \
	CFLAGS="-Qunused-arguments -arch x86_64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES)" \
	CPPFLAGS="-Qunused-arguments -arch x86_64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES)" \
	CXXFLAGS="-Qunused-arguments -arch x86_64 -pipe -isysroot $(SDK_IPHONESIMULATOR_PATH) -mios-simulator-version-min=$(IOS_DEPLOY_TGT) -O2 $(MEDIAINFO_THIRDPARTY_INCLUDES) -Wno-deprecated-register" \
	LDFLAGS="-arch x86_64 -isysroot $(SDK_IPHONESIMULATOR_PATH)" \
	../configure --host=x86_64-apple-darwin --prefix=$(MEDIAINFO_SRC)/$(FOLDER_SIM_X64) --enable-static --disable-shared
	cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_X64) && $(MAKE) -j8 && $(MAKE) install
	@echo "✅ MediaInfoLib sim-x86_64 done"

#######################
# Verify XCFramework
#######################
.PHONY : verify
verify :
	@echo "🔍 Verifying XCFramework structure..."
	@echo ""
	@echo "📁 Contents of $(MOBILE_MEDIAINFO_FRAMEWORK_DIR):"
	@ls -la $(MOBILE_MEDIAINFO_FRAMEWORK_DIR) 2>/dev/null || (echo "❌ Framework directory not found! Run 'make all' first." && exit 1)
	@echo ""
	@echo "📦 ZenLib.xcframework:"
	@ls -la $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/ZenLib.xcframework/ 2>/dev/null || echo "❌ Not found"
	@echo ""
	@echo "📦 MediaInfoLib.xcframework:"
	@ls -la $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/MediaInfoLib.xcframework/ 2>/dev/null || echo "❌ Not found"
	@echo ""
	@echo "🔬 Checking architectures..."
	@for fw in $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/*.xcframework; do \
		echo "$$fw:"; \
		for dir in "$$fw"/*/; do \
			lib=$$(find "$$dir" -name "*.a" 2>/dev/null | head -1); \
			if [ -n "$$lib" ]; then \
				echo "  $$(basename $$dir): $$(lipo -info "$$lib" 2>/dev/null | cut -d: -f3)"; \
			fi; \
		done; \
	done
	@echo ""
	@echo "✅ Verification complete!"

#######################
# Clean
#######################
.PHONY : clean
clean :
	-cd $(ZEN_SRC)/$(FOLDER_IOS_ARM64) 2>/dev/null && $(MAKE) clean
	-cd $(ZEN_SRC)/$(FOLDER_SIM_ARM64) 2>/dev/null && $(MAKE) clean
	-cd $(ZEN_SRC)/$(FOLDER_SIM_X64) 2>/dev/null && $(MAKE) clean
	-cd $(MEDIAINFO_SRC)/$(FOLDER_IOS_ARM64) 2>/dev/null && $(MAKE) clean
	-cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_ARM64) 2>/dev/null && $(MAKE) clean
	-cd $(MEDIAINFO_SRC)/$(FOLDER_SIM_X64) 2>/dev/null && $(MAKE) clean

.PHONY : distclean
distclean :
	@echo "🧹 Cleaning all build artifacts..."
	-rm -rf $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)
	-rm -rf $(MEDIAINFO_NAME)
	-rm -rf $(ZEN_NAME)
	@echo "✅ Clean complete!"