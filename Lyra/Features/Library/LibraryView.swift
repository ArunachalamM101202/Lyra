import SwiftUI

private enum LibrarySection: String, CaseIterable {
    case saved = "Saved"
    case folders = "Folders"
    case liked = "Liked"
    case visited = "Visited"

    var symbol: String {
        switch self {
        case .saved: "bookmark"
        case .folders: "folder"
        case .liked: "heart"
        case .visited: "clock.arrow.circlepath"
        }
    }
}

struct LibraryView: View {
    @Environment(AppModel.self) private var model

    let onSwipeToDiscover: () -> Void
    let onOpenArticle: (Article) -> Void

    @State private var section: LibrarySection = .saved
    @State private var showingAddURL = false
    @State private var showingNewFolder = false
    @State private var editingFolder: LibraryFolder?
    @State private var deletingFolder: LibraryFolder?
    @State private var organizingArticle: Article?
    @State private var editingArticle: Article?
    @State private var deletingArticle: Article?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(model.savedArticles.count) saved · \(model.folders.count) folders")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 14)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(LibrarySection.allCases, id: \.self) { item in
                        Button {
                            section = item
                        } label: {
                            Label("\(item.rawValue) \(count(for: item))", systemImage: item.symbol)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .foregroundStyle(section == item
                                    ? Color(uiColor: .systemBackground)
                                    : Color.primary)
                                .background(
                                    section == item
                                        ? Color.primary
                                        : Color(uiColor: .secondarySystemGroupedBackground),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(section == item ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .padding(.bottom, 16)

            ScrollView {
                sectionContent
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(
                DragGesture(minimumDistance: 30).onEnded { gesture in
                    let movement = gesture.translation
                    if movement.width < -80 && abs(movement.width) > abs(movement.height) * 1.4 {
                        onSwipeToDiscover()
                    }
                }
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .accessibilityAction(named: "Open Discover", onSwipeToDiscover)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddURL = true
                    } label: {
                        Label("Add URL", systemImage: "link.badge.plus")
                    }
                    Button {
                        showingNewFolder = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .accessibilityLabel("Add to Library")
                }
            }
        }
        .sheet(isPresented: $showingAddURL) {
            AddArticleView { _ in section = .saved }
        }
        .sheet(isPresented: $showingNewFolder) {
            FolderEditorView { _ in section = .folders }
        }
        .sheet(item: $editingFolder) { folder in
            FolderEditorView(folder: folder)
        }
        .sheet(item: $organizingArticle) { article in
            FolderPickerView(article: article)
        }
        .sheet(item: $editingArticle) { article in
            EditArticleView(article: article)
        }
        .confirmationDialog(
            "Delete this folder?",
            isPresented: Binding(
                get: { deletingFolder != nil },
                set: { if !$0 { deletingFolder = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let folder = deletingFolder {
                Button("Delete Folder", role: .destructive) {
                    do {
                        try model.deleteFolder(folder.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    deletingFolder = nil
                }
            }
        } message: {
            Text("Links in this folder stay in your Library.")
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
            Text("This removes the link from every folder and list.")
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

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .folders:
            if model.folders.isEmpty {
                emptyState(
                    title: "A place for every curiosity",
                    symbol: "folder.badge.plus",
                    description: "Make a folder for a topic, project, or weekend rabbit hole.",
                    button: "New folder",
                    action: { showingNewFolder = true }
                )
            } else {
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                    ForEach(model.folders) { folder in
                        NavigationLink {
                            FolderDetailView(folderID: folder.id, onOpenArticle: onOpenArticle)
                        } label: {
                            FolderTile(
                                folder: folder,
                                articleCount: model.articles(in: folder.id).count
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Edit Folder", systemImage: "pencil") {
                                editingFolder = folder
                            }
                            Button("Delete Folder", systemImage: "trash", role: .destructive) {
                                deletingFolder = folder
                            }
                        }
                    }
                }
            }
        case .saved, .liked, .visited:
            let items = articles(for: section)
            if items.isEmpty {
                switch section {
                case .saved:
                    emptyState(
                        title: "Save what stays with you",
                        symbol: "bookmark",
                        description: "Add a URL or bookmark a card from Discover.",
                        button: "Add a URL",
                        action: { showingAddURL = true }
                    )
                case .liked:
                    emptyState(
                        title: "Nothing liked yet",
                        symbol: "heart",
                        description: "Articles you like will collect here."
                    )
                case .visited:
                    emptyState(
                        title: "Your reading trail starts here",
                        symbol: "clock.arrow.circlepath",
                        description: "Open an article and it will appear here."
                    )
                case .folders: EmptyView()
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(items) { article in
                        LibraryArticleRow(
                            article: article,
                            detail: detail(for: article),
                            onOpen: { onOpenArticle(article) },
                            onOrganize: { organizingArticle = article },
                            onEdit: { editingArticle = article },
                            onDelete: { deletingArticle = article }
                        )
                    }
                }
            }
        }
    }

    private func emptyState(
        title: String,
        symbol: String,
        description: String,
        button: String? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(description)
        } actions: {
            if let button {
                Button(button, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func count(for section: LibrarySection) -> Int {
        switch section {
        case .saved: model.savedArticles.count
        case .folders: model.folders.count
        case .liked: model.likedArticles.count
        case .visited: model.visitedArticles.count
        }
    }

    private func articles(for section: LibrarySection) -> [Article] {
        switch section {
        case .saved: model.savedArticles
        case .liked: model.likedArticles
        case .visited: model.visitedArticles
        case .folders: []
        }
    }

    private func detail(for article: Article) -> String {
        guard section == .visited,
              let date = model.visitedDate(article),
              date.timeIntervalSince1970 > 86_400 else {
            return article.source
        }
        return "\(article.source) · \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}
