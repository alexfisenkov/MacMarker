# MacMarker

Native macOS menu-bar marker by Alexander Fisenkov. Hold a configurable key to draw over the desktop and mirrored Sidecar display; release to restore normal input and fade the strokes.

## Source of truth
- Owner brief, manifest and specification: `.aispa-work/2026-10-29-macmarker/`.
- Implementation: `Sources/MacMarker/`; packaging and local checks: `script/`.
- README explains public usage and permission boundaries. No iPad app, servers or runtime dependencies.

## Project map
- `Package.swift`: SwiftPM macOS executable, tools-version5.9, Swift 5 language mode for AppKit callbacks; healthy Swift6 toolchain verified in hosted CI.
- `Sources/MacMarker/`: input/hold state, overlay rendering, persisted preferences and native settings.
- `script/`: build, bundle, sign, notarize and install commands.
- `.github/workflows/`: manual final CI only; never push/PR-triggered runs.
- `.aispa-work/`: public, sanitized requirements and progress; no private machine state or credentials.

## Delivery and scope
- v0.1.1, bundle identifier `com.alexfisenkov.macmarker`, public `alexfisenkov/MacMarker`.
- Only color, opacity, width, configurable hold shortcut, and necessary enable/disable, launch/permission/quit controls. Hold freezes stroke visibility; release begins a 1.4-second fade and immediately restores normal input.
- Default: right Option. Any ordinary key/chord or single modifier may be recorded. Reserved OS keys cannot be promised.
- Accessibility permission is user-controlled. Never modify TCC databases or disable protections. Fail open when input monitoring is lost.
- Keyboard contents and screen content are never logged or stored; stroke geometry remains in RAM.
- Owner explicitly requested auto/fast, no critics or broad QA. Use one local build/smoke and one final manual hosted CI. Do not dispatch critics or blind-acceptance agents.
- Publishing, Developer ID signing and installation are explicitly authorized by the current brief.

## Verification
- Build app bundle: `./script/build.sh`; build and run: `./script/build_and_run.sh --verify`.
- Targeted production lifecycle smoke: `./dist/MacMarker.app/Contents/MacOS/MacMarker --self-test` (headless, no input synthesis).
- Install: `./script/install.sh`; optional notarization: `NOTARY_PROFILE=<existing-name> ./script/notarize.sh`.
- Signature validation: `codesign --verify --deep --strict /Applications/MacMarker.app`.
- Installed app/process/signature and physical Sidecar/Pencil acceptance are separate evidence. The owner confirmed working Pencil/Sidecar behavior and task completion on 2026-10-29; the agent did not perform that physical trial.
- Next session first reads `.aispa-work/PROGRESS.md`; it lists unresolved acceptance and direct owner decisions. Any later fix adds a dated entry there and an ordinary descriptive git commit.

## Release evidence and local trap
- Current release v0.1.1: source `af5552358c72c2099a0b90a83a2900b1d6194c7f`, CI41013105569, receipt `.aispa-work/updates/2026-10-30-toggle.json`. `Preferences.isEnabled` persists as markerEnabled; disabling removes CGEventTap, and timer/permission retries cannot recreate it while paused.
- Release v0.1.0 uses source SHA `caeb47d9d89e69ae0c40dad8aae06e9e754bb015`, successful GitHub CI40901640486, arm64 artifact. See run `release-verification.json` for signature/notary/published digest.
- Local Xcode changed during run; do not accept licenses or repair SDKs as part of ordinary app work. If local toolchain is inconsistent, build from a clean hosted runner, then sign the exact artifact locally.
- Finder metadata on generated bundles can invalidate codesign. Sign/staple in a generated release staging directory; remove only FinderInfo/ResourceFork from generated artifacts, preserve user originals.
- App currently installed at `/Applications/MacMarker.app`; UI showed `Готов`, login registration enabled. Physical Pencil/Sidecar acceptance was subsequently confirmed by the owner on 2026-10-29 (see release-verification.json).

- The owner tested menu enable/disable and accepted v0.1.1 on 2026-10-30; task complete. See `.aispa-work/updates/2026-10-30-toggle.json` for the direct confirmation.
