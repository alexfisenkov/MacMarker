# MacMarker product site

Live: https://alexfisenkov.github.io/MacMarker/ . Source: `website/`. Style origin: MacSwitcher/MacDictate exact family CSS, recorded in `website/style-origin.json`. No framework, CDN, analytics, forms or cookies. RU/EN selection is local browser state.

Download pins live in `website/release-manifest.json`; Mac0.1.1 and Windows0.2.0 are distinct release channels. Never point a platform button at an unrelated global latest asset.

Checks: `python3 script/check_website.py --javascript`, then `python3 script/check_website.py --javascript --published-release` after real assets are public. The latter reads public GitHub asset metadata.

Hosting uses GitHub Pages `build_type=workflow`, HTTPS enforced. `.github/workflows/pages.yml` is manual only and uploads only website/. `gh workflow run pages.yml --ref main` publishes the reviewed main tree. CI verification is also manual; `scope=windows` is reserved for a focused native repair after already-passed unchanged Mac/site checks.

Publication2026-11-02: source8126f78a6c417b14c668f5c19852754f04a07c9d, Pages run41411271199. All5 public site content files matched local bytes; rendered1440/390 and RU/EN/legal navigation passed. See the cross-platform release receipt for exact hashes and runtime boundaries.
