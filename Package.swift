// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "mobile-mediainfo",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "MobileMediaInfo",
            targets: ["MobileMediaInfo"]
        )
    ],
    targets: [
        .target(
            name: "MobileMediaInfo",
            dependencies: [
                "MediaInfoLib",
                "ZenLib"
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("CoreFoundation"),
                .linkedLibrary("c++"),
                .linkedLibrary("z")
            ]
        ),
        .binaryTarget(
            name: "MediaInfoLib",
            path: "mobile-mediainfo/Frameworks/MediaInfoLib.xcframework"
        ),
        .binaryTarget(
            name: "ZenLib",
            path: "mobile-mediainfo/Frameworks/ZenLib.xcframework"
        )
    ],
    cxxLanguageStandard: .cxx11
)
