import SwiftUI

struct EditArticleView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let article: Article
    @State private var title: String
    @State private var urlText: String
    @State private var summary: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(article: Article) {
        self.article = article
        _title = State(initialValue: article.title)
        _urlText = State(initialValue: article.originalURL.absoluteString)
        _summary = State(initialValue: article.hook)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Link") {
                    TextField("Title", text: $title)
                    TextField("URL", text: $urlText)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Card summary") {
                    TextField("What is this about?", text: $summary, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Edit link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save", action: save)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        Task {
            do {
                _ = try await model.updateArticle(
                    article,
                    title: title,
                    urlInput: urlText,
                    summary: summary
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
