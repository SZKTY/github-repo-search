import APIClient
import Entity
import Foundation
import os

/// 設定した結果を順番に返すモック。呼び出し(クエリ・ページ)を記録する。
final class MockRepositorySearchClient: RepositorySearchClient {
    struct Call: Equatable {
        let query: String
        let page: Int
    }

    private struct Storage {
        var calls: [Call] = []
        var results: [Result<SearchRepositoriesResponse, GitHubAPIError>] = []
    }

    private let storage = OSAllocatedUnfairLock(initialState: Storage())

    var calls: [Call] {
        storage.withLock { $0.calls }
    }

    func enqueue(_ result: Result<SearchRepositoriesResponse, GitHubAPIError>) {
        storage.withLock { $0.results.append(result) }
    }

    func search(query: String, page: Int) async throws -> SearchRepositoriesResponse {
        let result = storage.withLock { storage -> Result<SearchRepositoriesResponse, GitHubAPIError> in
            storage.calls.append(Call(query: query, page: page))
            guard !storage.results.isEmpty else {
                preconditionFailure("結果が設定されていません。enqueue(_:)で設定してください。")
            }
            return storage.results.removeFirst()
        }
        return try result.get()
    }
}
