import Entity

/// リポジトリ検索クライアント。ViewModelにはこのprotocolを注入し、テストではモックに差し替える。
public protocol RepositorySearchClient: Sendable {
    /// - Parameters:
    ///   - query: 検索クエリ文字列
    ///   - page: 1始まりのページ番号
    func search(query: String, page: Int) async throws -> SearchRepositoriesResponse
}
