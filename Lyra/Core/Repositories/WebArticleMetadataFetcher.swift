import Foundation

struct ArticleMetadata: Sendable {
    let title: String?
    let description: String?
    let themeColorHex: String?
}

protocol ArticleMetadataFetching: Sendable {
    func fetch(from url: URL) async -> ArticleMetadata
}

struct WebArticleMetadataFetcher: ArticleMetadataFetching {
    func fetch(from url: URL) async -> ArticleMetadata {
        var request = URLRequest(url: url, timeoutInterval: 12)
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
                return ArticleMetadata(title: nil, description: nil, themeColorHex: nil)
            }

            let prefix = Data(data.prefix(2_000_000))
            guard let html = String(data: prefix, encoding: .utf8)
                ?? String(data: prefix, encoding: .isoLatin1) else {
                return ArticleMetadata(title: nil, description: nil, themeColorHex: nil)
            }
            return Self.parse(html)
        } catch {
            return ArticleMetadata(title: nil, description: nil, themeColorHex: nil)
        }
    }

    static func parse(_ html: String) -> ArticleMetadata {
        var metadata: [String: String] = [:]

        for tag in matches(#"<meta\b[^>]*>"#, in: html, options: .caseInsensitive) {
            var attributes: [String: String] = [:]
            for match in attributeMatches(in: tag) {
                attributes[match.name.lowercased()] = match.value
            }

            if let name = attributes["property"] ?? attributes["name"],
               let content = attributes["content"] {
                metadata[name.lowercased()] = clean(content)
            }
        }

        let htmlTitle = firstCapture(
            #"<title\b[^>]*>(.*?)</title>"#,
            in: html,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
        let title = metadata["og:title"] ?? metadata["twitter:title"] ?? htmlTitle.map(clean)
        let description = metadata["og:description"]
            ?? metadata["twitter:description"]
            ?? metadata["description"]

        return ArticleMetadata(
            title: title?.isEmpty == false ? title : nil,
            description: description?.isEmpty == false ? description : nil,
            themeColorHex: metadata["theme-color"] ?? metadata["msapplication-tilecolor"]
        )
    }

    private static func attributeMatches(in tag: String) -> [(name: String, value: String)] {
        let pattern = #"([A-Za-z_:][A-Za-z0-9_:.-]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(tag.startIndex..., in: tag)

        return regex.matches(in: tag, range: range).compactMap { match in
            guard let nameRange = Range(match.range(at: 1), in: tag) else { return nil }
            let value = (2...4)
                .compactMap { Range(match.range(at: $0), in: tag) }
                .first
                .map { String(tag[$0]) }
            guard let value else { return nil }
            return (String(tag[nameRange]), value)
        }
    }

    private static func matches(
        _ pattern: String,
        in text: String,
        options: NSRegularExpression.Options = []
    ) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }

    private static func firstCapture(
        _ pattern: String,
        in text: String,
        options: NSRegularExpression.Options
    ) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range])
    }

    private static func clean(_ text: String) -> String {
        let replacements = [
            "&amp;": "&", "&quot;": "\"", "&#39;": "'",
            "&apos;": "'", "&lt;": "<", "&gt;": ">", "&nbsp;": " "
        ]
        var result = text
        for (entity, replacement) in replacements {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        result = result.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: " ",
            options: .regularExpression
        )
        return result
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
