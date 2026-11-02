# MacMarker Windows

Windows mouse-only counterpart. Hold F8 (configurable), move mouse to draw, release to restore input and fade in 1.4 seconds. No tablet/iPad integration, network, capture or keyboard logging.

- Source of truth: `../docs/superpowers/specs/2026-11-02-windows-and-website-design.md`.
- `src/MacMarker.Core`: portable settings/shortcut/hold/fade model; `src/MacMarker.Windows`: WinForms, hooks, overlays, settings, tray.
- `assets/MacMarker.ico` is derived from the existing MacMarker application icon (site PNG), without new visual design.
- .NET10, no third-party runtime packages. Release0.2.0, `MacMarker.exe`.
- Check: `dotnet run --project windows/tests/MacMarker.Core.Tests -c Release` from repository root.
- Cross-build: `dotnet build windows/src/MacMarker.Windows -c Release -p:EnableWindowsTargeting=true`.
- Windows package: `pwsh windows/scripts/build.ps1`; native/package smoke: `pwsh windows/scripts/smoke.ps1 -CiDesktop` on an isolated CI desktop only.
- Mouse moves always pass through. Suppressed downs have matching ups suppressed after release. Hooks removed on pause/lock/exit. Settings in LocalAppData/MacMarker; invalid preferences reported, preserved and recovered visibly.
- Native and physical Windows acceptance are separate. No local toolchain installation, automatic CI, source changes outside windows/, or critic cycle in this task.
