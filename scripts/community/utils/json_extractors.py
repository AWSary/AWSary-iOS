"""Defensive extraction of JSON embedded in public HTML and JavaScript."""

from __future__ import annotations

from dataclasses import dataclass
from html.parser import HTMLParser
import json
import re
from typing import Any
from urllib.parse import urljoin, urlparse


JSON_SCRIPT_TYPES = {"application/json", "application/ld+json"}


@dataclass(frozen=True)
class JsonCandidate:
    """A decoded JSON value and a short explanation of its origin."""

    kind: str
    data: Any


class _ScriptCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.scripts: list[tuple[dict[str, str], str]] = []
        self.json_links: list[str] = []
        self.javascript_links: list[str] = []
        self._attrs: dict[str, str] | None = None
        self._parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = {key.lower(): value or "" for key, value in attrs}
        if tag.lower() == "script":
            self._attrs = attributes
            self._parts = []
            source = attributes.get("src")
            if source and _looks_like_json_url(source):
                self.json_links.append(source)
            elif source and _looks_like_javascript_url(source):
                self.javascript_links.append(source)
        elif tag.lower() == "link":
            target = attributes.get("href")
            if target and _looks_like_json_url(target):
                self.json_links.append(target)

    def handle_data(self, data: str) -> None:
        if self._attrs is not None:
            self._parts.append(data)

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() == "script" and self._attrs is not None:
            self.scripts.append((self._attrs, "".join(self._parts)))
            self._attrs = None
            self._parts = []


def extract_json_from_html(html: str) -> list[JsonCandidate]:
    """Extract JSON scripts, Next.js data, and JSON-valued JS assignments."""

    collector = _ScriptCollector()
    collector.feed(html)
    candidates: list[JsonCandidate] = []

    for attrs, body in collector.scripts:
        script_type = attrs.get("type", "").lower()
        script_id = attrs.get("id", "")
        if script_type in JSON_SCRIPT_TYPES or script_id == "__NEXT_DATA__":
            decoded = _decode_json(body)
            if decoded is not None:
                kind = "next_data" if script_id == "__NEXT_DATA__" else script_type
                candidates.append(JsonCandidate(kind, decoded))
            continue

        candidates.extend(extract_json_from_javascript(body))

    return candidates


def discover_public_json_links(html: str, page_url: str) -> list[str]:
    """Return explicit HTTP(S) JSON resources referenced by an HTML page."""

    collector = _ScriptCollector()
    collector.feed(html)
    links = {urljoin(page_url, item) for item in collector.json_links}

    # Some applications place JSON asset URLs in inline configuration strings.
    for match in re.finditer(r"[\"']([^\"']+\.json(?:\?[^\"']*)?)[\"']", html, re.I):
        links.add(urljoin(page_url, match.group(1)))

    return sorted(link for link in links if urlparse(link).scheme in {"http", "https"})


def discover_public_javascript_links(html: str, page_url: str) -> list[str]:
    """Return explicit HTTP(S) JavaScript resources referenced by script tags."""

    collector = _ScriptCollector()
    collector.feed(html)
    return sorted(
        {
            urljoin(page_url, item)
            for item in collector.javascript_links
            if urlparse(urljoin(page_url, item)).scheme in {"http", "https"}
        }
    )


def extract_json_from_javascript(script: str) -> list[JsonCandidate]:
    """Extract direct assignments and serialized JSON without executing code."""

    return _extract_javascript_assignments(script) + _extract_serialized_json_strings(script)


def _looks_like_json_url(value: str) -> bool:
    return bool(re.search(r"\.json(?:$|[?#])", value, re.I))


def _looks_like_javascript_url(value: str) -> bool:
    return bool(re.search(r"\.m?js(?:$|[?#])", value, re.I))


def _decode_json(value: str) -> Any | None:
    try:
        return json.loads(value.strip())
    except (json.JSONDecodeError, TypeError):
        return None


def _extract_javascript_assignments(script: str) -> list[JsonCandidate]:
    """Decode object/array literals assigned directly to JS variables.

    This intentionally does not execute JavaScript. JSONDecoder.raw_decode stops at
    the end of the first value and safely ignores trailing semicolons.
    """

    results: list[JsonCandidate] = []
    decoder = json.JSONDecoder()
    assignment = re.compile(
        r"(?:window\.)?[A-Za-z_$][\w$]*(?:\.[A-Za-z_$][\w$]*)*\s*=\s*(?=[{\[])",
        re.MULTILINE,
    )
    for match in assignment.finditer(script):
        try:
            value, _ = decoder.raw_decode(script[match.end() :])
        except json.JSONDecodeError:
            continue
        results.append(JsonCandidate("javascript_assignment", value))
    return results


def _extract_serialized_json_strings(script: str) -> list[JsonCandidate]:
    """Decode JSON objects/arrays stored inside JavaScript string literals.

    Builder Center's runtime configuration uses this shape for
    `VITE_DEPLOYMENT_CONFIG`. Supporting strict JSON strings is safer than
    attempting to evaluate arbitrary JavaScript object literals.
    """

    results: list[JsonCandidate] = []
    seen: set[str] = set()

    # Single-quoted JavaScript strings can contain ordinary double-quoted JSON.
    for match in re.finditer(r"'(?P<value>[{\[][^'\n]{2,500000}[}\]])'", script):
        raw = match.group("value")
        decoded = _decode_json(raw)
        if decoded is not None and raw not in seen:
            seen.add(raw)
            results.append(JsonCandidate("serialized_json_string", decoded))

    # Double-quoted JavaScript strings typically contain escaped JSON. Let the
    # JSON decoder unescape the string before decoding its inner value.
    for match in re.finditer(r'"(?P<value>[{\[](?:\\.|[^"\n]){2,500000}[}\]])"', script):
        literal = match.group(0)
        try:
            raw = json.loads(literal)
        except json.JSONDecodeError:
            continue
        decoded = _decode_json(raw)
        if decoded is not None and raw not in seen:
            seen.add(raw)
            results.append(JsonCandidate("serialized_json_string", decoded))
    return results
