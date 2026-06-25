"""Small, dependency-free slug helpers."""

from __future__ import annotations

import re
import unicodedata


def slugify(value: str) -> str:
    """Return a stable lowercase ASCII slug."""

    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"[^a-z0-9]+", "-", ascii_value.lower()).strip("-")


def person_id(value: str) -> str:
    """Build a schema-compatible person identifier from a name or slug."""

    return f"person_{slugify(value).replace('-', '_')}"
