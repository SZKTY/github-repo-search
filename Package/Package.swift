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
        .library(name: "Home", targets: ["Home"]),
    ],
    targets: [
        // MARK: Core
        .target(
            name: "Logger",
            path: "Sources/Core/Logger"
        ),

        // MARK: Scene
        .target(
            name: "Home",
            dependencies: ["Logger"],
            path: "Sources/Scene/Home"
        ),

        // MARK: Tests
        .testTarget(
            name: "LoggerTests",
            dependencies: ["Logger"],
            path: "Tests/LoggerTests"
        ),
    ]
)
