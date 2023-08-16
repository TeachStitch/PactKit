// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PactKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PactKit",
            targets: ["PactKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/surpher/PactSwiftMockServer", from: "0.4.4"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "PactKit",
            dependencies: [
                .product(name: "PactSwiftMockServer", package: "PactSwiftMockServer")
            ]
        ),
        .testTarget(
            name: "PactKitTests",
            dependencies: ["PactKit"]),
    ],
    swiftLanguageVersions: [.v5]
)
