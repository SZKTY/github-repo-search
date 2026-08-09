import os

/// アプリ共通のロガー
public enum AppLogger {
    private static let logger = os.Logger(subsystem: "com.szkty.GitHubRepoSearch", category: "app")

    public static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
