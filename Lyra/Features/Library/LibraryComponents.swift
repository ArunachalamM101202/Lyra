import SwiftUI

enum FolderAppearance {
    static let colors: [Color] = [
        Color(red: 0.84, green: 0.91, blue: 0.98),
        Color(red: 0.88, green: 0.93, blue: 0.84),
        Color(red: 0.97, green: 0.88, blue: 0.84),
        Color(red: 0.92, green: 0.87, blue: 0.97),
        Color(red: 0.98, green: 0.92, blue: 0.78),
        Color(red: 0.83, green: 0.93, blue: 0.91),
        Color(red: 0.96, green: 0.86, blue: 0.91),
        Color(red: 0.88, green: 0.90, blue: 0.96)
    ]

    static func color(for index: Int) -> Color {
        colors[(index % colors.count + colors.count) % colors.count]
    }
}

struct FolderTile: View {
    let folder: LibraryFolder
    let articleCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .accessibilityHidden(true)
            Spacer(minLength: 18)
            Text(folder.name)
                .font(.headline)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(articleCount) \(articleCount == 1 ? "link" : "links")")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.62))
                .padding(.top, 4)
        }
        .foregroundStyle(Color(red: 0.17, green: 0.19, blue: 0.20))
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(FolderAppearance.color(for: folder.colorIndex), in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

struct LibraryArticleRow: View {
    @Environment(AppModel.self) private var model

    let article: Article
    let detail: String
    let onOpen: () -> Void
    let onOrganize: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    var onRemoveFromFolder: (() -> Void)? = nil

    private var palette: FeedPalette { FeedPalette(article: article) }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onOpen) {
                HStack(alignment: .center, spacing: 14) {
                    Text(String(article.source.prefix(1)).uppercased())
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(palette.foreground)
                        .frame(width: 44, height: 44)
                        .background(palette.background, in: RoundedRectangle(cornerRadius: 13))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(article.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        HStack(spacing: 7) {
                            Text(detail)
                                .lineLimit(1)
                            if model.isLiked(article) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.pink)
                                    .accessibilityLabel("Liked")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    if model.isSaved(article) {
                        model.unsaveArticle(article)
                    } else {
                        model.saveArticle(article)
                    }
                } label: {
                    Label(
                        model.isSaved(article) ? "Remove from Saved" : "Save to Library",
                        systemImage: model.isSaved(article) ? "bookmark.slash" : "bookmark"
                    )
                }

                Button {
                    model.toggleLiked(article)
                } label: {
                    Label(
                        model.isLiked(article) ? "Unlike" : "Like",
                        systemImage: model.isLiked(article) ? "heart.slash" : "heart"
                    )
                }

                Button(action: onOrganize) {
                    Label("Organize in Folders", systemImage: "folder")
                }

                if let onRemoveFromFolder {
                    Button(action: onRemoveFromFolder) {
                        Label("Remove from Folder", systemImage: "folder.badge.minus")
                    }
                }

                if model.isImported(article) {
                    Button(action: onEdit) {
                        Label("Edit Link", systemImage: "pencil")
                    }
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label(
                        model.isImported(article) ? "Delete Link" : "Remove from Library",
                        systemImage: "trash"
                    )
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Actions for \(article.title)")
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}
