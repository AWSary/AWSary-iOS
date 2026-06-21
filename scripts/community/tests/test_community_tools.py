"""Focused tests for extraction, normalization, and compact index behavior."""

from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace
import sys
import unittest


SCRIPT_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPT_DIR))

from build_people_index import build_index  # noqa: E402
from build_builder_center_index import build_heroes_alias_index  # noqa: E402
from build_ios_community_resource import build_ios_resource  # noqa: E402
from harvest_builder_center import _builder_alias_from_url, read_builder_index  # noqa: E402
from parse_builder_center import parse_document  # noqa: E402
from utils.json_extractors import (  # noqa: E402
    discover_public_javascript_links,
    discover_public_json_links,
    extract_json_from_html,
)


class JsonExtractorTests(unittest.TestCase):
    def test_extracts_supported_script_shapes_without_executing_javascript(self) -> None:
        html = """
        <script type="application/ld+json">{"@type":"Person","name":"Ada Example"}</script>
        <script id="__NEXT_DATA__" type="application/json">{"props":{"name":"Next"}}</script>
        <script>window.publicProfile = {"name":"Assigned"};</script>
        """
        candidates = extract_json_from_html(html)
        self.assertEqual([item.kind for item in candidates], ["application/ld+json", "next_data", "javascript_assignment"])

    def test_extracts_json_serialized_inside_runtime_javascript(self) -> None:
        html = """<script>window.env = { VITE_DEPLOYMENT_CONFIG: '{"stage":"prod","heroesToFollow":[{"alias":"ada"}]}' };</script>"""
        candidates = extract_json_from_html(html)
        serialized = [item.data for item in candidates if item.kind == "serialized_json_string"]
        self.assertEqual(serialized[0]["heroesToFollow"][0]["alias"], "ada")

    def test_discovers_only_explicit_json_links(self) -> None:
        html = '<script src="/assets/profile.json"></script><script src="/assets/app.js"></script>'
        self.assertEqual(
            discover_public_json_links(html, "https://builder.aws.com/community/person"),
            ["https://builder.aws.com/assets/profile.json"],
        )

    def test_discovers_linked_frontend_javascript(self) -> None:
        html = '<script type="module" src="/assets/index-abc.js"></script>'
        self.assertEqual(
            discover_public_javascript_links(html, "https://builder.aws.com/community/@ada"),
            ["https://builder.aws.com/assets/index-abc.js"],
        )


