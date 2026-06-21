#!/usr/bin/env python3
"""Harvest public AWS community pages into reviewable draft Person JSON files."""

from __future__ import annotations

import argparse
from hashlib import sha256
import json
from pathlib import Path
import sys
import time
from typing import Any, Iterable
from urllib.parse import urlparse
from urllib.parse import unquote

from parse_builder_center import parse_document
from utils.http_cache import HttpCache
from utils.json_extractors import (
    discover_public_javascript_links,
    discover_public_json_links,
    extract_json_from_html,
    extract_json_from_javascript,
)


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RAW_DIR = REPO_ROOT / "data/community/raw/builder-center"
DEFAULT_PEOPLE_DIR = REPO_ROOT / "data/community/people"
BUILDER_PROFILE_ENDPOINT = "https://api.builder.aws.com/ums/getProfileByAlias"
BUILDER_PUBLIC_HEADERS = {
    "Content-Type": "application/json",
    "builder-session-token": "dummy",
    "Origin": "https://builder.aws.com",
    "Referer": "https://builder.aws.com/",
}


def read_seed_file(path: Path) -> list[str]:
    """Read newline-separated URLs, ignoring blanks and comments."""

    return [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def harvest_url(
    url: str,
    cache: HttpCache,
    *,
    refresh: bool,
    follow_json_links: bool = True,
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Fetch one seed and any explicit AWS-hosted JSON assets it references."""

    _require_public_aws_url(url)
    response = cache.fetch(url, refresh=refresh)
    people = parse_document(
        response.body,
        source_url=response.url,
        retrieved_at=response.retrieved_at,
        content_type=response.content_type,
    )
    inspection: dict[str, Any] = {
        "seedUrl": url,
        "resolvedUrl": response.url,
        "retrievedAt": response.retrieved_at,
        "contentType": response.content_type,
        "rawCachePath": response.cache_path.name,
        "fromCache": response.from_cache,
        "embeddedCandidateCount": 0,
        "linkedJson": [],
        "linkedJavascript": [],
        "builderApi": None,
        "people": people,
    }

    if "html" in response.content_type.lower():
        html = response.body.decode("utf-8", errors="replace")
        inspection["embeddedCandidateCount"] = len(extract_json_from_html(html))
        if follow_json_links:
            for linked_url in discover_public_json_links(html, response.url):
                if not _is_public_aws_url(linked_url):
                    continue
                linked = cache.fetch(linked_url, refresh=refresh)
                linked_people = parse_document(
                    linked.body,
                    source_url=linked.url,
                    retrieved_at=linked.retrieved_at,
                    content_type=linked.content_type,
                )
                inspection["linkedJson"].append(
                    {
                        "url": linked.url,
                        "rawCachePath": linked.cache_path.name,
                        "personCount": len(linked_people),
                    }
                )
                people.extend(linked_people)

            # Builder Center is a client-rendered app. Inspect its explicitly
            # linked public JavaScript assets as data, but never execute them.
            for linked_url in discover_public_javascript_links(html, response.url)[:10]:
                if urlparse(linked_url).netloc.lower() != "builder.aws.com":
                    continue
                linked = cache.fetch(linked_url, refresh=refresh)
                script = linked.body.decode("utf-8", errors="replace")
                script_candidates = extract_json_from_javascript(script)
                linked_people: list[dict[str, Any]] = []
                for candidate in script_candidates:
                    linked_people.extend(
                        parse_document(
                            json.dumps(candidate.data),
                            source_url=linked.url,
                            retrieved_at=linked.retrieved_at,
                            content_type="application/json",
                        )
                    )
                inspection["linkedJavascript"].append(
                    {
                        "url": linked.url,
                        "rawCachePath": linked.cache_path.name,
                        "jsonCandidateCount": len(script_candidates),
                        "personCount": len(linked_people),
                    }
                )
                people.extend(linked_people)

        alias = _builder_alias_from_url(response.url)
        if alias:
            api_people, api_details = harvest_builder_alias(alias, cache, refresh=refresh)
            inspection["builderApi"] = api_details
            people.extend(api_people)

    unique = {person["slug"]: person for person in people}
    inspection["people"] = [unique[key] for key in sorted(unique)]
    return inspection["people"], inspection


def harvest_builder_alias(
    alias: str, cache: HttpCache, *, refresh: bool
) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    """Call the public profile request exactly as Builder Center's JS client does."""

    normalized_alias = alias.strip().removeprefix("@")
    if not normalized_alias or not all(character.isalnum() or character in "-_" for character in normalized_alias):
        raise ValueError(f"Invalid Builder Center alias: {alias!r}")
    body = json.dumps({"alias": normalized_alias}, separators=(",", ":")).encode("utf-8")
    response = cache.fetch(
        BUILDER_PROFILE_ENDPOINT,
        refresh=refresh,
        method="POST",
        headers=BUILDER_PUBLIC_HEADERS,
        body=body,
    )
    people = parse_document(
        response.body,
        source_url=response.url,
        retrieved_at=response.retrieved_at,
        content_type=response.content_type,
    )
    return people, {
        "alias": normalized_alias,
        "endpoint": response.url,
        "rawCachePath": response.cache_path.name,
        "fromCache": response.from_cache,
        "personCount": len(people),
        "publicHeader": "builder-session-token",
    }


def write_people(people: Iterable[dict[str, Any]], people_dir: Path) -> tuple[int, int]:
    """Create or update harvested records while preserving editorial state."""

    created = 0
    updated = 0
    people_dir.mkdir(parents=True, exist_ok=True)
    for harvested in sorted(people, key=lambda item: item["slug"]):
        path = people_dir / f"{harvested['slug']}.json"
        if path.exists():
            existing = json.loads(path.read_text(encoding="utf-8"))
            person = _merge_editorial_state(existing, harvested)
            updated += 1
        else:
            person = harvested
            created += 1
        path.write_text(json.dumps(person, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return created, updated


def _merge_editorial_state(existing: dict[str, Any], harvested: dict[str, Any]) -> dict[str, Any]:
    """Do not silently undo ownership, review, or publication decisions."""

    merged = dict(harvested)
    for field in ("id", "profileStatus", "ownershipStatus", "lastReviewedAt"):
        if field in existing:
            merged[field] = existing[field]
    if existing.get("featuredContent"):
        merged["featuredContent"] = existing["featuredContent"]
    return merged


def _inspection_path(raw_dir: Path, url: str) -> Path:
    host = urlparse(url).netloc.replace(".", "-")
    digest = sha256(url.encode("utf-8")).hexdigest()[:12]
    return raw_dir / f"candidates-{host}-{digest}.json"


def _builder_alias_from_url(url: str) -> str | None:
    parsed = urlparse(url)
    if parsed.netloc.lower() != "builder.aws.com":
        return None
    parts = [unquote(part) for part in parsed.path.split("/") if part]
    return parts[1][1:] if len(parts) >= 2 and parts[0] == "community" and parts[1].startswith("@") else None


def _is_public_aws_url(url: str) -> bool:
    parsed = urlparse(url)
    host = parsed.netloc.lower().split(":", 1)[0]
    return parsed.scheme in {"http", "https"} and (
        host == "aws.amazon.com"
        or host.endswith(".aws.amazon.com")
        or host == "builder.aws.com"
        or host.endswith(".awsstatic.com")
        or host.endswith(".aws.com")
        or host.endswith(".aws.dev")
    )


def _require_public_aws_url(url: str) -> None:
    if not _is_public_aws_url(url):
        raise ValueError(f"Seed URL must be a public AWS-controlled HTTP(S) URL: {url}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--seed-url", action="append", default=[], help="Public AWS URL; may be repeated")
    parser.add_argument(
        "--builder-alias",
        action="append",
        default=[],
        help="Public Builder Center alias; may be repeated and does not require a page fetch",
    )
    parser.add_argument("--seed-file", type=Path, action="append", default=[], help="File containing one URL per line")
    parser.add_argument("--raw-dir", type=Path, default=DEFAULT_RAW_DIR)
    parser.add_argument("--people-dir", type=Path, default=DEFAULT_PEOPLE_DIR)
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--delay", type=float, default=0.5, help="Minimum pause between seed requests")
    parser.add_argument("--refresh", action="store_true", help="Ignore cached responses")
    parser.add_argument("--no-follow-json-links", action="store_true")
    args = parser.parse_args()

    urls = list(args.seed_url)
    for seed_file in args.seed_file:
        urls.extend(read_seed_file(seed_file))
    urls = list(dict.fromkeys(urls))
    if not urls and not args.builder_alias:
        parser.error("provide at least one --seed-url, --seed-file, or --builder-alias")

    cache = HttpCache(args.raw_dir, timeout=args.timeout, retries=args.retries, delay=args.delay)
    all_people: dict[str, dict[str, Any]] = {}
    failures = 0
    for index, url in enumerate(urls):
        if index:
            time.sleep(args.delay)
        try:
            people, inspection = harvest_url(
                url,
                cache,
                refresh=args.refresh,
                follow_json_links=not args.no_follow_json_links,
            )
            inspection_path = _inspection_path(args.raw_dir, url)
            inspection_path.write_text(
                json.dumps(inspection, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            print(f"{url}: {len(people)} person candidate(s); inspection: {inspection_path}")
            if not people:
                print("  No public person payload found; cached page requires manual inspection.", file=sys.stderr)
            all_people.update({person["slug"]: person for person in people})
        except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
            failures += 1
            print(f"Failed: {url}: {exc}", file=sys.stderr)

    for alias in dict.fromkeys(args.builder_alias):
        try:
            people, details = harvest_builder_alias(alias, cache, refresh=args.refresh)
            inspection_url = f"https://builder.aws.com/community/@{alias.removeprefix('@')}"
            inspection = {
                "seedUrl": inspection_url,
                "retrievedAt": people[0]["lastHarvestedAt"] if people else None,
                "builderApi": details,
                "people": people,
            }
            inspection_path = _inspection_path(args.raw_dir, inspection_url)
            inspection_path.write_text(
                json.dumps(inspection, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
                encoding="utf-8",
            )
            print(f"Builder alias @{alias.removeprefix('@')}: {len(people)} person candidate(s); inspection: {inspection_path}")
            all_people.update({person["slug"]: person for person in people})
        except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
            failures += 1
            print(f"Failed Builder alias @{alias.removeprefix('@')}: {exc}", file=sys.stderr)

    created, updated = write_people(all_people.values(), args.people_dir)
    print(f"Harvest complete: {len(all_people)} unique person(s), {created} created, {updated} updated, {failures} failed seed(s).")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
