// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WatchBox",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WatchBox", targets: ["WatchBox"])
    ],
    dependencies: [
        .package(url: "https://github.com/videolan/vlckit-spm.git", from: "3.6.0")
    ],
    targets: [
        .target(
            name: "WatchBox",
            dependencies: [
                .product(name: "MobileVLCKit", package: "vlckit-spm", condition: .when(platforms: [.iOS])),
                .product(name: "VLCKit", package: "vlckit-spm", condition: .when(platforms: [.macOS]))
            ]
        )
    ]
)
