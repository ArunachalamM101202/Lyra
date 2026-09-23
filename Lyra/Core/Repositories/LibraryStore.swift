import Foundation

protocol LibraryStoring {
    func load() throws -> LibraryState?
    func save(_ state: LibraryState) throws
}

enum LibraryStoreError: LocalizedError {
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion:
            "This library was created by a newer version of Lyra."
        }
    }
}

struct FileLibraryStore: LibraryStoring {
    let url: URL

    init(url: URL? = nil) {
        if let url {
            self.url = url
        } else {
            let directory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            self.url = directory
                .appendingPathComponent("Lyra", isDirectory: true)
                .appendingPathComponent("library-v1.json")
        }
    }

    func load() throws -> LibraryState? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let state = try JSONDecoder().decode(LibraryState.self, from: Data(contentsOf: url))
        guard state.version == 1 else { throw LibraryStoreError.unsupportedVersion }
        return state
    }

    func save(_ state: LibraryState) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(state).write(to: url, options: .atomic)
    }
}
