import APIClient
import Entity
import XCTest

@testable import RepositorySearch

@MainActor
final class RepositorySearchViewModelTests: XCTestCase {
    // MARK: - 検索

    func test検索成功で結果と総件数が表示される() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1, 2], totalCount: 42)))

        viewModel.query = "swift"
        await viewModel.search()

        XCTAssertEqual(
            viewModel.state,
            .loaded(repositories: [.make(id: 1), .make(id: 2)], totalCount: 42)
        )
        XCTAssertEqual(viewModel.submittedQuery, "swift")
        XCTAssertEqual(client.calls, [.init(query: "swift", page: 1)])
    }

    func test空白のみのクエリでは検索しない() async {
        let (viewModel, client) = makeViewModel()

        viewModel.query = "   "
        await viewModel.search()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(client.calls.isEmpty)
    }

    func testクエリの前後の空白を除いて検索する() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1], totalCount: 1)))

        viewModel.query = "  swift  "
        await viewModel.search()

        XCTAssertEqual(viewModel.submittedQuery, "swift")
        XCTAssertEqual(client.calls, [.init(query: "swift", page: 1)])
    }

    func test結果が0件ならemptyになる() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [], totalCount: 0)))

        viewModel.query = "swift"
        await viewModel.search()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test検索失敗でエラーメッセージが表示される() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.failure(.rateLimitExceeded))

        viewModel.query = "swift"
        await viewModel.search()

        guard case .failed(let message) = viewModel.state else {
            XCTFail("failedであるべき: \(viewModel.state)")
            return
        }
        XCTAssertTrue(message.contains("利用制限"))
    }

    // MARK: - クリア / リトライ / リフレッシュ

    func testキーワードをクリアすると初期状態に戻る() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1], totalCount: 1)))
        viewModel.query = "swift"
        await viewModel.search()

        viewModel.query = ""

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.submittedQuery)
    }

    func testRetryは直近のクエリで再検索する() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.failure(.network(URLError(.notConnectedToInternet))))
        viewModel.query = "swift"
        await viewModel.search()

        client.enqueue(.success(.make(ids: [1], totalCount: 1)))
        await viewModel.retry()

        XCTAssertEqual(viewModel.state, .loaded(repositories: [.make(id: 1)], totalCount: 1))
        XCTAssertEqual(client.calls, [
            .init(query: "swift", page: 1),
            .init(query: "swift", page: 1),
        ])
    }

    func testRefreshはページ1で再検索して結果を置き換える() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1], totalCount: 2)))
        viewModel.query = "swift"
        await viewModel.search()

        client.enqueue(.success(.make(ids: [2], totalCount: 2)))
        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .loaded(repositories: [.make(id: 2)], totalCount: 2))
        XCTAssertEqual(client.calls.last, .init(query: "swift", page: 1))
    }

    // MARK: - ページネーション

    func testLoadMoreで次ページが追記される() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1, 2], totalCount: 4)))
        viewModel.query = "swift"
        await viewModel.search()

        client.enqueue(.success(.make(ids: [3, 4], totalCount: 4)))
        await viewModel.loadMoreIfNeeded(current: .make(id: 2))

        XCTAssertEqual(
            viewModel.state,
            .loaded(repositories: [1, 2, 3, 4].map { .make(id: $0) }, totalCount: 4)
        )
        XCTAssertEqual(client.calls.last, .init(query: "swift", page: 2))
    }

    func testLoadMoreは末尾以外の行では発火しない() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1, 2], totalCount: 4)))
        viewModel.query = "swift"
        await viewModel.search()

        await viewModel.loadMoreIfNeeded(current: .make(id: 1))

        XCTAssertEqual(client.calls.count, 1)
    }

    func testLoadMoreは全件取得済みなら発火しない() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1, 2], totalCount: 2)))
        viewModel.query = "swift"
        await viewModel.search()

        await viewModel.loadMoreIfNeeded(current: .make(id: 2))

        XCTAssertEqual(client.calls.count, 1)
    }

    func testLoadMoreで重複したIDは追記しない() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1, 2], totalCount: 3)))
        viewModel.query = "swift"
        await viewModel.search()

        // ページ間で順位が入れ替わり、2ページ目に1ページ目と同じリポジトリが混ざったケース
        client.enqueue(.success(.make(ids: [2, 3], totalCount: 3)))
        await viewModel.loadMoreIfNeeded(current: .make(id: 2))

        XCTAssertEqual(
            viewModel.state,
            .loaded(repositories: [1, 2, 3].map { .make(id: $0) }, totalCount: 3)
        )
    }

    func testLoadMore失敗時は表示中のリストを保つ() async {
        let (viewModel, client) = makeViewModel()
        client.enqueue(.success(.make(ids: [1, 2], totalCount: 4)))
        viewModel.query = "swift"
        await viewModel.search()

        client.enqueue(.failure(.network(URLError(.timedOut))))
        await viewModel.loadMoreIfNeeded(current: .make(id: 2))

        XCTAssertEqual(
            viewModel.state,
            .loaded(repositories: [.make(id: 1), .make(id: 2)], totalCount: 4)
        )
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    // MARK: - 競合(遅延レスポンスの破棄)

    func test検索中にクリアされたら古い結果を破棄する() async {
        let client = GatedRepositorySearchClient()
        let viewModel = RepositorySearchViewModel(client: client)

        viewModel.query = "swift"
        let searchTask = Task { await viewModel.search() }
        await waitUntil { client.pendingQueries.contains("swift") }

        viewModel.query = ""  // 検索中にクリア
        client.resume(query: "swift", with: .success(.make(ids: [1], totalCount: 1)))
        await searchTask.value

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.submittedQuery)
    }

    func test連続検索では後に実行した検索の結果を表示する() async {
        let client = GatedRepositorySearchClient()
        let viewModel = RepositorySearchViewModel(client: client)

        viewModel.query = "first"
        let firstTask = Task { await viewModel.search() }
        await waitUntil { client.pendingQueries.contains("first") }

        viewModel.query = "second"
        let secondTask = Task { await viewModel.search() }
        await waitUntil { client.pendingQueries.contains("second") }

        // 2回目が先に完了し、1回目のレスポンスが遅れて届く
        client.resume(query: "second", with: .success(.make(ids: [2], totalCount: 2)))
        await secondTask.value
        client.resume(query: "first", with: .success(.make(ids: [1], totalCount: 1)))
        await firstTask.value

        XCTAssertEqual(viewModel.state, .loaded(repositories: [.make(id: 2)], totalCount: 2))
        XCTAssertEqual(viewModel.submittedQuery, "second")
    }

    // MARK: - Helpers

    private func makeViewModel() -> (RepositorySearchViewModel, MockRepositorySearchClient) {
        let client = MockRepositorySearchClient()
        return (RepositorySearchViewModel(client: client), client)
    }

    private func waitUntil(
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) async {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail("タイムアウト: 条件が満たされませんでした", file: file, line: line)
                return
            }
            await Task.yield()
        }
    }
}
