# Original article reading experiment

## Goal

For the first two curated links, discovery should take one vertical swipe per
preview. Selecting a card should open the original article as the main reading
screen. Returning should reveal the same feed card.

## Navigation decision

- The feed remains a vertical paged `ScrollView` with a stable article ID.
- A card is a `NavigationLink` into `ReaderView`, so the system supplies a Back
  button and the usual back gesture. The feed view stays in the navigation
  stack while the article is open.
- The article uses `WKWebView` inside that screen. Apple documents `WKWebView`
  for web content embedded in an app's view hierarchy. Apple's guidance for
  `SFSafariViewController` calls for modal presentation and explicitly says not
  to embed it as a child view controller. That is why the earlier bottom sheet
  felt separate from the reading flow.
- The tab bar is hidden while reading. A single menu holds optional Done, Like,
  and Open in Safari actions. The page itself keeps normal vertical scrolling,
  links, and text selection.
- A failed main-page load offers retry and an external Safari fallback. Sites
  may still show their own sign-in, paywall, or app promotion screens.

## Verification

Build and run the iPhone 16 simulator target. Check both links, vertical paging,
opening and returning to the same card, web-page scrolling, the article menu,
and the Safari fallback if a site refuses embedded loading.

## Sources

- [Apple: NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [Apple: WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)
- [Apple: SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller)
