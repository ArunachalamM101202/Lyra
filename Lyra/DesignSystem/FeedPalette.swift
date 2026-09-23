import SwiftUI

struct FeedPalette {
    let background: Color
    let foreground: Color
    let accent: Color
    let isDark: Bool

    init(article: Article) {
        let host = article.originalURL.host?.lowercased() ?? ""
        let source = article.source.lowercased()

        if host.contains("netflixtechblog") || source.contains("netflix") {
            background = Color(red: 0.075, green: 0.075, blue: 0.075)
            foreground = .white
            accent = Color(red: 229 / 255, green: 9 / 255, blue: 20 / 255)
            isDark = true
            return
        }

        if host == "anthropic.com" || host.hasSuffix(".anthropic.com")
            || host == "claude.com" || host.hasSuffix(".claude.com")
            || source.contains("anthropic") {
            background = Color(red: 0.965, green: 0.953, blue: 0.929)
            foreground = Color(red: 0.16, green: 0.15, blue: 0.14)
            accent = Color(red: 0.72, green: 0.31, blue: 0.20)
            isDark = false
            return
        }

        guard let rgb = Self.rgb(from: article.themeColorHex) else {
            let fallback = Self.fallbackPalettes[Self.fallbackIndex(for: article)]
            background = Self.color(from: fallback.background)
            foreground = Self.color(from: fallback.foreground)
            accent = Self.color(from: fallback.accent)
            isDark = fallback.isDark
            return
        }
        let saturation = max(rgb.red, rgb.green, rgb.blue)
            - min(rgb.red, rgb.green, rgb.blue)

        if saturation > 0.42 {
            background = Color(red: 0.10, green: 0.10, blue: 0.11)
            foreground = .white
            accent = Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
            isDark = true
            return
        }

        background = Color(red: rgb.red, green: rgb.green, blue: rgb.blue)

        func channel(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * channel(rgb.red)
            + 0.7152 * channel(rgb.green)
            + 0.0722 * channel(rgb.blue)
        isDark = luminance <= 0.179
        foreground = isDark ? .white : .black
        accent = foreground
    }

    private struct FallbackPalette {
        let background: UInt32
        let foreground: UInt32
        let accent: UInt32
        let isDark: Bool
    }

    private static let fallbackPalettes: [FallbackPalette] = [
        .init(background: 0x0F172A, foreground: 0xF8FAFC, accent: 0x38BDF8, isDark: true),
        .init(background: 0x102A2A, foreground: 0xF0FDFA, accent: 0x5EEAD4, isDark: true),
        .init(background: 0x211A36, foreground: 0xFAF7FF, accent: 0xC4B5FD, isDark: true),
        .init(background: 0x202A44, foreground: 0xF8FAFC, accent: 0xF9A8D4, isDark: true),
        .init(background: 0x27211E, foreground: 0xFBF7F1, accent: 0xE6B689, isDark: true),
        .init(background: 0x162B35, foreground: 0xF0F9FF, accent: 0x67E8F9, isDark: true),
        .init(background: 0x20271C, foreground: 0xF7FBEF, accent: 0xBEF264, isDark: true),
        .init(background: 0x301C2C, foreground: 0xFDF6FA, accent: 0xFDA4AF, isDark: true),
        .init(background: 0xF6F0E7, foreground: 0x28231F, accent: 0xB76E3F, isDark: false),
        .init(background: 0xEAF3F1, foreground: 0x173530, accent: 0x0F766E, isDark: false),
        .init(background: 0xF2EFFA, foreground: 0x302743, accent: 0x8B5CF6, isDark: false),
        .init(background: 0xFCEEE9, foreground: 0x472B27, accent: 0xC96B52, isDark: false),
        .init(background: 0xECF3FA, foreground: 0x1B3148, accent: 0x3B82F6, isDark: false),
        .init(background: 0xEEF2E8, foreground: 0x25352B, accent: 0x5E8C61, isDark: false),
        .init(background: 0xF7F4EC, foreground: 0x2F2B25, accent: 0xC48C37, isDark: false),
        .init(background: 0xF9EDF1, foreground: 0x432835, accent: 0xC05A7A, isDark: false)
    ]

    private static func fallbackIndex(for article: Article) -> Int {
        let host = article.originalURL.host?.lowercased()
            .replacingOccurrences(of: #"^www\."#, with: "", options: .regularExpression)
            ?? article.originalURL.absoluteString
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in host.utf8 {
            hash = (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return Int(hash % UInt64(fallbackPalettes.count))
    }

    private static func color(from value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    private static func rgb(from hex: String?) -> (red: Double, green: Double, blue: Double)? {
        guard let hex else { return nil }
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        let expanded: String
        if value.count == 3 {
            expanded = value.map { "\($0)\($0)" }.joined()
        } else {
            expanded = value
        }
        guard expanded.count == 6, let number = UInt32(expanded, radix: 16) else { return nil }
        return (
            Double((number >> 16) & 0xFF) / 255,
            Double((number >> 8) & 0xFF) / 255,
            Double(number & 0xFF) / 255
        )
    }
}
