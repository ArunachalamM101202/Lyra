# Reader rendering: text, Markdown, code, math, and diagrams

Research snapshot: **September 21, 2026**

## Recommendation

Keep Markdown as the canonical article format and render it as semantic native
SwiftUI blocks. Prototype **Textual 0.5.0** as the V1 renderer. Put the renderer
behind a small Lyra-owned interface because Textual is still a young `0.x`
package. Render Mermaid separately with a pinned, local, hardened WebKit
component—or pre-render curated V1 diagrams during ingestion.

Do not render the entire article in WebKit simply to support Mermaid. Native
blocks integrate better with Dynamic Type, platform typography, selection,
theming, reader progress, and SwiftUI navigation.

## Why `Text(AttributedString)` is not enough

Foundation can parse Markdown into `AttributedString`, including inline
emphasis, links, presentation intents, custom Markdown attributes, and relative
URL resolution. SwiftUI `Text` is an excellent choice for hooks, previews,
captions, and other inline-rich content.

It is not a complete technical-document engine. SwiftUI `Text` renders only a
subset of Foundation attributes and does not independently solve block layout
for headings, fenced code, tables, images, diagram fences, math, or custom
article semantics.

Use native `Text` for feed cards and small labels; use a structured block
renderer for articles.

## Renderer candidates

| Option | Strengths | Risks / gaps | Lyra decision |
| --- | --- | --- | --- |
| `AttributedString` + `Text` | First-party, lightweight, offline, excellent inline adaptation | Not a full block-document renderer | Use for previews and leaf text, not whole articles |
| Textual 0.5.0 | Native SwiftUI pipeline; headings, lists, tables, code, images, selection, math, syntax themes, font-relative Dynamic Type spacing | New `0.x` project; iOS 18+; exact Markdown dialect needs fixture testing | **V1 proof-of-concept leader** |
| `swift-markdown` + Lyra renderer | Active Swift project; cmark-gfm AST; immutable/thread-safe/COW tree; maximum semantics and control | Lyra must implement and maintain every block, selection interaction, table, image, code, and accessibility behavior | Fallback if Textual fails; likely long-term option if needs become specialized |
| MarkdownUI | Mature-looking GFM SwiftUI renderer; iOS 15+; customizable; MIT | Repository is explicitly in maintenance mode and points to Textual | Do not begin new V1 work unless target support forces it and risks are accepted |
| Whole-article WebKit | Full HTML/CSS/JS ecosystem; easy Mermaid/KaTeX integration | Heavier; security boundary expands; native selection/accessibility/theming and scroll progress become harder | Avoid for primary reader |

### Textual-specific findings

Textual is the active successor to MarkdownUI. Its documented features include:

- `InlineText` and `StructuredText`.
- Native text selection and copy/paste.
- Asynchronously resolved attachments.
- Headings, paragraphs, blockquotes, lists, tables, links, code blocks, and
  per-block styling.
- Syntax highlighting with customizable themes.
- Inline and block math.
- Font-relative layout measurements that scale with Dynamic Type and
  accessibility settings.
- A pluggable `MarkupParser` abstraction.

Current costs: it requires iOS 18, Swift tools 6, and remains early in its
release life. Its built-in Markdown path uses Foundation parsing, so Lyra must
test nested lists, task lists, tables, raw HTML, footnotes, long tokens, and
other corpus-specific syntax rather than assume GFM parity.

## Proposed reader component boundary

The rest of the app should not import a third-party Markdown type. Convert a
stored article into Lyra-owned blocks:

```swift
enum ArticleBlock: Identifiable, Sendable {
    case heading(id: String, level: Int, text: String)
    case paragraph(id: String, markdown: String)
    case list(id: String, ordered: Bool, items: [ListItem])
    case quote(id: String, markdown: String)
    case code(id: String, language: String?, source: String)
    case table(id: String, table: ArticleTable)
    case math(id: String, source: String, display: Bool, spoken: String?)
    case image(id: String, asset: ArticleImage)
    case diagram(id: String, source: String, title: String, description: String)
}
```

This makes semantic progress restoration, correction/versioning, testing, and
renderer replacement possible. Stable block IDs should come from ingestion,
not array offsets or hashes that change with every typo fix.

