# Lyra V1 design blueprint

Research snapshot: **September 21, 2026**

This is the consolidated recommendation derived from the platform, rendering,
and scrolling research. It is intentionally scoped to the 20-article personal
prototype in `idea.md`.

## Product shape

```text
Native TabView / navigation
        |
        +-- Discovery feed
        |     vertical view-aligned paging
        |     flat content cards
        |     semantic current-article state
        |
        +-- Article reader
              continuous vertical scroll
              native structured Markdown blocks
              isolated diagram renderer
              semantic progress + explicit Done
```

Liquid Glass frames this structure through the standard navigation and control
layer. It does not become the visual surface of the feed cards or reader.

## Recommended V1 stack

- **App UI:** SwiftUI with `NavigationStack`, `TabView`, `ScrollView`, and
  system toolbars/sheets/menus.
- **Feed:** `ScrollView` + `LazyVStack` + `.scrollTargetBehavior(.paging)` +
  stable article IDs and `ScrollPosition`.
- **Reader:** ordinary `ScrollView` + `VStack` to keep a short article's
  geometry and selection predictable.
- **Markdown:** prototype Textual 0.5.0 behind a Lyra-owned renderer protocol.
- **Parser fallback:** `swift-markdown` plus custom block views if Textual does
  not pass the fixture and accessibility spike.
- **Math/code:** use Textual's native support initially; cache expensive output.
- **Mermaid:** pre-render the 20 curated V1 diagrams during ingestion where
  practical. Retain source and prose description. Add a pinned local WebKit
  renderer only for diagrams that must adapt dynamically.
- **State:** persist article ID, content version, nearest block ID, progress,
  opened/completed/liked state, and timestamps. Do not make pixel offset the
  source of truth.

## Screen decisions

### Feed card

Include:

- Source/category eyebrow.
- Clear article title.
- One hook and a short preview.
- Reading time and topic.
- Optional editorial image or restrained category color.
- A full-card semantic open action.

Behavior:

- One card settles per viewport.
- The layout uses container-relative dimensions.
- Tap opens the article. Horizontal swipe can be tested later but is not
  required and must never compete with vertical paging or system back.
- Like is not necessary on the discovery card if it creates accidental taps;
  the reader toolbar and article end provide calmer contexts.
- No per-card glass.

### Reader

Include:

- Native back/navigation.
- Title, source, metadata, and optional hero at the top.
- A bounded readable text column.
- Structured/selectable article blocks.
- Horizontally scrollable code and tables only within those blocks.
- Diagrams fitted to width with a larger zoomable presentation for dense ones.
- Like and More in the native toolbar.
- Explicit Done at the end, followed by a next-article suggestion only if it
  does not dilute closure.

Behavior:

- Continuous scroll with automatic indicator behavior.
- Quiet visual progress derived from geometry.
- Resume to a stable semantic block.
- Automatic completion only after the final block is meaningfully visible;
  explicit Done remains available.
- No translucent article canvas or glass Markdown components.

### History/library

V1 only needs a straightforward native list of opened/completed/liked items.
Use standard rows and controls. This screen is functional; it does not need a
custom card or glass system.

## Deployment strategy

Textual currently sets an iOS 18 floor, which is a reasonable prototype option
if supported devices permit it. Keep the app's core behavior at that baseline.

- iOS 18+: core feed, reader, text selection, navigation transition where
  appropriate, and Textual candidate.
- iOS 26+: native Liquid Glass appearance and optional custom glass button/
  container APIs; SwiftUI `WebView` can replace the compatibility wrapper
  inside the diagram module.
- iOS 27 generation: toolbar visibility/overflow/minimization and linked
  accessibility groups as availability-gated improvements.

Do not increase the floor to iOS 26/27 solely for appearance. Do not imitate
new materials on older versions.

## Content contract

The ingestion/editorial process should guarantee:

