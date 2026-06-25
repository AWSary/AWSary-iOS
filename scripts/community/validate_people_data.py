#!/usr/bin/env python3
"""Validate all AWSary community person files and detect cross-file conflicts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PEOPLE_DIR = REPO_ROOT / "data/community/people"
DEFAULT_SCHEMA = REPO_ROOT / "data/community/schemas/person.schema.json"


def load_people(people_dir: Path = DEFAULT_PEOPLE_DIR) -> tuple[list[tuple[Path, dict[str, Any]]], list[str]]:
    """Load person JSON objects and return them alongside structural errors."""

    people: list[tuple[Path, dict[str, Any]]] = []
    errors: list[str] = []
    for path in sorted(people_dir.glob("*.json")):
        try:
            value = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path}: invalid JSON: {exc}")
            continue
        if not isinstance(value, dict):
            errors.append(f"{path}: root must be a JSON object")
            continue
        people.append((path, value))
    if not people and not errors:
        errors.append(f"{people_dir}: no person JSON files found")
    return people, errors


def validate_people(
    people: list[tuple[Path, dict[str, Any]]], schema_path: Path = DEFAULT_SCHEMA
) -> list[str]:
    """Validate schemas, filenames, IDs, slugs, and duplicate records."""

    errors: list[str] = []
    ids: dict[str, Path] = {}
    slugs: dict[str, Path] = {}
    for path, person in people:
        errors.extend(validate_json_document(person, schema_path, label=str(path)))

        slug = person.get("slug")
        person_id = person.get("id")
        if isinstance(slug, str) and path.stem != slug:
            errors.append(f"{path}: filename must be {slug}.json")
        if isinstance(person_id, str):
            if person_id in ids:
                errors.append(f"{path}: duplicate id {person_id!r}; first seen in {ids[person_id]}")
            ids[person_id] = path
        if isinstance(slug, str):
            if slug in slugs:
                errors.append(f"{path}: duplicate slug {slug!r}; first seen in {slugs[slug]}")
            slugs[slug] = path
    return errors


def validate_json_document(value: Any, schema_path: Path, *, label: str) -> list[str]:
    """Validate one JSON value against a Draft 2020-12 schema."""

    try:
        from jsonschema import Draft202012Validator, FormatChecker
    except ImportError as exc:
        raise RuntimeError(
            "jsonschema is required; run: python -m pip install -r scripts/community/requirements.txt"
        ) from exc

    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors: list[str] = []
    for error in sorted(validator.iter_errors(value), key=lambda item: list(item.absolute_path)):
        location = ".".join(str(part) for part in error.absolute_path) or "<root>"
        errors.append(f"{label}: {location}: {error.message}")
    return errors


def validate_directory(people_dir: Path = DEFAULT_PEOPLE_DIR) -> tuple[list[dict[str, Any]], list[str]]:
    """Load and validate a directory, returning plain person objects."""

    loaded, errors = load_people(people_dir)
    if not errors:
        errors.extend(validate_people(loaded))
    return [person for _, person in loaded], errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--people-dir", type=Path, default=DEFAULT_PEOPLE_DIR)
    args = parser.parse_args()
    people, errors = validate_directory(args.people_dir)
    if errors:
        print(f"Validation failed: {len(errors)} error(s) across {len(people)} loaded file(s).", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Validated {len(people)} person file(s): no errors.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
