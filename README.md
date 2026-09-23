# Lyra

**Save a link. Swipe through the ideas. Read when one catches you.**

![Lyra app walkthrough](docs/lyra-demo.gif)

Lyra is a small iPhone reader for articles and blogs. Each link becomes a full-screen card with the publisher's colors when available. Swipe between cards, open the original article in a reading view, and keep the links you want in your Library.

## What you can do

- **Read by swiping:** Swipe up or down to move through article cards. Swipe left to open the current article, or right to open Library.
- **Add your own URLs:** Paste a link in Library. Lyra fetches its title, description, and theme color when the website provides them.
- **Keep things organized:** Save and like articles, create colored folders, edit or delete links you added, and browse your visited articles.
- **Choose the right reader:** Article pages open in Safari Reader when Lyra recognizes supported article markup. Other pages open in an immersive in-app browser.
- **Pick up where you left off:** Links, folders, likes, and visits are stored locally on the device.

Lyra starts with two example articles from Uber Engineering and Netflix Technology Blog. Added links appear in both Discover and Library.

## Run it

Requirements: macOS with Xcode 27, the iOS 27 simulator runtime, and XcodeGen for the command-line workflow. The app targets iOS 18 or later.

Open [`Lyra.xcodeproj`](Lyra.xcodeproj) in Xcode, select the **Lyra** scheme and an iPhone simulator, then press **Run**. For the repository's pinned iPhone 18 Pro simulator:

```sh
make run
```

Run the unit tests with `make test`. The Makefile targets the simulator ID listed in [`setup.md`](setup.md); use Xcode's destination picker for a different simulator or a physical iPhone. A physical-device build needs an Apple development team selected in **Signing & Capabilities**.

## Project layout

| Path | Purpose |
| --- | --- |
| [`Lyra/App`](Lyra/App) | App entry point, navigation, and state |
| [`Lyra/Features/Feed`](Lyra/Features/Feed) | Full-screen cards and URL entry |
| [`Lyra/Features/Reader`](Lyra/Features/Reader) | Safari Reader routing and in-app browser |
| [`Lyra/Features/Library`](Lyra/Features/Library) | Saved, folders, liked, and visited views |
| [`Lyra/Core`](Lyra/Core) | Article models, metadata, and local JSON storage |
| [`LyraTests`](LyraTests) | Persistence and reader-routing tests |

The app is written in SwiftUI. [`project.yml`](project.yml) is the XcodeGen source of truth; the generated Xcode project is checked in so it can also be opened directly. [`design/`](design) contains the interaction and reader research.

## Current scope

Library data stays on the device; there is no account or cross-device sync. Reader availability and page appearance depend on each website's markup and loading behavior.

For environment details and simulator troubleshooting, see [`setup.md`](setup.md).
