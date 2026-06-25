#!/usr/bin/env python3
"""Merge canonical community data into the bundled iOS CommunityMember resource."""

from __future__ import annotations

import argparse
from difflib import SequenceMatcher
import json
from pathlib import Path
import re
from typing import Any, Iterable
from urllib.parse import urlparse

from utils.slugify import person_id, slugify


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BUILDER_INDEX = REPO_ROOT / "data/community/indexes/builder-center-heroes.index.json"
DEFAULT_PEOPLE_DIR = REPO_ROOT / "data/community/people"
DEFAULT_LEGACY_HEROES = REPO_ROOT / "utils/heroes_to_json/aws_heroes.json"
DEFAULT_OUTPUT = REPO_ROOT / "ios/AWSary/resources/community_members.json"


def load_people(people_dir: Path) -> list[dict[str, Any]]:
    return [json.loads(path.read_text(encoding="utf-8")) for path in sorted(people_dir.glob("*.json"))]


def build_ios_resource(
    builder_index: dict[str, Any],
    canonical_people: Iterable[dict[str, Any]],
    legacy_heroes: Iterable[dict[str, Any]],
    *,
    include_drafts: bool = False,
) -> list[dict[str, Any]]:
    """Build one app record per member of the authoritative Builder Center Hero group."""

    canonical = list(canonical_people)
    legacy = list(legacy_heroes)
    canonical_by_alias = {
        alias: person
        for person in canonical
        if (alias := _builder_alias(person)) is not None
    }
    canonical_by_name = _by_identity_name(canonical, key="displayName")
    legacy_by_name = _by_identity_name(legacy, key="name")

    roster = [
        member
        for member in builder_index.get("people", [])
        if isinstance(member, dict) and isinstance(member.get("alias"), str)
    ]
    roster.extend(
        {"alias": None, "displayName": name}
        for name in builder_index.get("omittedWithoutAlias", [])
        if isinstance(name, str)
    )

    result = []
    missing = []
    for member in roster:
        alias = member.get("alias")
        display_name = str(member.get("displayName") or "")
        person = canonical_by_alias.get(alias) if alias else None
        person = person or _lookup_by_name(canonical_by_name, display_name)
        legacy_person = _legacy_for_member(legacy, legacy_by_name, display_name, alias)
        if person is None and legacy_person is None:
            missing.append(display_name or str(alias))
            continue
        if not include_drafts and person and person.get("profileStatus") != "published":
            continue
        result.append(_app_member(person, legacy_person, authoritative_name=display_name))

    if missing:
        raise ValueError(f"No canonical or legacy record for Builder Center members: {', '.join(missing)}")

    ids = [member["id"] for member in result]
    if len(ids) != len(set(ids)):
        duplicates = sorted({identifier for identifier in ids if ids.count(identifier) > 1})
        raise ValueError(f"Duplicate iOS community IDs: {', '.join(duplicates)}")
    return sorted(result, key=lambda member: member["name"].casefold())


def _app_member(
    person: dict[str, Any] | None,
    legacy: dict[str, Any] | None,
    *,
    authoritative_name: str,
) -> dict[str, Any]:
    person = person or {}
    legacy = legacy or {}
    name = str(person.get("displayName") or authoritative_name or legacy.get("name") or "").strip()
    if not name:
        raise ValueError("Community member has no display name")

    programs = [program for program in person.get("programs", []) if isinstance(program, dict)]
    statuses = _unique(
        str(program.get("name"))
        for program in programs
        if program.get("name")
    ) or ["AWS Hero"]
    specialties = _unique(
        [
            *(_specialty(program.get("category")) for program in programs),
            *(_specialty(topic) for topic in person.get("topics", []) if topic),
            _specialty(legacy.get("heroCategory")),
        ]
    )

    avatar = person.get("avatar") if isinstance(person.get("avatar"), dict) else {}
    profile_url = _profile_url(person) or str(legacy.get("heroBioURL") or "")
    return {
        "id": str(person.get("id") or legacy.get("id") or person_id(slugify(name))),
        "name": name,
        "bio": _summary(person.get("summary"), legacy.get("description")),
        "location": _display_location(person.get("location"), legacy.get("heroLocation")),
        "imageURL": str(avatar.get("url") or legacy.get("heroImageURL") or ""),
        "profileURL": profile_url,
        "statuses": statuses,
        "specialties": specialties,
        "links": _merged_links(person.get("links"), legacy.get("hero_links"), profile_url),
    }


def _builder_alias(person: dict[str, Any]) -> str | None:
    for link in person.get("links", []):
        if not isinstance(link, dict):
            continue
        match = re.fullmatch(r"https://builder\.aws\.com/community/@([a-z0-9]+)", str(link.get("url", "")))
        if match:
            return match.group(1)
    return None


def _by_identity_name(records: Iterable[dict[str, Any]], *, key: str) -> dict[str, dict[str, Any]]:
    result = {}
    for record in records:
        name = record.get(key)
        if isinstance(name, str) and name:
            for candidate in _identity_keys(name):
                result.setdefault(candidate, record)
    return result


def _lookup_by_name(records: dict[str, dict[str, Any]], name: str) -> dict[str, Any] | None:
    return next((records[key] for key in _identity_keys(name) if key in records), None)


