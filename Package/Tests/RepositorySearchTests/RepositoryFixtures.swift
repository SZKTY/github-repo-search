import Entity
import Foundation

extension Repository {
    static func make(id: Int, name: String = "repo") -> Repository {
        Repository(
            id: id,
            name: "\(name)\(id)",
            fullName: "owner/\(name)\(id)",
            owner: Owner(login: "owner", avatarURL: nil),
            description: nil,
            language: nil,
            stargazersCount: 0,
            forksCount: 0,
            watchersCount: 0,
            openIssuesCount: 0,
            license: nil,
            htmlURL: URL(filePath: "/") // テストでは参照しない
        )
    }
}

extension SearchRepositoriesResponse {
    static func make(ids: [Int], totalCount: Int) -> SearchRepositoriesResponse {
        SearchRepositoriesResponse(
            totalCount: totalCount,
            incompleteResults: false,
            items: ids.map { Repository.make(id: $0) }
        )
    }
}
