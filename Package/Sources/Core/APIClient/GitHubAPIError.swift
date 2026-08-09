import Foundation

/// GitHub API呼び出しで発生するエラー
public enum GitHubAPIError: Error, Equatable, LocalizedError {
    /// リクエストURLの生成に失敗
    case invalidRequest
    /// 検索条件が不正(HTTP 422)
    case invalidQuery
    /// レート制限に到達(HTTP 403 / 429)。未認証のSearch APIは10リクエスト/分。
    case rateLimitExceeded
    /// 上記以外のHTTPエラー
    case serverError(statusCode: Int)
    /// 通信エラー(オフライン・タイムアウト等)
    case network(URLError)
    /// レスポンスのデコードに失敗
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "リクエストの生成に失敗しました。"
        case .invalidQuery:
            "検索条件が正しくありません。キーワードを変えて再度お試しください。"
        case .rateLimitExceeded:
            "GitHub APIの利用制限に達しました。しばらく待ってから再度お試しください。"
        case .serverError(let statusCode):
            "サーバーエラーが発生しました。(HTTP \(statusCode))"
        case .network(let error):
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                "インターネットに接続されていません。接続を確認して再度お試しください。"
            default:
                "通信に失敗しました。しばらくしてから再度お試しください。"
            }
        case .decodingFailed:
            "レスポンスの解析に失敗しました。"
        }
    }
}
