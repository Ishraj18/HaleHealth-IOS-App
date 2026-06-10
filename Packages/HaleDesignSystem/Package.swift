// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HaleDesignSystem",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HaleDesignSystem",
            targets: ["HaleDesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "HaleDesignSystem",
            resources: [
                .copy("Resources/Fonts")
            ]
        )
    ]
)
