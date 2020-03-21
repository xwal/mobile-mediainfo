#!/bin/sh

# directories
MEDIAINFO_VERSION="19.09"
ZEN_VERSION="master"

MEDIAINFO_SOURCE="MediaInfoLib"
ZEN_SOURCE="ZenLib"

FAT="`pwd`/MediaInfo-iOS"
THIN=`pwd`/"thin"
mkdir -p $THIN

ARCHS="armv7 arm64 i386 x86_64"
DEPLOYMENT_TARGET="8.0"

if [ ! `which brew` ]
then
    echo 'Homebrew not found. Trying to install...'
                ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
        || exit 1
fi

if [ ! -r $ZEN_SOURCE ]
then
    echo 'ZenLib source not found. Trying to download...'
    curl https://codeload.github.com/MediaArea/ZenLib/tar.gz/$ZEN_VERSION | tar xj \
        || exit 1
    mv "ZenLib-$ZEN_VERSION" "$ZEN_SOURCE"
fi

if [ ! -r $MEDIAINFO_SOURCE ]
then
    echo 'MediaInfoLib source not found. Trying to download...'
    curl https://codeload.github.com/MediaArea/MediaInfoLib/tar.gz/v$MEDIAINFO_VERSION | tar xj \
        || exit 1
    mv "MediaInfoLib-$MEDIAINFO_VERSION" "$MEDIAINFO_SOURCE"
fi

CWD=`pwd`

echo "building"
cd "$CWD/$ZEN_SOURCE/Project/GNU/Library"
sh autogen.sh
cd "$CWD/$MEDIAINFO_SOURCE/Project/GNU/Library"
sh autogen.sh

echo "building i386 x86_64..."
cd "$CWD/$ZEN_SOURCE/Project/GNU/Library"
make clean
./configure --enable-static --enable-arch-i386 --enable-arch-x86_64 --with-iphoneos-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk --with-iphoneos-version-min=$DEPLOYMENT_TARGET CFLAGS="-fembed-bitcode" CXXFLAGS="-fembed-bitcode" LDFLAGS="-fembed-bitcode" --prefix=$THIN/simulator
make -j3 install || exit 1

cd "$CWD/$MEDIAINFO_SOURCE/Project/GNU/Library"
make clean
./configure --enable-static --enable-arch-i386 --enable-arch-x86_64 --with-iphoneos-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk --with-iphoneos-version-min=$DEPLOYMENT_TARGET CFLAGS="-fembed-bitcode" CXXFLAGS="-fembed-bitcode" LDFLAGS="-fembed-bitcode" --prefix=$THIN/simulator
make -j3 install || exit 1

echo "building armv7 arm64..."
cd "$CWD/$ZEN_SOURCE/Project/GNU/Library"
make clean
./configure --enable-static --enable-arch-armv7 --enable-arch-arm64 --with-iphoneos-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk --with-iphoneos-version-min=$DEPLOYMENT_TARGET CFLAGS="-fembed-bitcode" CXXFLAGS="-fembed-bitcode" LDFLAGS="-fembed-bitcode" --prefix=$THIN/embedded
make -j3 install || exit 1

cd "$CWD/$MEDIAINFO_SOURCE/Project/GNU/Library"
make clean
./configure --enable-static --enable-arch-armv7 --enable-arch-arm64 --with-iphoneos-sdk=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk --with-iphoneos-version-min=$DEPLOYMENT_TARGET CFLAGS="-fembed-bitcode" CXXFLAGS="-fembed-bitcode" LDFLAGS="-fembed-bitcode" --prefix=$THIN/embedded
make -j3 install || exit 1

echo "building fat binaries..."
mkdir -p $FAT/lib
lipo -create $THIN/embedded/lib/libzen.a $THIN/simulator/lib/libzen.a -output $FAT/lib/libzen.a
lipo -create $THIN/embedded/lib/libmediainfo.a $THIN/simulator/lib/libmediainfo.a -output $FAT/lib/libmediainfo.a
cd $CWD
cp -rf $THIN/embedded/include $FAT

echo Done
