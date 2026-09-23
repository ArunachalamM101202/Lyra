import Foundation

struct LibraryFolder: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var colorIndex: Int
    let createdAt: Date
    var articleIDs: [Article.ID]
}

struct LibraryState: Codable, Sendable {
    var version = 1
    var importedArticles: [Article] = []
    var savedAt: [Article.ID: Date] = [:]
    var likedAt: [Article.ID: Date] = [:]
    var visitedAt: [Article.ID: Date] = [:]
    var completedAt: [Article.ID: Date] = [:]
    var folders: [LibraryFolder] = []

    static func migrate(from storage: UserDefaults) -> LibraryState {
        var state = LibraryState()
        let now = Date()

        if let data = storage.data(forKey: "lyra.savedArticles.v1"),
           let articles = try? JSONDecoder().decode([Article].self, from: data) {
            state.importedArticles = articles
            for (index, article) in articles.enumerated() {
                state.savedAt[article.id] = now.addingTimeInterval(-Double(index))
            }
        }

        func migratedDates(_ key: String) -> [Article.ID: Date] {
            var dates: [Article.ID: Date] = [:]
            for id in (storage.stringArray(forKey: key) ?? []).compactMap(UUID.init(uuidString:)) {
                dates[id] = Date(timeIntervalSince1970: 0)
            }
            return dates
        }

        state.likedAt = migratedDates("lyra.likedArticles.v1")
        state.visitedAt = migratedDates("lyra.openedArticles.v1")
        state.completedAt = migratedDates("lyra.completedArticles.v1")
        return state
    }
}
