# Scrolling, paging, navigation, and reading progress

Research snapshot: **September 21, 2026**

## Two scrolling modes, two jobs

The discovery feed and article reader should not share interaction behavior:

- **Feed:** discrete, view-aligned vertical paging that makes one article easy
  to evaluate at a time.
- **Reader:** continuous vertical scrolling with stable position, selection,
  accessibility navigation, and calm motion.

The reader is where comprehension happens. Do not carry the feed's snap and
gesture intensity into it.

## Discovery feed structure

A suitable starting structure is:

```swift
ScrollView(.vertical) {
    LazyVStack(spacing: 0) {
        ForEach(articles) { article in
            FeedCard(article: article)
                .containerRelativeFrame([.horizontal, .vertical])
                .id(article.id)
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.paging)
.scrollPosition($feedPosition)
```

- `.paging` gives container-aligned settling for one-card-per-screen discovery.
- `.containerRelativeFrame` uses the real scroll container rather than
  `UIScreen.main.bounds`, so it survives rotation, Split View, and resizable
  windows.
- Use stable article IDs. Each `ForEach` iteration should produce one stable,
  top-level card.
- Start with `LazyVStack` for a growing feed. If the V1 corpus is exactly 20
  light cards, compare it to a regular `VStack`; Apple notes that non-lazy
  stacks have more deterministic layout and lazy containers should earn their
  complexity through profiling.

## Position, impressions, and history

- Bind feed position to a semantic article ID, not a raw content offset.
- Use target visibility changes to identify the current card. A threshold in
  the `0.6...0.8` range is a reasonable experimental starting point; it must be
  tuned against card layout.
- Commit an “opened/impression” event only after the card meets the chosen
  visibility and dwell criteria. A fast fly-by is not meaningful reading.
- Use scroll-phase changes to batch/persist state once movement returns to idle
  rather than writing on every frame.
- Store current article, history, likes, and completion outside card-local
  `@State`. Lazy containers can destroy off-screen views.
- Avoid analytics based on absolute content offsets. Lazy stacks estimate
  off-screen geometry and revise it as content is realized.

## Feed affordance

- Preserve system physics and bounce behavior.
- Show a restrained glimpse or gradient cue for the next article if a full
  screen card makes scrollability unclear.
- An open-ended feed should not use conventional page dots. If the 20-article
  prototype is deliberately finite, test a quiet “3 of 20” accessibility value
  rather than a large page-control treatment.
- Do not show both a same-axis page control and scroll indicator.
- Keep animation subtle: small opacity/scale changes can reinforce focus, but
  large rotations/translations create motion fatigue and may defeat lazy
  visibility assumptions.

## Opening an article

The primary action should be a full-card `NavigationLink` or semantic Button
that pushes into a `NavigationStack`.

This preserves expected navigation, the system edge-swipe-back gesture,
keyboard/VoiceOver/Voice Control access, and platform transitions.

The idea document mentions horizontal swipe. Treat that as optional sugar:

- Keep tap as the complete, discoverable action.
- If user testing justifies horizontal swipe, direction-lock only after the
  horizontal translation clearly dominates vertical movement.
- Avoid `highPriorityGesture` across the entire card unless testing proves it
  does not steal vertical paging.
- Never defer or replace the system back-edge gesture for this feature.
- Provide a non-gesture alternative for every custom gesture.

On iOS 18+, the system zoom navigation transition can visually connect a card
and article. Use it only if it remains calm; fall back to automatic/cross-fade
when Reduce Motion or a cross-fade preference is active.

## Reader structure

Use an ordinary vertical `ScrollView` with a regular `VStack` for a typical
5–8 minute article. Benefits include stable whole-document geometry, simpler
selection, predictable progress, and no loss of off-screen block state.

Only switch to lazy article blocks after Instruments and real-device testing
show a material cost. If that happens:

- Pre-parse the article before scrolling.
- Keep one stable top-level view and ID per block.
- Keep reading state in the model, not the block view.
- Reserve image/diagram dimensions before loading.
- Do not radically change a block's layout in `onAppear`.

## Progress and restoration

Use geometry to drive the on-screen percentage, but persist semantic position.

### Visual progress

Transform scroll geometry immediately into the smallest useful `Equatable`
value, such as an integer percentage. Do not inject raw per-frame geometry into
a broad observable model.

```swift
.onScrollGeometryChange(for: Int.self) { geometry in
    let distance = max(
        1,
        geometry.contentSize.height - geometry.containerSize.height
    )
    let travelled = max(
        0,
        geometry.contentOffset.y + geometry.contentInsets.top
    )
    return Int((min(1, travelled / distance) * 100).rounded())
} action: { _, percent in
    displayedProgress = percent
}
```

Throttle database writes to meaningful changes or wait until the scroll phase
becomes idle.

### Resume position

Persist:

- Article ID and content version.
- Nearest stable block ID.
- Optional local fraction/character anchor within that block.
- Last meaningful visual percentage for display only.

