# mobile-mediainfo

[![Platform](https://img.shields.io/badge/platform-iOS%2012.0%2B-blue.svg)](#requirements)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Use MediaInfo in iOS projects. Easy and fast.**

[MediaInfo](https://github.com/MediaArea/MediaInfo) is a convenient unified display of the most relevant technical and tag data for video and audio files.

[mobile-mediainfo](https://github.com/xwal/mobile-mediainfo) builds [MediaInfoLib](https://github.com/MediaArea/MediaInfoLib) and [ZenLib](https://github.com/MediaArea/ZenLib) into static XCFrameworks for iOS and wraps them in a `MobileMediaInfo` package you can consume with Swift Package Manager or CocoaPods.

## What's inside

| Library | Version |
|---------|---------|
| MediaInfoLib | 25.04 (upstream tag `v25.04`) |
| ZenLib | 0.4.41 (upstream tag `v0.4.41`) |

* Static libraries — no dynamic frameworks, no bitcode (Xcode 14+ dropped bitcode support).
* XCFramework slices: `ios-arm64` (devices) and `ios-arm64_x86_64-simulator` (Apple Silicon + Intel simulators).
* Deployment target: **iOS 12.0**.
* The MediaInfoLib headers are shipped with a small patch (`#include <wchar.h>`, because the C API is `wchar_t`-based) plus a `module.modulemap`, so Swift can import them directly. The umbrella header also defines `UNICODE`/`_UNICODE`, so clients get the wide-character symbols without touching their own build settings.

## Installation

### Swift Package Manager

In Xcode: **File > Add Package Dependencies…** and enter:

```text
https://github.com/xwal/mobile-mediainfo.git
```

Add the `MobileMediaInfo` product to your iOS target. Or, in a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/xwal/mobile-mediainfo.git", branch: "master")
]
```

There are no release tags yet, so pin a branch or a commit. Then:

```swift
import MobileMediaInfo
```

`MobileMediaInfo` re-exports MediaInfoLib, so `import MobileMediaInfo` is all you need.

### CocoaPods

The pod is not published on the CocoaPods trunk — install it from the repository:

```ruby
pod 'mobile-mediainfo', :git => 'https://github.com/xwal/mobile-mediainfo.git', :branch => 'master'
```

Then run `pod install`. The podspec (version `25.04`) vendors the XCFrameworks, links `Foundation`, `CoreFoundation`, `z` and `c++`, and defines `UNICODE=1` / `_UNICODE=1` for the host target.

## Usage

The wrapper exposes MediaInfo's C API as-is:

```swift
import MobileMediaInfo

let handle = MediaInfo_New()
defer { MediaInfo_Delete(handle) }

print(MobileMediaInfoPackage.version) // "25.04"
```

All strings in the C API are `wchar_t`, so a tiny bridge is handy:

```swift
private extension String {
    func withWideCharacters<Result>(_ body: (UnsafePointer<wchar_t>) -> Result) -> Result {
        let characters = unicodeScalars.map { wchar_t(bitPattern: $0.value) } + [0]
        return characters.withUnsafeBufferPointer { body($0.baseAddress!) }
    }
}

// Read the returned wchar_t* back as a Swift String (UTF-32 little endian on iOS).
func string(from pointer: UnsafePointer<wchar_t>?) -> String {
    guard let pointer else { return "" }
    return NSString(
        bytes: pointer,
        length: wcslen(pointer) * MemoryLayout<wchar_t>.size,
        encoding: String.Encoding.utf32LittleEndian.rawValue
    ) as String? ?? ""
}
```

Generating a report from a file you picked with `UIDocumentPicker` / `.fileImporter` (security-scoped URL) is best done with the buffered API — open, feed chunks, finalize:

```swift
_ = option("Inform", value: "Text")               // ask for a plain-text report
MediaInfo_Open_Buffer_Init(handle, fileSize, 0)

// feed the file in chunks
while true {
    let status = MediaInfo_Open_Buffer_Continue(handle, buffer, byteCount)
    if status & 0x08 != 0 { break }               // status 0x08 = done
    let seekOffset = MediaInfo_Open_Buffer_Continue_GoTo_Get(handle)
    if seekOffset != MediaInfo_int64u.max { ... } // jump and MediaInfo_Open_Buffer_Init again
}

MediaInfo_Open_Buffer_Finalize(handle)
let report = string(from: MediaInfo_Inform(handle, 0))
```

For a plain file path you already have access to, `MediaInfo_Open(handle, widePath)` works too. A complete, runnable version of the buffered reader lives in [`Example-SPM/MobileMediaInfoDemo/MediaInfoReader.swift`](Example-SPM/MobileMediaInfoDemo/MediaInfoReader.swift).

## Example

* **CocoaPods demo** — `cd Example && pod install`, then open `Example/mobile-mediainfo.xcworkspace` and run the `mobile-mediainfo-Example` scheme. The Example project builds against the pod from `../` and targets iOS 16.
* **Swift Package demo** — open `Example-SPM/MobileMediaInfoDemo.xcodeproj` directly in Xcode and run the `MobileMediaInfoDemo` scheme (SwiftUI, iOS 16+). It references the package in the repository root, so no CocoaPods needed.

## Building the XCFrameworks from source

```sh
make             # = make all: ZenLib + MediaInfoLib -> mobile-mediainfo/Frameworks/*.xcframework
make verify      # prints the slices and their architectures
make clean       # cleans the per-architecture build trees
make distclean   # also removes the downloaded sources and the frameworks
```

`make` does the following:

1. downloads the upstream sources (`MediaArea/ZenLib@v0.4.41`, `MediaArea/MediaInfoLib@v25.04`) and runs their `autogen.sh`;
2. configures and builds a static library for each architecture against the iphoneos / iphonesimulator SDK (`make zenlib-ios-arm64`, `make mediainfo-sim-x86_64`, …);
3. `lipo`-merges the two simulator libraries and calls `xcodebuild -create-xcframework`;
4. patches `MediaInfoDLL_Static.h` (`#include <wchar.h>`) and writes a `module.modulemap` into each slice.

Updating to another version of the libraries only means changing the four variables at the top of the Makefile:

```make
MEDIAINFO_NAME     := MediaInfoLib-25.04
MEDIAINFO_SRC_NAME := v25.04
ZEN_NAME           := ZenLib-0.4.41
ZEN_SRC_NAME       := v0.4.41
```

Requirements for building: macOS with the Xcode command line tools, `autoconf` / `automake` / `libtool`, and `curl`. Cloning the repository needs **Git LFS**, since the built `.a` files are stored through it.

## Requirements

* iOS 12.0+
* Swift tools 5.7 or newer (`swift-tools-version: 5.7`) for the Swift Package

## Author

xwal, chaosky.me@gmail.com

## License

mobile-mediainfo is available under the MIT license. See the LICENSE file for more info.
