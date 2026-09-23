import Foundation

enum ReaderRoute: Sendable {
    case safariReader
    case immersiveBrowser
}

/// Safari does not publish Reader eligibility, so this is a best-effort page check.
actor ReaderRouteResolver {
    static let shared = ReaderRouteResolver()

    private var cache: [URL: ReaderRoute] = [:]
    private var pending: [URL: Task<ReaderRoute, Never>] = [:]

    func route(for article: Article) async -> ReaderRoute {
        let url = article.originalURL
        if let cached = cache[url] { return cached }
        if let task = pending[url] { return await task.value }

        let task = Task { await Self.check(url) }
        pending[url] = task
        let result = await task.value
        cache[url] = result
        pending[url] = nil
        return result
    }

    private static func check(_ url: URL) async -> ReaderRoute {
        let host = url.host?.lowercased() ?? ""
        if (host == "medium.com" || host.hasSuffix(".medium.com"))
            && url.lastPathComponent.range(of: #"-[0-9a-f]{12}$"#, options: .regularExpression) != nil {
            return .safariReader
        }

        var request = URLRequest(url: url, timeoutInterval: 4)
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode),
                  response.mimeType == "text/html" else {
                return .immersiveBrowser
            }
            let prefix = Data(data.prefix(1_500_000))
            guard let html = String(data: prefix, encoding: .utf8)
                ?? String(data: prefix, encoding: .isoLatin1) else {
                return .immersiveBrowser
            }
            return Self.classify(html)
        } catch {
            return .immersiveBrowser
        }
    }

    static func classify(_ html: String) -> ReaderRoute {
        if html.range(
            of: #"(?i)"@type"\s*:\s*"(?:NewsArticle|BlogPosting|Article|TechArticle|ScholarlyArticle)""#,
            options: .regularExpression
        ) != nil {
            return .safariReader
        }

        let metaTags = matches(#"(?i)<meta\b[^>]*>"#, in: html)
        if metaTags.contains(where: { tag in
            tag.range(of: "og:type", options: .caseInsensitive) != nil
                && tag.range(
                    of: #"(?i)\bcontent\s*=\s*['"]article['"]"#,
                    options: .regularExpression
                ) != nil
        }) {
            return .safariReader
        }

        if let article = firstMatch(#"(?is)<article\b[^>]*>.*?</article>"#, in: html),
           paragraphCount(in: article) >= 4,
           wordCount(in: article) >= 180 {
            return .safariReader
        }

        if let main = firstMatch(#"(?is)<main\b[^>]*>.*?</main>"#, in: html),
           main.range(of: #"(?i)<h1\b"#, options: .regularExpression) != nil,
           paragraphCount(in: main) >= 8,
           wordCount(in: main) >= 350 {
            return .safariReader
        }

        return .immersiveBrowser
    }

    private static func paragraphCount(in html: String) -> Int {
        matches(#"(?i)<p\b"#, in: html).count
    }

    private static func wordCount(in html: String) -> Int {
        let text = html.replacingOccurrences(
            of: #"(?s)<[^>]*>"#,
            with: " ",
            options: .regularExpression
        )
        return text.split(whereSeparator: \.isWhitespace).count
    }

    private static func firstMatch(_ pattern: String, in html: String) -> String? {
        matches(pattern, in: html).first
    }

    private static func matches(_ pattern: String, in html: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            .compactMap { Range($0.range, in: html).map { String(html[$0]) } }
    }
}
