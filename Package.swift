// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SelectAndSearchLLM",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SelectAndSearchLLM",
            targets: ["SelectAndSearchLLM"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SelectAndSearchLLM",
            path: "Sources"
        ),
        .testTarget(
            name: "SelectAndSearchLLMTests",
            dependencies: ["SelectAndSearchLLM"],
            path: "Tests"
        )
    ]
)
