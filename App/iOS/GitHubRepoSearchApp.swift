import RepositorySearch
import SwiftUI

@main
struct GitHubRepoSearchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RepositorySearchView()
            }
        }
    }
}
