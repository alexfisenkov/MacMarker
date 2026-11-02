# MacMarker for Windows

Hold **F8** and move the mouse to draw over the desktop. No click is needed. Release F8 to restore normal input immediately; marks fade over1.4seconds. Escape clears marks until you release the shortcut. This Windows version uses the mouse, with no tablet or iPad integration.

Windows10 (build19041+) / Windows11, x64. Version0.2.0. Author: Alexander Fisenkov. MIT license.

Download the per-user installer `MacMarker-0.2.0-windows-x64-setup.exe`, or extract `MacMarker-0.2.0-windows-x64.zip` and run `MacMarker.exe`. No administrator privileges or separately installed .NET runtime are needed. Windows builds are **unsigned**; verify the release SHA-256 checksums and source. Respect Windows security decisions and your organization's policies.

The first launch opens Settings. Use the tray icon to open Settings, pause/enable drawing, or quit. Pausing removes both input hooks and persists across launches. Color accepts any color from the native picker; opacity0–100%, width1–100. Record a single key, chord, or left/right Shift, Control or Alt modifier, then Save. F8 is recommended: Ctrl+Alt/AltGr, Windows keys and reserved OS chords cannot be recorded. Extra modifiers prevent activation. You can choose optional start at login; it registers the quoted executable path for the current user. If you move the portable executable, toggle that option again.

Preferences are written atomically to `%LOCALAPPDATA%\MacMarker\settings.json`, with the preceding version retained as `settings.json.previous`. Malformed preferences show a warning and defaults; the original remains until a deliberate save. Reinstall/uninstall preserves preferences. Marks exist only in RAM. No screen capture, network requests or typed-key logs. Keyboard pressed state is used transiently to recognize the selected shortcut; pointer moves always pass through to keep the cursor moving. System lock, pause, exit and failures clear marks and release hooks.

Settings temporarily suspend drawing. Hooks still observe only transient shortcut state while Settings is open; recording explicitly captures one shortcut. Paused mode installs hooks only while you request shortcut recording, removing them when recording ends.

## Build and verify

.NET SDK10.0.402, PowerShell7, and Inno Setup6 (installer only). No external runtime NuGet packages. The self-contained packages include the exact Microsoft runtime licenses, third-party notices and package/version provenance under `licenses/`. From the repository root:

```powershell
dotnet run --project windows/tests/MacMarker.Core.Tests/MacMarker.Core.Tests.csproj -c Release
dotnet build windows/src/MacMarker.Windows/MacMarker.Windows.csproj -c Release -p:EnableWindowsTargeting=true
pwsh -File windows/scripts/build.ps1 -OutputDirectory windows/dist
```

Commit source before a release build. The build embeds the git SHA, publishes a self-contained single-file app under `windows/dist/app/`, produces both versioned packages, `windows-build-manifest.json`, and `WINDOWS-SHA256SUMS`. Outputs must be fresh; existing packages are never overwritten. Inno Setup is installed automatically only on a GitHub runner if absent, never on a local machine. `-SkipInstaller` builds the portable package alone.

On an isolated Windows CI desktop only (`CI=true`):

```powershell
pwsh -File windows/scripts/smoke.ps1 -Executable windows/dist/app/MacMarker.exe -Receipt windows/dist/native-smoke.json -CiDesktop
pwsh -File windows/scripts/test-install.ps1 -Installer windows/dist/MacMarker-0.2.0-windows-x64-setup.exe -Receipt windows/dist/install-smoke.json -CiDesktop
```

Smoke extracts and executes the portable ZIP when adjacent, creates actual WinForms/tray/per-monitor alpha overlays, synthesizes F8 and mouse motion with SendInput, verifies held drawing, key-up/fade/rehold, hook removal on pause, preference read-back, reenable and clean exit. Installer smoke verifies per-user install, installed native first launch, uninstall and preference preservation. All smoke preferences and runtime extraction are isolated, and no login entry is created. Never run native smoke on a person's desktop.

A cross-build confirms compilation only. Hosted Windows Server desktop smoke does not prove physical Windows10/11 keyboard layouts, mixed-DPI/hotplug/multiple displays, secure desktop/UAC, games/exclusive fullscreen or drawing above higher-integrity apps. MacMarker does not elevate or bypass those boundaries. Physical hardware acceptance remains a separate owner check.
