import Entity
import SwiftUI

/// リポジトリ検索画面
public struct RepositorySearchView: View {
    @StateObject private var viewModel: RepositorySearchViewModel

    public init(viewModel: RepositorySearchViewModel = RepositorySearchViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        content
            .navigationTitle("リポジトリ検索")
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "キーワードを入力"
            )
            .onSubmit(of: .search) {
                Task { await viewModel.search() }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            message(
                systemImage: "magnifyingglass",
                title: "GitHubリポジトリを検索",
                description: "キーワードを入力して検索してください。"
            )
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let repositories, let totalCount):
            resultList(repositories: repositories, totalCount: totalCount)
        case .empty:
            message(
                systemImage: "questionmark.folder",
                title: "見つかりませんでした",
                description: "「\(viewModel.submittedQuery ?? "")」に一致するリポジトリはありません。"
            )
        case .failed(let errorMessage):
            VStack(spacing: 16) {
                message(
                    systemImage: "exclamationmark.triangle",
                    title: "検索できませんでした",
                    description: errorMessage
                )
                Button("再試行") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func resultList(repositories: [Repository], totalCount: Int) -> some View {
        List {
            Section {
                ForEach(repositories) { repository in
                    NavigationLink(value: repository) {
                        RepositoryRowView(repository: repository)
                    }
                    .task {
                        await viewModel.loadMoreIfNeeded(current: repository)
                    }
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        // 一度消えたインジケータが再表示時にアニメーションしないため、毎回別ビューとして生成させる
                        .id(UUID())
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                }
            } header: {
                Text("「\(viewModel.submittedQuery ?? "")」の検索結果 \(totalCount.formatted())件")
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func message(systemImage: String, title: String, description: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        RepositorySearchView()
    }
}
