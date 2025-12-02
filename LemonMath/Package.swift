// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LemonMath",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LemonMath",
            targets: ["LemonMath"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "LemonMath",
            dependencies: [],
            path: "LemonMath")
    ]
)
