#!/usr/bin/env python3
"""Build a local AWS User Groups index from Builder Center's public bundle."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
from typing import Any, Iterable
from urllib.parse import urljoin, urlparse

from harvest_builder_center import REPO_ROOT
from utils.http_cache import HttpCache
from utils.json_extractors import discover_public_javascript_links


BUILDER_USER_GROUPS_PAGE = "https://builder.aws.com/community/user-groups"
DEFAULT_OUTPUT = REPO_ROOT / "data/community/indexes/builder-center-user-groups.index.json"

_JS_STRING = r'"(?:\\.|[^"\\])*"'
_USER_GROUP_PATTERN = re.compile(
    rf"\{{id:(?P<id>{_JS_STRING}),"
    rf"link:(?P<link>{_JS_STRING}),"
    rf"countryCode:(?P<country_code>{_JS_STRING}),"
    rf"name:(?P<name>{_JS_STRING}),"
    rf"location:(?P<location>{_JS_STRING}),"
    rf"country:(?P<country>{_JS_STRING})\}}"
)
_MODULE_ASSET_PATTERN = re.compile(r'["\'](?:\.?/)?(?P<path>assets/module-[A-Za-z0-9_.-]+\.js)["\']')


def extract_user_groups_from_javascript(script: str) -> list[dict[str, Any]]:
    """Extract the static public directory without evaluating production JavaScript."""

    groups: list[dict[str, Any]] = []
    for match in _USER_GROUP_PATTERN.finditer(script):
        groups.append(
            {
                "id": _decode_js_string(match.group("id")),
                "name": _decode_js_string(match.group("name")),
                "location": _decode_js_string(match.group("location")),
                "country": _decode_js_string(match.group("country")),
                "countryCode": _decode_js_string(match.group("country_code")),
                "url": _normalize_join_url(_decode_js_string(match.group("link"))),
            }
        )
    return groups


def discover_module_asset_urls(entry_script: str, entry_url: str) -> list[str]:
    """Return the hashed module chunks that may contain page-owned static data."""

    base_url = f"{urlparse(entry_url).scheme}://{urlparse(entry_url).netloc}/"
    paths = {match.group("path") for match in _MODULE_ASSET_PATTERN.finditer(entry_script)}
    return [urljoin(base_url, path) for path in sorted(paths)]


def build_user_groups_index(cache: HttpCache, *, refresh: bool = False) -> dict[str, Any]:
    """Discover Builder Center's current bundle and return its User Groups directory."""

    page = cache.fetch(BUILDER_USER_GROUPS_PAGE, refresh=refresh)
    html = page.body.decode("utf-8", errors="replace")
    entry_urls = discover_public_javascript_links(html, page.url)
    if not entry_urls:
        raise ValueError("Builder Center User Groups page did not link a JavaScript entry bundle")

    retrieved_at = page.retrieved_at
    source_asset_url: str | None = None
    groups: list[dict[str, Any]] = []
    inspected_assets: list[str] = []
    for entry_url in entry_urls:
        entry = cache.fetch(entry_url, refresh=refresh)
        retrieved_at = max(retrieved_at, entry.retrieved_at)
        entry_script = entry.body.decode("utf-8", errors="replace")
        groups = extract_user_groups_from_javascript(entry_script)
        if groups:
            source_asset_url = entry.url
            break

        for asset_url in discover_module_asset_urls(entry_script, entry.url):
            inspected_assets.append(asset_url)
            asset = cache.fetch(asset_url, refresh=refresh)
            retrieved_at = max(retrieved_at, asset.retrieved_at)
            groups = extract_user_groups_from_javascript(asset.body.decode("utf-8", errors="replace"))
            if groups:
                source_asset_url = asset.url
                break
        if groups:
            break

    if not groups or source_asset_url is None:
        raise ValueError(
            "Builder Center bundle contained no AWS User Group records "
            f"after inspecting {len(inspected_assets)} module asset(s)"
        )

    return make_user_groups_index(
        groups,
        generated_at=retrieved_at,
        source_asset_url=source_asset_url,
    )


def make_user_groups_index(
    groups: list[dict[str, Any]], *, generated_at: str, source_asset_url: str
) -> dict[str, Any]:
    """Validate and shape extracted records into the deterministic local index."""

    _validate_user_groups(groups)
    sorted_groups = sorted(groups, key=lambda group: (group["name"].casefold(), group["id"]))
    country_counts = Counter((group["countryCode"], group["country"]) for group in sorted_groups)
    countries = [
        {"code": code, "name": name, "count": count}
        for (code, name), count in sorted(country_counts.items(), key=lambda item: item[0][1].casefold())
    ]
    return {
        "generatedAt": generated_at,
        "sourceUrl": BUILDER_USER_GROUPS_PAGE,
        "sourceAssetUrl": source_asset_url,
        "count": len(sorted_groups),
        "countryCount": len(countries),
        "countries": countries,
        "groups": sorted_groups,
    }


def _decode_js_string(literal: str) -> str:
    try:
        value = json.loads(literal)
    except json.JSONDecodeError as error:
        raise ValueError(f"Unsupported JavaScript string literal: {literal[:80]}") from error
    if not isinstance(value, str):
        raise ValueError("Expected a JavaScript string literal")
    return value


def _normalize_join_url(value: str) -> str | None:
    parsed_url = urlparse(value)
    return value if parsed_url.scheme == "https" and parsed_url.netloc else None


def _validate_user_groups(groups: Iterable[dict[str, Any]]) -> None:
    seen_ids: set[str] = set()
    for group in groups:
        if not group["id"].startswith("Space-UG_"):
            raise ValueError(f"Unexpected AWS User Group id: {group['id']!r}")
        if group["id"] in seen_ids:
            raise ValueError(f"Duplicate AWS User Group id: {group['id']}")
        seen_ids.add(group["id"])
        if len(group["countryCode"]) != 2 or not group["countryCode"].isupper():
            raise ValueError(f"Invalid country code for {group['id']}: {group['countryCode']!r}")
        if group["url"] is not None:
            parsed_url = urlparse(group["url"])
            if parsed_url.scheme != "https" or not parsed_url.netloc:
                raise ValueError(f"Invalid join URL for {group['id']}: {group['url']!r}")
        if not group["name"] or not group["country"]:
            raise ValueError(f"Incomplete AWS User Group record: {group['id']}")


def write_index(index: dict[str, Any], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--raw-dir", type=Path, default=REPO_ROOT / "data/community/raw/builder-center")
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--delay", type=float, default=0.5)
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()

    cache = HttpCache(args.raw_dir, timeout=args.timeout, retries=args.retries, delay=args.delay)
    index = build_user_groups_index(cache, refresh=args.refresh)
    write_index(index, args.output)
    print(
        f"Builder Center User Groups index: {index['count']} groups across "
        f"{index['countryCount']} countries written to {args.output}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
