import SwiftUI

struct FolderEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let folder: LibraryFolder?
    let onCreated: (LibraryFolder) -> Void

    @State private var name: String
    @State private var colorIndex: Int
    @State private var errorMessage: String?

    init(folder: LibraryFolder? = nil, onCreated: @escaping (LibraryFolder) -> Void = { _ in }) {
        self.folder = folder
        self.onCreated = onCreated
        _name = State(initialValue: folder?.name ?? "")
        _colorIndex = State(initialValue: folder?.colorIndex ?? Int.random(in: 0..<FolderAppearance.colors.count))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Weekend reading", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(save)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(FolderAppearance.colors.indices, id: \.self) { index in
                            Button {
                                colorIndex = index
                            } label: {
                                Circle()
                                    .fill(FolderAppearance.color(for: index))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if colorIndex == index {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.black)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Folder color \(index + 1)")
                            .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 5)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(folder == nil ? "New folder" : "Edit folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        do {
            if let folder {
                try model.updateFolder(folder.id, name: name, colorIndex: colorIndex)
            } else {
                let created = try model.createFolder(name: name, colorIndex: colorIndex)
                onCreated(created)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
