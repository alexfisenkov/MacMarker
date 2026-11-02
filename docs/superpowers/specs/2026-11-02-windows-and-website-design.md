# MacMarker: Windows and product website

## Owner request
«сделай теперь для этого также сайт как для других продуктов из наших разработок в том же стиле - и сделай версию для винды тоже самое прям что бы было!»
Clarification: «не просто подчеркивание - без плагшетов просто мышкой водить и что бы подчеркивалось когда клавиша нажата».

## Contract
- Windows app draws over the desktop while a configurable key is physically held. Mouse movement alone draws; no mouse button, tablet, pen or iPad transport required. Default F8 (engineering choice, avoids AltGr). On release ordinary input returns immediately; marks fade1.4sec. Rehold cancels old fade. Escape cancels until trigger released.
- Same existing palette, opacity0–100%, width1–100, arbitrary normal key/chord or modifier-only binding, tray enable/disable switch with actual hook removal, persisted settings and optional start-at-login. No accounts, network or screen recording. Geometry RAM-only.
- macOS implementation, installed0.1.1 and its owner-accepted behavior stay untouched. This iteration releases Windows0.2.0 as a distinct channel, not a new Mac binary.
- Website reuses exact CSS/layout from MacSwitcher (itself MacDictate family), source f269821d170d9c9cfaac21662fb297774873e986: dark#0a0a0a, blue#007aff, gradient headline, system font, glass navigation/cards, RU/EN, mobile/reduced-motion. Adapt content/icon and two platform downloads only. No new frontend framework/build chain.
- Hosting: existing GitHub Pages workflow model, URL https://alexfisenkov.github.io/MacMarker/ , upload only website/. No DNS, third-party hosting or payment.
- Author Alexander Fisenkov / existing MIT license. Windows binary has no Authenticode certificate presently available; never describe it as signed/notarized, never recommend disabling Windows protections. Show checksum/source and practical limits honestly.

## Architecture and ownership
- windows/src/MacMarker.Core/: pure .NET10 hold/fade/shortcut model and settings serialization. Portable console tests, no test-framework dependency needed.
- windows/src/MacMarker.Windows/: .NET10 WinForms tray/settings, Win32 keyboard/mouse hooks, nonactivating per-monitor layered overlays. MouseMove must pass through so cursor remains usable; block pointer button down/up only while marking. Hook callbacks do minimal work; fail open; unhook on disable/exit/session lock. Handle negative monitor origins and PerMonitorV2 DPI. No admin/UAC bypass.
- windows/scripts/: build/publish self-contained win-x64 executable, ZIP, Inno Setup per-user installer, targeted native smoke. Unique AppId, preserve settings across reinstall, safe quoted startup path. SourceRoot and source SHA embedded in build receipt, not personal paths.
- website/: static site and legal page, shared style source above, actual release-specific download URLs, existing MacMarker icon extracted from installed app.
- Parent owns .github/workflows/, root docs/README/AGENTS, git/release/Pages provision/deploy. Workers never overlap these paths or commit.

## Release interface
Windows version0.2.0. Assets: MacMarker-0.2.0-windows-x64-setup.exe and MacMarker-0.2.0-windows-x64.zip under tag v0.2.0. Mac stays https://github.com/alexfisenkov/MacMarker/releases/download/v0.1.1/MacMarker-0.1.1-macOS-arm64.zip . Publish Windows release with --latest=false; site has explicit platform buttons. Windows exe in package is MacMarker.exe.

## Verification boundaries
One final manual GitHub CI for app/macOS/website on the final source set; no push/PR-triggered Actions. Local portable checks/build first where toolchains permit, then Windows native CI check actual startup/settings/tray/hold/fade/pause. Installer and portable artifact must execute, not merely compile. Physical Windows10/11 keyboard/mouse/DPI and real user desktop remain NOT_RUN unless actually tested; Server CI is separate evidence.
Project owner fast/no-critic policy remains: no critic/blind agents. Parallel implementation authorized by global AGENTS for this multilayer task. Build isolated branch; no changes in the owner's dataless Documents checkout. Only deployment of this public product site and product releases is in scope.
