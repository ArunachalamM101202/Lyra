# Immersive discovery feed

The swipe feed is a sequence of full-viewport editorial canvases. Each canvas
uses a site's palette on a calm full-screen background, with one readable system-font
hierarchy: source, title, short hook, optional preview, and a single reading cue.
The Read original button or a left swipe opens the article.

The pager clips every card to exactly one full-display frame, including the
status and home indicator areas. Text stays inside those safe areas. Dragging
follows the finger, and the page uses a 120 millisecond settle animation after release.

Article opening first checks the page for article markup. Likely articles open
in Safari with `entersReaderIfAvailable` enabled; other pages open in the
full-screen custom `ReaderView` and `ArticleWebView`. Medium article URLs use
Safari directly because Medium blocks simple page checks. Apple's Safari API
does not report Reader availability, so this route is an informed estimate.

The source color comes from the page's theme-color metadata when available.
The Netflix card uses a near-black canvas with red accent; Anthropic URLs use a
warm cream canvas with a clay-colored accent even if the site supplies no theme
metadata. Saturated theme colors become accents instead of covering the screen.
Unknown or invalid theme colors select one of 16 curated light and dark palettes
using a stable hash of the website host. Cards from the same site keep the same
palette across launches. The Discover title is removed, and Add URL appears in Library. A right swipe from Discover opens
Library; a left swipe in Library returns to Discover. Vertical swipes continue
paging through articles.

Typography uses scalable iOS system styles rather than embedding OpenAI Sans or
imitating a brand identity. Large accessible type reduces optional preview text
so the title and hook remain the focus. Foreground text switches between black
and white according to the canvas for contrast.

Sources:

- [Apple typography guidance](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Apple color guidance](https://developer.apple.com/design/human-interface-guidelines/color)
- [OpenAI design guidelines](https://openai.com/brand/)
- [Netflix brand red](https://brand.netflix.com/en/assets/logos/)
