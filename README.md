# MacMarker

A native macOS menu bar app for drawing over your Mac desktop and a mirrored Sidecar display. MIT licensed; © 2026 Alexander Fisenkov.

## Download and install

Download the [latest release](https://github.com/alexfisenkov/MacMarker/releases/latest) or directly get [MacMarker 0.1.1 for Apple silicon](https://github.com/alexfisenkov/MacMarker/releases/download/v0.1.1/MacMarker-0.1.1-macOS-arm64.zip). The published app is signed and notarized.

1. Unzip the download.
2. Move `MacMarker.app` to Applications and open it.
3. When macOS asks, allow MacMarker under **System Settings → Privacy & Security → Accessibility** so it can handle the hold shortcut globally.

The release download is for Apple silicon Macs. Building from source produces a native build for the Mac architecture in use.

## Build and install

Requires macOS 13 or later and Xcode command line tools with Swift 6 or later.

```sh
./script/build.sh
./script/install.sh
```

The build creates `dist/MacMarker.app`. Set `SIGNING_IDENTITY` to an existing Developer ID Application signing identity to sign with hardened runtime and a secure timestamp; without it, the app is ad hoc signed. For local development, `./script/build.sh --debug` builds a debug bundle. `./script/build_and_run.sh` is the single build-and-launch command; add `--verify` to confirm the process starts.

To notarize an already built app using an existing `notarytool` Keychain profile, set `NOTARY_PROFILE` to its profile name and run `./script/notarize.sh`. No credentials are stored in this repository.

## Use

The default shortcut is **Right Option**. Hold it and draw with the mouse or a pointer translated through Sidecar, including Apple Pencil. Strokes stay visible while the shortcut is held; releasing it restores normal input immediately and fades the marks over 1.4 seconds. While held, mouse and pointer interactions are captured too.

Native settings let you change color, opacity, stroke width, and the hold shortcut. macOS Accessibility permission is required for global input handling; grant it in System Settings when prompted. The app also provides a control for starting at login. Escape cancels marking. macOS reserves some keys and combinations, so those shortcuts may not be available.

Use **Выключить маркер / Включить маркер** in the menu bar menu to pause or resume without quitting. Pausing removes the global input hook, clears marks and releases the shortcut immediately. The choice is remembered across launches; changing settings or checking permission does not resume a paused marker.

MacMarker makes no network requests, does not record the screen, and keeps stroke geometry in memory only. Sidecar input is provided by macOS and behavior depends on the connected device and available shortcuts. Physical iPad and Apple Pencil acceptance has not yet been performed.

## Release checks

The GitHub Actions workflow is manual (`workflow_dispatch`) and produces an unsigned app archive. It does not use signing credentials or run on pushes or pull requests.