class ParserTests(unittest.TestCase):
    def test_normalizes_public_directory_item(self) -> None:
        payload = {
            "items": [
                {
                    "item": {
                        "id": "community-heroes#ada-example",
                        "additionalFields": {
                            "heroName": "Ada Example",
                            "heroCategory": "AWS Serverless Hero",
                            "heroSinceDate": "Hero since 2024",
                            "heroLocation": "Lisbon, Portugal",
                            "heroBioURL": "https://aws.amazon.com/developer/community/heroes/ada-example/",
                            "heroImageURL": "https://d1.awsstatic.com/ada.png",
                            "links": [{"text": "GitHub", "url": "https://github.com/ada"}],
                        },
                    }
                }
            ]
        }
        people = parse_document(
            json.dumps(payload),
            source_url="https://aws.amazon.com/api/dirs/items/search?item.directoryId=community-heroes",
            retrieved_at="2026-06-21T10:00:00Z",
            content_type="application/json",
        )
        self.assertEqual(len(people), 1)
        person = people[0]
        self.assertEqual(person["slug"], "ada-example")
        self.assertEqual(person["location"]["country"], "Portugal")
        self.assertEqual(person["programs"][0]["startYear"], 2024)
        self.assertEqual(person["profileStatus"], "draft")
        self.assertFalse(next(link for link in person["links"] if link["type"] == "github")["verified"])
        self.assertIn("/api/dirs/items/search", person["sourceEvidence"][0]["sourceUrl"])

    def test_parses_ld_json_person_from_html(self) -> None:
        html = '<script type="application/ld+json">{"@type":"Person","name":"Ada Example","url":"https://builder.aws.com/community/@ada"}</script>'
        people = parse_document(
            html,
            source_url="https://builder.aws.com/community/@ada",
            retrieved_at="2026-06-21T10:00:00Z",
            content_type="text/html",
        )
        self.assertEqual(people[0]["displayName"], "Ada Example")
        self.assertEqual(people[0]["sourceEvidence"][0]["sourceType"], "aws_builder_center")

    def test_normalizes_builder_profile_api_response(self) -> None:
        payload = {
            "profile": {
                "basicInfo": {
                    "name": "Ada Example",
                    "alias": "ada",
                    "headline": "Cloud Builder",
                    "bio": "Public biography",
                },
                "location": {"displayLocation": "Lisbon, Portugal"},
                "interests": ["Serverless"],
                "awsPrograms": [
                    {
                        "programName": "COMMUNITY_BUILDER",
                        "memberStatus": "ACTIVE",
                        "category": "SERVERLESS",
                        "joinedAt": "2024-01-01",
                    }
                ],
                "socials": {"github": "https://github.com/ada"},
            }
        }
        people = parse_document(
            json.dumps(payload),
            source_url="https://api.builder.aws.com/ums/getProfileByAlias",
            retrieved_at="2026-06-21T10:00:00Z",
            content_type="application/json",
        )
        self.assertEqual(people[0]["programs"][0]["name"], "AWS Community Builder")
        self.assertEqual(people[0]["sourceEvidence"][0]["sourceType"], "aws_builder_center")
        self.assertEqual(people[0]["links"][0]["url"], "https://builder.aws.com/community/@ada")

    def test_normalizes_real_builder_location_and_all_programs(self) -> None:
        payload = {
            "profile": {
                "basicInfo": {"name": "Ada Example", "alias": "ada"},
                "location": {"displayLocation": {"countryRegion": "PT", "stateProvince": "Lisbon"}},
                "awsPrograms": [
                    {"programName": "HERO", "category": "Community Hero", "memberStatus": "ACTIVE", "joinedAt": 2024.0},
                    {"programName": "USER_GROUP_LEADER", "joinedAt": 2021.0},
                ],
            }
        }
        person = parse_document(
            json.dumps(payload),
            source_url="https://api.builder.aws.com/ums/getProfileByAlias",
            retrieved_at="2026-06-21T10:00:00Z",
            content_type="application/json",
        )[0]
        self.assertEqual(person["location"], {"city": None, "country": "PT", "region": "Lisbon"})
        self.assertEqual([program["name"] for program in person["programs"]], ["AWS Hero", "AWS User Group Leader"])

    def test_reads_aliases_from_builder_index(self) -> None:
        from tempfile import TemporaryDirectory

        with TemporaryDirectory() as directory:
            path = Path(directory) / "heroes.json"
            path.write_text(json.dumps({"people": [{"alias": "ada"}, {"alias": "grace"}, {"alias": "ada"}]}))
            self.assertEqual(read_builder_index(path), ["ada", "grace"])

    def test_extracts_alias_from_public_profile_url(self) -> None:
        self.assertEqual(_builder_alias_from_url("https://builder.aws.com/community/@ada"), "ada")
        self.assertIsNone(_builder_alias_from_url("https://builder.aws.com/community/heroes/AdaExample"))


