#!/usr/bin/env python3
"""Normalize public AWS community JSON or HTML into AWSary Person records."""

from __future__ import annotations

from datetime import datetime, timezone
import json
import re
from typing import Any, Iterable, Iterator
from urllib.parse import urlparse

from utils.json_extractors import extract_json_from_html
from utils.slugify import person_id, slugify


AWS_BUILDER_HOST = "builder.aws.com"


def parse_document(
    raw: bytes | str,
    *,
    source_url: str,
    retrieved_at: str,
    content_type: str | None = None,
) -> list[dict[str, Any]]:
    """Parse an HTML or JSON document and return unique normalized people."""

    text = raw.decode("utf-8", errors="replace") if isinstance(raw, bytes) else raw
    is_json = "json" in (content_type or "").lower() or text.lstrip().startswith(("{", "["))
    candidates: list[Any] = []
    if is_json:
        try:
            candidates.append(json.loads(text))
        except json.JSONDecodeError:
            return []
    else:
        candidates.extend(candidate.data for candidate in extract_json_from_html(text))

    people: dict[str, dict[str, Any]] = {}
    for candidate in candidates:
        for record in extract_candidate_records(candidate):
            person = normalize_candidate(record, source_url=source_url, retrieved_at=retrieved_at)
            if person:
                people[person["slug"]] = person
    return [people[key] for key in sorted(people)]


def extract_candidate_records(value: Any) -> Iterator[dict[str, Any]]:
    """Walk decoded JSON and yield structures that look like person records."""

    if isinstance(value, list):
        for item in value:
            yield from extract_candidate_records(item)
        return
    if not isinstance(value, dict):
        return

    # aws.amazon.com public directory API wrapper.
    if isinstance(value.get("item"), dict) and isinstance(value["item"].get("additionalFields"), dict):
        yield value["item"]
        return

    if _looks_like_directory_person(value) or _looks_like_builder_profile(value) or _looks_like_schema_person(value):
        yield value
        return

    # Named containers are traversed before the generic fallback to make this
    # resilient to API envelopes without relying on a single response shape.
    for key in ("items", "profiles", "people", "heroes", "results", "data", "profile"):
        if key in value:
            yield from extract_candidate_records(value[key])


def normalize_candidate(
    record: dict[str, Any], *, source_url: str, retrieved_at: str
) -> dict[str, Any] | None:
    """Normalize a supported AWS record shape into the Person schema."""

    if _looks_like_directory_person(record):
        return _normalize_directory_person(record, source_url, retrieved_at)
    if _looks_like_builder_profile(record):
        return _normalize_builder_profile(record, source_url, retrieved_at)
    if _looks_like_schema_person(record):
        return _normalize_schema_person(record, source_url, retrieved_at)
    return None


def _looks_like_directory_person(value: dict[str, Any]) -> bool:
    fields = value.get("additionalFields")
    return isinstance(fields, dict) and bool(fields.get("heroName") or fields.get("name"))


def _looks_like_builder_profile(value: dict[str, Any]) -> bool:
    basic = value.get("basicInfo")
    return isinstance(basic, dict) and bool(basic.get("name") or basic.get("firstName"))


def _looks_like_schema_person(value: dict[str, Any]) -> bool:
    return value.get("@type") == "Person" and bool(value.get("name"))


def _normalize_directory_person(
    record: dict[str, Any], source_url: str, retrieved_at: str
) -> dict[str, Any]:
    fields = record["additionalFields"]
    name = _clean_text(fields.get("heroName") or fields.get("name"))
    profile_url = _absolute_http_url(fields.get("heroBioURL")) or source_url
    location = _split_location(_clean_text(fields.get("heroLocation")))
    category = _clean_text(fields.get("heroCategory")) or "AWS Hero"
    start_year = _extract_year(fields.get("heroSinceDate"))
    summary = _clean_text(fields.get("description") or fields.get("heroDescription"))
    topics = _topics_from_values(fields.get("topics"), fields.get("tags"), category)
    links = _normalize_links(fields.get("hero_links") or fields.get("links"), profile_url)
    if not any(link["url"] == profile_url for link in links):
        links.insert(0, _source_profile_link(profile_url))

    populated = ["displayName", "programs", "links"]
    if summary:
        populated.append("summary")
    if location["city"] or location["country"]:
        populated.append("location")
    avatar_url = _absolute_http_url(fields.get("heroImageURL"))
    if avatar_url:
        populated.append("avatar")
    if topics:
        populated.append("topics")

    return _person(
        name=name,
        headline=category,
        summary=summary,
        location=location,
        avatar_url=avatar_url,
        program_name="AWS Hero",
        program_category=category.removeprefix("AWS "),
        start_year=start_year,
        topics=topics,
        links=links,
        source_url=source_url,
        retrieved_at=retrieved_at,
        evidence_fields=populated,
    )


