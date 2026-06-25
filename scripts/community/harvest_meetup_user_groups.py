#!/usr/bin/env python3
"""Enrich AWS User Groups from their public Meetup HTML pages."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any
from urllib.parse import quote, urlparse, urlsplit, urlunsplit

from harvest_builder_center import REPO_ROOT
from utils.http_cache import HttpCache
from utils.json_extractors import extract_json_from_html


DEFAULT_INPUT = REPO_ROOT / "data/community/indexes/builder-center-user-groups.index.json"
DEFAULT_OUTPUT = REPO_ROOT / "data/community/indexes/meetup-user-groups.index.json"
DEFAULT_RAW_DIR = REPO_ROOT / "data/community/raw/meetup"


def parse_meetup_group_html(
    html: str, *, source_url: str, retrieved_at: str
) -> dict[str, Any]:
    """Parse public structured data without calling Meetup's internal GraphQL API."""

    candidates = extract_json_from_html(html)
    json_ld = [candidate.data for candidate in candidates if candidate.kind == "application/ld+json"]
    schema_candidates = [
        value
        for value in json_ld
        if isinstance(value, dict)
        and value.get("@type") == "Organization"
        and value.get("name") != "Meetup"
    ]
    next_data = next((candidate.data for candidate in candidates if candidate.kind == "next_data"), None)
    if not isinstance(next_data, dict):
        if schema_candidates:
            return _schema_only_record(schema_candidates[0], source_url, retrieved_at)
        raise ValueError("Meetup page contained neither group JSON-LD nor __NEXT_DATA__")

    page_props = next_data.get("props", {}).get("pageProps", {})
    state = page_props.get("__APOLLO_STATE__") if isinstance(page_props, dict) else None
    if not isinstance(state, dict):
        if schema_candidates:
            return _schema_only_record(schema_candidates[0], source_url, retrieved_at)
        raise ValueError("Meetup page did not contain public Apollo page state")
    group = next(
        (
            value
            for key, value in state.items()
            if key.startswith("Group:") and isinstance(value, dict) and value.get("__typename") == "Group"
        ),
        None,
    )
    if group is None:
        if schema_candidates:
            return _schema_only_record(schema_candidates[0], source_url, retrieved_at)
        raise ValueError("Meetup page state did not contain a Group entity")

    group_id = _required_string(group, "id")
    name = _required_string(group, "name")
    group_schema = next((value for value in schema_candidates if value.get("name") == name), {})

    topics = []
    for reference in group.get("activeTopics", []):
        topic = _resolve_reference(state, reference)
        if topic and isinstance(topic.get("name"), str):
            topics.append(topic["name"])

    social_links = []
    for item in group.get("socialNetworks", []):
        if not isinstance(item, dict):
            continue
        url = item.get("url")
        if not _is_valid_https_url(url):
            continue
        social_links.append(
            {
                "type": str(item.get("service") or "other").lower(),
                "url": url,
            }
        )
    for url in group_schema.get("sameAs", []):
        if _is_valid_https_url(url) and all(link["url"] != url for link in social_links):
            social_links.append({"type": "other", "url": url})

    network = _resolve_reference(state, group.get("proNetwork"))
    network_data = None
    if network:
        network_data = {
            "id": network.get("id"),
            "name": network.get("name"),
            "urlName": network.get("urlname"),
            "groupCount": _nested(network, "groups", "totalCount"),
        }

    image_url = group_schema.get("image") if isinstance(group_schema.get("image"), str) else None
    if not _is_valid_https_url(image_url):
        photo = _resolve_reference(state, group.get("keyGroupPhoto"))
        image_url = photo.get("highResUrl") if photo else None
    if not _is_valid_https_url(image_url):
        image_url = None

    member_counts = _nested(group, "stats", "memberCounts") or {}
    ratings = _nested(group, "stats", "eventRatings") or {}
    return {
        "awsUserGroupId": None,
        "meetupId": group_id,
        "name": name,
        "urlName": group.get("urlname"),
        "canonicalURL": source_url,
        "description": group.get("description"),
        "imageURL": image_url,
        "foundedAt": group.get("foundedDate") or group_schema.get("foundingDate"),
        "location": {
            "city": group.get("city"),
            "region": group.get("state"),
            "countryCode": group.get("country"),
            "latitude": group.get("lat"),
            "longitude": group.get("lon"),
            "timezone": group.get("timezone"),
        },
        "access": {
            "isPrivate": group.get("isPrivate"),
            "joinMode": group.get("joinMode"),
            "status": group.get("status"),
        },
        "topics": sorted(set(topics), key=str.casefold),
        "socialLinks": sorted(social_links, key=lambda link: (link["type"], link["url"])),
        "network": network_data,
        "activitySnapshot": {
            "capturedAt": retrieved_at,
            "memberCount": member_counts.get("all") if isinstance(member_counts, dict) else None,
            "leaderCount": member_counts.get("leadership") if isinstance(member_counts, dict) else None,
            "ratingAverage": ratings.get("average") if isinstance(ratings, dict) else None,
            "ratingCount": ratings.get("total") if isinstance(ratings, dict) else None,
            "upcomingEventCount": _event_count(group, "ACTIVE"),
            "pastEventCount": _event_count(group, "PAST"),
        },
        "lastHarvestedAt": retrieved_at,
        "sourceURL": source_url,
    }


