import Entity
import SwiftUI

/// リポジトリ詳細画面
public struct RepositoryDetailView: View {
    private let repository: Repository

    public init(repository: Repository) {
        self.repository = repository
    }

    public var body: some View {
        List {
            Section {
                header
            }

            Section("統計") {
                statRow(label: "スター", systemImage: "star", count: repository.stargazersCount)
                statRow(label: "フォーク", systemImage: "arrow.triangle.branch", count: repository.forksCount)
                statRow(label: "ウォッチャー", systemImage: "eye", count: repository.watchersCount)
                statRow(label: "Issue", systemImage: "exclamationmark.circle", count: repository.openIssuesCount)
            }

            Section("情報") {
                if let language = repository.language {
                    LabeledContent("言語", value: language)
                }
                if let license = repository.license {
                    LabeledContent("ライセンス", value: license.name)
                }
                if let owner = repository.owner {
                    LabeledContent("オーナー", value: owner.login)
                }
            }

            Section {
                Link(destination: repository.htmlURL) {
                    Label("GitHubで開く", systemImage: "safari")
                }
            }
        }
        .navigationTitle(repository.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            AsyncImage(url: repository.owner?.avatarURL) { image in
                image.resizable()
            } placeholder: {
                Color(.systemGray5)
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(repository.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(repository.name)
                    .font(.title2)
                    .bold()
                if let description = repository.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statRow(label: String, systemImage: String, count: Int) -> some View {
        LabeledContent {
            Text(count.formatted())
        } label: {
            Label(label, systemImage: systemImage)
        }
    }
}

#Preview {
    NavigationStack {
        RepositoryDetailView(
            repository: Repository(
                id: 1,
                name: "swift",
                fullName: "swiftlang/swift",
                owner: Repository.Owner(
                    login: "swiftlang",
                    avatarURL: URL(string: "https://avatars.githubusercontent.com/u/42816656?v=4")
                ),
                description: "The Swift Programming Language",
                language: "C++",
                stargazersCount: 67912,
                forksCount: 10391,
                watchersCount: 67912,
                openIssuesCount: 7529,
                license: Repository.License(name: "Apache License 2.0"),
                htmlURL: URL(string: "https://github.com/swiftlang/swift")!
            )
        )
    }
}
