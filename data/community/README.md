# AWS Community People data

This directory is the source-controlled foundation for an AWS Community People Index. It is intentionally independent of the iOS application so that harvesting, review, and publication decisions can evolve without coupling them to a client release.

The first supported source is public AWS Heroes data. The model is program-neutral and can also represent Community Builders, Amazonians, user group leaders, speakers, instructors, and other community members.

## Layout

- `people/*.json`: one canonical, reviewable Person record per file.
- `schemas/person.schema.json`: JSON Schema 2020-12 contract for canonical records.
- `schemas/people-index.schema.json`: contract for the compact client index.
- `indexes/people.index.json`: generated list/search payload. Drafts are excluded by default.
- `indexes/builder-center-heroes.index.json`: generated Builder Center alias index used for detail harvesting.
- `indexes/builder-center-user-groups.index.json`: generated local directory of official AWS User Groups.
- `indexes/meetup-user-groups.index.json`: optional public Meetup metadata keyed back to the AWS User Group IDs.
- `indexes/topics.index.json` and `indexes/programs.index.json`: initial seed vocabularies for later normalization work.
- `builder-center-seeds.txt`: tested public seed URLs.
- `raw/builder-center/`: ignored local HTTP and candidate cache. Only `.gitkeep` is committed.

## Person model

Identity fields (`id`, `slug`, and `displayName`) are stable local identifiers and public display data. `headline`, `summary`, `location`, `avatar`, `programs`, `topics`, `links`, and `featuredContent` describe the public profile.

Editorial state is explicit:

- `profileStatus`: `draft`, `published`, `hidden`, or `needs_review`.
- `ownershipStatus`: `unclaimed`, `claimed`, or `pending_claim`.
- `lastReviewedAt`: the most recent human review, if any.
- `lastHarvestedAt`: the source retrieval time used to produce the current harvested fields.

Program membership carries its own verification status. `aws_source_verified` means the program claim appeared in an AWS-controlled source. It does not mean that every biographical or external-link claim was independently verified.

## Provenance and verification

Every record has one or more `sourceEvidence` entries containing the source type, exact URL, retrieval timestamp, and fields supported by that source. Harvested records start as `draft`; the harvester never publishes them.

The supported source types are:

- `aws_builder_center`: a public page or public payload under `builder.aws.com`.
- `aws_public_page`: another AWS-controlled public page or endpoint.
- `manual`: manually curated data with recorded evidence.
- `owner_submitted`: data provided through a future owner workflow.

External social/profile links are copied only when present in public AWS data. Their `verified` value remains `false`: AWS displaying a link is evidence that it was observed, not proof that the linked account is currently controlled by that person. AWS-hosted profile links are marked verified as AWS source links.

## Setup

Python 3.11 or newer is required. The HTTP and parsing code uses the standard library. Schema validation uses one dependency:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r scripts/community/requirements.txt
```

## Harvest public data

Builder Center exposes Hero discovery and full profile details through separate public APIs. Run the pipeline in two steps.

First, build the current Hero alias index. This discovers the `HERO` group through `/camp/groups`, then reads its members from `/camp/groups/{groupId}/members`:

```sh
.venv/bin/python scripts/community/build_builder_center_index.py --refresh
```

Second, fetch every full profile with `POST /ums/getProfileByAlias` using the aliases from that index:

```sh
.venv/bin/python scripts/community/harvest_builder_center.py \
  --builder-index data/community/indexes/builder-center-heroes.index.json \
  --refresh
```

The group index currently includes trimmed card data. The per-alias call supplies the complete biography, headline, Builder Center avatar, AWS program memberships, location, and public social links. Profiles without a public alias are reported in `omittedWithoutAlias` because `getProfileByAlias` cannot retrieve them.

For a local end-to-end test bundle, merge the authoritative Builder Center roster and profiles into the existing iOS resource. The legacy AWS Heroes export is used only to fill missing presentation fields and profiles that Builder Center cannot retrieve by alias:

```sh
.venv/bin/python scripts/community/build_ios_community_resource.py --include-drafts
```

This replaces only `ios/AWSary/resources/community_members.json`; the current Swift model and views do not need to change. Omit `--include-drafts` once release exports should contain only reviewed, published profiles.

For targeted inspection, use one URL or alias directly:

Use one URL directly:

```sh
.venv/bin/python scripts/community/harvest_builder_center.py \
  --seed-url "https://builder.aws.com/community/heroes/RaphaelQuisumbing"
```

For a normal Builder Center profile, the public alias is the most direct seed:

```sh
.venv/bin/python scripts/community/harvest_builder_center.py \
  --builder-alias "misskecupbung"
```

The legacy AWS Heroes directory can still be harvested as a comparison source:

```sh
.venv/bin/python scripts/community/harvest_builder_center.py \
  --seed-file data/community/builder-center-seeds.txt
