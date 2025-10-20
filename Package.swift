// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FVendors",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "FVendors",
            targets: ["FVendors"])
    ],
    dependencies: [
    
    ],
    targets: [
        .target(
            name: "FVendors",
            path: "Sources/FVendors"
        )
    ]
)
