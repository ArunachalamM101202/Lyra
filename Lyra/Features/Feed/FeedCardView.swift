import SwiftUI

struct FeedCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let article: Article
    let topInset: CGFloat
    let bottomInset: CGFloat
    let onReadOriginal: () -> Void
    let isSaved: Bool
    let onToggleSaved: () -> Void
    let isLiked: Bool
    let onToggleLiked: () -> Void

    private var palette: FeedPalette {
        FeedPalette(article: article)
    }

    var body: some View {
        ZStack {
            palette.background

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text(article.source.uppercased())
                        .font(.subheadline.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(palette.foreground)
                        .lineLimit(1)

                    Spacer(minLength: 16)

                    if let minutes = article.estimatedReadMinutes {
                        Text("\(minutes) MIN")
                            .font(.caption.monospacedDigit().weight(.medium))
                            .foregroundStyle(palette.foreground.opacity(0.85))
                    }
                }

                Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 12 : 36)

                VStack(alignment: .leading, spacing: 22) {
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: 36, height: 3)
                        .accessibilityHidden(true)

                    Text(article.title)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(palette.foreground)
                        .multilineTextAlignment(.leading)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(article.hook)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.foreground.opacity(0.92))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    if !article.preview.isEmpty && !dynamicTypeSize.isAccessibilitySize {
                        Text(article.preview)
                            .font(.body)
                            .foregroundStyle(palette.foreground.opacity(0.85))
                            .lineSpacing(3)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: dynamicTypeSize.isAccessibilitySize ? 12 : 36)

                HStack(spacing: 10) {
                    Button(action: onReadOriginal) {
                        HStack(spacing: 8) {
                            Text("Read original")
                                .font(.headline)
                            Image(systemName: "arrow.up.right")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 8)

                    Button(action: onToggleSaved) {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(isSaved ? "Remove from saved" : "Save article")

                    Button(action: onToggleLiked) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(isLiked ? "Unlike article" : "Like article")
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.foreground)
                .padding(.top, 20)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(palette.foreground.opacity(0.32))
                        .frame(height: 1)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, max(topInset, 44) + 40)
            .padding(.bottom, bottomInset + 42)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .contentShape(.rect)
    }
}
