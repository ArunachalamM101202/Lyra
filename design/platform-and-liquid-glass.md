# Platform design and Liquid Glass

Research snapshot: **September 21, 2026**

## What is current

Liquid Glass arrived with the iOS 26 generation. The 2027 OS releases shown at
WWDC26 refine it rather than replace it: stronger diffusion over complex
content, clearer edge separation, brighter highlights, more consistent
toolbars, and a user-controlled system appearance ranging from clearer to more
tinted. Apps using standard controls inherit most of these refinements without
custom drawing—and, in some cases, without recompilation.

WWDC26 also adds SwiftUI toolbar adaptation controls such as visibility
priority, a dedicated overflow container, pinned trailing placement, and
navigation-bar minimization during scrolling. Treat these as progressive
enhancements rather than prerequisites for the reader.

## The governing model: two layers

Apple's current guidance separates an interface into:

- **Content layer:** the material the user came to see—article text, imagery,
  feed cards, code, tables, and diagrams.
- **UI layer:** navigation and actions floating above that content—tab bars,
  navigation bars, toolbars, menus, sheets, and a few important controls.

Liquid Glass belongs to the UI layer. It should not be used as a generic card
background or decorative article material. This distinction fits Lyra
especially well: visual effects must never compete with reading.

## What Lyra should do

### App structure

- Start with standard `TabView` and `NavigationStack` structures.
- Let system tab bars, navigation bars, sheets, alerts, menus, and toolbars
  acquire the correct appearance automatically.
- Do not install opaque custom backgrounds behind system bars unless testing
  demonstrates a real legibility problem.
- Express the Lyra brand through content typography, editorial spacing,
  illustrations, category color, and motion—not a custom navigation language.
- Lay out against available size and size class, never a device-name check.
  Resizable iPhone experiences make this increasingly important in the iOS 27
  generation.

### Feed

- Feed cards are content. Use solid or standard content surfaces with clear
  type hierarchy; do **not** apply `.glassEffect()` to every card.
- Allow imagery or restrained category color to move beneath the native bar so
  the system material can pick up context naturally.
- On supported iPhones, tab-bar minimization on downward scrolling can create
  more room for discovery. Restore it on reverse scroll through the standard
  behavior; do not build a custom disappearing bar.
- Scroll-edge effects should exist only where floating or pinned controls
  overlap scrolling content. Use the automatic/soft system behavior first.

### Reader

- The article canvas should be an opaque, calm, high-contrast reading surface.
- Keep the toolbar sparse: Back, Like, and a More menu are enough during
  reading. Place lower-frequency actions such as Share, Open Original, reader
  settings, and report/correction in the overflow menu.
- “Done” is a product-defining action. Prefer a stable end-of-article button.
  A persistent glass control is justified only if testing shows it improves
  completion without obscuring content.
- A reading-progress indicator should be visually quiet. Prefer a thin system-
  colored line attached to the navigation boundary, or display progress in
  content. Avoid a permanent glass HUD.
- Let the automatic scroll-edge treatment preserve toolbar legibility over
  text, hero images, code blocks, and diagrams before choosing a custom style.

### Custom controls

- Prefer `.buttonStyle(.glass)` or `.glassProminent` for standalone actionable
  controls rather than applying raw glass to arbitrary decoration.
- Use tint only to communicate semantic prominence, for example the primary
  “Done” action. Tinting every action destroys hierarchy.
- If a real floating cluster is needed (for example reader font controls), put
  its glass views inside one `GlassEffectContainer`. This improves sampling
  performance and enables coherent merging/morphing.
- Never put glass on glass. Hide or relocate a custom floating glass cluster
  when a glass menu or sheet would overlap it.
- Apply `.glassEffect()` after appearance and shape modifiers. Use
  `.interactive()` only for genuinely interactive elements.

## Regular versus clear glass

- **Regular** is the general-purpose, adaptive choice and maintains legibility
  across a broad range of backgrounds.
