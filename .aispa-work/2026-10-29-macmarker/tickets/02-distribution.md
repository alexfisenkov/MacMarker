# 02 — Публичный воспроизводимый выпуск

**Требования:** R11, R12, R14
**Зависит от:** —
**Зона:** `script/` · `Resources/` · `.github/` · `.codex/` · `README.md` · `LICENSE`
**Волна:** 1
**Ревью:** нет — прямое указание владельца
**Модель:** обычная

## Что должно заработать
Reproducible macOS app bundle/build-run scripts, optional Developer ID signing, unsigned CI artifact, workflow_dispatch-only final CI, public usage and MIT author credit. Parent executes actual publication/signing/install.

## Из брифа, дословно
> «на GitHub в открытый репозиторий, там же его проверять, подписать его мной, установить его»
> «очень быстро, без кучи проверок, критиков»

## Разделы спецификации
spec.md distribution/constraints, interfaces.md executable/bundle interface.

## Критерии приёмки
- [ ] script/build.sh produces dist/MacMarker.app from SwiftPM product, no dependencies or private defaults.
- [ ] Optional SIGNING_IDENTITY codesigns hardened runtime; version0.1.0 and source SHA embedded.
- [ ] Manual-only CI builds and runs production --self-test, uploads unsigned zip; no intermediate Actions.
- [ ] README/License explain hold/release, permissions, Sidecar limits, reproducible build and Alexander Fisenkov authorship.
