// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrisisKit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "CrisisKit", targets: ["CrisisKit"])],
    dependencies: [
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0"),
    ],
    targets: [
        .target(name: "CrisisKit", dependencies: [.product(name: "Tokenizers", package: "swift-transformers")]),
        .testTarget(name: "CrisisKitTests", dependencies: ["CrisisKit"], resources: [.copy("Resources")]),
    ]
)
