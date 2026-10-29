# 01 — Удерживаемый маркер и настройки

**Требования:** R01, R02, R03, R04, R05, R06, R07, R08, R09, R10, R13, R15
**Зависит от:** —
**Зона:** `Package.swift` · `Sources/`
**Волна:** 1
**Ревью:** нет — прямое указание владельца
**Модель:** сильная

## Что должно заработать
Native menu-bar MacMarker with settings, hold shortcut input interception, all-screen transparent drawing, retained marks while held, immediate pass-through and1.4sec fade on release, login startup and permission UX.

## Из брифа, дословно
> «пока зажато, а когда отпускаю, то это медленно растворяется»
> «выбор цвета ... непрозрачности ... толщину ... горячую клавишу»

## Разделы спецификации
spec.md — all app behavior and implementation; interfaces.md ownership.

## Критерии приёмки
- [ ] swift build -c release succeeds; production --self-test exercises hold/release/rehold/fail-open/shortcut matching.
- [ ] While holding, strokes remain visible and underlying UI cannot be clicked/selected. Release immediately restores input; fade finishes1.4sec later.
- [ ] Native color, opacity, width and hotkey recorder persist; right Option default. Login item control and permission state are visible.
- [ ] No screen capture/typing logs/network; no extra drawing tools.
