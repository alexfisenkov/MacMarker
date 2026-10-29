# MacMarker v0.1.0

## Задача
В зеркальном Sidecar превращать Apple Pencil в маркер на время удержания клавиши на Mac; отпускание возвращает обычное управление и запускает плавное растворение.

## Решение
- R01/R02/R05: native menu-bar app, transparent nonactivating overlays over every NSScreen. While shortcut held, intercept pointer down/drag/up so underlying apps never select/click; pen and mouse both work (Sidecar translates input). Do not claim Pencil-only filtering.
- R03/R04/R06: preserve all strokes while held. On release, immediately restore click-through and fade accumulated strokes over 1.4 sec. Re-hold cancels stale fade without allowing an old callback to destroy new strokes. Finish any active stroke and swallow matching mouseUp if release occurs mid-drag. Escape cancels; lost tap, sleep and screen changes return normal input.
- R07/R08/R09/R10: compact native settings with arbitrary NSColorPanel, opacity 0–100%, width 1–100pt, shortcut recorder (single left/right modifier, any normal physical key, or chord). Persist preferences in UserDefaults. Default right Option, yellow-orange, opacity85%, width5pt. No permanently active marker modes.
- R11/R12: public MIT repository alexfisenkov/MacMarker, copyright Alexander Fisenkov; workflow_dispatch only final CI; signed Developer ID archive, notarize if existing local profile available. No signing credentials in repository or hosted CI.
- R13: install /Applications/MacMarker.app and open it, login item control for persistent use via ServiceManagement. Needs Accessibility for global interception; provide clear prompt/link and runtime recheck, fail open if unavailable. Never read or edit TCC databases.
- R14/R15: auto/fast, owner explicitly disabled critics and large test loops. Only compile, targeted behavior smoke, signature/notary checks and one hosted CI. No broad review/independent coverage/blind QA agents. Existing explicit publication/sign/install instruction authorizes those steps; no repeated permission requests.

## Реализация
SwiftPM executable, AppKit for status item/nonactivating windows/NSColorWell and shortcut capture. No dependencies or network. CGEventTap for global hold and blocking marker mouse events; main-run-loop state. Overlay should not activate app or change keyboard focus. Input typed during hold mode is not forwarded with triggering modifier; at idle never alter input. Consider nonmodifier key repeats and modifier flags. Rendering only geometry, no screenshots, logging keystrokes or clipboard. At most a few thematic Swift files; one writer owns app code.

## Границы
See interfaces.md. Worker01 owns app executable + Package.swift; Worker02 owns packaging/README/license/manual CI. Parent owns AISpa/memory/git/release actions.

## Вне рамок
No iPad app, video transport, drawing tool modes, shapes, eraser, accounts, telemetry, update service or payments. Full OS-reserved shortcut support cannot be promised. A held marker also captures mouse/touch pointer interactions; normal finger control returns on release.

## Открытые места
Physical iPad/Pencil smoke requires the owner. Permission grant is controlled by macOS/user, not bypassed by the app. Do not mark physical acceptance proven by CI or simulations.

## Discovered release constraints
D01: Xcode changed during build and now requires owner license agreement; do not accept or modify SDKs. Clean hosted CI artifact may be the unsigned release source, then local codesign/notary/install. CLT contains stale private PackageDescription interface, unrelated to app runtime.
D02: Corrected CI setup version parsing after first hosted attempt failed before app compilation; repaired final CI is justified.
