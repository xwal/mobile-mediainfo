MEDIAINFO_NAME     	:= MediaInfoLib-24.06
MEDIAINFO_SRC_NAME 	:= v24.06
ZEN_NAME   			:= ZenLib-master
ZEN_SRC_NAME       	:= master

SDK_IPHONEOS_PATH=$(shell xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
XCODE_DEVELOPER_PATH="`xcode-select -p`"
XCODETOOLCHAIN_PATH=$(XCODE_DEVELOPER_PATH)/Toolchains/XcodeDefault.xctoolchain
IOS_DEPLOY_TGT="8.0"

MOBILE_MEDIAINFO_SRC = $(shell pwd)
MEDIAINFO_SRC = $(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Project/GNU/Library
ZEN_SRC = $(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Project/GNU/Library

MOBILE_MEDIAINFO_LIB_DIR = $(shell pwd)/mobile-mediainfo/lib/
MOBILE_MEDIAINFO_INC_DIR = $(shell pwd)/mobile-mediainfo/include/
MOBILE_MEDIAINFO_FRAMEWORK_DIR = $(shell pwd)/mobile-mediainfo/Frameworks/

libmediainfofiles = libmediainfo.a
libzenfiles = libzen.a

sdks = $(SDK_IPHONEOS_PATH) $(SDK_IPHONESIMULATOR_PATH) 
archs_all = arm64 x86_64 
arch_names_all = aarch64-apple-ios x86_64-apple-ios
targets_all = aarch64-apple-ios x86_64-apple-ios-simulator
arch_names = $(foreach arch, $(ARCHS), $(call swap, $(arch), $(archs_all), $(arch_names_all) ) )
ARCHS ?= $(archs_all)

libmediainfofolders  = $(foreach arch, $(arch_names), $(MEDIAINFO_SRC)/$(arch)/)
libzenfolders = $(foreach arch, $(arch_names), $(ZEN_SRC)/$(arch)/)

libmediainfofolders_all  = $(foreach arch, $(arch_names_all), $(MEDIAINFO_SRC)/$(arch)/)
libzenfolders_all = $(foreach arch, $(arch_names_all), $(ZEN_SRC)/$(arch)/)

libmediainfomakefile  = $(foreach folder, $(libmediainfofolders), $(addprefix $(folder), Makefile) )
libzenmakefile = $(foreach folder, $(libzenfolders), $(addprefix $(folder), Makefile) )

libmediainfofat  = $(addprefix $(MOBILE_MEDIAINFO_LIB_DIR), $(libmediainfofiles))
libzenfat = $(addprefix $(MOBILE_MEDIAINFO_LIB_DIR), $(libzenfiles))

libmediainfo  = $(foreach folder, $(libmediainfofolders), $(addprefix $(folder)/lib/, $(libmediainfofiles)) )
libzen = $(foreach folder, $(libzenfolders), $(addprefix $(folder)/lib/, $(libzenfiles)) )

libmediainfoautogen = $(MEDIAINFO_SRC)/autogen.sh
libmediainfoconfig  = $(MEDIAINFO_SRC)/configure
libzenautogen = $(ZEN_SRC)/autogen.sh
libzenconfig = $(ZEN_SRC)/configure

index = $(words $(shell a="$(2)";echo $${a/$(1)*/$(1)} ))
swap  = $(word $(call index,$(1),$(2)),$(3))

dependant_libs = libzen libmediainfo

.PHONY : all
all : $(dependant_libs)

libmediainfo : $(libmediainfofat)

$(libmediainfofat) : $(libmediainfo)
	mkdir -p $(@D)
	xcrun lipo $(realpath $(addsuffix lib/$(@F), $(libmediainfofolders_all)) ) -create -output $@
	mkdir -p $(MOBILE_MEDIAINFO_INC_DIR)
	cp -rvf $(firstword $(libmediainfofolders))/include/* $(MOBILE_MEDIAINFO_INC_DIR)
	xcrun xcodebuild -create-xcframework \
	$(foreach dir, $(libmediainfofolders_all), \
		-library $(addsuffix lib/$(@F), $(dir)) -headers $(addsuffix include, $(dir)) ) \
    -output $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/MediaInfoLib.xcframework

$(libmediainfo) :  $(libmediainfomakefile)
	cd $(abspath $(@D)/..) ; \
	$(MAKE) -sj8 && $(MAKE) clean && $(MAKE) install

$(MEDIAINFO_SRC)/%/Makefile : $(libmediainfoautogen)
	export PKG_CONFIG_PATH="$(ZEN_SRC)/$*/lib/pkgconfig:$$PKG_CONFIG_PATH"; \
	export SDKROOT="$(call swap, $*, $(arch_names_all), $(sdks))" ; \
	export CFLAGS="-Qunused-arguments -arch $(call swap, $*, $(arch_names_all), $(archs_all)) -pipe -no-cpp-precomp -isysroot $$SDKROOT -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 -fembed-bitcode -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/tinyxml2 -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/aes-gladman -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/md5 -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/sha1-gladman -I$(MOBILE_MEDIAINFO_SRC)/$(MEDIAINFO_NAME)/Source/ThirdParty/sha2-gladman" ; \
	export CPPFLAGS=$$CFLAGS ; \
	export CXXFLAGS="$$CFLAGS -Wno-deprecated-register"; \
	mkdir -p $(@D) ; \
	cd $(@D) ; \
	../configure --host=$* --enable-fast-install --prefix=`pwd` --enable-static --enable-arch-$(call swap, $*, $(arch_names_all), $(archs_all)) --target=$(call swap, $*, $(arch_names_all), $(targets_all))

$(libmediainfoautogen): $(libmediainfoconfig)
	cd $(@D) && ./autogen.sh 2> /dev/null

libzen : $(libzenfat)

$(libzenfat) : $(libzen)
	mkdir -p $(@D)
	xcrun lipo $(realpath $(addsuffix lib/$(@F), $(libzenfolders_all)) ) -create -output $@
	mkdir -p $(MOBILE_MEDIAINFO_INC_DIR)
	cp -rvf $(firstword $(libzenfolders))/include/* $(MOBILE_MEDIAINFO_INC_DIR)
	xcrun xcodebuild -create-xcframework \
	$(foreach dir, $(libzenfolders_all), \
		-library $(addsuffix lib/$(@F), $(dir)) -headers $(addsuffix include, $(dir)) ) \
    -output $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)/ZenLib.xcframework

$(libzen) : $(libzenmakefile)
	cd $(abspath $(@D)/..) ; \
	$(MAKE) -sj8 && $(MAKE) clean && $(MAKE) install

$(ZEN_SRC)/%/Makefile : $(libzenautogen)
	export SDKROOT="$(call swap, $*, $(arch_names_all), $(sdks))" ; \
	export CFLAGS="-Qunused-arguments -arch $(call swap, $*, $(arch_names_all), $(archs_all)) -pipe -no-cpp-precomp -isysroot $$SDKROOT -miphoneos-version-min=$(IOS_DEPLOY_TGT) -O2 -fembed-bitcode -I$(MOBILE_MEDIAINFO_SRC)/$(ZEN_NAME)/Source" ; \
	export CPPFLAGS=$$CFLAGS ; \
	export CXXFLAGS="$$CFLAGS -Wno-deprecated-register"; \
	export LDFLAGS=$$CFLAGS; \
	mkdir -p $(@D) ; \
	cd $(@D) ; \
	../configure --host=$* --enable-fast-install --prefix=`pwd` --enable-static --enable-arch-$(call swap, $*, $(arch_names_all), $(archs_all)) --target=$(call swap, $*, $(arch_names_all), $(targets_all))

$(libzenautogen): $(libzenconfig)
	cd $(@D) && ./autogen.sh 2> /dev/null

#######################
# Download sources
#######################
$(libmediainfoconfig) :
	curl -L https://github.com/MediaArea/MediaInfoLib/archive/$(MEDIAINFO_SRC_NAME).tar.gz | tar -xpf-

$(libzenconfig) :
	curl -L https://github.com/MediaArea/ZenLib/archive/$(ZEN_SRC_NAME).tar.gz | tar -xpf-

#######################
# Clean
#######################
.PHONY : clean
clean : cleanmediainfo cleanzen

.PHONY : cleanmediainfo
cleanmediainfo :
	for folder in $(realpath $(libmediainfofolders_all) ); do \
        cd $$folder; \
        $(MAKE) clean; \
	done

.PHONY : cleanzen
cleanzen :
	for folder in $(realpath $(libzenfolders_all) ); do \
        cd $$folder; \
        $(MAKE) clean; \
	done

.PHONY : mostlyclean
mostlyclean : mostlycleanmediainfo mostlycleanzen

.PHONY : mostlycleanmediainfo
mostlycleanmediainfo :
	for folder in $(realpath $(libmediainfofolders_all) ); do \
        cd $$folder; \
        $(MAKE) mostlyclean; \
    done

.PHONY : mostlycleanzen
mostlycleanzen :
	for folder in $(realpath $(libzenfolders_all) ); do \
        cd $$folder; \
        $(MAKE) mostlyclean; \
	done

.PHONY : distclean
distclean :
	-rm -rf $(MOBILE_MEDIAINFO_FRAMEWORK_DIR)
	-rm -rf $(MOBILE_MEDIAINFO_LIB_DIR)
	-rm -rf $(MOBILE_MEDIAINFO_INC_DIR)
	-rm -rf $(MEDIAINFO_SRC)
	-rm -rf $(ZEN_SRC)