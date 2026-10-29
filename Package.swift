// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacMarker",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MacMarker", targets: ["MacMarker"])],
    targets: [.executableTarget(name: "MacMarker")],
    swiftLanguageModes: [.v5]
)
