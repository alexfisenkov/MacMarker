# MacMarker

A native desktop marker for macOS and Windows. Hold a key to draw over the screen; release it to fade the marks. MIT licensed; © 2026 Alexander Fisenkov.

[Product website](https://alexfisenkov.github.io/MacMarker/) · [Windows documentation](windows/README.md)

## Download and install

Download the [latest release](https://github.com/alexfisenkov/MacMarker/releases/latest) or directly get [MacMarker 0.1.2 for Apple silicon](https://github.com/alexfisenkov/MacMarker/releases/download/v0.1.2/MacMarker-0.1.2-macOS-arm64.zip). The published app is signed and notarized.

1. Unzip the download.
2. Move `MacMarker.app` to Applications and open it.
3. When macOS asks, allow MacMarker under **System Settings → Privacy & Security → Accessibility** so it can handle the hold shortcut globally.

The Mac release download is for Apple silicon Macs. Building from source produces a native build for the Mac architecture in use.

### Windows

Download [Windows0.2.0 installer](https://github.com/alexfisenkov/MacMarker/releases/download/v0.2.0/MacMarker-0.2.0-windows-x64-setup.exe) or [portable ZIP](https://github.com/alexfisenkov/MacMarker/releases/download/v0.2.0/MacMarker-0.2.0-windows-x64.zip). Windows10 build19041+ / Windows11 x64. The package includes its .NET runtime.

Hold **F8** and move the mouse to draw — no mouse button or tablet is required. Release to restore normal input immediately and fade the marks over1.4 seconds. Settings contain color, opacity, width and a customizable hold key. The tray enable/disable command removes the global hooks when paused and remembers the choice.

Windows packages are currently **unsigned**; check the published source and SHA-256. No Windows security settings need to be disabled. See [Windows build, installation and runtime boundaries](windows/README.md). Mac0.1.2 remains a separate release channel.

## Build and install on macOS

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

MacMarker makes no network requests, does not record the screen, and keeps stroke geometry in memory only. Sidecar input is provided by macOS and behavior depends on the connected device and available shortcuts. The owner accepted the physical Mac/iPad behavior on2026-10-29 and the pause switch on2026-10-30. This does not establish physical Windows hardware acceptance.

## Release checks

The GitHub Actions verification workflow is manual (`workflow_dispatch`): existing Mac build/smoke, Windows Core/native/package checks and static-site validation. A separate manual Pages workflow publishes only `website/` after the download assets are public. No workflows run on push or pull requests, and no signing credentials are stored in GitHub.

Mac0.1.2 fixes Fn/Globe-held Pencil drawing through Sidecar: Fn is tracked from its own keyboard edges, so tablet events cannot falsely release it. Existing settings and pause behavior are preserved.
