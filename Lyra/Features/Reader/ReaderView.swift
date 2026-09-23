import SwiftUI

struct ReaderView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let article: Article

    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadID = 0

    var body: some View {
        ZStack(alignment: .top) {
            ArticleWebView(
                url: article.originalURL,
                isLoading: $isLoading,
                loadFailed: $loadFailed,
                onExit: { dismiss() }
            )
            .id(reloadID)
            .ignoresSafeArea()

            if isLoading && !loadFailed {
                ProgressView()
                    .controlSize(.small)
                    .padding(10)
                    .background(.regularMaterial, in: .capsule)
                    .padding(.top, 12)
                    .accessibilityLabel("Loading article")
            }

            if loadFailed {
                ContentUnavailableView {
                    Label("Article unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("The website could not load here.")
                } actions: {
                    Button("Try Again") {
                        loadFailed = false
                        isLoading = true
                        reloadID += 1
                    }

                    Link("Open in Safari", destination: article.originalURL)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }

            HStack {
                Spacer()
                Menu {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close article", systemImage: "xmark")
                    }

                    Divider()

                    if !model.isCompleted(article) {
                        Button {
                            model.markCompleted(article)
                        } label: {
                            Label("Mark as Done", systemImage: "checkmark.circle")
                        }
                    }

                    Button {
                        model.toggleLiked(article)
                    } label: {
                        Label(
                            model.isLiked(article) ? "Unlike" : "Like",
                            systemImage: model.isLiked(article) ? "heart.fill" : "heart"
                        )
                    }

                    Link(destination: article.originalURL) {
                        Label("Open in Safari", systemImage: "safari")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                        .accessibilityLabel("Article actions")
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.light)
    }
}
