import Logger
import SwiftUI

/// ホーム画面
public struct HomeView: View {
    public init() {}

    public var body: some View {
        Text("Home")
            .navigationTitle("ホーム")
            .onAppear {
                AppLogger.debug("HomeView appeared")
            }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