def _schema_only_record(
    schema: dict[str, Any], source_url: str, retrieved_at: str
) -> dict[str, Any]:
    """Return the durable subset when Meetup's richer embedded state changes."""

    name = _required_string(schema, "name")
    address = _nested(schema, "address", "location", "address") or {}
    social_links = [
        {"type": "other", "url": url}
        for url in schema.get("sameAs", [])
        if _is_valid_https_url(url)
    ]
    image_url = schema.get("image") if _is_valid_https_url(schema.get("image")) else None
    return {
        "awsUserGroupId": None,
        "meetupId": None,
        "name": name,
        "urlName": None,
        "canonicalURL": schema.get("url") if _is_valid_https_url(schema.get("url")) else source_url,
        "description": None,
        "imageURL": image_url,
        "foundedAt": schema.get("foundingDate"),
        "location": {
            "city": address.get("addressLocality") if isinstance(address, dict) else None,
            "region": address.get("addressRegion") if isinstance(address, dict) else None,
            "countryCode": address.get("addressCountry") if isinstance(address, dict) else None,
            "latitude": None,
            "longitude": None,
            "timezone": None,
        },
        "access": {"isPrivate": None, "joinMode": None, "status": None},
        "topics": [],
        "socialLinks": sorted(social_links, key=lambda link: link["url"]),
        "network": None,
        "activitySnapshot": {
            "capturedAt": retrieved_at,
            "memberCount": None,
            "leaderCount": None,
            "ratingAverage": None,
            "ratingCount": None,
            "upcomingEventCount": None,
            "pastEventCount": None,
        },
        "lastHarvestedAt": retrieved_at,
        "sourceURL": source_url,
    }


def build_meetup_index(
    source_index: dict[str, Any],
    cache: HttpCache,
    *,
    refresh: bool = False,
    group_ids: set[str] | None = None,
    limit: int | None = None,
) -> dict[str, Any]:
    """Fetch Meetup-backed AWS User Groups and return their public enrichment index."""

    source_groups = source_index.get("groups")
    if not isinstance(source_groups, list):
        raise ValueError("AWS User Groups index has no groups array")
    eligible = [
        group
        for group in source_groups
        if isinstance(group, dict)
        and isinstance(group.get("id"), str)
        and _is_public_meetup_url(group.get("url"))
        and (group_ids is None or group["id"] in group_ids)
    ]
    if limit is not None:
        eligible = eligible[:limit]

    records = []
    failures = []
    retrieved_at_values = []
    for position, source_group in enumerate(eligible, start=1):
        print(f"[{position}/{len(eligible)}] {source_group['id']} {source_group.get('name', '')}")
        response = None
        try:
            fetch_url = _normalize_public_url(source_group["url"])
            response = cache.fetch(fetch_url, refresh=refresh)
            retrieved_at_values.append(response.retrieved_at)
            html = response.body.decode("utf-8", errors="replace")
            record = parse_meetup_group_html(
                html,
                source_url=response.url,
                retrieved_at=response.retrieved_at,
            )
            record["awsUserGroupId"] = source_group["id"]
            records.append(record)
        except Exception as error:
            reason = _failure_reason(error, response.body if response is not None else None)
            print(f"  skipped: {reason}")
            failures.append(
                {
                    "awsUserGroupId": source_group["id"],
                    "name": source_group.get("name"),
                    "sourceURL": source_group["url"],
                    "reason": reason,
                }
            )

    records.sort(key=lambda record: (record["name"].casefold(), record["awsUserGroupId"]))
    return {
        "generatedAt": max(retrieved_at_values, default=source_index.get("generatedAt")),
        "sourceIndex": "data/community/indexes/builder-center-user-groups.index.json",
        "sourceGroupCount": len(source_groups),
        "meetupEligibleCount": sum(
            1 for group in source_groups if isinstance(group, dict) and _is_public_meetup_url(group.get("url"))
        ),
        "count": len(records),
        "failureCount": len(failures),
        "failures": failures,
        "groups": records,
    }


