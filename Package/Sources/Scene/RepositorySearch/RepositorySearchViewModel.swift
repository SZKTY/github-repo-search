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
    /// 状態
    @Published public private(set) var state: State = .idle
    /// 直近に検索を実行したクエリ(結果ヘッダーの表示用)
    @Published public private(set) var submittedQuery: String?
    /// 次ページを読み込み中(リスト末尾のスピナー表示用)
    @Published public private(set) var isLoadingMore = false

    private let client: any RepositorySearchClient
    private var currentPage = 1

    /// Search APIが返す結果は最大1,000件(超えたページの要求は422になる)
    private static let maxSearchResults = 1000

    public init(client: any RepositorySearchClient = GitHubAPIClient()) {
        self.client = client
    }

    public func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        submittedQuery = trimmedQuery
        state = .loading
        currentPage = 1
        await performSearch(query: trimmedQuery)
    }

    /// 表示中のクエリで再検索する(Pull to Refresh用)。
    /// リストを保ったまま更新するため、loading状態には遷移させない。
    public func refresh() async {
        guard let submittedQuery else { return }
        currentPage = 1
        await performSearch(query: submittedQuery)
    }

    /// 末尾の行が表示されたら次ページを読み込む
    public func loadMoreIfNeeded(current repository: Repository) async {
        guard case .loaded(let repositories, let totalCount) = state,
              repository.id == repositories.last?.id,
              !isLoadingMore,
              repositories.count < min(totalCount, Self.maxSearchResults),
              let submittedQuery
        else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await client.search(query: submittedQuery, page: nextPage)
            guard self.submittedQuery == submittedQuery,
                  case .loaded(let currentRepositories, _) = state
            else { return }
            // ページ間で順位が入れ替わると同じリポジトリが再度返ることがあるため、既知のIDは除いて追記する
            let knownIDs = Set(currentRepositories.map(\.id))
            let appended = currentRepositories + response.items.filter { !knownIDs.contains($0.id) }
            currentPage = nextPage
            state = .loaded(repositories: appended, totalCount: response.totalCount)
        } catch {
            // 追加読み込みの失敗は表示中のリストを保つ(末尾が再表示されれば自動で再試行される)
        }
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
