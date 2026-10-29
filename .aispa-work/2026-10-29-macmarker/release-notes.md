MacMarker turns a held key into a temporary desktop marker — useful with Apple Pencil on a mirrored Sidecar display.

- Hold **Right Option** and draw; marks remain until you release the key, then fade smoothly over 1.4 seconds.
- Native color palette, opacity, stroke width and configurable hold shortcut.
- Menu-bar app with optional launch at login.
- No network requests or screen recording. Stroke geometry is held in memory only.

**Installation:** unzip the Apple Silicon app, move MacMarker.app to Applications, open it and grant Accessibility permission when prompted. Sidecar mirroring is configured separately in macOS.

**Scope:** macOS13+ on Apple Silicon for this binary. Source can be built for other supported Mac architectures. While marking, mouse/pointer input is captured too. System-reserved shortcuts are subject to macOS restrictions. Automated checks do not establish acceptance on a physical iPad/Pencil setup.

Author: Alexander Fisenkov. MIT license.

Build source: `caeb47d9d89e69ae0c40dad8aae06e9e754bb015`. Hosted verification: https://github.com/alexfisenkov/MacMarker/actions/runs/40901640486 . Developer ID signed by Aleksander Fisenkov; Apple notarization Accepted and ticket stapled; Gatekeeper accepted. SHA-256 is supplied in SHA256SUMS.
