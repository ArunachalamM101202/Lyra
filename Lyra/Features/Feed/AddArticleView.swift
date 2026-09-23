import SwiftUI

struct AddArticleView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let folderID: LibraryFolder.ID?
    let onAdded: (Article) -> Void

    @State private var urlText = ""
    @State private var isAdding = false
    @State private var errorMessage: String?

    init(folderID: LibraryFolder.ID? = nil, onAdded: @escaping (Article) -> Void) {
        self.folderID = folderID
        self.onAdded = onAdded
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/article", text: $urlText)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { submit() }
                } header: {
                    Text("Article URL")
                } footer: {
                    Text(folderID == nil
                        ? "Add a link to your feed and Library."
                        : "Add a link to this folder and your feed.")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .navigationTitle("Add article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isAdding {
                        ProgressView()
                            .accessibilityLabel("Adding article")
                    } else {
                        Button("Add") { submit() }
                            .fontWeight(.semibold)
                            .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func submit() {
        guard !isAdding else { return }
        isAdding = true
        errorMessage = nil

        Task {
            do {
                let article = try await model.addArticle(from: urlText, folderID: folderID)
                onAdded(article)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isAdding = false
        }
    }
}
