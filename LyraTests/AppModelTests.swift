import XCTest
@testable import Lyra

@MainActor
final class AppModelTests: XCTestCase {
    func testLinksCanBeCreatedEditedDeletedAndSurviveRestart() async throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let model = fixture.model()

        let article = try await model.addArticle(from: "example.com/first")
        XCTAssertEqual(model.articles.first?.id, article.id)
        XCTAssertEqual(model.savedArticles.first?.id, article.id)

        let edited = try await model.updateArticle(
            article,
            title: "My new title",
            urlInput: "https://example.com/second",
            summary: "My notes"
        )
        XCTAssertEqual(edited.id, article.id)
        XCTAssertEqual(edited.title, "My new title")
        XCTAssertEqual(edited.hook, "My notes")
        XCTAssertEqual(fixture.model().articles.first, edited)

        try model.deleteArticle(edited)
        XCTAssertFalse(fixture.model().articles.contains { $0.id == article.id })
    }

    func testFoldersGroupLinksWithoutDeletingThem() async throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let model = fixture.model()
        let article = try await model.addArticle(from: "example.com/folder-link")

        let folder = try model.createFolder(name: "Research", colorIndex: 2)
        try model.setFolderMembership(article, folderID: folder.id, isMember: true)
        XCTAssertEqual(model.articles(in: folder.id), [article])

        try model.updateFolder(folder.id, name: "Ideas", colorIndex: 5)
        let reloaded = fixture.model()
        XCTAssertEqual(reloaded.folder(with: folder.id)?.name, "Ideas")
        XCTAssertEqual(reloaded.folder(with: folder.id)?.colorIndex, 5)
        XCTAssertEqual(reloaded.articles(in: folder.id), [article])

        try model.deleteFolder(folder.id)
        XCTAssertNil(fixture.model().folder(with: folder.id))
        XCTAssertTrue(fixture.model().savedArticles.contains(article))
    }

    func testSavedLikedAndVisitedAreIndependentAndPersisted() async throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let model = fixture.model()
        let article = try await model.addArticle(from: "example.com/read-me")

        model.toggleLiked(article)
        model.markOpened(article)
        model.unsaveArticle(article)

        let reloaded = fixture.model()
        XCTAssertFalse(reloaded.isSaved(article))
        XCTAssertTrue(reloaded.isLiked(article))
        XCTAssertTrue(reloaded.isVisited(article))
        XCTAssertEqual(reloaded.likedArticles.first?.id, article.id)
        XCTAssertEqual(reloaded.visitedArticles.first?.id, article.id)
        XCTAssertTrue(reloaded.libraryArticles.contains(article))
    }

    func testLegacyDataMigratesOnlyOnce() throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let curated = try XCTUnwrap(PreviewArticleRepository().articles().first)
        fixture.defaults.set([curated.id.uuidString], forKey: "lyra.likedArticles.v1")
        let first = fixture.model()
        XCTAssertTrue(first.isLiked(curated))

        fixture.defaults.removeObject(forKey: "lyra.likedArticles.v1")
        XCTAssertTrue(fixture.model().isLiked(curated))
    }

    func testDuplicateURLIsRejected() async throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let model = fixture.model()
        _ = try await model.addArticle(from: "example.com/a-good-article")

        do {
            _ = try await model.addArticle(from: "https://example.com/a-good-article")
            XCTFail("Expected duplicate URL error")
        } catch ArticleImportError.alreadyAdded {
            XCTAssertEqual(model.savedArticles.count, 1)
        }
    }

    func testDeletingLinkClearsFolderLikesAndVisits() async throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let model = fixture.model()
        let article = try await model.addArticle(from: "example.com/remove-me")
        let folder = try model.createFolder(name: "Read later", colorIndex: 0)
        try model.setFolderMembership(article, folderID: folder.id, isMember: true)
        model.toggleLiked(article)
        model.markOpened(article)

        try model.deleteArticle(article)
        let reloaded = fixture.model()
        XCTAssertTrue(reloaded.articles(in: folder.id).isEmpty)
        XCTAssertFalse(reloaded.isLiked(article))
        XCTAssertFalse(reloaded.isVisited(article))
        XCTAssertFalse(reloaded.libraryArticles.contains(article))
    }

    func testFolderNamesMustBeUniqueIgnoringCase() throws {
        let fixture = try TestLibrary()
        defer { fixture.remove() }
        let model = fixture.model()
        _ = try model.createFolder(name: "Research", colorIndex: 0)

        XCTAssertThrowsError(try model.createFolder(name: " research ", colorIndex: 1)) { error in
            guard case LibraryActionError.duplicateFolderName = error else {
                XCTFail("Expected a duplicate folder name error")
                return
            }
        }
    }

    func testHTMLMetadataExtraction() {
        let html = """
        <html><head>
          <meta content="A short &amp; useful introduction." name="description">
          <meta property="og:title" content="A Good Article">
          <meta name="theme-color" content="#123456">
        </head></html>
        """
        let metadata = WebArticleMetadataFetcher.parse(html)
        XCTAssertEqual(metadata.title, "A Good Article")
        XCTAssertEqual(metadata.description, "A short & useful introduction.")
        XCTAssertEqual(metadata.themeColorHex, "#123456")
    }

    func testReaderRoutingRecognizesArticleMarkup() {
        let paragraph = "<p>" + String(repeating: "A useful technical explanation. ", count: 12) + "</p>"
        let article = "<main><h1>How it works</h1>" + String(repeating: paragraph, count: 9) + "</main>"
        XCTAssertEqual(ReaderRouteResolver.classify(article), .safariReader)
        XCTAssertEqual(
            ReaderRouteResolver.classify("<meta property='og:type' content='article'>"),
            .safariReader
        )
    }

    func testReaderRoutingFallsBackForNonArticlePage() {
        let page = "<main><h1>Home</h1><p>Browse our products.</p></main>"
        XCTAssertEqual(ReaderRouteResolver.classify(page), .immersiveBrowser)
    }
}

private struct TestLibrary {
    let directory: URL
    let defaults: UserDefaults
    let store: FileLibraryStore

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LyraTests-\(UUID().uuidString)", isDirectory: true)
        defaults = UserDefaults(suiteName: "LyraTests.\(UUID().uuidString)")!
        store = FileLibraryStore(url: directory.appendingPathComponent("library.json"))
    }

    @MainActor func model() -> AppModel {
        AppModel(
            repository: PreviewArticleRepository(),
            store: store,
            legacyStorage: defaults,
            metadataFetcher: StubMetadataFetcher()
        )
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

private struct StubMetadataFetcher: ArticleMetadataFetching {
    func fetch(from url: URL) async -> ArticleMetadata {
        ArticleMetadata(
            title: "A Good Article",
            description: "A useful introduction.",
            themeColorHex: "#123456"
        )
    }
}
