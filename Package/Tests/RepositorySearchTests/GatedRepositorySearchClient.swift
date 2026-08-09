import APIClient
import Entity
import Foundation

/// `resume(query:with:)` が呼ばれるまでレスポンスを返さないモック。
/// 「検索中にクリア・再検索が起きた」という競合状態を再現するために使う。
final class GatedRepositorySearchClient: RepositorySearchClient, @unchecked Sendable {
    private let lock = NSLock()
    private var pending: [(query: String, continuation: CheckedContinuation<SearchRepositoriesResponse, any Error>)] = []

    var pendingQueries: [String] {
        lock.lock()
        defer { lock.unlock() }
        return pending.map(\.query)
    }

    func search(query: String, page: Int) async throws -> SearchRepositoriesResponse {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            pending.append((query: query, continuation: continuation))
            lock.unlock()
        }
    }

    func resume(query: String, with result: Result<SearchRepositoriesResponse, GitHubAPIError>) {
        lock.lock()
        let index = pending.firstIndex { $0.query == query }
        let item = index.map { pending.remove(at: $0) }
        lock.unlock()
        item?.continuation.resume(with: result)
    }
}
