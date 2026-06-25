#!/usr/bin/env python3
"""Build the compact, deterministic community people index consumed by clients."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any

from validate_people_data import (
    DEFAULT_PEOPLE_DIR,
    REPO_ROOT,
    validate_directory,
    validate_json_document,
)


DEFAULT_OUTPUT = REPO_ROOT / "data/community/indexes/people.index.json"
INDEX_SCHEMA = REPO_ROOT / "data/community/schemas/people-index.schema.json"


def build_index(people: list[dict[str, Any]], *, include_drafts: bool = False, generated_at: str | None = None) -> dict[str, Any]:
    """Create the compact index with stable order and timestamp semantics."""

    included = [person for person in people if person["profileStatus"] == "published" or include_drafts]
    included.sort(key=lambda person: (person["displayName"].casefold(), person["slug"]))
    if generated_at is None:
        # Source-derived timestamps make repeated builds byte-for-byte stable.
        generated_at = max((person["lastHarvestedAt"] for person in people), default="1970-01-01T00:00:00Z")
    compact = []
    for person in included:
        primary_program = person["programs"][0]["name"] if person["programs"] else None
        compact.append(
            {
                "id": person["id"],
                "slug": person["slug"],
                "displayName": person["displayName"],
                "headline": person["headline"],
                "country": person["location"]["country"],
                "avatarUrl": person["avatar"]["url"],
                "primaryProgram": primary_program,
                "topics": person["topics"],
                "profileStatus": person["profileStatus"],
            }
        )
    return {"generatedAt": generated_at, "count": len(compact), "people": compact}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--people-dir", type=Path, default=DEFAULT_PEOPLE_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--include-drafts", action="store_true")
    parser.add_argument("--generated-at", help="Override generatedAt (otherwise latest source timestamp)")
    args = parser.parse_args()

    people, errors = validate_directory(args.people_dir)
    if errors:
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        print("Index not written because person validation failed.", file=sys.stderr)
        return 1

    index = build_index(people, include_drafts=args.include_drafts, generated_at=args.generated_at)
    index_errors = validate_json_document(index, INDEX_SCHEMA, label="generated people index")
    if index_errors:
        for error in index_errors:
            print(f"- {error}", file=sys.stderr)
        print("Index not written because generated output validation failed.", file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(index, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {index['count']} person(s) to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
