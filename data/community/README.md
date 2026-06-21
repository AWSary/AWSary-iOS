# AWS Community People data

This directory is the source-controlled foundation for an AWS Community People Index. It is intentionally independent of the iOS application so that harvesting, review, and publication decisions can evolve without coupling them to a client release.

The first supported source is public AWS Heroes data. The model is program-neutral and can also represent Community Builders, Amazonians, user group leaders, speakers, instructors, and other community members.

## Layout

- `people/*.json`: one canonical, reviewable Person record per file.
- `schemas/person.schema.json`: JSON Schema 2020-12 contract for canonical records.
- `schemas/people-index.schema.json`: contract for the compact client index.
- `indexes/people.index.json`: generated list/search payload. Drafts are excluded by default.
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

Or use the tested bulk seed file:

```sh
.venv/bin/python scripts/community/harvest_builder_center.py \
  --seed-file data/community/builder-center-seeds.txt
```

The current bulk seed is AWS's unauthenticated `aws.amazon.com/api/dirs/items/search` community-heroes directory endpoint. It exposes structured Hero card data and is more useful for bulk seeding than the current Builder Center HTML shell.

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

As tested on 2026-06-21, `builder.aws.com/community/heroes/...` returns a small client-rendered HTML shell. It contains site-level JSON-LD but no person payload. The data access contract and static public session header are defined in the downloaded production JavaScript. This project inspects and caches those public assets without executing them, and uses the same public profile call for known aliases.

Hero vanity URLs use a display-name path rather than necessarily exposing the Builder alias. The bulk AWS Heroes directory remains the reliable discovery seed; known Builder aliases can be supplied directly. The parser also remains ready for schema.org `Person`, Next.js data, or other supported public JSON shapes as the frontend changes.

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
