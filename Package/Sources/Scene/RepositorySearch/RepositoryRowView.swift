import Entity
import SwiftUI

/// 検索結果リストの1行
struct RepositoryRowView: View {
    let repository: Repository

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.headline)
                Text(repository.fullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let description = repository.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 12) {
                    Label(repository.stargazersCount.formatted(), systemImage: "star")
                    if let language = repository.language {
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var avatar: some View {
        AsyncImage(url: repository.owner?.avatarURL) { image in
            image.resizable()
        } placeholder: {
            Color(.systemGray5)
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
