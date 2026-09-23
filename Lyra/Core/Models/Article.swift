import Foundation

struct Article: Identifiable, Hashable, Codable, Sendable {
    enum Category: String, CaseIterable, Hashable, Codable, Sendable {
        case saved = "Saved"
        case artificialIntelligence = "AI"
        case distributedSystems = "Distributed Systems"
        case programming = "Programming"
        case science = "Science"
    }

    let id: UUID
    let title: String
    let source: String
    let originalURL: URL
    let hook: String
    let preview: String
    let category: Category
    let tags: [String]
    let estimatedReadMinutes: Int?
    let themeColorHex: String?
}