class IndexTests(unittest.TestCase):
    def test_builds_ios_resource_with_builder_precedence_and_legacy_fallback(self) -> None:
        builder_index = {
            "people": [{"alias": "ada", "displayName": "Ada Example"}],
            "omittedWithoutAlias": ["No Alias"],
        }
        canonical = [
            {
                "id": "person_ada_example",
                "displayName": "Ada Example",
                "summary": "Builder bio",
                "location": {"city": None, "country": "PT", "region": None},
                "avatar": {"url": "https://avatars.builderprofile.aws.dev/ada.webp"},
                "programs": [{"name": "AWS Hero", "category": "Community Hero"}],
                "topics": ["Serverless"],
                "links": [
                    {"type": "builder_center", "label": "AWS Builder Center", "url": "https://builder.aws.com/community/@ada"},
                    {"type": "github", "label": "Github", "url": "https://github.com/new-ada"},
                ],
                "profileStatus": "draft",
            }
        ]
        legacy = [
            {
                "id": "legacy_ada",
                "name": "Ada Example",
                "description": "Legacy bio",
                "heroLocation": "Lisbon, Portugal",
                "heroCategory": "AWS Community Hero",
                "hero_links": [
                    {"text": "GitHub", "url": "https://github.com/old-ada"},
                    {"text": "Meetup", "url": "https://meetup.com/ada"},
                ],
            },
            {
                "id": "legacy_no_alias",
                "name": "No Alias",
                "description": "Legacy-only bio",
                "heroLocation": "London, United Kingdom",
                "heroCategory": "AWS Serverless Hero",
                "heroBioURL": "https://aws.amazon.com/no-alias",
                "heroImageURL": "https://aws.amazon.com/no-alias.png",
                "hero_links": [],
            },
        ]

        members = build_ios_resource(builder_index, canonical, legacy, include_drafts=True)
        ada = next(member for member in members if member["name"] == "Ada Example")
        self.assertEqual(ada["bio"], "Builder bio")
        self.assertEqual(ada["location"], "Lisbon, Portugal")
        self.assertEqual(ada["profileURL"], "https://builder.aws.com/community/@ada")
        self.assertEqual(ada["specialties"], ["Community", "Serverless"])
        self.assertEqual(
            [link["url"] for link in ada["links"]],
            ["https://github.com/new-ada", "https://meetup.com/ada"],
        )
        self.assertEqual(next(member for member in members if member["name"] == "No Alias")["bio"], "Legacy-only bio")

    def test_builds_builder_alias_index_and_omits_unfetchable_profiles(self) -> None:
        class FakeCache:
            def fetch(self, url: str, **_: object) -> SimpleNamespace:
                if url.endswith("/camp/groups"):
                    payload = {"groupOverviewList": [{"groupId": "heroes-1", "groupType": "HERO"}]}
                else:
                    payload = {
                        "userProfiles": [
                            {"basicInfo": {"alias": "grace", "builderProfileId": "2", "name": "Grace"}},
                            {"basicInfo": {"builderProfileId": "3", "name": "No Alias"}},
                            {"basicInfo": {"alias": "ada", "builderProfileId": "1", "name": "Ada"}},
                        ]
                    }
                return SimpleNamespace(
                    body=json.dumps(payload).encode(),
                    retrieved_at="2026-06-21T10:00:00Z",
                )

        index = build_heroes_alias_index(FakeCache(), page_size=500)  # type: ignore[arg-type]
        self.assertEqual([person["alias"] for person in index["people"]], ["ada", "grace"])
        self.assertEqual(index["omittedWithoutAlias"], ["No Alias"])
        self.assertEqual(index["groupId"], "heroes-1")

    def test_excludes_drafts_and_sorts_names(self) -> None:
        base = {
            "id": "person_zed",
            "slug": "zed",
            "displayName": "Zed",
            "headline": None,
            "location": {"country": None},
            "avatar": {"url": None},
            "programs": [],
            "topics": [],
            "profileStatus": "draft",
            "lastHarvestedAt": "2026-06-21T10:00:00Z",
        }
        published = dict(base, id="person_ada", slug="ada", displayName="Ada", profileStatus="published")
        index = build_index([base, published])
        self.assertEqual(index["count"], 1)
        self.assertEqual(index["people"][0]["displayName"], "Ada")
        self.assertEqual(index["generatedAt"], "2026-06-21T10:00:00Z")


if __name__ == "__main__":
    unittest.main()
