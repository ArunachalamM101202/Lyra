# Lyra design research

Research snapshot: **September 21, 2026**

This folder turns current Apple platform guidance and primary-source library
documentation into implementation decisions for Lyra. It covers the product
described in [`../idea.md`](../idea.md): a swipe-first discovery feed leading
to a calm, substantive technical reader.

## Documents

- [`platform-and-liquid-glass.md`](platform-and-liquid-glass.md) — current
  Apple design language, iOS 26 foundations, iOS 27 refinements, availability,
  accessibility, and where glass belongs in Lyra.
- [`reader-rendering.md`](reader-rendering.md) — typography, Markdown, code,
  tables, math, Mermaid diagrams, WebKit, security, and the recommended render
  stack.
- [`scrolling-and-navigation.md`](scrolling-and-navigation.md) — discovery
  paging, reader scrolling, progress restoration, gesture behavior,
  performance, and accessibility.
- [`v1-blueprint.md`](v1-blueprint.md) — the consolidated design and technical
  recommendation for the first prototype.
- [`sources.md`](sources.md) — dated primary sources and why each matters.

## Executive conclusion

Lyra should feel like a reading product, not a glass-effects demo:

1. Use native `NavigationStack`, `TabView`, toolbars, menus, and sheets. These
   receive Liquid Glass and future platform refinements automatically.
2. Keep feed cards and the article body in the flat content layer. Liquid
   Glass belongs only to navigation and a very small number of floating,
   actionable controls.
3. Use vertical view-aligned paging for discovery, but ordinary continuous
   scrolling for articles. The user must always be able to stop, select text,
   inspect a diagram, and resume precisely.
4. Use a native block-based Markdown renderer. As of this research,
   **Textual** is the most capable current candidate, but its young version
   line warrants a proof-of-concept and a renderer abstraction. Apple's
   `AttributedString(markdown:)` alone is insufficient for a full technical
   document.
5. Render Mermaid in a tightly isolated local `WebView`/`WKWebView`, or
   pre-render diagrams to SVG/PNG during ingestion. Do not turn the whole
   article into a web view merely to support diagrams.
6. Make semantic structure, Dynamic Type, VoiceOver navigation, contrast, and
   reduced-motion behavior part of the content model—not a cleanup pass.

## Recommended deployment posture

- Pick the minimum deployment target based on the devices the prototype must
  support; do not raise it solely for a visual effect.
- Keep iOS 26 and iOS 27 enhancements behind small availability-gated view
  modifiers.
- Build the core feed and reader from APIs available on the chosen baseline.
- Do not reproduce Liquid Glass on older systems. Let their native materials
  and controls look native to those systems.
- Re-check iOS 27/Xcode 27 API signatures against the final SDK used to ship.

## Decision gates before implementation

Run three small spikes before committing the app architecture:

1. Render one representative long article containing nested lists, links,
   quotes, a wide table, three code languages, inline/block math, and two
   diagrams using Textual.
2. Build a 20-card vertical paging feed and measure hitching, memory, state
   restoration, VoiceOver order, and accidental horizontal navigation on a
   real lower-end supported device.
3. Render Mermaid from bundled JavaScript with networking disabled and verify
   light/dark themes, Dynamic Type alternatives, VoiceOver summaries, invalid
   syntax, and very wide diagrams.

These spikes resolve the highest-risk choices while the app is still tiny.
