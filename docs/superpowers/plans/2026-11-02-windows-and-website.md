# MacMarker Windows and website implementation plan

Goal: publish the family-style MacMarker site and a usable standalone Windows marker.
Architecture: native .NET10 WinForms/Core under windows/, static site under website/, existing Swift app unchanged.
Spec: docs/superpowers/specs/2026-11-02-windows-and-website-design.md.

## Tasks and ownership
- [ ] Windows worker: windows/** only. Build app/core, portable model tests, self-contained executable, Inno per-user installer/ZIP, targeted native smoke scripts. Actual draw is key-held mouse movement, no click needed. Return real commands/results and any platform limits.
- [ ] Website worker: website/** and script/check_website.py only. Reuse verified MacSwitcher family CSS/layout; exact Mac/Windows downloads; responsive RU/EN and legal; use real MacMarker icon. Return checker and visual/runtime evidence available.
- [ ] Parent: root docs/AGENTS/README, .github/workflows/** only, shared .NET SDK availability, integration, final single manual CI, Windows release upload/read-back, Pages setup/deploy/read-back and wide/mobile visual check.

## Delivery sequence
- [ ] Read existing MacMarker behavior and MacSwitcher website patterns; record owner clarification (done in spec).
- [ ] Implement disjoint Windows/site work in parallel; do not alter Swift or existing release assets.
- [ ] Run local Core tests, cross-build Windows if SDK available, static/JS/link checks for site. Fix actual failures without adding unrelated scope.
- [ ] Commit and push the complete candidate; one manual workflow verifies Windows package/runtime, existing Mac smoke and site.
- [ ] Publish Windows0.2.0 EXE/ZIP/checksum from exact CI SHA; keep Mac0.1.1 global latest and preserve previous assets.
- [ ] Provision GitHub Pages (workflow build) for this repo, deploy reviewed website only, compare HTTPS bytes and links, test390px/1440px.
- [ ] Record release evidence, source SHA, live URL, unsigned Windows status and physical-hardware NOT_RUN clearly in project progress.
