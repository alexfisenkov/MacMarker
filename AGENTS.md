# MacMarker

Native macOS menu-bar marker by Alexander Fisenkov. Hold a configurable key to draw over the desktop and mirrored Sidecar display; release to restore normal input and fade the strokes.

## Source of truth
- Owner brief, manifest and specification: `.aispa-work/2026-10-29-macmarker--wip/` (run directory loses `--wip` after landing).
- Implementation: `Sources/MacMarker/`; packaging and local checks: `script/`.
- README explains public usage and permission boundaries. No iPad app, servers or runtime dependencies.

## Project map
- `Package.swift`: SwiftPM macOS executable, Swift 6 toolchain in Swift 5 language mode where needed for AppKit callbacks.
- `Sources/MacMarker/`: input/hold state, overlay rendering, persisted preferences and native settings.
- `script/`: build, bundle, sign, notarize and install commands.
- `.github/workflows/`: manual final CI only; never push/PR-triggered runs.
- `.aispa-work/`: public, sanitized requirements and progress; no private machine state or credentials.

## Delivery and scope
- v0.1.0, bundle identifier `com.alexfisenkov.macmarker`, public `alexfisenkov/MacMarker`.
- Only color, opacity, width, configurable hold shortcut, and necessary launch/permission/quit controls. Hold freezes stroke visibility; release begins a 1.4-second fade and immediately restores normal input.
- Default: right Option. Any ordinary key/chord or single modifier may be recorded. Reserved OS keys cannot be promised.
- Accessibility permission is user-controlled. Never modify TCC databases or disable protections. Fail open when input monitoring is lost.
- Keyboard contents and screen content are never logged or stored; stroke geometry remains in RAM.
- Owner explicitly requested auto/fast, no critics or broad QA. Use one local build/smoke and one final manual hosted CI. Do not dispatch critics or blind-acceptance agents.
- Publishing, Developer ID signing and installation are explicitly authorized by the current brief.

## Verification
Commands will be recorded once implemented; do not invent results. Installed app/process/signature and physical Sidecar/Pencil acceptance are separate evidence. Physical acceptance remains pending until tested on the owner's actual iPad.
