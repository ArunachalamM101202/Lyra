protocol ArticleRepository: Sendable {
    func articles() -> [Article]
}
