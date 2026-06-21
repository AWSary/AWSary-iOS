#!/usr/bin/env python3
"""Build an AWS Heroes alias index from Builder Center's public group API."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any
from urllib.parse import urlencode

from harvest_builder_center import BUILDER_PUBLIC_HEADERS, REPO_ROOT
from utils.http_cache import HttpCache


BUILDER_GROUPS_ENDPOINT = "https://api.builder.aws.com/camp/groups"
DEFAULT_OUTPUT = REPO_ROOT / "data/community/indexes/builder-center-heroes.index.json"


def build_heroes_alias_index(
    cache: HttpCache,
    *,
    refresh: bool = False,
    page_size: int = 500,
) -> dict[str, Any]:
    """Discover the HERO group and return its public profiles with usable aliases."""

    groups_response = cache.fetch(
        BUILDER_GROUPS_ENDPOINT,
        refresh=refresh,
        headers=BUILDER_PUBLIC_HEADERS,
    )
    groups = json.loads(groups_response.body)
    hero_group = next(
        (
            group
            for group in groups.get("groupOverviewList", [])
            if group.get("groupType") == "HERO" and group.get("groupId")
        ),
        None,
    )
    if hero_group is None:
        raise ValueError("Builder Center did not return a HERO group")

    group_id = hero_group["groupId"]
    members_url = f"{BUILDER_GROUPS_ENDPOINT}/{group_id}/members"
    query: dict[str, Any] = {"pageSize": page_size}
    profiles: list[dict[str, Any]] = []
    retrieved_at = groups_response.retrieved_at
    while True:
        response = cache.fetch(
            f"{members_url}?{urlencode(query)}",
            refresh=refresh,
            headers=BUILDER_PUBLIC_HEADERS,
        )
        retrieved_at = max(retrieved_at, response.retrieved_at)
        payload = json.loads(response.body)
        profiles.extend(
            profile for profile in payload.get("userProfiles", []) if isinstance(profile, dict)
        )
        next_token = payload.get("nextToken")
        if not next_token:
            break
        query["nextToken"] = next_token

    indexed: list[dict[str, Any]] = []
    omitted: list[str] = []
    for profile in profiles:
        basic = profile.get("basicInfo") if isinstance(profile.get("basicInfo"), dict) else {}
        alias = basic.get("alias")
        if not isinstance(alias, str) or not alias:
            omitted.append(str(basic.get("name") or basic.get("builderProfileId") or "unknown"))
            continue
        indexed.append(
            {
                "alias": alias,
                "builderProfileId": basic.get("builderProfileId"),
                "displayName": basic.get("name"),
            }
        )

    indexed.sort(key=lambda person: person["alias"].casefold())
    return {
        "generatedAt": retrieved_at,
        "groupId": group_id,
        "groupType": "HERO",
        "sourceUrl": f"{members_url}?{urlencode({'pageSize': page_size})}",
        "count": len(indexed),
        "people": indexed,
        "omittedWithoutAlias": sorted(omitted, key=str.casefold),
    }


def write_index(index: dict[str, Any], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--raw-dir", type=Path, default=REPO_ROOT / "data/community/raw/builder-center")
    parser.add_argument("--page-size", type=int, default=500)
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--delay", type=float, default=0.5)
    parser.add_argument("--refresh", action="store_true")
    args = parser.parse_args()
    if args.page_size < 1:
        parser.error("--page-size must be positive")

    cache = HttpCache(args.raw_dir, timeout=args.timeout, retries=args.retries, delay=args.delay)
    index = build_heroes_alias_index(cache, refresh=args.refresh, page_size=args.page_size)
    write_index(index, args.output)
    print(
        f"Builder Center Hero index: {index['count']} aliases written to {args.output}; "
        f"{len(index['omittedWithoutAlias'])} profile(s) omitted without an alias."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