def _normalize_builder_profile(
    record: dict[str, Any], source_url: str, retrieved_at: str
) -> dict[str, Any]:
    basic = record["basicInfo"]
    name = _clean_text(basic.get("name")) or " ".join(
        filter(None, [_clean_text(basic.get("firstName")), _clean_text(basic.get("lastName"))])
    )
    alias = _clean_text(basic.get("alias"))
    profile_url = source_url
    if alias:
        profile_url = f"https://builder.aws.com/community/@{alias}"

    location_data = record.get("location") if isinstance(record.get("location"), dict) else {}
    display_location_value = location_data.get("displayLocation")
    if isinstance(display_location_value, dict):
        location = {
            "city": _clean_text(display_location_value.get("city")) or None,
            "country": _clean_text(display_location_value.get("countryRegion")) or None,
            "region": _clean_text(display_location_value.get("stateProvince")) or None,
        }
        display_location = ", ".join(value for value in location.values() if value)
    else:
        display_location = _clean_text(display_location_value)
        location = _split_location(display_location)
    interests = record.get("interests") if isinstance(record.get("interests"), list) else []
    programs = record.get("awsPrograms") if isinstance(record.get("awsPrograms"), list) else []
    active_programs = [item for item in programs if isinstance(item, dict) and item.get("memberStatus", "ACTIVE") == "ACTIVE"]
    hero = next((item for item in active_programs if item.get("programName") == "HERO"), None)
    community_builder = next((item for item in active_programs if item.get("programName") == "COMMUNITY_BUILDER"), None)
    program = hero or community_builder
    program_name = "AWS Hero" if hero else "AWS Community Builder" if community_builder else "AWS Community Member"
    category = _humanize(program.get("category")) if program else None
    start_year = _extract_year(program.get("joinedAt")) if program else None
    socials = record.get("socials") if isinstance(record.get("socials"), dict) else {}
    links = _normalize_links(socials, profile_url)
    links.insert(0, _source_profile_link(profile_url))
    avatar_url = _absolute_http_url(basic.get("avatar"))
    headline = _clean_text(basic.get("headline"))
    summary = _clean_text(basic.get("bio"))

    evidence = ["displayName", "links"]
    for field, value in (("headline", headline), ("summary", summary), ("avatar", avatar_url), ("topics", interests), ("programs", program)):
        if value:
            evidence.append(field)
    if display_location:
        evidence.append("location")

    person = _person(
        name=name,
        headline=headline,
        summary=summary,
        location=location,
        avatar_url=avatar_url,
        program_name=program_name,
        program_category=category,
        start_year=start_year,
        topics=_topics_from_values(interests),
        links=_deduplicate_links(links),
        source_url=profile_url,
        retrieved_at=retrieved_at,
        evidence_fields=evidence,
    )
    normalized_programs = _normalize_builder_programs(active_programs, profile_url, retrieved_at)
    if normalized_programs:
        person["programs"] = normalized_programs
    return person


def _normalize_builder_programs(
    programs: list[dict[str, Any]], source_url: str, retrieved_at: str
) -> list[dict[str, Any]]:
    names = {
        "HERO": "AWS Hero",
        "COMMUNITY_BUILDER": "AWS Community Builder",
        "USER_GROUP_LEADER": "AWS User Group Leader",
        "AWS_AUTHORIZED_INSTRUCTOR": "AWS Authorized Instructor",
    }
    normalized = []
    for program in programs:
        raw_name = _clean_text(program.get("programName"))
        if not raw_name:
            continue
        normalized.append(
            {
                "name": names.get(raw_name, _humanize(raw_name)),
                "category": _humanize(program.get("category")) or None,
                "startYear": _extract_year(program.get("joinedAt")),
                "endYear": None,
                "verificationStatus": "aws_source_verified",
                "sourceUrl": source_url,
                "lastCheckedAt": retrieved_at[:10],
            }
        )
    return normalized


