// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiveWallpaper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LiveWallpaper", targets: ["LiveWallpaper"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LiveWallpaper",
            dependencies: [],
            path: "Sources/LiveWallpaper"
        )
    ]
)
