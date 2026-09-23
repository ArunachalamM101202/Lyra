import SwiftUI

enum AppSection: Hashable {
    case discover
    case library
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var section: AppSection = .discover
    @State private var safariArticle: Article?
    @State private var immersiveArticle: Article?
    @State private var isRouting = false
    @State private var routingTask: Task<Void, Never>?

    var body: some View {
        TabView(selection: $section) {
            Tab("Discover", systemImage: "sparkles", value: AppSection.discover) {
                NavigationStack {
                    FeedView(
                        onSwipeToLibrary: { section = .library },
                        onOpenArticle: openArticle
                    )
                        .toolbar(.hidden, for: .tabBar)
                }
            }

            Tab("Library", systemImage: "books.vertical", value: AppSection.library) {
                NavigationStack {
                    LibraryView(
                        onSwipeToDiscover: { section = .discover },
                        onOpenArticle: openArticle
                    )
                        .toolbar(.hidden, for: .tabBar)
                }
            }
        }
        .tint(LyraTheme.accent)
        .background(SafariReaderPresenter(article: $safariArticle).frame(width: 1, height: 1))
        .fullScreenCover(item: $immersiveArticle) { article in
            ReaderView(article: article)
        }
        .overlay {
            if isRouting {
                ProgressView("Opening article")
                    .padding(20)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .alert(
            "Library unavailable",
            isPresented: Binding(
                get: { model.storageErrorMessage != nil },
                set: { if !$0 { model.clearStorageError() } }
            )
        ) {
            Button("OK") { model.clearStorageError() }
        } message: {
            Text(model.storageErrorMessage ?? "Please try again.")
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                for article in model.articles.prefix(3) {
                    group.addTask {
                        _ = await ReaderRouteResolver.shared.route(for: article)
                    }
                }
            }
        }
    }

    private func openArticle(_ article: Article) {
        routingTask?.cancel()
        model.markOpened(article)
        isRouting = true
        routingTask = Task {
            let route = await ReaderRouteResolver.shared.route(for: article)
            guard !Task.isCancelled else { return }
            isRouting = false
            switch route {
            case .safariReader:
                safariArticle = article
            case .immersiveBrowser:
                immersiveArticle = article
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppModel(repository: PreviewArticleRepository()))
}
