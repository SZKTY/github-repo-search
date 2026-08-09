import Foundation

/// GET /search/repositories のレスポンス
public struct SearchRepositoriesResponse: Hashable, Sendable, Decodable {
    public let totalCount: Int
    public let incompleteResults: Bool
    public let items: [Repository]

    public init(totalCount: Int, incompleteResults: Bool, items: [Repository]) {
        self.totalCount = totalCount
        self.incompleteResults = incompleteResults
        self.items = items
    }

    private enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case incompleteResults = "incomplete_results"
        case items
    }
}
