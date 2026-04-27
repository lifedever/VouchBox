// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VouchBox",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "vouchbox", targets: ["VouchBoxCLI"]),
        .executable(name: "VouchBoxApp", targets: ["VouchBox"]),
        .executable(name: "com.lifedever.vouchbox.helper", targets: ["VouchBoxHelper"]),
        .library(name: "VouchBoxCore", targets: ["VouchBoxCore"]),
        .library(name: "SignKit", targets: ["SignKit"]),
        .library(name: "ManifestKit", targets: ["ManifestKit"]),
        .library(name: "InstallKit", targets: ["InstallKit"]),
        .library(name: "HelperProtocol", targets: ["HelperProtocol"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(name: "VouchBoxCore"),
        .target(name: "SignKit", dependencies: ["VouchBoxCore"]),
        .target(name: "ManifestKit", dependencies: ["VouchBoxCore"]),
        .target(name: "HelperProtocol", dependencies: ["VouchBoxCore"]),
        .target(name: "InstallKit", dependencies: ["VouchBoxCore", "SignKit", "ManifestKit", "HelperProtocol"]),
        .executableTarget(
            name: "VouchBoxHelper",
            dependencies: ["VouchBoxCore", "SignKit", "HelperProtocol"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "VouchBoxCLI",
            dependencies: [
                "InstallKit",
                "ManifestKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "VouchBox",
            dependencies: ["InstallKit", "ManifestKit", "VouchBoxCore"]
        ),
        .testTarget(name: "VouchBoxCoreTests", dependencies: ["VouchBoxCore"]),
        .testTarget(name: "SignKitTests", dependencies: ["SignKit"]),
        .testTarget(name: "ManifestKitTests", dependencies: ["ManifestKit"]),
        .testTarget(name: "InstallKitTests", dependencies: ["InstallKit"]),
    ]
)