- **Clear** is permanently more transparent. Apple reserves it for bold,
  bright foreground content over rich media where a dimming treatment will not
  damage the underlying content.
- Do not mix regular and clear variants within one control system.
- Lyra has almost no strong V1 use case for clear glass. Reading surfaces and
  feed text need predictable contrast more than extra translucency.

## iOS 27 / Xcode 27 additions worth tracking

- `visibilityPriority(_:)` can keep Like or another critical toolbar item
  visible as width contracts.
- `ToolbarOverflowMenu` can force infrequent commands into overflow.
- `.topBarPinnedTrailing` can keep one truly critical action visible.
- `.toolbarMinimizeBehavior(.onScrollDown, for: .navigationBar)` can increase
  reading space, but must be tested for discoverability and accessibility.
- Liquid Glass appearance can vary with a new system preference. Never tune
  text or icons for only one translucency setting.
- Existing adopters receive many material improvements automatically. Favor
  semantic standard components so Lyra continues to benefit.

These APIs belong to the 2027 platform generation in current documentation.
Gate them by availability and verify their final signatures in the shipping
SDK. The core experience must remain complete without them.

## Backward compatibility

- The first-generation custom Liquid Glass APIs are iOS 26-era APIs. Wrap
  custom uses in `if #available(iOS 26, *)` when supporting older versions.
- On older systems, use their standard buttons, bars, and materials. Avoid a
  hand-built visual imitation of Liquid Glass.
- Recompiling with Xcode 26 makes standard controls adopt the iOS 26 design on
  that OS. The compatibility opt-out was transitional; Apple states that the
  Xcode 27 generation removes it.
- Keep compatibility code centralized in small modifiers such as
  `lyraPrimaryActionStyle()` rather than scattering availability branches
  through the feed and reader.

## Accessibility checklist

System glass automatically adapts to Reduce Transparency, Increase Contrast,
and Reduce Motion, which is another reason to prefer it over imitation.
Lyra still needs to test all combinations explicitly:

- Light and Dark appearances.
- Reduce Transparency, Increase Contrast, and Reduce Motion.
- VoiceOver and Voice Control.
- The iOS 27 glass preference at both extremes.
- Busy hero art, plain white articles, code, tables, and diagrams moving under
  bars.
- Icon-only buttons with explicit accessibility labels and standard target
  sizes.
- Large accessibility text sizes without clipped toolbar controls.

Do not encode information with glass, color, or motion alone. The state of
Like, Done, selected category, and progress needs a semantic label/value or a
second visible cue.

## Performance guidance

- Standard controls are the safest and least expensive route.
- Avoid a glass effect on each cell in a vertically moving feed. Besides being
  the wrong hierarchy, every surface needs backdrop sampling.
- Group the few custom effects in a `GlassEffectContainer`.
- Profile on hardware while continuously paging through image-heavy cards.
  Visual smoothness in a static Xcode preview is not performance evidence.

## Sources

- [What’s new in SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/)
- [Platforms State of the Union — WWDC26](https://developer.apple.com/videos/play/wwdc2026/102/)
- [SwiftUI Group Lab — WWDC26](https://developer.apple.com/videos/play/wwdc2026/8120/)
- [Communicate your brand identity on iOS — WWDC26](https://developer.apple.com/videos/play/wwdc2026/251/)
- [Meet Liquid Glass — WWDC25](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Get to know the new design system — WWDC25](https://developer.apple.com/videos/play/wwdc2025/356/)
- [Build a SwiftUI app with the new design — WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Human Interface Guidelines: Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [`GlassEffectContainer`](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [`ScrollEdgeEffectStyle`](https://developer.apple.com/documentation/swiftui/scrolledgeeffectstyle)
- [`TabBarMinimizeBehavior`](https://developer.apple.com/documentation/swiftui/tabbarminimizebehavior)
- [SwiftUI toolbars](https://developer.apple.com/documentation/swiftui/toolbars)
