import SwiftUI

struct FolderPickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let article: Article
    @State private var showingNewFolder = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if model.folders.isEmpty {
                    ContentUnavailableView(
                        "No folders yet",
                        systemImage: "folder",
                        description: Text("Create one to group your links.")
                    )
                }

                ForEach(model.folders) { folder in
                    Button {
                        toggle(folder)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(FolderAppearance.color(for: folder.colorIndex))
                            Text(folder.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if model.isInFolder(article, folderID: folder.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LyraTheme.accent)
                            }
                        }
                    }
                }

                Button {
                    showingNewFolder = true
                } label: {
                    Label("New folder", systemImage: "folder.badge.plus")
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("Organize link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewFolder) {
                FolderEditorView { folder in
                    do {
                        try model.setFolderMembership(article, folderID: folder.id, isMember: true)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func toggle(_ folder: LibraryFolder) {
        do {
            try model.setFolderMembership(
                article,
                folderID: folder.id,
                isMember: !model.isInFolder(article, folderID: folder.id)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
