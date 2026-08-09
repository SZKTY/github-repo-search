import Foundation

/// GitHub Search API のリポジトリ
public struct Repository: Identifiable, Hashable, Sendable, Decodable {
    public struct Owner: Hashable, Sendable, Decodable {
        public let login: String
        public let avatarURL: URL?

        public init(login: String, avatarURL: URL?) {
            self.login = login
            self.avatarURL = avatarURL
        }

        private enum CodingKeys: String, CodingKey {
            case login
            case avatarURL = "avatar_url"
        }
    }

    public struct License: Hashable, Sendable, Decodable {
        public let name: String

        public init(name: String) {
            self.name = name
        }
    }

    public let id: Int
    public let name: String
    public let fullName: String
    public let owner: Owner?
    public let description: String?
    public let language: String?
    public let stargazersCount: Int
    public let forksCount: Int
    public let watchersCount: Int
    public let openIssuesCount: Int
    public let license: License?
    public let htmlURL: URL

    public init(
        id: Int,
        name: String,
        fullName: String,
        owner: Owner?,
        description: String?,
        language: String?,
        stargazersCount: Int,
        forksCount: Int,
        watchersCount: Int,
        openIssuesCount: Int,
        license: License?,
        htmlURL: URL
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.owner = owner
        self.description = description
        self.language = language
        self.stargazersCount = stargazersCount
        self.forksCount = forksCount
        self.watchersCount = watchersCount
        self.openIssuesCount = openIssuesCount
        self.license = license
        self.htmlURL = htmlURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case owner
        case description
        case language
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case watchersCount = "watchers_count"
        case openIssuesCount = "open_issues_count"
        case license
        case htmlURL = "html_url"
    }
}
