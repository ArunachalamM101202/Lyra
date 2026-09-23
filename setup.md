# Lyra development setup

## Supported local environment

This repository is configured and verified for:

- **Xcode:** 27.0 (`27A266a`)
- **Swift:** 6.4 toolchain, Swift language mode 6
- **Minimum deployment target:** iOS 18.0
- **Development simulator:** **iPhone 18 Pro running iOS 27.0**
- **Simulator device ID:** `3E8101D8-44A6-4A22-8A88-A6D35EF74DEE`
- **Project generator:** XcodeGen 2.45.3

The Mac may contain other simulator devices and runtimes installed by Xcode,
but Lyra's checked-in development commands intentionally target only the
iPhone 18 Pro above. They do not select an iPad, another iPhone, or another iOS
runtime.

The target is iPhone-only (`TARGETED_DEVICE_FAMILY = 1`). The app remains
responsive to varying window widths; the iPhone 18 Pro selection is a local
development/test destination, not permission to hard-code screen dimensions.

## First-time setup

From the repository root:

```sh
make resolve
make build
make test
```

`make resolve` generates `Lyra.xcodeproj` from `project.yml` and resolves the
Swift package dependency. The generated Xcode project is checked in for
convenience, but `project.yml` is the source of truth for project structure and
build settings.

## Run in the simulator

```sh
make run
```

This command:

1. Verifies the exact iPhone 18 Pro simulator exists.
2. Boots it and waits until it is ready.
3. Builds Lyra into repository-local `build/DerivedData`.
4. Installs and launches `com.lyra.reader`.

To open the project manually:

```sh
open Lyra.xcodeproj
```

In Xcode, select the shared **Lyra** scheme and the **iPhone 18 Pro (iOS 27.0)**
destination before pressing Run. The command-line workflow is preferred because
it pins the exact simulator device instead of relying on Xcode's last-selected
destination.

## Common commands

```sh
make generate          # Regenerate Lyra.xcodeproj after project.yml changes
make resolve           # Resolve Swift packages
make build             # Build for the configured iPhone 18 Pro
make test              # Run tests on the configured iPhone 18 Pro
make run               # Boot, build, install, and launch
make clean             # Clean repository-local build products
make verify-simulator  # Confirm the configured device is available
```

## Repository structure

```text
Lyra/
  App/             App entry point and application state
  Core/            Models and repositories
  DesignSystem/    Shared visual tokens and reusable styles
  Features/
    Feed/           Paged article discovery
    Reader/         Markdown reader and completion flow
    Library/        Reading history, liked, and completed articles
  Resources/       Asset catalogs
LyraTests/         Unit tests
project.yml        XcodeGen source of truth
Makefile           Pinned simulator development commands
```

## Package policy

The project currently pins
[Textual 0.5.0](https://github.com/gonzalezreal/textual) for the Markdown
renderer. It is kept behind
`ArticleMarkdownView` so it can be replaced by a Lyra-owned renderer without
changing feed, reader, or persistence code.

When changing a package version, regenerate, build, run tests, and inspect
`Package.resolved` before committing.

## Simulator troubleshooting

Confirm the configured device:

```sh
xcrun simctl list devices available | grep "iPhone 18 Pro"
```

If the ID changes because the simulator was deleted and recreated, update
`SIMULATOR_ID` in `Makefile` and this document together. Keep the runtime at
iOS 27.0 unless the project's supported simulator is intentionally migrated.

Xcode 27 presents simulator devices through **DeviceHub** rather than the older
standalone Simulator application; `make run` opens Xcode's bundled DeviceHub.

If CoreSimulator is unresponsive, quit DeviceHub and Xcode, reopen Xcode once,
then retry `make verify-simulator`. Avoid deleting simulator data unless the
device is genuinely corrupted because that removes installed apps and state.

## Signing

Simulator builds and tests disable code signing. Running on a physical device
later requires selecting a Development Team in Xcode; no personal team ID is
committed to the repository.