- Stable article and block IDs.
- A content schema/version.
- Valid source and original URL.
- A short feed hook and preview written separately from article body Markdown.
- Image alt text and attribution/licensing metadata.
- Diagram title, prose description, Mermaid source, renderer version, and
  pre-rendered fallback where available.
- Code-fence language identifiers.
- Optional spoken text for complex math.
- No arbitrary raw HTML or script in article content.
- Validated/allow-listed outbound URL schemes.

## Renderer abstraction

Keep these responsibilities separate:

```text
Article Markdown + metadata
        |
        v
Parse / validate / assign semantic blocks
        |
        +-- Native text/list/quote/image/code/table/math blocks
        |
        +-- DiagramRenderer protocol
                +-- bundled pre-rendered asset
                +-- local hardened Mermaid WebKit renderer
```

This limits WebKit to the feature that needs it and allows the Markdown package
to be replaced without rewriting feed, history, or progress storage.

## State and measurement model

Persist infrequently and semantically:

- `feed_article_id`
- `article_id`
- `article_content_version`
- `resume_block_id`
- `resume_local_fraction` (optional)
- `reading_progress` (display/analytics, not sole restoration source)
- `opened_at`, `last_read_at`, `completed_at`
- `liked`, `completed`

Use visibility events and idle scroll phases to avoid database writes for every
frame. Store state in a model/repository rather than view-local state.

## Performance budget and likely hot spots

The likely problems are not simple prose. Profile:

- Feed artwork decoding and transitions during rapid paging.
- Repeated Markdown parsing when a reader view recomputes.
- Syntax highlighting for large code blocks.
- Table layout at large Dynamic Type sizes.
- Mermaid JavaScript startup/render and SVG rasterization.
- Async block height changes that move the reading location.
- Broad observable state invalidations caused by scroll geometry.

Preparse and cache immutable article representations. Reserve media dimensions.
Perform parsing/highlighting/rendering away from the main actor, then publish a
completed result.

## Accessibility definition of done

- Feed opens, pages, and announces position with VoiceOver.
- Every action is a native control with an intelligible label, value, and state.
- Article headings and links are navigable; prose supports granular reading and
  selection.
- Speak Screen can read the article in a coherent order.
- Diagrams have descriptions that communicate their conclusion.
- Code and tables remain understandable without shrinking text.
- All core content works at the largest accessibility Dynamic Type sizes.
- Reduce Motion removes nonessential scale/parallax and chooses a calm
  transition; cross-fade preference is honored.
- Reduce Transparency and Increase Contrast keep controls and content legible.
- Nothing important is communicated by color, blur, glass, or gesture alone.

## Three implementation spikes

### 1. Reader fixture

Build one deliberately difficult article in Textual. Acceptance:

- All content types render without truncation or layout loops.
- Selection, copy, VoiceOver, Speak Screen, themes, and Dynamic Type work.
- Rotation/resizing preserves a semantic location.
- No visible hitch while scrolling through large code/diagram blocks.

If it fails, use `swift-markdown` and implement Lyra-owned block views.

### 2. Feed prototype

Create 100 local fixture cards to reveal lazy behavior. Acceptance:

- Stable 60/120 Hz-feeling paging on target hardware.
- No state loss when cards are recycled.
- Correct current-card restoration after termination.
- Diagonal drags do not accidentally navigate.
- VoiceOver and Reduce Motion paths remain complete.

### 3. Diagram sandbox

Test pre-rendered and on-device Mermaid paths. Acceptance:

- Fully offline and deterministic.
- External requests/navigation impossible.
- Strict security mode, size/node/time limits, and graceful invalid-source
  fallback.
- Correct Light/Dark/contrast rendering with stable height.
- Native or verified web accessibility description.

## Explicit V1 non-goals

- Custom recommendation ranking.
- General web browsing inside the app.
- Arbitrary article HTML/JavaScript.
- A custom clone of Liquid Glass.
- Complex custom horizontal gestures.
- Infinite feed illusion before the 20 curated articles justify it.
- A universal rendering engine for every Markdown extension.

The V1 win is a polished loop—discover, understand, finish—not surface area.
