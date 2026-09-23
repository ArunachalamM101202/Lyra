import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let repository: any ArticleRepository
    private let store: any LibraryStoring
    private let metadataFetcher: any ArticleMetadataFetching
    private var state: LibraryState
    private var storageAvailable = true

    private(set) var articles: [Article] = []
    var storageErrorMessage: String?

    init(
        repository: any ArticleRepository,
        store: any LibraryStoring = FileLibraryStore(),
        legacyStorage: UserDefaults = .standard,
        metadataFetcher: any ArticleMetadataFetching = WebArticleMetadataFetcher()
    ) {
        self.repository = repository
        self.store = store
        self.metadataFetcher = metadataFetcher

        var initialState = LibraryState.migrate(from: legacyStorage)
        do {
            if let stored = try store.load() {
                initialState = stored
            } else {
                try store.save(initialState)
            }
        } catch {
            storageAvailable = false
            storageErrorMessage = "Could not open your library: \(error.localizedDescription)"
        }
        state = initialState
        rebuildArticles()
    }

    var folders: [LibraryFolder] { state.folders }
    var savedArticles: [Article] { orderedArticles(by: state.savedAt) }
    var likedArticles: [Article] { orderedArticles(by: state.likedAt) }
    var visitedArticles: [Article] { orderedArticles(by: state.visitedAt) }

    var libraryArticles: [Article] {
        let folderIDs = Set(state.folders.flatMap(\.articleIDs))
        return articles.filter { article in
            state.savedAt[article.id] != nil
                || state.likedAt[article.id] != nil
                || state.visitedAt[article.id] != nil
                || state.completedAt[article.id] != nil
                || folderIDs.contains(article.id)
        }
    }

    func articles(in folderID: LibraryFolder.ID) -> [Article] {
        guard let folder = state.folders.first(where: { $0.id == folderID }) else { return [] }
        let byID = Dictionary(uniqueKeysWithValues: articles.map { ($0.id, $0) })
        return folder.articleIDs.compactMap { byID[$0] }
    }

    func folder(with id: LibraryFolder.ID) -> LibraryFolder? {
        state.folders.first { $0.id == id }
    }

    func isImported(_ article: Article) -> Bool {
        state.importedArticles.contains { $0.id == article.id }
    }

    func isSaved(_ article: Article) -> Bool { state.savedAt[article.id] != nil }
    func isLiked(_ article: Article) -> Bool { state.likedAt[article.id] != nil }
    func isCompleted(_ article: Article) -> Bool { state.completedAt[article.id] != nil }
    func isVisited(_ article: Article) -> Bool { state.visitedAt[article.id] != nil }
    func visitedDate(_ article: Article) -> Date? { state.visitedAt[article.id] }

    func isInFolder(_ article: Article, folderID: LibraryFolder.ID) -> Bool {
        folder(with: folderID)?.articleIDs.contains(article.id) == true
    }

    func addArticle(from input: String, folderID: LibraryFolder.ID? = nil) async throws -> Article {
        let url = try Self.validatedURL(from: input)
        guard !articles.contains(where: { $0.originalURL == url }) else {
            throw ArticleImportError.alreadyAdded
        }
        if let folderID, folder(with: folderID) == nil { throw LibraryActionError.folderNotFound }

        let metadata = await metadataFetcher.fetch(from: url)
        guard !articles.contains(where: { $0.originalURL == url }) else {
            throw ArticleImportError.alreadyAdded
        }

        let source = Self.source(for: url)
        let fallbackTitle = url.lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        let article = Article(
            id: UUID(),
            title: metadata.title ?? (fallbackTitle.isEmpty ? source : fallbackTitle),
            source: source,
            originalURL: url,
            hook: metadata.description.map { String($0.prefix(220)) }
                ?? "A link from \(source), ready to read.",
            preview: "",
            category: .saved,
            tags: [],
            estimatedReadMinutes: nil,
            themeColorHex: metadata.themeColorHex
        )

        try commit { state in
            state.importedArticles.insert(article, at: 0)
            state.savedAt[article.id] = Date()
            if let folderID, let index = state.folders.firstIndex(where: { $0.id == folderID }) {
                state.folders[index].articleIDs.insert(article.id, at: 0)
            }
        }
        return article
    }

    func updateArticle(
        _ article: Article,
        title: String,
        urlInput: String,
        summary: String
    ) async throws -> Article {
        guard isImported(article) else { throw LibraryActionError.notEditable }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw LibraryActionError.emptyTitle }
        let url = try Self.validatedURL(from: urlInput)
        guard !articles.contains(where: { $0.id != article.id && $0.originalURL == url }) else {
            throw ArticleImportError.alreadyAdded
        }

        let changedURL = url != article.originalURL
        let metadata = changedURL ? await metadataFetcher.fetch(from: url) : nil
        guard isImported(article) else { throw LibraryActionError.notEditable }
        guard !articles.contains(where: { $0.id != article.id && $0.originalURL == url }) else {
            throw ArticleImportError.alreadyAdded
        }

        let source = changedURL ? Self.source(for: url) : article.source
        let cleanSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = Article(
            id: article.id,
            title: cleanTitle,
            source: source,
            originalURL: url,
            hook: cleanSummary.isEmpty
                ? (metadata?.description ?? (changedURL
                    ? "A link from \(source), ready to read."
                    : article.hook))
                : cleanSummary,
            preview: changedURL ? "" : article.preview,
            category: article.category,
            tags: article.tags,
            estimatedReadMinutes: changedURL ? nil : article.estimatedReadMinutes,
            themeColorHex: changedURL ? metadata?.themeColorHex : article.themeColorHex
        )

        try commit { state in
            if let index = state.importedArticles.firstIndex(where: { $0.id == article.id }) {
                state.importedArticles[index] = updated
            }
        }
        return updated
    }

    func deleteArticle(_ article: Article) throws {
        try commit { state in
            state.importedArticles.removeAll { $0.id == article.id }
            state.savedAt[article.id] = nil
            state.likedAt[article.id] = nil
            state.visitedAt[article.id] = nil
            state.completedAt[article.id] = nil
            for index in state.folders.indices {
                state.folders[index].articleIDs.removeAll { $0 == article.id }
            }
        }
    }

    func saveArticle(_ article: Article) {
        perform { $0.savedAt[article.id] = Date() }
    }

    func unsaveArticle(_ article: Article) {
        perform { $0.savedAt[article.id] = nil }
    }

    func toggleLiked(_ article: Article) {
        perform { state in
            state.likedAt[article.id] = state.likedAt[article.id] == nil ? Date() : nil
        }
    }

    func markOpened(_ article: Article) {
        perform { $0.visitedAt[article.id] = Date() }
    }

    func markCompleted(_ article: Article) {
        perform { state in
            let now = Date()
            state.visitedAt[article.id] = now
            state.completedAt[article.id] = now
        }
    }

    func createFolder(name: String, colorIndex: Int) throws -> LibraryFolder {
        let cleanName = try validatedFolderName(name)
        let folder = LibraryFolder(
            id: UUID(),
            name: cleanName,
            colorIndex: colorIndex,
            createdAt: Date(),
            articleIDs: []
        )
        try commit { $0.folders.append(folder) }
        return folder
    }

    func updateFolder(
        _ folderID: LibraryFolder.ID,
        name: String,
        colorIndex: Int
    ) throws {
        guard folder(with: folderID) != nil else { throw LibraryActionError.folderNotFound }
        let cleanName = try validatedFolderName(name, excluding: folderID)
        try commit { state in
            if let index = state.folders.firstIndex(where: { $0.id == folderID }) {
                state.folders[index].name = cleanName
                state.folders[index].colorIndex = colorIndex
            }
        }
    }

    func deleteFolder(_ folderID: LibraryFolder.ID) throws {
        guard folder(with: folderID) != nil else { throw LibraryActionError.folderNotFound }
        try commit { $0.folders.removeAll { $0.id == folderID } }
    }

    func setFolderMembership(
        _ article: Article,
        folderID: LibraryFolder.ID,
        isMember: Bool
    ) throws {
        guard folder(with: folderID) != nil else { throw LibraryActionError.folderNotFound }
        try commit { state in
            guard let index = state.folders.firstIndex(where: { $0.id == folderID }) else { return }
            state.folders[index].articleIDs.removeAll { $0 == article.id }
            if isMember {
                state.folders[index].articleIDs.insert(article.id, at: 0)
                state.savedAt[article.id] = state.savedAt[article.id] ?? Date()
            }
        }
    }

    func clearStorageError() { storageErrorMessage = nil }

    private func orderedArticles(by dates: [Article.ID: Date]) -> [Article] {
        articles.filter { dates[$0.id] != nil }
            .sorted { left, right in
                let leftDate = dates[left.id] ?? .distantPast
                let rightDate = dates[right.id] ?? .distantPast
                return leftDate == rightDate
                    ? left.title.localizedStandardCompare(right.title) == .orderedAscending
                    : leftDate > rightDate
            }
    }

    private func validatedFolderName(
        _ name: String,
        excluding folderID: LibraryFolder.ID? = nil
    ) throws -> String {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw LibraryActionError.emptyFolderName }
        guard !state.folders.contains(where: {
            $0.id != folderID && $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame
        }) else { throw LibraryActionError.duplicateFolderName }
        return cleanName
    }

    private func commit(_ change: (inout LibraryState) -> Void) throws {
        guard storageAvailable else { throw LibraryActionError.storageUnavailable }
        var next = state
        change(&next)
        try store.save(next)
        state = next
        rebuildArticles()
    }

    private func perform(_ change: (inout LibraryState) -> Void) {
        do {
            try commit(change)
        } catch {
            storageErrorMessage = "Could not save your library: \(error.localizedDescription)"
        }
    }

    private func rebuildArticles() {
        let importedURLs = Set(state.importedArticles.map(\.originalURL))
        articles = state.importedArticles + repository.articles().filter {
            !importedURLs.contains($0.originalURL)
        }
    }

    private static func source(for url: URL) -> String {
        url.host?.replacingOccurrences(of: #"^www\."#, with: "", options: .regularExpression)
            ?? "Website"
    }

    private static func validatedURL(from input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host,
              !host.isEmpty else {
            throw ArticleImportError.invalidURL
        }
        components.fragment = nil
        guard let url = components.url else { throw ArticleImportError.invalidURL }
        return url
    }
}

enum ArticleImportError: LocalizedError {
    case invalidURL
    case alreadyAdded

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Enter a valid web address."
        case .alreadyAdded: "This article is already in your feed."
        }
    }
}

enum LibraryActionError: LocalizedError {
    case notEditable
    case emptyTitle
    case emptyFolderName
    case duplicateFolderName
    case folderNotFound
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .notEditable: "Only links you added can be edited."
        case .emptyTitle: "Give this link a title."
        case .emptyFolderName: "Give this folder a name."
        case .duplicateFolderName: "A folder with that name already exists."
        case .folderNotFound: "This folder no longer exists."
        case .storageUnavailable: "Your library file could not be opened."
        }
    }
}
