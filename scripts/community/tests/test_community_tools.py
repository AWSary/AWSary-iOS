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
from build_builder_user_groups_index import (  # noqa: E402
    build_user_groups_index,
    discover_module_asset_urls,
    extract_user_groups_from_javascript,
)
from build_ios_community_resource import build_ios_resource  # noqa: E402
from build_ios_user_groups_resource import build_ios_user_groups_resource  # noqa: E402
from harvest_builder_center import _builder_alias_from_url, read_builder_index  # noqa: E402
from harvest_meetup_user_groups import (  # noqa: E402
    _normalize_public_url,
    build_meetup_index,
    parse_meetup_group_html,
)
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
    def test_parses_public_meetup_group_metadata_without_member_profiles(self) -> None:
        group = {
            "__typename": "Group",
            "id": "123",
            "name": "AWS User Group Lisbon",
            "urlname": "aws-user-group-lisbon",
            "description": "Public description",
            "timezone": "Europe/Lisbon",
            "city": "Lisbon",
            "state": "",
            "country": "pt",
            "lat": 38.72,
            "lon": -9.14,
            "isPrivate": False,
            "joinMode": "OPEN",
            "status": "PAID",
            "foundedDate": "2016-05-16T16:52:52+01:00",
            "keyGroupPhoto": {"__ref": "PhotoInfo:1"},
            "proNetwork": {"__ref": "ProNetwork:1"},
            "activeTopics": [{"__ref": "Topic:1"}],
            "socialNetworks": [{"service": "LINKEDIN", "url": "https://linkedin.com/company/awsuglisbon"}],
            "stats": {
                "memberCounts": {"all": 2000, "leadership": 8},
                "eventRatings": {"average": 4.8, "total": 369},
            },
            'events({"filter":{"status":["ACTIVE"]}})': {"totalCount": 2},
            'events({"filter":{"status":["PAST"]}})': {"totalCount": 54},
        }
        state = {
            "Group:123": group,
            "PhotoInfo:1": {"highResUrl": "https://secure.meetupstatic.com/group.jpeg"},
            "Topic:1": {"name": "Cloud Computing"},
            "ProNetwork:1": {
                "id": "network-1",
                "name": "Global AWS User Group Community",
                "urlname": "global-aws-user-group-community",
                "groups": {"totalCount": 391},
            },
            "Member:private": {"name": "Not harvested"},
        }
        html = (
            '<script type="application/ld+json">'
            '{"@type":"Organization","name":"AWS User Group Lisbon","image":"https://meetupstatic.com/group.webp"}'
            "</script>"
            '<script id="__NEXT_DATA__" type="application/json">'
            + json.dumps({"props": {"pageProps": {"__APOLLO_STATE__": state}}})
            + "</script>"
        )
        record = parse_meetup_group_html(
            html,
            source_url="https://www.meetup.com/aws-user-group-lisbon/",
            retrieved_at="2026-06-22T10:00:00Z",
        )
        self.assertEqual(record["meetupId"], "123")
        self.assertEqual(record["topics"], ["Cloud Computing"])
        self.assertEqual(record["network"]["groupCount"], 391)
        self.assertEqual(record["activitySnapshot"]["pastEventCount"], 54)
        self.assertNotIn("members", record)
        self.assertNotIn("organizers", record)

    def test_falls_back_to_public_meetup_json_ld(self) -> None:
        html = '''<script type="application/ld+json">{
          "@type":"Organization",
          "@context":"https://schema.org",
          "url":"https://www.meetup.com/aws-user-group-lisbon/",
          "name":"AWS User Group Lisbon",
          "image":"https://meetupstatic.com/group.webp",
          "foundingDate":"2016-05-16T15:52:52.000Z",
          "address":{"location":{"address":{"addressLocality":"Lisbon","addressCountry":"pt"}}},
          "sameAs":["https://www.linkedin.com/company/aws-user-group-lisbon"]
        }</script>'''
        record = parse_meetup_group_html(
            html,
            source_url="https://www.meetup.com/aws-user-group-lisbon/",
            retrieved_at="2026-06-22T10:00:00Z",
        )
        self.assertIsNone(record["meetupId"])
        self.assertEqual(record["location"]["city"], "Lisbon")
        self.assertEqual(record["foundedAt"], "2016-05-16T15:52:52.000Z")
        self.assertIsNone(record["activitySnapshot"]["memberCount"])

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
    def test_builds_ios_user_groups_with_aws_identity_and_meetup_enrichment(self) -> None:
        aws_index = {
            "groups": [
                {
                    "id": "Space-UG_307",
                    "name": "AWS User Group Lisbon",
                    "location": "Lisbon",
                    "country": "Portugal",
                    "countryCode": "PT",
                    "url": "https://www.meetup.com/aws-user-group-lisbon/",
                },
                {
                    "id": "Space-UG_900",
                    "name": "AWS User Group Example",
                    "location": "Example City",
                    "country": "Portugal",
                    "countryCode": "PT",
                    "url": "https://example.com/aws-group",
                },
            ]
        }
        meetup_index = {
            "groups": [
                {
                    "awsUserGroupId": "Space-UG_307",
                    "description": "**AWS builders** in [Lisbon](https://example.com).",
                    "imageURL": "https://meetupstatic.com/lisbon.webp",
                    "foundedAt": "2016-05-16T16:52:52+01:00",
                    "location": {
                        "city": "Lisbon",
                        "region": None,
                        "latitude": 38.72,
                        "longitude": -9.14,
                        "timezone": "Europe/Lisbon",
                    },
                    "topics": ["Cloud Computing", "Amazon Web Services"],
                    "socialLinks": [
                        {"type": "linkedin", "url": "https://linkedin.com/company/aws-user-group-lisbon"}
                    ],
                    "network": {"name": "Global AWS User Group Community"},
                    "activitySnapshot": {"capturedAt": "2026-06-22T10:00:00Z", "memberCount": 2000},
                }
            ],
            "failures": [],
        }
        groups = build_ios_user_groups_resource(aws_index, meetup_index)
        lisbon = next(group for group in groups if group["id"] == "Space-UG_307")
        directory_only = next(group for group in groups if group["id"] == "Space-UG_900")
        self.assertEqual(lisbon["summary"], "AWS builders in Lisbon.")
        self.assertEqual(lisbon["location"]["country"], "Portugal")
        self.assertEqual(lisbon["metadataStatus"], "enriched")
        self.assertEqual(lisbon["activity"]["memberCount"], 2000)
        self.assertEqual([link["label"] for link in lisbon["links"]], ["Meetup", "LinkedIn"])
        self.assertEqual(directory_only["metadataStatus"], "directory_only")
        self.assertIsNone(directory_only["activity"])

    def test_builds_meetup_only_enrichment_index(self) -> None:
        state = {
            "Group:123": {
                "__typename": "Group",
                "id": "123",
                "name": "AWS User Group Lisbon",
                "stats": {"memberCounts": {}, "eventRatings": {}},
            }
        }
        html = '<script id="__NEXT_DATA__" type="application/json">' + json.dumps(
            {"props": {"pageProps": {"__APOLLO_STATE__": state}}}
        ) + "</script>"
        source = {
            "generatedAt": "2026-06-22T09:00:00Z",
            "groups": [
                {"id": "Space-UG_1", "url": "https://www.meetup.com/aws-user-group-lisbon/"},
                {"id": "Space-UG_2", "url": "https://example.com/not-meetup"},
            ],
        }

        class FakeCache:
            def fetch(self, url: str, **_: object) -> SimpleNamespace:
                return SimpleNamespace(body=html.encode(), retrieved_at="2026-06-22T10:00:00Z", url=url)

        index = build_meetup_index(source, FakeCache())  # type: ignore[arg-type]
        self.assertEqual(index["sourceGroupCount"], 2)
        self.assertEqual(index["meetupEligibleCount"], 1)
        self.assertEqual(index["failureCount"], 0)
        self.assertEqual(index["groups"][0]["awsUserGroupId"], "Space-UG_1")

    def test_encodes_unsafe_characters_in_official_meetup_urls(self) -> None:
        self.assertEqual(
            _normalize_public_url(
                "https://www.meetup.com/es/aws-Women's User Groups-colombia-user-group/"
            ),
            "https://www.meetup.com/es/aws-Women%27s%20User%20Groups-colombia-user-group/",
        )

    def test_records_an_unavailable_meetup_group_and_continues(self) -> None:
        source = {
            "generatedAt": "2026-06-22T09:00:00Z",
            "groups": [
                {"id": "Space-UG_535", "name": "Stale group", "url": "https://www.meetup.com/stale/"},
                {"id": "Space-UG_307", "name": "Lisbon", "url": "https://www.meetup.com/lisbon/"},
            ],
        }
        valid_state = {
            "Group:123": {
                "__typename": "Group",
                "id": "123",
                "name": "AWS User Group Lisbon",
                "stats": {"memberCounts": {}, "eventRatings": {}},
            }
        }
        valid_html = '<script id="__NEXT_DATA__" type="application/json">' + json.dumps(
            {"props": {"pageProps": {"__APOLLO_STATE__": valid_state}}}
        ) + "</script>"

        class FakeCache:
            def fetch(self, url: str, **_: object) -> SimpleNamespace:
                body = b"<title>Meetup | Group not found</title>" if "stale" in url else valid_html.encode()
                return SimpleNamespace(body=body, retrieved_at="2026-06-22T10:00:00Z", url=url)

        index = build_meetup_index(source, FakeCache())  # type: ignore[arg-type]
        self.assertEqual(index["count"], 1)
        self.assertEqual(index["failureCount"], 1)
        self.assertEqual(index["failures"][0]["reason"], "group_not_found")

    def test_classifies_a_localized_not_found_page(self) -> None:
        source = {
            "groups": [
                {
                    "id": "Space-UG_465",
                    "name": "AWS Women's User Groups Colombia",
                    "url": "https://www.meetup.com/es/aws-Women's User Groups-colombia-user-group/",
                }
            ]
        }
        html = '<title>Meetup | Grupo no encontrado</title><meta name="robots" content="noindex, follow"/>'

        class FakeCache:
            def fetch(self, url: str, **_: object) -> SimpleNamespace:
                return SimpleNamespace(body=html.encode(), retrieved_at="2026-06-22T10:00:00Z", url=url)

        index = build_meetup_index(source, FakeCache())  # type: ignore[arg-type]
        self.assertEqual(index["failures"][0]["reason"], "group_not_found")

    def test_extracts_user_groups_without_executing_javascript(self) -> None:
        script = '''const other={id:"not-a-group"};const groups=[
        {id:"Space-UG_2",link:"https://www.meetup.com/zurich/",countryCode:"CH",name:"AWS User Group Zürich",location:"Zürich",country:"Switzerland"},
        {id:"Space-UG_1",link:"https://www.meetup.com/lisbon/",countryCode:"PT",name:"AWS User Group Lisbon",location:"Lisbon",country:"Portugal"}
        ];'''
        groups = extract_user_groups_from_javascript(script)
        self.assertEqual([group["id"] for group in groups], ["Space-UG_2", "Space-UG_1"])
        self.assertEqual(groups[0]["name"], "AWS User Group Zürich")

    def test_normalizes_an_unavailable_join_link(self) -> None:
        script = '''const groups=[{id:"Space-UG_1",link:"TBD",countryCode:"PT",name:"AWS User Group Lisbon",location:"Lisbon",country:"Portugal"}];'''
        self.assertIsNone(extract_user_groups_from_javascript(script)[0]["url"])

    def test_discovers_hashed_builder_module_assets(self) -> None:
        script = '''const assets=["assets/module-abc123.js","assets/index-ignore.js"];
        import("./module-def456.js");'''
        self.assertEqual(
            discover_module_asset_urls(script, "https://builder.aws.com/assets/index-main.js"),
            ["https://builder.aws.com/assets/module-abc123.js"],
        )

    def test_builds_user_group_index_and_country_facets(self) -> None:
        html = '<script type="module" src="/assets/index-main.js"></script>'
        entry = 'const preload=["assets/module-data.js"];'
        module = '''const groups=[
        {id:"Space-UG_2",link:"https://www.meetup.com/porto/",countryCode:"PT",name:"AWS User Group Porto",location:"Porto",country:"Portugal"},
        {id:"Space-UG_1",link:"https://www.meetup.com/lisbon/",countryCode:"PT",name:"AWS User Group Lisbon",location:"Lisbon",country:"Portugal"}
        ];'''

        class FakeCache:
            def fetch(self, url: str, **_: object) -> SimpleNamespace:
                body = html if url.endswith("user-groups") else entry if url.endswith("index-main.js") else module
                return SimpleNamespace(body=body.encode(), retrieved_at="2026-06-22T10:00:00Z", url=url)

        index = build_user_groups_index(FakeCache())  # type: ignore[arg-type]
        self.assertEqual(index["count"], 2)
        self.assertEqual(index["countryCount"], 1)
        self.assertEqual(index["countries"], [{"code": "PT", "name": "Portugal", "count": 2}])
        self.assertEqual([group["name"] for group in index["groups"]], ["AWS User Group Lisbon", "AWS User Group Porto"])

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
