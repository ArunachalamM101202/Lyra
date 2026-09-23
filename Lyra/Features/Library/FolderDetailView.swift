import SwiftUI

struct FolderDetailView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let folderID: LibraryFolder.ID
    let onOpenArticle: (Article) -> Void

    @State private var showingAddURL = false
    @State private var showingAddExisting = false
    @State private var showingEditor = false
    @State private var showingDeleteFolder = false
    @State private var organizingArticle: Article?
    @State private var editingArticle: Article?
    @State private var deletingArticle: Article?
    @State private var errorMessage: String?

    private var folder: LibraryFolder? { model.folder(with: folderID) }
    private var folderArticles: [Article] { model.articles(in: folderID) }

    var body: some View {
        Group {
            if let folder {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title)
                            Spacer()
                            Text("\(folderArticles.count) \(folderArticles.count == 1 ? "link" : "links")")
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color(red: 0.17, green: 0.19, blue: 0.20))
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            FolderAppearance.color(for: folder.colorIndex),
                            in: RoundedRectangle(cornerRadius: 22)
                        )

                        if folderArticles.isEmpty {
                            ContentUnavailableView {
                                Label("This folder is ready", systemImage: "folder")
                            } description: {
                                Text("Add an existing link or paste a new URL.")
                            } actions: {
                                Button("Add a link") { showingAddExisting = true }
                                    .buttonStyle(.borderedProminent)
                            }
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(folderArticles) { article in
                                    LibraryArticleRow(
                                        article: article,
                                        detail: article.source,
                                        onOpen: { onOpenArticle(article) },
                                        onOrganize: { organizingArticle = article },
                                        onEdit: { editingArticle = article },
                                        onDelete: { deletingArticle = article },
                                        onRemoveFromFolder: { remove(article) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(18)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            } else {
                ContentUnavailableView("Folder unavailable", systemImage: "folder.badge.questionmark")
            }
        }
        .navigationTitle(folder?.name ?? "Folder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddURL = true
                    } label: {
                        Label("Add URL", systemImage: "link.badge.plus")
                    }
                    Button {
                        showingAddExisting = true
                    } label: {
                        Label("Add from Library", systemImage: "text.badge.plus")
                    }
                    Divider()
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Edit Folder", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showingDeleteFolder = true
                    } label: {
                        Label("Delete Folder", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel("Folder actions")
                }
            }
        }
        .sheet(isPresented: $showingAddURL) {
            AddArticleView(folderID: folderID) { _ in }
        }
        .sheet(isPresented: $showingAddExisting) {
            AddToFolderView(folderID: folderID)
        }
        .sheet(isPresented: $showingEditor) {
            if let folder { FolderEditorView(folder: folder) }
        }
        .sheet(item: $organizingArticle) { article in
            FolderPickerView(article: article)
        }
        .sheet(item: $editingArticle) { article in
            EditArticleView(article: article)
        }
        .confirmationDialog(
            "Delete this folder?",
            isPresented: $showingDeleteFolder,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                do {
                    try model.deleteFolder(folderID)
                    dismiss()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        } message: {
            Text("The links will remain in your Library.")
        }
        .confirmationDialog(
            "Delete this link?",
            isPresented: Binding(
                get: { deletingArticle != nil },
                set: { if !$0 { deletingArticle = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let article = deletingArticle {
                Button(
                    model.isImported(article) ? "Delete Link" : "Remove from Library",
                    role: .destructive
                ) {
                    do {
                        try model.deleteArticle(article)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    deletingArticle = nil
                }
            }
        } message: {
            Text("A deleted link is removed from every folder and list.")
        }
        .alert(
            "Couldn't update Library",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func remove(_ article: Article) {
        do {
            try model.setFolderMembership(article, folderID: folderID, isMember: false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddToFolderView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let folderID: LibraryFolder.ID
    @State private var searchText = ""
    @State private var errorMessage: String?

    private var candidates: [Article] {
        model.libraryArticles
            .filter { searchText.isEmpty
                || $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.source.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(candidates) { article in
                Button {
                    do {
                        try model.setFolderMembership(
                            article,
                            folderID: folderID,
                            isMember: !model.isInFolder(article, folderID: folderID)
                        )
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .foregroundStyle(.primary)
                            Text(article.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if model.isInFolder(article, folderID: folderID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(LyraTheme.accent)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .overlay {
                if model.libraryArticles.isEmpty {
                    ContentUnavailableView(
                        "No links yet",
                        systemImage: "link",
                        description: Text("Add a URL first, then place it here.")
                    )
                }
            }
            .navigationTitle("Add to folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(
                "Couldn't update folder",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }
}
