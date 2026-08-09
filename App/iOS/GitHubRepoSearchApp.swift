import Entity
import RepositoryDetail
import RepositorySearch
import SwiftUI

@main
struct GitHubRepoSearchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RepositorySearchView()
                    .navigationDestination(for: Repository.self) { repository in
                        RepositoryDetailView(repository: repository)
                    }
            }
        }
    }
}
