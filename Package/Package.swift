// swift-tools-version: 6.0
import PackageDescription

// レイヤー構成:
//   Scene (画面) → Core (ロジック・モデル)
// Scene同士は依存させない。画面間の遷移はAppシェル側で合成する。

let package = Package(
    name: "GitHubRepoSearch",
    defaultLocalization: "ja",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Logger", targets: ["Logger"]),
        .library(name: "Entity", targets: ["Entity"]),
        .library(name: "APIClient", targets: ["APIClient"]),
        .library(name: "Home", targets: ["Home"]),
        .library(name: "RepositorySearch", targets: ["RepositorySearch"]),
    ],
    targets: [
        // MARK: Core
        .target(
            name: "Logger",
            path: "Sources/Core/Logger"
        ),
        .target(
            name: "Entity",
            path: "Sources/Core/Entity"
        ),
        .target(
            name: "APIClient",
            dependencies: ["Entity"],
            path: "Sources/Core/APIClient"
        ),

        // MARK: Scene
        .target(
            name: "Home",
            dependencies: ["Logger"],
            path: "Sources/Scene/Home"
        ),
        .target(
            name: "RepositorySearch",
            dependencies: ["Entity", "APIClient"],
            path: "Sources/Scene/RepositorySearch"
        ),

        // MARK: Tests
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"],
            path: "Tests/LoggerTests"
        ),
        .testTarget(
            name: "APIClientTests",
            dependencies: ["APIClient", "Entity"],
            path: "Tests/APIClientTests",
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
