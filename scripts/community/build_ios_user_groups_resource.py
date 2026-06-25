#!/usr/bin/env python3
"""Merge AWS and Meetup User Group indexes into the bundled iOS resource."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
from typing import Any, Iterable
from urllib.parse import quote, urlparse, urlsplit, urlunsplit


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_AWS_INDEX = REPO_ROOT / "data/community/indexes/builder-center-user-groups.index.json"
DEFAULT_MEETUP_INDEX = REPO_ROOT / "data/community/indexes/meetup-user-groups.index.json"
DEFAULT_OUTPUT = REPO_ROOT / "ios/AWSary/resources/community_user_groups.json"


def build_ios_user_groups_resource(
    aws_index: dict[str, Any], meetup_index: dict[str, Any]
) -> list[dict[str, Any]]:
    """Build one app record for every group in the authoritative AWS directory."""

    aws_groups = aws_index.get("groups")
    meetup_groups = meetup_index.get("groups")
    if not isinstance(aws_groups, list):
        raise ValueError("AWS User Groups index has no groups array")
    if not isinstance(meetup_groups, list):
        raise ValueError("Meetup User Groups index has no groups array")

    enriched_by_id = {
        group["awsUserGroupId"]: group
        for group in meetup_groups
        if isinstance(group, dict) and isinstance(group.get("awsUserGroupId"), str)
    }
    failures_by_id = {
        failure["awsUserGroupId"]: failure
        for failure in meetup_index.get("failures", [])
        if isinstance(failure, dict) and isinstance(failure.get("awsUserGroupId"), str)
    }
    source_ids = {
        group.get("id") for group in aws_groups if isinstance(group, dict) and isinstance(group.get("id"), str)
    }
    unknown_ids = sorted(set(enriched_by_id) - source_ids)
    if unknown_ids:
        raise ValueError(f"Meetup enrichment contains unknown AWS User Group IDs: {', '.join(unknown_ids)}")

    result = []
    for source in aws_groups:
        if not isinstance(source, dict):
            raise ValueError("AWS User Groups index contains a non-object record")
        group_id = _required_string(source, "id")
        name = _required_string(source, "name")
        enriched = enriched_by_id.get(group_id, {})
        raw_join_url = source.get("url")
        join_url = _normalize_url(raw_join_url) if isinstance(raw_join_url, str) else ""
        platform = _platform(join_url)
        links = _links(enriched.get("socialLinks"), join_url, platform)
        activity = _activity(enriched.get("activitySnapshot"))
        enriched_location = enriched.get("location") if isinstance(enriched.get("location"), dict) else {}

        result.append(
            {
                "id": group_id,
                "name": name,
                "summary": _plain_text(enriched.get("description")),
                "location": {
                    "displayName": str(source.get("location") or "").strip(),
                    "city": _optional_string(enriched_location.get("city")),
                    "region": _optional_string(enriched_location.get("region")),
                    "country": _required_string(source, "country"),
                    "countryCode": _required_string(source, "countryCode").upper(),
                    "latitude": _optional_number(enriched_location.get("latitude")),
                    "longitude": _optional_number(enriched_location.get("longitude")),
                    "timezone": _optional_string(enriched_location.get("timezone")),
                },
                "imageURL": str(enriched.get("imageURL") or ""),
                "joinURL": join_url,
                "platform": platform,
                "topics": _unique(enriched.get("topics", [])),
                "links": links,
                "foundedAt": _optional_string(enriched.get("foundedAt")),
                "networkName": _network_name(enriched.get("network")),
                "metadataStatus": (
                    "enriched"
                    if enriched
                    else "unavailable"
                    if group_id in failures_by_id
                    else "directory_only"
                ),
                "activity": activity,
            }
        )

    ids = [group["id"] for group in result]
    if len(ids) != len(set(ids)):
        raise ValueError("iOS User Groups resource contains duplicate IDs")
    return sorted(result, key=lambda group: (group["name"].casefold(), group["id"]))


def _links(value: Any, join_url: str, platform: str) -> list[dict[str, str]]:
    result = []
    seen = set()
    if join_url:
        result.append({"label": _platform_label(platform), "url": join_url})
        seen.add(join_url)
    for link in value if isinstance(value, list) else []:
        if not isinstance(link, dict):
            continue
        url = _normalize_url(link.get("url")) if isinstance(link.get("url"), str) else ""
        if not url or url in seen:
            continue
        result.append({"label": _link_label(link.get("type")), "url": url})
        seen.add(url)
    return result


def _activity(value: Any) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        return None
    return {
        "capturedAt": _optional_string(value.get("capturedAt")),
        "memberCount": _optional_integer(value.get("memberCount")),
        "leaderCount": _optional_integer(value.get("leaderCount")),
        "ratingAverage": _optional_number(value.get("ratingAverage")),
        "ratingCount": _optional_integer(value.get("ratingCount")),
        "upcomingEventCount": _optional_integer(value.get("upcomingEventCount")),
        "pastEventCount": _optional_integer(value.get("pastEventCount")),
    }


def _plain_text(value: Any) -> str:
    text = str(value or "").strip()
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"[*_`]+", "", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def _platform(url: str) -> str:
    host = (urlparse(url).hostname or "").lower()
    if host.endswith("meetup.com"):
        return "meetup"
    if host.endswith("connpass.com"):
        return "connpass"
    if host.endswith("doorkeeper.jp"):
        return "doorkeeper"
    if host.endswith("awscommunity.cn"):
        return "aws_community"
    for platform in ("linkedin", "facebook", "luma", "accupass"):
        if platform in host:
            return platform
    return "website"


def _platform_label(platform: str) -> str:
    return {
        "meetup": "Meetup",
        "connpass": "Connpass",
        "doorkeeper": "Doorkeeper",
        "aws_community": "AWS Community",
        "linkedin": "LinkedIn",
        "facebook": "Facebook",
        "luma": "Luma",
        "accupass": "Accupass",
    }.get(platform, "Website")


def _link_label(value: Any) -> str:
    return {
        "linkedin": "LinkedIn",
        "facebook": "Facebook",
        "instagram": "Instagram",
        "twitter": "X",
        "youtube": "YouTube",
        "other": "Website",
    }.get(str(value or "").lower(), "Website")


def _network_name(value: Any) -> str | None:
    return _optional_string(value.get("name")) if isinstance(value, dict) else None


def _normalize_url(value: str) -> str:
    stripped = value.strip()
    if not stripped:
        return ""
    parsed = urlsplit(stripped)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        return ""
    return urlunsplit(
        (
            "https" if parsed.scheme == "http" else parsed.scheme,
            parsed.netloc,
            quote(parsed.path, safe="/%-._~"),
            quote(parsed.query, safe="=&;%:+,/?@-._~"),
            "",
        )
    )


def _required_string(value: dict[str, Any], key: str) -> str:
    result = value.get(key)
    if not isinstance(result, str) or not result.strip():
        raise ValueError(f"User Group record has no {key}")
    return result.strip()


def _optional_string(value: Any) -> str | None:
    return value.strip() if isinstance(value, str) and value.strip() else None


def _optional_number(value: Any) -> int | float | None:
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def _optional_integer(value: Any) -> int | None:
    return value if isinstance(value, int) and not isinstance(value, bool) else None


def _unique(values: Iterable[Any]) -> list[str]:
    result = []
    seen = set()
    for value in values:
        cleaned = str(value or "").strip()
        key = cleaned.casefold()
        if cleaned and key not in seen:
            seen.add(key)
            result.append(cleaned)
    return sorted(result, key=str.casefold)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--aws-index", type=Path, default=DEFAULT_AWS_INDEX)
    parser.add_argument("--meetup-index", type=Path, default=DEFAULT_MEETUP_INDEX)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()

    resource = build_ios_user_groups_resource(
        json.loads(args.aws_index.read_text(encoding="utf-8")),
        json.loads(args.meetup_index.read_text(encoding="utf-8")),
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(resource, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"iOS User Groups resource: {len(resource)} group(s) written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