If Textual renders a complete document best, Lyra can still maintain a parallel
block index for anchors, accessibility metadata, and custom Mermaid insertion.

## Typography and article measure

- Prefer system text styles and relative sizing. Do not freeze point sizes.
- Use a readable line length on wide/resizable layouts. Center the article in a
  bounded column while allowing code, tables, and diagrams to opt into a wider
  presentation when needed.
- Scale vertical rhythm with type. Textual's font-relative spacing is useful
  here.
- Preserve semantic heading hierarchy; avoid styling every heading as a custom
  bold paragraph.
- Enable text selection for prose and code.
- Use semantic foreground/background colors that adapt to Light, Dark, and
  Increased Contrast appearances.
- Avoid placing prose on translucent or image-heavy backgrounds.

## Code blocks

- Default to horizontal scrolling rather than soft-wrapping code, with an
  optional wrap toggle if testing supports it.
- Display the language when known and provide a native Copy button.
- Keep code selectable, monospaced, and high contrast.
- Highlight off the main thread and cache results; never tokenize a large block
  repeatedly during scroll layout.
- Start with Textual's bundled syntax support. Add another highlighter only if
  the representative corpus exposes a real gap.
- Avoid the legacy Highlightr dependency; its project now marks itself
  unmaintained. HighlighterSwift is an available successor but reports iOS as
  untested, so it is not the default choice.

## Tables

- Put only the table block inside a horizontal `ScrollView`; retain one native
  vertical article scroll.
- Never shrink an entire table below readable type sizes to make it fit.
- Give cells comfortable minimum widths and allow Dynamic Type expansion.
- Preserve header/row associations for VoiceOver. If native traversal is not
  understandable, provide a row-by-row semantic summary.
- Test links, code, long unbroken values, and multiple paragraphs in cells.

## Math

Textual integrates `swiftui-math`, which provides native vector inline and
display math, bundled fonts, offline operation, tint adaptation, and an iOS 17+
base. It supports math mode, not arbitrary LaTeX documents.

- Prefer vector math to bitmap/WebKit output for scaling and theming.
- Store or generate a spoken alternative for equations whose visual notation
  is not read meaningfully.
- Validate VoiceOver output rather than assuming a visible equation is
  accessible.

## Mermaid diagrams

There is no sufficiently mature native Swift Mermaid renderer in the reviewed
sources. The realistic choices are:

1. **Pre-render during ingestion.** Best V1 safety and runtime performance for
   20 curated articles. Store source plus SVG/PNG variants and a textual
   description.
2. **Render locally on device.** Bundle a pinned Mermaid JS build and run it in
   an isolated WebKit renderer. This enables theme and width re-rendering but
   adds JavaScript, security, caching, and sizing complexity.

Mermaid 12.0.0 was current during this research. Its releases can change
layout, theme, and included rendering engines, so pin the version and maintain
visual fixtures.

### Required diagram metadata

Every diagram must have:

- A concise visible title.
- A useful prose description explaining the architecture or conclusion—not
  merely “flowchart.”
- Mermaid `accTitle` and `accDescr` when live SVG is used.
- Equivalent native accessibility metadata if the SVG is converted to an
  `Image`, because SVG ARIA semantics will otherwise be lost.
- A graceful source/error fallback and an option to open a larger zoomable
  view.

### Diagram layout

- Disable inner vertical scrolling in the article.
- Fit simple diagrams to the reader width.
- Give dense diagrams a tap-to-open zoom/pan view rather than tiny labels.
- Reserve a stable aspect-ratio placeholder before asynchronous rendering so
  the article does not jump while the user reads.
- Cache output using a key containing Mermaid version, source hash, color
  scheme/contrast, target width, and text-size bucket.
- Put a strict upper bound on source length, node/edge count, render time, and
  output dimensions.

### WebKit hardening

- Bundle Mermaid and all required assets; never depend on a CDN.
- Use Mermaid's default `securityLevel: "strict"` or stronger sandbox mode.
  Never use `loose` for article-authored input.
- Load only local/custom-scheme resources.
- Reject every external navigation. Open explicitly allowed article links
  through the app/system browser instead.
- Use a restrictive Content Security Policy, for example:

```text
default-src 'none';
script-src 'self';
style-src 'self' 'unsafe-inline';
img-src 'self' data:;
font-src 'self';
connect-src 'none'
```

