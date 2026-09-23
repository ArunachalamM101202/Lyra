import SwiftUI

@main
struct LyraApp: App {
    @State private var model = AppModel(repository: PreviewArticleRepository())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
