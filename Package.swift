// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Fireplace",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Fireplace",
            path: "Fireplace"
        )
    ]
)