def _legacy_for_member(
    legacy: list[dict[str, Any]],
    legacy_by_name: dict[str, dict[str, Any]],
    display_name: str,
    alias: Any,
) -> dict[str, Any] | None:
    exact = _lookup_by_name(legacy_by_name, display_name)
    if exact:
        return exact

    needles = [_compact_identity(display_name)]
    if isinstance(alias, str):
        needles.append(_compact_identity(alias))
    compact_records = [
        (
            record,
            {
                _compact_identity(str(record.get("name") or "")),
                _compact_identity(str(record.get("id") or "").split("#")[-1]),
            },
        )
        for record in legacy
    ]
    contained = [
        record
        for record, candidates in compact_records
        if any(
            (len(needle) >= 5 and any(needle in candidate or candidate in needle for candidate in candidates))
            or (len(needle) >= 3 and any(candidate.startswith(needle) for candidate in candidates))
            for needle in needles
        )
    ]
    if len(contained) == 1:
        return contained[0]

    scored = []
    for record, candidates in compact_records:
        score = max(
            SequenceMatcher(None, needle, candidate).ratio()
            for needle in needles
            for candidate in candidates
            if needle and candidate
        )
        scored.append((score, record))
    scored.sort(key=lambda item: item[0], reverse=True)
    if not scored or scored[0][0] < 0.72:
        return None
    if len(scored) > 1 and scored[0][0] - scored[1][0] < 0.08:
        return None
    return scored[0][1]


def _identity_keys(name: str) -> list[str]:
    cleaned = re.sub(r"\s*\[AWS Hero\]\s*", " ", name, flags=re.IGNORECASE)
    cleaned = re.sub(r"\s*\((?:he/him|she/her|wolkencode)\)\s*", " ", cleaned, flags=re.IGNORECASE)
    return _unique([slugify(name), slugify(cleaned)])


def _compact_identity(value: str) -> str:
    return slugify(value).replace("-", "")


def _summary(builder_summary: Any, legacy_summary: Any) -> str:
    builder = str(builder_summary or "").strip()
    legacy = str(legacy_summary or "").strip()
    if "<" in builder or "learn more" in builder.casefold():
        return legacy
    return builder or legacy


def _display_location(value: Any, legacy_location: Any) -> str:
    location = value if isinstance(value, dict) else {}
    city = str(location.get("city") or "").strip()
    region = str(location.get("region") or "").strip()
    country = str(location.get("country") or "").strip()
    legacy = str(legacy_location or "").strip()

    # Builder Center commonly supplies only an ISO country code. The legacy
    # AWS profile provides the display-ready city/country string in that case.
    if legacy and not city and not region and len(country) == 2:
        return legacy
    if legacy and len(country) == 2:
        legacy_country = legacy.rsplit(",", 1)[-1].strip()
        country = legacy_country or country
    return ", ".join(_unique([city, region, country])) or legacy


def _profile_url(person: dict[str, Any]) -> str:
    links = [link for link in person.get("links", []) if isinstance(link, dict)]
    preferred = next((link for link in links if link.get("type") == "builder_center"), None)
    preferred = preferred or next(
        (link for link in links if "aws" in urlparse(str(link.get("url", ""))).netloc),
        None,
    )
    return str(preferred.get("url") or "") if preferred else ""


def _merged_links(canonical_links: Any, legacy_links: Any, profile_url: str) -> list[dict[str, str]]:
    result = []
    represented_types = set()
    seen_urls = {profile_url} if profile_url else set()

    for link in canonical_links if isinstance(canonical_links, list) else []:
        if not isinstance(link, dict):
            continue
        url = str(link.get("url") or "")
        link_type = str(link.get("type") or _link_type(link.get("label"), url))
        if not url or url in seen_urls or link_type == "builder_center":
            continue
        result.append({"label": str(link.get("label") or "Website"), "url": url})
        represented_types.add(link_type)
        seen_urls.add(url)

    for link in legacy_links if isinstance(legacy_links, list) else []:
        if not isinstance(link, dict):
            continue
        url = str(link.get("url") or "")
        label = str(link.get("text") or link.get("label") or "Website")
        link_type = _link_type(label, url)
        if not url or url in seen_urls or link_type in represented_types:
            continue
        result.append({"label": label, "url": url})
        represented_types.add(link_type)
        seen_urls.add(url)
    return result


def _link_type(label: Any, url: str) -> str:
    text = f"{label or ''} {urlparse(url).netloc}".lower()
    for link_type, marker in (
        ("linkedin", "linkedin"),
        ("x", "twitter"),
        ("x", "x.com"),
        ("github", "github"),
        ("youtube", "youtube"),
        ("twitch", "twitch"),
        ("newsletter", "newsletter"),
        ("blog", "blog"),
        ("meetup", "meetup"),
    ):
        if marker in text:
            return link_type
    return "website"


def _specialty(value: Any) -> str:
    text = str(value or "").strip()
    text = re.sub(r"^AWS\s+", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s+Hero$", "", text, flags=re.IGNORECASE)
    return text.strip()


def _unique(values: Iterable[str]) -> list[str]:
    result = []
    seen = set()
    for value in values:
        cleaned = str(value or "").strip()
        key = cleaned.casefold()
        if cleaned and key not in seen:
            seen.add(key)
            result.append(cleaned)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--builder-index", type=Path, default=DEFAULT_BUILDER_INDEX)
    parser.add_argument("--people-dir", type=Path, default=DEFAULT_PEOPLE_DIR)
    parser.add_argument("--legacy-heroes", type=Path, default=DEFAULT_LEGACY_HEROES)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--include-drafts", action="store_true")
    args = parser.parse_args()

    members = build_ios_resource(
        json.loads(args.builder_index.read_text(encoding="utf-8")),
        load_people(args.people_dir),
        json.loads(args.legacy_heroes.read_text(encoding="utf-8")),
        include_drafts=args.include_drafts,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(members, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"iOS community resource: {len(members)} member(s) written to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