def _resolve_reference(state: dict[str, Any], value: Any) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        return None
    reference = value.get("__ref")
    resolved = state.get(reference) if isinstance(reference, str) else None
    return resolved if isinstance(resolved, dict) else None


def _nested(value: dict[str, Any], *keys: str) -> Any:
    current: Any = value
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def _event_count(group: dict[str, Any], status: str) -> int | None:
    for key, value in group.items():
        if key.startswith("events(") and f'"{status}"' in key and isinstance(value, dict):
            count = value.get("totalCount")
            return count if isinstance(count, int) else None
    return None


def _failure_reason(error: Exception, body: bytes | None) -> str:
    html = body.decode("utf-8", errors="replace") if body is not None else ""
    if "captcha" in html.casefold() or "access denied" in html.casefold():
        return "access_interstitial"
    if (
        "Group not found" in html
        or "group you're looking for doesn't exist" in html
        or 'name="robots" content="noindex, follow"' in html
    ):
        return "group_not_found"
    if isinstance(error, RuntimeError):
        return "fetch_failed"
    return "unsupported_page_shape"


def _required_string(value: dict[str, Any], key: str) -> str:
    result = value.get(key)
    if not isinstance(result, str) or not result:
        raise ValueError(f"Meetup Group entity has no {key}")
    return result


def _is_valid_https_url(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    parsed = urlparse(value)
    return parsed.scheme == "https" and bool(parsed.netloc)


def _is_public_meetup_url(value: Any) -> bool:
    if not _is_valid_https_url(value):
        return False
    return urlparse(value).hostname in {"meetup.com", "www.meetup.com"}


def _normalize_public_url(value: str) -> str:
    """Percent-encode unsafe source characters before passing a URL to urllib."""

    parsed = urlsplit(value)
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError(f"Invalid public URL: {value!r}")
    return urlunsplit(
        (
            parsed.scheme,
            parsed.netloc,
            quote(parsed.path, safe="/-._~"),
            quote(parsed.query, safe="=&;%:+,/?@-._~"),
            "",
        )
    )


def write_index(index: dict[str, Any], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--raw-dir", type=Path, default=DEFAULT_RAW_DIR)
    parser.add_argument("--group-id", action="append", default=[])
    parser.add_argument("--limit", type=int)
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--retries", type=int, default=2)
    parser.add_argument("--delay", type=float, default=1.0)
    parser.add_argument("--refresh", action="store_true")
    parser.add_argument(
        "--fail-on-error",
        action="store_true",
        help="Write the index, then return a non-zero status if any group failed",
    )
    args = parser.parse_args()
    if args.limit is not None and args.limit < 1:
        parser.error("--limit must be positive")

    source_index = json.loads(args.input.read_text(encoding="utf-8"))
    cache = HttpCache(args.raw_dir, timeout=args.timeout, retries=args.retries, delay=args.delay)
    index = build_meetup_index(
        source_index,
        cache,
        refresh=args.refresh,
        group_ids=set(args.group_id) or None,
        limit=args.limit,
    )
    write_index(index, args.output)
    print(
        f"Meetup enrichment index: {index['count']} of {index['meetupEligibleCount']} eligible "
        f"groups written to {args.output}; {index['failureCount']} failure(s)."
    )
    return 1 if args.fail_on_error and index["failureCount"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
