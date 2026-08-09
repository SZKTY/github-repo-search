import XCTest

@testable import Logger

final class AppLoggerTests: XCTestCase {
    func testDebugDoesNotCrash() {
        AppLogger.debug("test message")
    }
}
