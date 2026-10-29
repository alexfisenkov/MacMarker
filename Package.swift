// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacMarker",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MacMarker", targets: ["MacMarker"])],
    targets: [.executableTarget(name: "MacMarker")],
    swiftLanguageVersions: [.v5]
)