def _normalize_schema_person(
    record: dict[str, Any], source_url: str, retrieved_at: str
) -> dict[str, Any]:
    name = _clean_text(record.get("name"))
    profile_url = _absolute_http_url(record.get("url")) or source_url
    address = record.get("address") if isinstance(record.get("address"), dict) else {}
    location = {
        "city": _clean_text(address.get("addressLocality")) or None,
        "country": _clean_text(address.get("addressCountry")) or None,
        "region": _clean_text(address.get("addressRegion")) or None,
    }
    links = [_source_profile_link(profile_url)]
    links.extend(_normalize_links(record.get("sameAs"), profile_url))
    summary = _clean_text(record.get("description"))
    headline = _clean_text(record.get("jobTitle"))
    avatar_url = _absolute_http_url(record.get("image"))
    evidence = ["displayName", "links"]
    for field, value in (("headline", headline), ("summary", summary), ("avatar", avatar_url)):
        if value:
            evidence.append(field)
    if any(location.values()):
        evidence.append("location")

    return _person(
        name=name,
        headline=headline,
        summary=summary,
        location=location,
        avatar_url=avatar_url,
        program_name="AWS Community Member",
        program_category=None,
        start_year=None,
        topics=[],
        links=_deduplicate_links(links),
        source_url=profile_url,
        retrieved_at=retrieved_at,
        evidence_fields=evidence,
    )


def _person(
    *,
    name: str,
    headline: str | None,
    summary: str | None,
    location: dict[str, str | None],
    avatar_url: str | None,
    program_name: str,
    program_category: str | None,
    start_year: int | None,
    topics: list[str],
    links: list[dict[str, Any]],
    source_url: str,
    retrieved_at: str,
    evidence_fields: list[str],
) -> dict[str, Any]:
    slug = slugify(name)
    source_type = _source_type(source_url)
    return {
        "id": person_id(slug),
        "slug": slug,
        "displayName": name,
        "headline": headline,
        "summary": summary,
        "location": location,
        "avatar": {
            "url": avatar_url,
            "sourceUrl": source_url if avatar_url else None,
            "sourceType": source_type,
            "verified": bool(avatar_url and _is_aws_controlled(avatar_url)),
        },
        "programs": [
            {
                "name": program_name,
                "category": program_category,
                "startYear": start_year,
                "endYear": None,
                "verificationStatus": "aws_source_verified",
                "sourceUrl": source_url,
                "lastCheckedAt": retrieved_at[:10],
            }
        ],
        "topics": sorted(set(topics), key=str.casefold),
        "links": _deduplicate_links(links),
        "featuredContent": [],
        "sourceEvidence": [
            {
                "sourceType": source_type,
                "sourceUrl": source_url,
                "retrievedAt": retrieved_at,
                "fields": sorted(set(evidence_fields)),
            }
        ],
        "profileStatus": "draft",
        "ownershipStatus": "unclaimed",
        "lastReviewedAt": None,
        "lastHarvestedAt": retrieved_at,
    }


def _normalize_links(value: Any, source_url: str) -> list[dict[str, Any]]:
    pairs: list[tuple[str, str]] = []
    if isinstance(value, str):
        pairs.append(("Website", value))
    elif isinstance(value, list):
        for item in value:
            if isinstance(item, str):
                pairs.append(("Website", item))
            elif isinstance(item, dict):
                url = item.get("url") or item.get("href")
                label = item.get("label") or item.get("text") or item.get("type") or "Website"
                if url:
                    pairs.append((str(label), str(url)))
    elif isinstance(value, dict):
        for label, url in value.items():
            if isinstance(url, str) and url:
                pairs.append((str(label), url))

    links = []
    for label, url in pairs:
        normalized_url = _absolute_http_url(url)
        if not normalized_url:
            continue
        link_type = _link_type(label, normalized_url)
        links.append(
            {
                "type": link_type,
                "label": _humanize(label) or "Website",
                "url": normalized_url,
                "handle": _link_handle(link_type, normalized_url),
                # AWS displaying a link proves observation, not ownership.
                "verified": link_type == "builder_center",
                "sourceUrl": source_url,
            }
        )
    return links


