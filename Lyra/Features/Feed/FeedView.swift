import SwiftUI

struct FeedView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentArticleID: Article.ID?
    @State private var dragOffset: CGFloat = 0
    let onSwipeToLibrary: () -> Void
    let onOpenArticle: (Article) -> Void

    private var currentIndex: Int {
        model.articles.firstIndex { $0.id == currentArticleID } ?? 0
    }

    private var currentArticle: Article? {
        model.articles.first(where: { $0.id == currentArticleID }) ?? model.articles.first
    }

    private var visibleIndices: [Int] {
        guard !model.articles.isEmpty else { return [] }
        return Array(max(0, currentIndex - 1)...min(model.articles.count - 1, currentIndex + 1))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                forEachCards(in: geometry.size, safeAreaInsets: geometry.safeAreaInsets)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .contentShape(Rectangle())
            .highPriorityGesture(pageGesture(pageHeight: geometry.size.height))
            .accessibilityAction(named: "Next article") {
                moveArticle(by: 1)
            }
            .accessibilityAction(named: "Previous article") {
                moveArticle(by: -1)
            }
            .accessibilityAction(named: "Open article") {
                if let article = currentArticle { onOpenArticle(article) }
            }
            .accessibilityAction(named: "Open Library", onSwipeToLibrary)
        }
        .ignoresSafeArea()
        .background {
            if let article = currentArticle {
                FeedPalette(article: article).background.ignoresSafeArea()
            }
        }
        .preferredColorScheme(currentArticle.map {
            FeedPalette(article: $0).isDark ? .dark : .light
        })
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if currentArticleID == nil {
                currentArticleID = model.articles.first?.id
            }
        }
    }

    @ViewBuilder
    private func forEachCards(in size: CGSize, safeAreaInsets: EdgeInsets) -> some View {
        ForEach(visibleIndices, id: \.self) { index in
            let article = model.articles[index]
            FeedCardView(
                article: article,
                topInset: safeAreaInsets.top,
                bottomInset: safeAreaInsets.bottom,
                onReadOriginal: { onOpenArticle(article) },
                isSaved: model.isSaved(article),
                onToggleSaved: {
                    if model.isSaved(article) {
                        model.unsaveArticle(article)
                    } else {
                        model.saveArticle(article)
                    }
                },
                isLiked: model.isLiked(article),
                onToggleLiked: { model.toggleLiked(article) }
            )
            .frame(width: size.width, height: size.height)
            .offset(y: CGFloat(index - currentIndex) * size.height + dragOffset)
            .accessibilityHidden(index != currentIndex)
        }
    }

    private func pageGesture(pageHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { gesture in
                let movement = gesture.translation
                guard abs(movement.height) > abs(movement.width) * 1.15 else {
                    dragOffset = 0
                    return
                }

                let isAtStart = currentIndex == 0 && movement.height > 0
                let isAtEnd = currentIndex == model.articles.count - 1 && movement.height < 0
                dragOffset = isAtStart || isAtEnd
                    ? movement.height * 0.18
                    : movement.height
            }
            .onEnded { gesture in
                let movement = gesture.translation
                if abs(movement.width) > 80
                    && abs(movement.width) > abs(movement.height) * 1.4 {
                    dragOffset = 0
                    if movement.width < 0 {
                        if let article = currentArticle { onOpenArticle(article) }
                    } else {
                        onSwipeToLibrary()
                    }
                    return
                }

                let projected = gesture.predictedEndTranslation.height
                let direction: Int
                if movement.height < -65 || projected < -pageHeight * 0.22 {
                    direction = 1
                } else if movement.height > 65 || projected > pageHeight * 0.22 {
                    direction = -1
                } else {
                    direction = 0
                }
                moveArticle(by: direction)
            }
    }

    private func moveArticle(by direction: Int) {
        let nextIndex = currentIndex + direction
        let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.12)
        withAnimation(animation) {
            if model.articles.indices.contains(nextIndex) {
                currentArticleID = model.articles[nextIndex].id
            }
            dragOffset = 0
        }
    }

}

#Preview {
    NavigationStack {
        FeedView(onSwipeToLibrary: {}, onOpenArticle: { _ in })
    }
    .environment(AppModel(repository: PreviewArticleRepository()))
}
