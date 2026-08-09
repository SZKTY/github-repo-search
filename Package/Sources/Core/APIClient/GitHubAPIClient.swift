import Entity
import Foundation

/// GitHub REST API (GET /search/repositories) 呼び出し
/// - SeeAlso: https://docs.github.com/ja/rest/search/search#search-repositories
public struct GitHubAPIClient: RepositorySearchClient {
    /// 1ページあたりの取得件数
    public static let perPage = 30

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(query: String, page: Int) async throws -> SearchRepositoriesResponse {
        let request = try makeSearchRequest(query: query, page: page)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw GitHubAPIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.serverError(statusCode: -1)
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try JSONDecoder().decode(SearchRepositoriesResponse.self, from: data)
            } catch {
                throw GitHubAPIError.decodingFailed
            }
        case 403, 429:
            throw GitHubAPIError.rateLimitExceeded
        case 422:
            throw GitHubAPIError.invalidQuery
        default:
            throw GitHubAPIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func makeSearchRequest(query: String, page: Int) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/search/repositories"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(Self.perPage)),
        ]

        guard let url = components.url else {
            throw GitHubAPIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }
}
