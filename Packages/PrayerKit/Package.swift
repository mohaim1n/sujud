// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrayerKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PrayerKit",
            targets: ["PrayerKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PrayerKit",
            dependencies: [],
            path: "Sources/PrayerKit"
        ),
        .testTarget(
            name: "PrayerKitTests",
            dependencies: ["PrayerKit"],
            path: "Tests/PrayerKitTests"
        ),
    ]
)
