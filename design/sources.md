# Research source index

Research snapshot: **September 21, 2026**

Primary sources were preferred: Apple documentation and WWDC sessions for
platform behavior, and official project documentation/repositories for open-
source dependencies. WWDC26 describes the 2027 platform generation; those APIs
are identified as availability-gated throughout the notes.

## Latest SwiftUI and 2027 platform generation

- [What’s new in SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/)
  — refreshed Liquid Glass, adaptive toolbars, navigation-bar minimization,
  arbitrary-container swipe actions, image caching, and state/performance.
- [WWDC26 SwiftUI guide](https://developer.apple.com/wwdc26/guides/swiftui/)
  — current overview and API routing.
- [Platforms State of the Union — WWDC26](https://developer.apple.com/videos/play/wwdc2026/102/)
  — OS 27 Liquid Glass legibility/personalization refinements and automatic
  adoption behavior.
- [Dive into lazy stacks and scrolling with SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/321/)
  — lazy geometry estimates, stable identity/layout, prefetch, state, and
  diagram-loading implications.
- [Enhance the accessibility of your reading app — WWDC26](https://developer.apple.com/videos/play/wwdc2026/219/)
  — selectable native text, granular navigation, linked groups, and page-based
  reader semantics.
- [Communicate your brand identity on iOS — WWDC26](https://developer.apple.com/videos/play/wwdc2026/251/)
  — native UI layer above an expressive content layer.
- [SwiftUI Group Lab — WWDC26](https://developer.apple.com/videos/play/wwdc2026/8120/)
  — engineer guidance on limiting glass to controls/navigation.

## Liquid Glass foundation

- [Meet Liquid Glass — WWDC25](https://developer.apple.com/videos/play/wwdc2025/219/)
  — material principles, regular/clear variants, hierarchy, and automatic
  accessibility adaptation.
- [Get to know the new design system — WWDC25](https://developer.apple.com/videos/play/wwdc2025/356/)
  — control grouping, color, iconography, and functional scroll-edge effects.
- [Build a SwiftUI app with the new design — WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/)
  — standard-component adoption and SwiftUI glass APIs.
- [Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
  — current rule that Liquid Glass is a control/navigation layer, not a content
  material.
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
  — migration and testing checklist.
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
  — modifiers, effect containers, morphing, and performance.
- [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
  — grouped rendering and effect interaction.
- [`ScrollEdgeEffectStyle`](https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle)
  — automatic, soft, hard, and hidden edge behavior.
- [`TabBarMinimizeBehavior`](https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior)
  — tab-bar behavior during scrolling.
- [SwiftUI toolbars](https://developer.apple.com/documentation/swiftui/toolbars)
  — current toolbar configuration and adaptive item APIs.

## Scrolling, gestures, and performance

- [SwiftUI scroll views](https://developer.apple.com/documentation/swiftui/scroll-views)
  — API collection for positions, targets, visibility, phases, and geometry.
- [Paging scroll target behavior](https://developer.apple.com/documentation/swiftui/scrolltargetbehavior/paging)
  — container-aligned paging.
- [Creating performant scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks)
  — Apple implementation guidance.
- [`scrollPosition`](https://developer.apple.com/documentation/swiftui/view/scrollposition(_:anchor:))
  — semantic scroll position binding.
- [`onScrollPhaseChange`](https://developer.apple.com/documentation/swiftui/view/onscrollphasechange(_:))
  — tracking interaction/deceleration/idle transitions.
- [`onScrollGeometryChange`](https://developer.apple.com/documentation/swiftui/view/onscrollgeometrychange(for:of:action:))
  — efficient derived geometry observation.
- [`ScrollGeometry`](https://developer.apple.com/documentation/swiftui/scrollgeometry)
  — scroll container metrics.
- [Optimize SwiftUI performance with Instruments — WWDC25](https://developer.apple.com/videos/play/wwdc2025/306/)
  — cause/effect graph and SwiftUI performance workflow.
- [What’s new in SwiftUI — WWDC24](https://developer.apple.com/videos/play/wwdc2024/10144/)
  — modern scroll position, geometry, and visibility APIs.
- [Human Interface Guidelines: Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views)
  — paging, indicators, nested axes, and scroll affordance.
- [Human Interface Guidelines: Gestures](https://developer.apple.com/design/human-interface-guidelines/gestures/)
  — familiar gestures and non-gesture alternatives.
- [`ZoomNavigationTransition`](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)
  — system source-to-destination transition.

## Native text and WebKit

- [Foundation `AttributedString`](https://developer.apple.com/documentation/Foundation/AttributedString)
  — Markdown parsing, attributes, links, and custom extensions.
- [SwiftUI `Text` from `AttributedString`](https://developer.apple.com/documentation/swiftui/text/init%28_%3A%29)
  — supported rendering scope.
- [Building rich SwiftUI text experiences](https://developer.apple.com/documentation/swiftui/building-rich-swiftui-text-experiences)
  — Apple's WWDC25 rich-text sample.
- [Cook up a rich text experience — WWDC25](https://developer.apple.com/videos/play/wwdc2025/280/)
  — rich `AttributedString` editing and constraints.
- [WebKit for SwiftUI](https://developer.apple.com/documentation/webkit/webkit-for-swiftui)
  — `WebView`, `WebPage`, navigation, local resources, and scroll integration.
- [Meet WebKit for SwiftUI — WWDC25](https://developer.apple.com/videos/play/wwdc2025/231/)
  — architecture and local custom scheme example.
- [`WKWebView.loadHTMLString`](https://developer.apple.com/documentation/webkit/wkwebview/loadhtmlstring%28_%3Abaseurl%3A%29)
  — compatibility path for local HTML.
- [Dynamic Type — WWDC24](https://developer.apple.com/videos/play/wwdc2024/10074/)
  — scalable text/layout guidance.

## Markdown and rich-content projects

- [Swift Markdown](https://github.com/swiftlang/swift-markdown)
  — official Swift-project GFM parser/AST; Apache-2.0.
- [Swift Markdown package index](https://swiftpackageindex.com/swiftlang/swift-markdown)
  — release/platform currency.
- [Textual](https://github.com/gonzalezreal/textual)
  — active SwiftUI structured-text renderer; MIT.
- [Textual releases](https://github.com/gonzalezreal/textual/releases)
  — current version and change history.
- [Textual package index](https://swiftpackageindex.com/gonzalezreal/textual)
  — platform and package status.
- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui)
  — maintenance-mode notice and feature baseline.
- [SwiftUI Math](https://github.com/gonzalezreal/swiftui-math)
  — native vector math engine used by Textual.
- [HighlighterSwift](https://github.com/smittytone/HighlighterSwift)
  — possible code-highlighting fallback; not the default recommendation.

## Mermaid

- [Mermaid usage](https://mermaid.js.org/config/usage)
  — render API and security-level behavior.
- [Mermaid configuration schema](https://mermaid.js.org/config/schema-docs/config)
  — configuration and locked security keys.
- [Mermaid accessibility](https://mermaid.js.org/config/accessibility)
  — `accTitle`, `accDescr`, SVG title/description, and ARIA behavior.
- [Mermaid releases](https://github.com/mermaid-js/mermaid/releases)
  — version/layout change tracking.
- [Mermaid security](https://github.com/mermaid-js/mermaid/security)
  — advisories and update monitoring.

## Source policy

Version numbers and maintenance status are a snapshot, not a permanent fact.
Re-check package releases, minimum deployment targets, licenses, security
advisories, and Apple API availability immediately before implementation and
again before shipping.