- Do not add native JavaScript message handlers unless absolutely necessary.
- Patch the pinned Mermaid version deliberately; the project has published
  security advisories involving untrusted diagram content.
- Sanitize extracted SVG if it leaves the isolated rendering context.

On iOS 26+, Apple's SwiftUI `WebView`/`WebPage` APIs provide native SwiftUI
integration, navigation decisions, scroll control, and local URL scheme
handling. For an iOS 18 floor, a small `WKWebView` wrapper is still required;
hide that implementation behind one diagram interface.

## Accessibility and reading continuity

WWDC26's reading-app guidance reinforces using selectable native text. Native
text-input semantics give VoiceOver and Speak Screen word, line, character,
selection, and read-all behavior that custom drawing would have to recreate.

- Keep headings, paragraphs, lists, code, captions, and diagrams as semantic
  elements; do not collapse the article into one accessibility label.
- Test continuous VoiceOver reading across separately rendered blocks.
- On the 2027 platform generation,
  `accessibilityLinkedGroup(id:in:)` can connect separate selectable text
  elements for continuous granular reading. Use it behind availability and
  retain a meaningful older-OS fallback.
- Test heading rotor navigation, link navigation, selection, Speak Screen, and
  Accessibility Reader.
- Every image needs meaningful alternative text or must be explicitly
  decorative.
- At the largest accessibility sizes, reflow and scroll; never truncate core
  article content.

## Performance

- Parse Markdown and prepare syntax/diagram work outside the scrolling hot
  path, then publish immutable render results.
- Cache the parsed article for its content version.
- A 5–8 minute article should begin with a normal `VStack`, not a lazy stack.
  It gives more deterministic geometry and simpler selection/progress behavior.
  Change only after profiling shows a real problem.
- If article blocks become lazy, keep all reading state in the article model;
  off-screen view state is disposable.
- Avoid `onAppear` work that radically changes block height.
- Profile real articles containing wide tables, large code blocks, images,
  math, and diagrams on hardware.

## Renderer spike acceptance fixture

The proof article should contain:

- All heading levels and multiple paragraphs.
- Nested ordered/unordered/task lists.
- Blockquotes and inline/fenced code in several languages.
- A wide table with links and long tokens.
- Local and remote images, including failures and alt text.
- Inline and display math.
- Multiple valid Mermaid types plus invalid and intentionally hostile input.
- RTL, CJK, emoji, combining characters, and very long unbroken strings.
- At least one 300-line code block.

Verify it in Light/Dark/Increase Contrast, every Dynamic Type category,
Reduce Motion, VoiceOver read-all/rotor/selection, Speak Screen, airplane mode,
rotation/resizing, and Instruments scroll/memory traces.

## Sources

- [Foundation `AttributedString`](https://developer.apple.com/documentation/Foundation/AttributedString)
- [SwiftUI `Text` from an attributed string](https://developer.apple.com/documentation/swiftui/text/init%28_%3A%29)
- [Swift Markdown](https://github.com/swiftlang/swift-markdown)
- [Textual](https://github.com/gonzalezreal/textual)
- [Textual releases](https://github.com/gonzalezreal/textual/releases)
- [MarkdownUI maintenance notice](https://github.com/gonzalezreal/swift-markdown-ui)
- [SwiftUI Math](https://github.com/gonzalezreal/swiftui-math)
- [Mermaid usage and security levels](https://mermaid.js.org/config/usage)
- [Mermaid accessibility](https://mermaid.js.org/config/accessibility)
- [Mermaid security advisories](https://github.com/mermaid-js/mermaid/security)
- [Mermaid releases](https://github.com/mermaid-js/mermaid/releases)
- [WebKit for SwiftUI](https://developer.apple.com/documentation/webkit/webkit-for-swiftui)
- [`WKWebView.loadHTMLString`](https://developer.apple.com/documentation/webkit/wkwebview/loadhtmlstring%28_%3Abaseurl%3A%29)
- [Enhance the accessibility of your reading app — WWDC26](https://developer.apple.com/videos/play/wwdc2026/219/)
- [Dive into lazy stacks and scrolling with SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/321/)
- [Meet WebKit for SwiftUI — WWDC25](https://developer.apple.com/videos/play/wwdc2025/231/)
