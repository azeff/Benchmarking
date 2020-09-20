// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Benchmarking",
    products: [
        .library(name: "Benchmarking", targets: ["Benchmarking", "BenchmarkIPC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.1"),
    ],
    targets: [
        .target(name: "BenchmarkIPC", path: "BenchmarkIPC"),
        .target(
            name: "Benchmarking",
            dependencies: [
                "BenchmarkIPC",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Benchmarking"),
    ],
    swiftLanguageVersions: [.v5]
)
