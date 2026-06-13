# TASKS

Small, repo-local queue for steady project momentum. Keep items concrete enough that one focused pass can finish or meaningfully advance them.

## How To Use

- Put newly discovered work in `Inbox`.
- Move the best near-term items into `Next`.
- Keep each task scoped to one area: `ios`, `website`, `terraform`, `utils`, `docs`, or `repo`.
- Promote tasks to GitHub Issues when they need discussion, screenshots, prioritization, or multiple PRs.
- Move completed items to `Done` with the completion date.

## Task Template

```md
- [ ] [area/type] Short task title
  - Goal: What should be true when this is done.
  - Notes: Constraints, files, reproduction steps, or links.
  - Verify: Command, manual check, or "not needed".
```

Types: `bug`, `polish`, `feature`, `refactor`, `test`, `docs`, `research`, `infra`.

## Next

- [ ] [repo/docs] Do an initial repository orientation pass
  - Goal: Identify the main subprojects, common commands, and obvious safe first improvements.
  - Notes: Update `MOMENTUM.md` with findings.
  - Verify: Documentation-only change.

## Inbox

- [ ] [ios/research] Identify one small SwiftUI polish improvement
  - Goal: Find a low-risk UI improvement that can be implemented in a single pass.
  - Notes: Prefer existing patterns and Apple public APIs.
  - Verify: Relevant Xcode build or manual simulator check when feasible.

- [ ] [website/research] Identify one small accessibility or content polish improvement
  - Goal: Find a focused improvement in labels, semantics, copy, or layout.
  - Notes: Follow existing website tooling and formatting.
  - Verify: Relevant lint/build command when available.

- [ ] [terraform/research] Review Terraform backend docs for one small clarity improvement
  - Goal: Improve documentation or naming clarity without changing infrastructure behavior.
  - Notes: Keep variables and outputs documented.
  - Verify: `terraform fmt` or documentation-only check as applicable.

## Later

## Done

