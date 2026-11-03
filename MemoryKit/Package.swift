// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MemoryKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "MemoryKit", targets: ["MemoryKit"])],
    targets: [
        .target(name: "MemoryKit"),
        .testTarget(name: "MemoryKitTests", dependencies: ["MemoryKit"], resources: [.copy("Resources")]),
    ]
)