A raw pixel offset or percentage is not a reliable resume anchor after Dynamic
Type changes, rotation, width changes, image arrival, or article corrections.
If the content version changes and the block no longer exists, restore to the
nearest surviving block or a conservative percentage fallback.

### Completion

Do not infer completion merely because an estimated total offset approaches
the bottom. Mark an article completed when:

- The final semantic content block crosses a visibility threshold, or
- The user explicitly taps Done.

Keep Done available at the end even if automatic completion exists; explicit
closure is part of Lyra's product philosophy.

## Lazy stack rules from WWDC26

Apple's latest dedicated guidance has several direct implications:

- Lazy stacks estimate off-screen dimensions; total size and absolute offsets
  can change as estimates improve.
- A `LazyVStack` derives ideal width from its first subview. Make the first card
  horizontally flexible.
- A nested horizontal lazy stack derives height from its first child. Give
  horizontal code/table/diagram regions stable heights or reserved space.
- Filter and transform data before `ForEach`; avoid branches that return zero
  or multiple top-level cells.
- Avoid geometry measurement that mutates cell state and triggers a second
  layout pass.
- Keep scroll transitions from translating an otherwise off-screen item into
  view. Small fade/scale effects are safer.
- Lazy containers prefetch. Heavy synchronous work in `onAppear` defeats that
  benefit.
- Diagram/image parsing and rasterization should happen away from the main
  actor; publish a completed, cacheable result.

## Accessibility

- Use native selectable text for prose. Test VoiceOver word, line, character,
  heading, link, and read-all navigation.
- Preserve block semantics rather than exposing the article as a single giant
  label.
- Every diagram needs a useful spoken description of what it communicates.
- Make feed cards `NavigationLink`s/Buttons, not tap gestures.
- If custom paging ever bypasses native scroll semantics, add an accessibility
  scroll action and announce the new article/title and position.
- Respect `accessibilityReduceMotion` and
  `accessibilityPrefersCrossFadeTransitions`.
- At accessibility text sizes, allow the card to recompose. Do not force the
  same number of preview lines or truncate critical controls.
- Test Switch Control, Voice Control, hardware keyboard focus, and VoiceOver
  while paging rapidly.

## iOS 27 generation enhancements

Availability-gate these; V1 need not require them:

- Navigation-bar minimization during downward scrolling.
- Toolbar item visibility priority, explicit overflow, and pinned trailing
  placement.
- Swipe actions in arbitrary scroll containers through
  `swipeActionsContainer()`.
- Linked accessibility groups for continuous granular reading across multiple
  selectable text blocks.
- Improved `AsyncImage` HTTP caching and request/session customization.

Reader-bar minimization is promising but should be tested with progress,
VoiceOver, larger type, and the ability to find actions. Maximizing pixels is
not worth making Like, More, or Back feel unstable.

## Verification plan

- Rapidly page through at least 100 fixture cards, including cached and missing
  artwork.
- Profile on the slowest supported physical device with SwiftUI, Hangs,
  Hitches, and Time Profiler instruments.
- Rotate and resize while stopped mid-feed and mid-article.
- Change Dynamic Type while an article is open, relaunch, and validate semantic
  restoration.
- Test vertical paging while making small diagonal drags near both screen edges.
- Test VoiceOver paging and opening without relying on gesture direction.
- Confirm Reduce Motion removes scale/parallax and uses a calmer navigation
  transition.
- Confirm asynchronous tables/images/diagrams do not cause the visible passage
  to jump.

## Sources

- [Paging scroll target behavior](https://developer.apple.com/documentation/swiftui/scrolltargetbehavior/paging)
- [SwiftUI scroll views](https://developer.apple.com/documentation/swiftui/scroll-views)
- [Creating performant scrollable stacks](https://developer.apple.com/documentation/swiftui/creating-performant-scrollable-stacks)
- [`scrollPosition`](https://developer.apple.com/documentation/swiftui/view/scrollposition(_:anchor:))
- [`onScrollPhaseChange`](https://developer.apple.com/documentation/swiftui/view/onscrollphasechange(_:))
- [`onScrollGeometryChange`](https://developer.apple.com/documentation/swiftui/view/onscrollgeometrychange(for:of:action:))
- [`ScrollGeometry`](https://developer.apple.com/documentation/swiftui/scrollgeometry)
- [Dive into lazy stacks and scrolling with SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/321/)
- [Enhance the accessibility of your reading app — WWDC26](https://developer.apple.com/videos/play/wwdc2026/219/)
- [What’s new in SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/)
- [Optimize SwiftUI performance with Instruments — WWDC25](https://developer.apple.com/videos/play/wwdc2025/306/)
- [What’s new in SwiftUI — WWDC24](https://developer.apple.com/videos/play/wwdc2024/10144/)
- [Human Interface Guidelines: Gestures](https://developer.apple.com/design/human-interface-guidelines/gestures/)
- [Human Interface Guidelines: Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views)
- [`ZoomNavigationTransition`](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)
- [Dynamic Type — WWDC24](https://developer.apple.com/videos/play/wwdc2024/10074/)
