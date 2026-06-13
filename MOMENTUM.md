# MOMENTUM

Running log for small increments, decisions, verification commands, and useful project context.

## Current Operating Mode

- Default autonomy: small focused fixes are allowed.
- Escalate before: adding dependencies, broad refactors, destructive git operations, infrastructure behavior changes, or user-visible product direction changes.
- Default done bar: inspect relevant code, make a targeted change, run feasible checks, document skipped checks.

## Project Map

| Area | Path | Notes |
| --- | --- | --- |
| iOS app | `ios/` | Swift, SwiftUI, Xcode project. Prefer native Apple APIs. |
| Website | `website/` | Follow local linting and formatting rules. |
| Terraform | `terraform/` | Follow existing module patterns. Document variables and outputs. |
| Utilities | `utils/` | Keep scripts focused and document assumptions. |
| Repository workflow | root, `.github/`, `docs/` | Local task queue plus promoted GitHub Issues. |

## Verification Commands

Add commands here as they are discovered.

| Area | Command | Notes |
| --- | --- | --- |
| repo | `git status --short` | Check worktree state before and after changes. |
| iOS | `xcodebuild -project ios/awsary.xcodeproj -scheme "awsary (iOS)" -destination "platform=iOS Simulator,name=iPhone 17 Pro" clean test` | Default local simulator target. |
| website | Manual/static content review | No `package.json` or website build command discovered yet. |
| terraform | `terraform -chdir=terraform fmt -check -recursive` | Formatting check for root Terraform and modules. |

## Decisions

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-06-13 | Use `TASKS.md` for the lightweight local queue and GitHub Issues for promoted work. | Keeps tiny increments low ceremony while preserving a path for larger tracked work. |
| 2026-06-13 | Use `iPhone 17 Pro` as the default simulator target. | Matches the preferred local development target. |
| 2026-06-13 | Keep GitHub Issue template labels empty for now. | The repo does not yet define matching labels, so local `[area/type]` prefixes remain the source of truth until labels are created deliberately. |
| 2026-06-13 | Remove the existing iOS GitHub Actions workflow. | GitHub Actions CI is not currently in use for this project. |

## Completed Increments

| Date | Area | Change | Verification |
| --- | --- | --- | --- |

## Resolved Questions

| Question | Answer |
| --- | --- |
| What is the preferred iOS simulator/device target for routine local checks? | `iPhone 17 Pro`. |
| Which website command should be considered the default quick verification? | None discovered. Use manual/static content review until website tooling is added. |
| Should GitHub Issues use labels matching the local task types? | Not yet. Keep labels empty until repo labels are created intentionally. |

## Open Questions

- What is the preferred local quick build command for iOS changes when full `clean test` is too slow?
- Should the website remain static content only, or should it gain explicit validation tooling?
