import Entity
import XCTest
import os

@testable import APIClient

final class GitHubAPIClientTests: XCTestCase {
    private var client: GitHubAPIClient?

    override func setUp() {
        super.setUp()
        client = GitHubAPIClient(session: StubURLProtocol.makeSession())
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        client = nil
        super.tearDown()
    }

    // MARK: - リクエスト検証

    func testSearchはクエリとページ番号を含む正しいリクエストを送る() async throws {
        let requestBox = OSAllocatedUnfairLock<URLRequest?>(initialState: nil)
        StubURLProtocol.handler = { request in
            requestBox.withLock { $0 = request }
            return (Self.okResponse(for: request), Self.fixtureData())
        }

        _ = try await XCTUnwrap(client).search(query: "swift kit", page: 2)

        let request = try XCTUnwrap(requestBox.withLock { $0 })
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.host, "api.github.com")
        XCTAssertEqual(components.path, "/search/repositories")

        let queryItems = try XCTUnwrap(components.queryItems)
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "q", value: "swift kit")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page", value: "2")))
        XCTAssertTrue(queryItems.contains(URLQueryItem(name: "per_page", value: "30")))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
    }

    // MARK: - デコード

    func testSearchは200レスポンスをデコードして返す() async throws {
        StubURLProtocol.handler = { request in
            (Self.okResponse(for: request), Self.fixtureData())
        }

        let response = try await XCTUnwrap(client).search(query: "swift", page: 1)

        XCTAssertEqual(response.totalCount, 3_211_364)
        XCTAssertFalse(response.incompleteResults)
        XCTAssertEqual(response.items.count, 3)

        let first = try XCTUnwrap(response.items.first)
        XCTAssertEqual(first.id, 44_838_949)
        XCTAssertEqual(first.name, "swift")
        XCTAssertEqual(first.fullName, "swiftlang/swift")
        XCTAssertEqual(first.owner?.login, "swiftlang")
        XCTAssertEqual(first.language, "C++")
        XCTAssertEqual(first.stargazersCount, 67_912)
        XCTAssertEqual(first.license?.name, "Apache License 2.0")
        XCTAssertEqual(first.htmlURL.absoluteString, "https://github.com/swiftlang/swift")

        // description / language / license がnullでもデコードできる
        let last = try XCTUnwrap(response.items.last)
        XCTAssertNil(last.description)
        XCTAssertNil(last.language)
    }

    // MARK: - エラーハンドリング

    func testSearchは403をレート制限エラーにマップする() async throws {
        await assertSearchThrows(statusCode: 403, expected: .rateLimitExceeded)
    }

    func testSearchは429をレート制限エラーにマップする() async throws {
        await assertSearchThrows(statusCode: 429, expected: .rateLimitExceeded)
    }

    func testSearchは422を検索条件エラーにマップする() async throws {
        await assertSearchThrows(statusCode: 422, expected: .invalidQuery)
    }

    func testSearchは500をサーバーエラーにマップする() async throws {
        await assertSearchThrows(statusCode: 500, expected: .serverError(statusCode: 500))
    }

    func testSearchは通信エラーをnetworkにマップする() async throws {
        StubURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await XCTUnwrap(client).search(query: "swift", page: 1)
            XCTFail("エラーが投げられるべき")
        } catch let error as GitHubAPIError {
            guard case .network = error else {
                XCTFail("networkエラーであるべき: \(error)")
                return
            }
        }
    }

    func testSearchは不正なJSONをデコード失敗にマップする() async throws {
        StubURLProtocol.handler = { request in
            (Self.okResponse(for: request), Data("broken".utf8))
        }

        do {
            _ = try await XCTUnwrap(client).search(query: "swift", page: 1)
            XCTFail("エラーが投げられるべき")
        } catch let error as GitHubAPIError {
            XCTAssertEqual(error, .decodingFailed)
        }
    }

    // MARK: - エラーメッセージ

    func testオフライン起因の通信エラーは未接続メッセージになる() {
        let error = GitHubAPIError.network(URLError(.notConnectedToInternet))
        XCTAssertEqual(
            error.errorDescription,
            "インターネットに接続されていません。接続を確認して再度お試しください。"
        )
    }

    func testオフライン以外の通信エラーは汎用メッセージになる() {
        let error = GitHubAPIError.network(URLError(.timedOut))
        XCTAssertEqual(
            error.errorDescription,
            "通信に失敗しました。しばらくしてから再度お試しください。"
        )
    }

    // MARK: - Helpers

    private func assertSearchThrows(
        statusCode: Int,
        expected: GitHubAPIError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        StubURLProtocol.handler = { request in
            (Self.response(for: request, statusCode: statusCode), Data())
        }

        do {
            _ = try await XCTUnwrap(client).search(query: "swift", page: 1)
            XCTFail("エラーが投げられるべき", file: file, line: line)
        } catch let error as GitHubAPIError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("GitHubAPIErrorであるべき: \(error)", file: file, line: line)
        }
    }

    private static func okResponse(for request: URLRequest) -> HTTPURLResponse {
        response(for: request, statusCode: 200)
    }

    private static func response(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        else {
            preconditionFailure("レスポンスの生成に失敗")
        }
        return response
    }

    private static func fixtureData() -> Data {
        guard let url = Bundle.module.url(forResource: "Fixtures/search_repositories", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            preconditionFailure("フィクスチャの読み込みに失敗")
        }
        return data
    }
}
