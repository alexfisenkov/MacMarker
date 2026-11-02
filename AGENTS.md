# MacMarker

Native macOS menu-bar and Windows tray marker by Alexander Fisenkov, with a static product website. Hold a configurable key to draw over the desktop and mirrored Sidecar display; release to restore normal input and fade the strokes.

## Source of truth
- Owner brief, manifest and specification: `.aispa-work/2026-10-29-macmarker/`.
- Mac implementation: `Sources/MacMarker/`; Windows: `windows/src/MacMarker.Core/` and `windows/src/MacMarker.Windows/`. Static site: `website/`; pins: `website/release-manifest.json`.
- README explains public usage and permission boundaries. No iPad app, servers or runtime dependencies.

## Project map
- `Package.swift`: SwiftPM macOS executable, tools-version5.9, Swift 5 language mode for AppKit callbacks; healthy Swift6 toolchain verified in hosted CI.
- `Sources/MacMarker/`: input/hold state, overlay rendering, persisted preferences and native settings.
- `script/`: build, bundle, sign, notarize and install commands.
- `.github/workflows/`: manual final CI only; never push/PR-triggered runs.
- `.aispa-work/`: public, sanitized requirements and progress; no private machine state or credentials.

## Delivery and scope
- macOSv0.1.1, bundle identifier `com.alexfisenkov.macmarker`, public `alexfisenkov/MacMarker`.
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
- Current Mac release v0.1.1: source `af5552358c72c2099a0b90a83a2900b1d6194c7f`, CI41013105569, receipt `.aispa-work/updates/2026-10-30-toggle.json`. `Preferences.isEnabled` persists as markerEnabled; disabling removes CGEventTap, and timer/permission retries cannot recreate it while paused.
- Release v0.1.0 uses source SHA `caeb47d9d89e69ae0c40dad8aae06e9e754bb015`, successful GitHub CI40901640486, arm64 artifact. See run `release-verification.json` for signature/notary/published digest.
- Local Xcode changed during run; do not accept licenses or repair SDKs as part of ordinary app work. If local toolchain is inconsistent, build from a clean hosted runner, then sign the exact artifact locally.
- Finder metadata on generated bundles can invalidate codesign. Sign/staple in a generated release staging directory; remove only FinderInfo/ResourceFork from generated artifacts, preserve user originals.
- App currently installed at `/Applications/MacMarker.app`; UI showed `Готов`, login registration enabled. Physical Pencil/Sidecar acceptance was subsequently confirmed by the owner on 2026-10-29 (see release-verification.json).

- The owner tested menu enable/disable and accepted v0.1.1 on 2026-10-30; task complete. See `.aispa-work/updates/2026-10-30-toggle.json` for the direct confirmation.

## Windows and site work (2026-11-02)
- Current design/plan: docs/superpowers/specs/2026-11-02-windows-and-website-design.md and docs/superpowers/plans/2026-11-02-windows-and-website.md.
- Windows is mouse-only: key held + mouse MOVE draws without clicking. Default F8, fade1.4s; existing Mac app unchanged. .NET10/Core+WinForms matches existing MacDictate Windows stack.
- windows/** and website/** are independent worker ownership zones; parent owns workflows and root docs. No automatic CI or separate critic cycle.
- Site must follow the live MacSwitcher/MacDictate family layout; publish via manual GitHub Pages workflow at /MacMarker/.

## Current cross-platform delivery
- Windows0.2.0 + site source8126f78, release receipt `.aispa-work/updates/2026-11-02-windows-and-website.json`. Windows unsigned; never imply Authenticode signing from the Mac Developer ID.
- Windows commands (SDK10.0.402): `dotnet run --project windows/tests/MacMarker.Core.Tests/MacMarker.Core.Tests.csproj -c Release`; `dotnet build windows/src/MacMarker.Windows/MacMarker.Windows.csproj -c Release`. Packaging/native/installer commands are in `windows/README.md`.
- Native input smoke runs only on isolated Windows CI with CI=true and -CiDesktop. Do not synthesize input on the owner's real desktop as a test.
- Site style is the exact MacSwitcher/MacDictate family; `website/style-origin.json` records the source. Hosting: https://alexfisenkov.github.io/MacMarker/ .
- Site check: `python3 script/check_website.py --javascript`; add --published-release after assets uploaded. Pages deployment is a separate manual workflow, not an automatic push action.
- Native/installer Windows CI, site1440/390 and HTTPS read-back passed. Physical Windows10/11 and mixedDPI/SmartScreen remain NOT_RUN.