```

The legacy bulk seed is AWS's unauthenticated `aws.amazon.com/api/dirs/items/search` community-heroes directory endpoint. It exposes abbreviated Hero card data, not complete Builder Center profiles.

The harvester:

1. accepts only public HTTP(S) URLs on AWS-controlled hosts;
2. sends an identifying user agent, timeout, retries, and a configurable delay;
3. caches raw responses and response metadata locally;
4. inspects `application/json`, `application/ld+json`, `__NEXT_DATA__`, direct JSON-valued JavaScript assignments, explicit linked `.json` resources, and public JavaScript assets referenced by Builder Center;
5. writes a normalized candidate inspection file to the ignored raw directory;
6. creates or updates draft Person files while preserving existing publication, ownership, and human-review state.

For `/community/@alias` pages and `--builder-alias`, the harvester reproduces the generated frontend client's public request to `https://api.builder.aws.com/ums/getProfileByAlias`. The production JavaScript configures `builder-session-token: dummy` as a static API-key-style header. The harvester sends that header plus the public Builder Center origin/referrer. It does not copy browser cookies, authorization headers, Builder ID tokens, or private credentials.

Use `--refresh` to bypass the local cache. Run `--help` for timeout, retry, delay, and output-directory options.

### Current Builder Center behavior

As tested on 2026-06-21, the Heroes page builds its index from the public `camp` group endpoints and loads full records from `https://api.builder.aws.com/ums/getProfileByAlias`. The data access contract and static public session header are defined in the production JavaScript. The scripts use the same public calls with no browser cookies or private credentials.

Hero vanity URLs use a display-name path rather than the Builder alias. For example, `/community/heroes/TiagoRodrigues` resolves through the Hero group entry whose API alias is `tigpt`; posting `TiagoRodrigues` to `getProfileByAlias` is invalid. This is why the index step must precede full-profile harvesting.

## Build the AWS User Groups index

The User Groups page uses a different delivery mechanism from Heroes. The complete public directory is shipped as static data in a hashed Builder Center JavaScript module; there is no User Groups collection in the public `camp` group API. Build a deterministic local index with:

```sh
.venv/bin/python scripts/community/build_builder_user_groups_index.py --refresh
```

The script starts from the official `https://builder.aws.com/community/user-groups` page, discovers its current entry bundle and hashed module assets, then extracts the records without executing production JavaScript. It validates IDs, country codes, HTTPS join links, required fields, and duplicates before writing the index. Raw HTML and JavaScript responses remain in the ignored cache directory for inspection.

The generated index preserves the official group ID, name, location, country, country code, and valid HTTPS join URL. AWS placeholder link values such as `TBD` are normalized to `null`. The index also includes country counts for client-side filtering. Because Builder Center changes asset hashes on deployment, consumers should run the discovery pipeline instead of pinning a bundle URL.

### Enrich Meetup-backed User Groups

The official index currently contains Meetup links for most, but not all, groups. Enrich those records from their anonymous public HTML pages with:

```sh
.venv/bin/python scripts/community/harvest_meetup_user_groups.py --refresh
```

For a targeted or low-cost verification run, use `--group-id Space-UG_...` or `--limit 3` and write to a temporary output path. Responses are cached under the ignored `data/community/raw/meetup/` directory; the default one-second delay keeps a full refresh polite.

The parser prefers public JSON-LD and uses the page's embedded `__NEXT_DATA__` state for richer group-level fields. It does not call Meetup's internal GraphQL or `/_next/data` endpoints. Stable fields include the Meetup ID and slug, description, image, founding date, public location, topics, social links, and Pro network affiliation. Member totals, ratings, and event totals are isolated in `activitySnapshot` because they change frequently.

Member lists, organizer profiles, attendee details, sponsor details, and full event descriptions are deliberately excluded. Meetup's official authenticated API remains a possible later replacement if a suitable Meetup Pro API license and data scope are available.

Stale or unavailable Meetup links do not abort a full refresh. They are reported during the run and written to the generated index's `failures` array with a short machine-readable reason. Use `--fail-on-error` in automation when any skipped group should produce a non-zero exit status.

### Build the iOS User Groups bundle

Merge the authoritative AWS directory with optional Meetup enrichment into the app-facing resource:

```sh
.venv/bin/python scripts/community/build_ios_user_groups_resource.py
```

This writes `ios/AWSary/resources/community_user_groups.json`. All AWS-listed groups remain in the bundle, including non-Meetup groups and stale Meetup records. `metadataStatus` distinguishes `enriched`, `directory_only`, and `unavailable` records. The schema is defined in `schemas/ios-user-groups.schema.json`; the app-side `CommunityUserGroupStore` decodes the bundled resource without making a network request.

## Validate canonical data

```sh
.venv/bin/python scripts/community/validate_people_data.py
```

Validation checks the JSON Schema, date/URI formats, required fields, filename-to-slug consistency, and duplicate IDs/slugs. Any error produces a non-zero exit code.

## Build the client index

Build the normal public index (published records only):

```sh
.venv/bin/python scripts/community/build_people_index.py
```

Include drafts for local client testing:

```sh
.venv/bin/python scripts/community/build_people_index.py --include-drafts
```

Records are sorted by `displayName`. By default, `generatedAt` is the latest `lastHarvestedAt` value in the source records, so an unchanged build is byte-for-byte deterministic. Automation can pass `--generated-at` when a release timestamp is required.

Run parser and index unit tests with:

```sh
python3 -m unittest discover -s scripts/community/tests -v
```

## Intentionally out of scope

- iOS UI or application integration
- owner editing and profile claims
- scraping LinkedIn, X, GitHub, or any other social platform
- private APIs, credentials, cookies, or authenticated scraping
- automatic publication of harvested records
- automatic trust of non-AWS claims or external-account ownership
