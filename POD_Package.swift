// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "${POD_NAME}",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
    ],
    products: [
        .library(
            name: "${POD_NAME}",
            targets: ["${POD_NAME}"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "${POD_NAME}",
            dependencies: [],
            path: "${POD_NAME}/Classes",
            exclude: []),
    ]
)
