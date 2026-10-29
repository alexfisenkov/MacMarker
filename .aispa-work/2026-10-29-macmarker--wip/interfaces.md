# Interfaces

## Ownership
Worker01: Package.swift, Sources/MacMarker/**, narrow test seam only if needed. Exposes executable product `MacMarker`; supports `--self-test` without GUI/permissions to check hold/fade lifecycle and shortcut matching using production pure code. Must build using `swift build -c release`.
Worker02: script/**, Resources/**, .github/workflows/**, .codex/environments/**, README.md, LICENSE. Bundle app consumes `.build/release/MacMarker`; bundle id `com.alexfisenkov.macmarker`, v0.1.0 build1; SwiftPM only, macOS13+. Build unsigned or developer-ID sign using SIGNING_IDENTITY environment variable; do not embed identity hash/private paths in public scripts. CI workflow_dispatch uses macos-26 with installed Xcode selection that supports tools-version6.0. Root scripts use script/build.sh and script/build_and_run.sh. No compilation in parallel with worker01.
Parent: AGENTS.md, .gitignore, .aispa-work/**, git commits/push/repo creation, final CI/release/notary/install; alone stages/commits.

## Constraints
No external deps. No runtime network. Input geometries RAM only. Right Option default, custom single key/chord recorder. Overlays should be nonactivating and click-through at idle/fade. Self-test must not generate global input. No critics/review/blind agents, direct owner fast override. No worker changes paths outside owned perimeter or reverts others; workers share directory.
