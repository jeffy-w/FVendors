// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FVendors",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .watchOS(.v26),
    ],
    products: [
        // UI Utilities
        .library(
            name: "FVendorsExt",
            targets: ["FVendorsExt"]),
        // Dependency Clients
        .library(
            name: "FVendors",
    ],
    dependencies: [
        .package(
            url: "https://github.com/Alamofire/Alamofire",
            from: "5.10.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-custom-dump",
            exact: "1.3.3"
        ),
        .package(
            url: "https://github.com/apple/swift-log",
            from: "1.6.0"
        ),
            targets: ["FVendors"])
    ],
    dependencies: [
    
    ],
    targets: [
        // MARK: - UI Utilities
        .target(
            name: "FVendorsExt",
            path: "Sources/FVendorsExt"
        ),

        // MARK: - Dependency Clients (single import)
        .target(
            name: "FVendors",
            dependencies: [
                "FVendorsClientsLive",
                "FVendorsClients",
                "FVendorsModels",
            ]
        ),

        // MARK: - Models
        .target(
            name: "FVendorsModels",
            dependencies: []
        ),
        .testTarget(
            name: "FVendorsModelsTests",
            dependencies: [
                "FVendorsModels",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),

        // MARK: - Clients
        .target(
            name: "FVendorsClients",
            dependencies: ["FVendorsModels"]
        ),
        .testTarget(
            name: "FVendorsClientsTests",
            dependencies: [
                "FVendorsClients",
                "FVendorsClientsLive",
                "FVendorsModels",
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),

        // MARK: - Live Implementations
        .target(
            name: "FVendorsClientsLive",
            dependencies: [
                "FVendorsClients",
                "FVendorsModels",
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),

    ]
)
