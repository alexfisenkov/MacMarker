#!/usr/bin/env python3
"""Portable checks for MacMarker's standalone, two-platform GitHub Pages site."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import unquote, urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "website"
PAGES = (WEB / "index.html", WEB / "legal.html")
FORBIDDEN = ("MacSwitcher", "MacDictate", "Whisper", "releases/latest", "alpha.19", "/Users/")
VOID_TAGS = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr"}


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.links: list[str] = []
        self.downloads: list[tuple[str, str]] = []
        self.ids: set[str] = set()
        self.i18n: set[str] = set()
        self.scripts: list[str] = []
        self.stack: list[str] = []
        self.script_parts: list[str] | None = None
        self.errors: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attr = dict(attrs)
        for key in ("href", "src"):
            if value := attr.get(key):
                self.links.append(value)
        if ident := attr.get("id"):
            if ident in self.ids:
                self.errors.append(f"duplicate ID: {ident}")
            self.ids.add(ident)
        if key := attr.get("data-i18n"):
            self.i18n.add(key)
        if platform := attr.get("data-platform"):
            self.downloads.append((platform, attr.get("href") or ""))
        if tag == "script" and not attr.get("src"):
            self.script_parts = []
        if tag not in VOID_TAGS:
            self.stack.append(tag)

    def handle_endtag(self, tag: str) -> None:
        if not self.stack or self.stack[-1] != tag:
            self.errors.append(f"unexpected closing tag: {tag}")
        else:
            self.stack.pop()
        if tag == "script" and self.script_parts is not None:
            self.scripts.append("".join(self.script_parts))
            self.script_parts = None

    def handle_data(self, data: str) -> None:
        if self.script_parts is not None:
            self.script_parts.append(data)


def read_json(path: Path) -> dict:
    try:
        result = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        fail(f"cannot read {path.relative_to(ROOT)}: {error}")
    if not isinstance(result, dict):
        fail(f"expected object in {path.relative_to(ROOT)}")
    return result


def check_published_assets(manifest: dict) -> None:
    """Read actual GitHub release asset metadata; do not download executables."""
    grouped: dict[str, list[dict]] = {}
    for asset in manifest["downloads"]:
        grouped.setdefault(asset["tag"], []).append(asset)
    for tag, expected_assets in grouped.items():
        request = Request(
            f'https://api.github.com/repos/{manifest["repository"]}/releases/tags/{tag}',
            headers={"Accept": "application/vnd.github+json", "User-Agent": "MacMarker-website-check"},
        )
        try:
            with urlopen(request, timeout=25) as response:
                release = json.load(response)
        except HTTPError as error:
            fail(f"published release {tag} metadata returned HTTP {error.code}")
        except (TimeoutError, socket.timeout):
            fail(f"timed out checking published release {tag}")
        except (URLError, OSError, ValueError):
            fail(f"could not read published release {tag} metadata")
        if not isinstance(release, dict) or release.get("draft") is not False or release.get("tag_name") != tag:
            fail(f"release {tag} is not public or has unexpected metadata")
        assets = release.get("assets")
        if not isinstance(assets, list):
            fail(f"release {tag} has no valid asset metadata")
        for expected in expected_assets:
            matches = [item for item in assets if isinstance(item, dict) and item.get("name") == expected["name"]]
            if len(matches) != 1:
                fail(f'expected one published asset {expected["name"]}, found {len(matches)}')
            actual = matches[0]
            if actual.get("state") != "uploaded" or not isinstance(actual.get("size"), int) or actual["size"] <= 0:
                fail(f'asset {expected["name"]} is not uploaded and nonempty')
            if actual.get("browser_download_url") != expected["url"]:
                fail(f'published download URL mismatch for {expected["name"]}')
            digest = actual.get("digest")
            if digest is not None and not re.fullmatch(r"sha256:[0-9a-fA-F]{64}", digest):
                fail(f'invalid SHA-256 metadata for {expected["name"]}')
            print(f'PASS: published {expected["name"]} ({actual["size"]} bytes)')


def main() -> None:
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("--javascript", action="store_true", help="also parse inline JavaScript with Node")
    args.add_argument("--published-release", action="store_true", help="require all Mac/Windows downloads in public GitHub release metadata")
    options = args.parse_args()
    parsed: dict[Path, PageParser] = {}
    for page in PAGES:
        if not page.is_file():
            fail(f"missing page: {page.relative_to(ROOT)}")
        source = page.read_text(encoding="utf-8")
        for marker in FORBIDDEN:
            if marker in source:
                fail(f"stale product/reference marker {marker!r} in {page.relative_to(ROOT)}")
        if re.search(r"(?:src|href)=[\"'](?:https?:)?//[^\"']*(?:cdn|unpkg|jsdelivr)", source, re.I):
            fail("website must not depend on a CDN")
        if "prefers-reduced-motion" not in source or "@media" not in source:
            fail(f"missing responsive/reduced-motion rules in {page.name}")
        parser = PageParser()
        parser.feed(source)
        parser.close()
        if parser.stack or parser.errors:
            fail(f"invalid HTML structure in {page.name}: {parser.errors or parser.stack}")
        if not parser.scripts:
            fail(f"missing localization script in {page.name}")
        # Translation tables intentionally use JSON-compatible objects.
        match = re.search(r"const translations\s*=\s*", parser.scripts[0])
        if not match:
            fail(f"missing translation table in {page.name}")
        try:
            translations, _ = json.JSONDecoder().raw_decode(parser.scripts[0][match.end():])
        except ValueError:
            fail(f"invalid translation table in {page.name}")
        if not isinstance(translations, dict) or set(translations) != {"ru", "en"}:
            fail(f"expected RU and EN translations in {page.name}")
        for lang, values in translations.items():
            if not isinstance(values, dict) or not parser.i18n.issubset(values):
                fail(f"missing {lang} translation in {page.name}")
            if any(not isinstance(value, str) or not value.strip() for value in values.values()):
                fail(f"empty/nontext {lang} translation in {page.name}")
        if set(translations["ru"]) != set(translations["en"]):
            fail(f"RU/EN translation keys differ in {page.name}")
        parsed[page] = parser
    for page, parser in parsed.items():
        for raw in parser.links:
            url = urlparse(raw)
            if url.scheme or url.netloc:
                if url.scheme not in {"https", "mailto"} or url.netloc and not url.scheme:
                    fail(f"unexpected link scheme in {page.name}: {raw}")
                continue
            target = (page.parent / unquote(url.path or page.name)).resolve()
            if not target.is_relative_to(WEB.resolve()):
                fail(f"local link escapes website in {page.name}: {raw}")
            if not target.is_file():
                fail(f"broken local link in {page.name}: {raw}")
            if url.fragment and (target_parser := parsed.get(target)):
                if unquote(url.fragment) not in target_parser.ids:
                    fail(f"broken anchor in {page.name}: {raw}")
    if not (WEB / ".nojekyll").is_file():
        fail("missing .nojekyll")
    origin = read_json(WEB / "style-origin.json")
    icon = WEB / "assets/MacMarker.png"
    if not icon.is_file() or hashlib.sha256(icon.read_bytes()).hexdigest() != origin.get("icon_sha256"):
        fail("missing or changed canonical product icon")
    if icon.read_bytes()[:8] != b"\x89PNG\r\n\x1a\n":
        fail("product icon is not a PNG")
    manifest = read_json(WEB / "release-manifest.json")
    if manifest.get("schema") != 1 or manifest.get("repository") != "alexfisenkov/MacMarker" or manifest.get("site") != "https://alexfisenkov.github.io/MacMarker/":
        fail("unexpected release manifest identity")
    downloads = manifest.get("downloads")
    if not isinstance(downloads, list) or len(downloads) != 3 or any(not isinstance(item, dict) for item in downloads):
        fail("expected Mac, Windows installer, and Windows ZIP in release manifest")
    expected = {"macos": ("v0.1.2", "MacMarker-0.1.2-macOS-arm64.zip", 2),
                "windows": ("v0.2.0", "MacMarker-0.2.0-windows-x64-setup.exe", 2),
                "windows-portable": ("v0.2.0", "MacMarker-0.2.0-windows-x64.zip", 1)}
    actual_links = Counter(parsed[WEB / "index.html"].downloads)
    expected_links: Counter[tuple[str, str]] = Counter()
    for asset in downloads:
        platform = asset.get("platform")
        if platform not in expected:
            fail("unexpected platform in release manifest")
        tag, name, count = expected.pop(platform)
        url = f'https://github.com/{manifest["repository"]}/releases/download/{tag}/{name}'
        if (asset.get("tag"), asset.get("name"), asset.get("links"), asset.get("url")) != (tag, name, count, url):
            fail(f"unexpected {platform} release asset")
        expected_links[(platform, url)] = count
    if actual_links != expected_links:
        fail("download buttons do not match the explicit two-platform release manifest")
    for raw in parsed[WEB / "index.html"].links:
        if "/releases/download/" in raw and raw not in {asset["url"] for asset in downloads}:
            fail(f"download is absent from the release manifest: {raw}")
    if options.javascript:
        node = shutil.which("node")
        if not node:
            fail("node is required for --javascript")
        for page, parser in parsed.items():
            for i, script in enumerate(parser.scripts, 1):
                result = subprocess.run([node, "--check", "--input-type=commonjs"], input=script, text=True, capture_output=True)
                if result.returncode:
                    fail(f"JavaScript syntax error in {page.name} inline script {i}: {result.stderr.strip()}")
    print(f"PASS: {len(PAGES)} HTML pages, structure, relative links, anchors, RU/EN, product icon, and two-platform downloads")
    if options.javascript:
        print("PASS: inline JavaScript syntax")
    if options.published_release:
        check_published_assets(manifest)


if __name__ == "__main__":
    main()
