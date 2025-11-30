// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LemonMath",
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
            path: "LemonMath"),
        .testTarget(
            name: "LemonMathTests",
            dependencies: ["LemonMath"],
            path: "LemonMathTests"),
    ]
)