def _source_profile_link(source_url: str) -> dict[str, Any]:
    is_builder = urlparse(source_url).netloc.lower() == AWS_BUILDER_HOST
    return {
        "type": "builder_center" if is_builder else "website",
        "label": "AWS Builder Center" if is_builder else "AWS public profile",
        "url": source_url,
        "handle": None,
        "verified": True,
        "sourceUrl": source_url,
    }


def _link_type(label: str, url: str) -> str:
    host = urlparse(url).netloc.lower().removeprefix("www.")
    text = f"{label} {host}".lower()
    rules = (
        ("builder_center", "builder.aws.com"),
        ("linkedin", "linkedin"),
        ("x", "twitter"),
        ("x", "x.com"),
        ("github", "github"),
        ("youtube", "youtube"),
        ("twitch", "twitch"),
        ("newsletter", "newsletter"),
        ("mastodon", "mastodon"),
        ("blog", "blog"),
    )
    return next((kind for kind, marker in rules if marker in text), "website")


def _link_handle(link_type: str, url: str) -> str | None:
    if link_type not in {"linkedin", "x", "github", "youtube", "twitch", "mastodon"}:
        return None
    path = urlparse(url).path.strip("/")
    return path.split("/")[-1] if path else None


def _deduplicate_links(links: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for link in links:
        result[link["url"]] = link
    return sorted(result.values(), key=lambda item: (item["type"], item["url"]))


def _topics_from_values(*values: Any) -> list[str]:
    topics: list[str] = []
    for value in values:
        if isinstance(value, str):
            chunks = re.split(r"[,;|]", value)
        elif isinstance(value, list):
            chunks = value
        else:
            continue
        for chunk in chunks:
            if isinstance(chunk, dict):
                chunk = chunk.get("name") or chunk.get("label")
            cleaned = _humanize(str(chunk)) if chunk else ""
            if cleaned and cleaned.lower() not in {"aws hero", "hero"}:
                topics.append(cleaned.removeprefix("AWS "))
    return sorted(set(topics), key=str.casefold)


def _split_location(value: str) -> dict[str, str | None]:
    if not value:
        return {"city": None, "country": None, "region": None}
    parts = [part.strip() for part in value.split(",") if part.strip()]
    if len(parts) == 1:
        return {"city": None, "country": parts[0], "region": None}
    if len(parts) == 2:
        return {"city": parts[0], "country": parts[1], "region": None}
    return {"city": parts[0], "country": parts[-1], "region": ", ".join(parts[1:-1])}


def _extract_year(value: Any) -> int | None:
    match = re.search(r"\b(20\d{2})\b", str(value or ""))
    return int(match.group(1)) if match else None


def _clean_text(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return " ".join(value.split()).strip()


def _humanize(value: str | None) -> str:
    return " ".join(part.capitalize() for part in re.split(r"[_\-\s]+", value or "") if part)


def _absolute_http_url(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    parsed = urlparse(value.strip())
    return value.strip() if parsed.scheme in {"http", "https"} and parsed.netloc else None


def _is_aws_controlled(url: str) -> bool:
    host = urlparse(url).netloc.lower()
    return host == "aws.amazon.com" or host.endswith(".aws.amazon.com") or host.endswith(".awsstatic.com") or host.endswith(".aws.com") or host.endswith(".aws.dev")


def _source_type(url: str) -> str:
    return (
        "aws_builder_center"
        if urlparse(url).netloc.lower() in {AWS_BUILDER_HOST, "api.builder.aws.com"}
        else "aws_public_page"
    )


def main() -> int:
    """Parse a local file for debugging without performing network requests."""

    import argparse
    from pathlib import Path

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("--source-url", required=True)
    parser.add_argument(
        "--retrieved-at",
        default=datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    )
    args = parser.parse_args()
    people = parse_document(args.input.read_bytes(), source_url=args.source_url, retrieved_at=args.retrieved_at)
    print(json.dumps(people, indent=2, ensure_ascii=False, sort_keys=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
