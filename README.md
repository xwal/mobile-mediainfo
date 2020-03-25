# mobile-mediainfo

[![CI Status](https://img.shields.io/travis/chaoskyme/mobile-mediainfo.svg?style=flat)](https://travis-ci.org/chaoskyme/mobile-mediainfo)
[![Version](https://img.shields.io/cocoapods/v/mobile-mediainfo.svg?style=flat)](https://cocoapods.org/pods/mobile-mediainfo)
[![License](https://img.shields.io/cocoapods/l/mobile-mediainfo.svg?style=flat)](https://cocoapods.org/pods/mobile-mediainfo)
[![Platform](https://img.shields.io/cocoapods/p/mobile-mediainfo.svg?style=flat)](https://cocoapods.org/pods/mobile-mediainfo)

**Use MediaInfo in iOS 8.0+ projects. Easy and fast.**

[MediaInfo](https://github.com/MediaArea/MediaInfo) is a convenient unified display of the most relevant technical and tag data for video and audio files.

[mobile-mediainfo](https://github.com/chaoskyme/mobile-mediainfo) is a Framework for iOS8+, compiled also for armv7, armv7s, arm64 , i386(Simulator) and x86_64(Simulator).

These are the current versions of the upstream bundled libraries within the framework that this repository provides:

* MediaInfoLib 19.09 ([homepage](https://github.com/MediaArea/MediaInfoLib))

* ZenLib master ([homepage](https://github.com/MediaArea/ZenLib))

**All libs are with bitcode integrated**

## Build

Creates "fat" binary libraries compatible with i386/Simulator, x86_64, arm64, armv7 and armv7s 

    make            #builds all libraries

By default every "fat" library will contain all architectures specified above. So it can be linked with apps either for devices or simulator. If you don't need all architectures above (for example, for AppStore submittion), just specify the necessary architectures in the `ARCHS` environement variable as follows:

    export ARCHS=armv7, armv7s, arm64

It's much easier now to update to a any (new or old) versions of library: just change a corresponding version numbers in the beginning of the make file:

    MEDIAINFO_NAME     	:= MediaInfoLib-19.09
    MEDIAINFO_SRC_NAME 	:= v19.09
    ZEN_NAME   			:= ZenLib-master
    ZEN_SRC_NAME       	:= master

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS 8.0+

## Installation

mobile-mediainfo is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'mobile-mediainfo', :git => 'https://github.com/SwiftGrowth/mobile-mediainfo.git'
```

## Author

chaoskyme, chaosky.me@gmail.com

## License

mobile-mediainfo is available under the MIT license. See the LICENSE file for more info.
