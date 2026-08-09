import APIClient
import Entity
import Foundation

@MainActor
public final class RepositorySearchViewModel: ObservableObject {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(repositories: [Repository], totalCount: Int)
        case empty
        case failed(message: String)
    }

    /// 検索バーの入力中テキスト。空にすると検索結果も初期状態に戻す。
    @Published public var query = "" {
        didSet {
            if query.isEmpty, !oldValue.isEmpty {
                reset()
            }
        }
    }
    /// 通信ステータス
    @Published public private(set) var state: State = .idle
    /// 直近に検索を実行したクエリ(結果ヘッダーの表示用)
    @Published public private(set) var submittedQuery: String?

    private let client: any RepositorySearchClient

    public init(client: any RepositorySearchClient = GitHubAPIClient()) {
        self.client = client
    }

    public func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        submittedQuery = trimmedQuery
        state = .loading
        await performSearch(query: trimmedQuery)
    }

    /// 表示中のクエリで再検索する(Pull to Refresh用)。
    /// リストを保ったまま更新するため、loading状態には遷移させない。
    public func refresh() async {
        guard let submittedQuery else { return }
        await performSearch(query: submittedQuery)
    }

    /// 検索結果を破棄して初期状態に戻す
    public func reset() {
        submittedQuery = nil
        state = .idle
    }

    private func performSearch(query: String) async {
        do {
            let response = try await client.search(query: query, page: 1)
            // 検索中にクリア・別クエリで再検索された場合、古い結果で画面を上書きしない
            guard submittedQuery == query else { return }
            if response.items.isEmpty {
                state = .empty
            } else {
                state = .loaded(repositories: response.items, totalCount: response.totalCount)
            }
        } catch {
            guard submittedQuery == query else { return }
            state = .failed(message: Self.errorMessage(from: error))
        }
    }

    public func retry() async {
        guard let submittedQuery else { return }
        query = submittedQuery
        await search()
    }

    private static func errorMessage(from error: any Error) -> String {
        (error as? any LocalizedError)?.errorDescription ?? "予期しないエラーが発生しました。"
    }
}
