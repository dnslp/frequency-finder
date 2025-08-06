// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "FrequencyFinder",
    platforms: [
        .iOS(.v14)
    ],
    products: [],
    dependencies: [
        .package(url: "https://github.com/spotify/ios-sdk.git", from: "3.0.0")
    ],
    targets: []
)
