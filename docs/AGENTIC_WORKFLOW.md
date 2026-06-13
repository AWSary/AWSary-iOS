# Agentic Workflow

This repository uses a lightweight loop for steady, small improvements. The goal is to keep momentum high while preserving code quality and project context.

## Files

- `TASKS.md`: local queue for small increments, rough ideas, and near-term work.
- `MOMENTUM.md`: running memory for decisions, verification commands, shipped increments, and open questions.
- `.github/ISSUE_TEMPLATE/increment.yml`: GitHub Issue template for work that outgrows the local queue.

## Default Loop

1. Pick one task from `TASKS.md`, usually from `Next`.
2. Confirm the affected area: `ios`, `website`, `terraform`, `utils`, `docs`, or `repo`.
3. Inspect the relevant files before editing.
4. Make the smallest useful change that satisfies the task.
5. Run the narrowest meaningful verification.
6. Update `TASKS.md` and `MOMENTUM.md`.
7. Promote follow-up work to `Inbox` or a GitHub Issue.

## When To Use GitHub Issues

Use `TASKS.md` for:

- Small bugs.
- Local polish.
- One-pass refactors.
- Verification improvements.
- Rough ideas that need shaping.

Use GitHub Issues for:

- Features that need discussion or acceptance criteria.
- Bugs with reproduction steps or screenshots.
- Work spanning multiple pull requests.
- Anything that needs labels, assignment, prioritization, or external tracking.

## Suggested Prompts

```text
Take the next item from TASKS.md and finish it end to end.
```

```text
Do a repo health pass. Find 3 small improvement opportunities and fix the safest one.
```

```text
Pick one low-risk iOS polish task, implement it, and run the relevant check.
```

```text
Promote this TASKS.md item into a GitHub Issue with clear acceptance criteria.
```

```text
Review the current branch like a PR and fix any obvious small issues.
```

## Autonomy Levels

Use these phrases to tune how much initiative the agent should take.

| Mode | Meaning |
| --- | --- |
| Ask first | Inspect and propose options before editing. |
| Small fixes allowed | Make focused fixes, polish, docs, and tests without stopping for every decision. |
| Feature mode | Design and implement a small feature slice, calling out assumptions. |
| PR mode | Prepare the branch for review, including commit and draft PR when requested. |

## Done Bar

For a normal small increment:

- The change is scoped to the task.
- Existing patterns are followed.
- Relevant tests, builds, linters, or manual checks were run when feasible.
- Skipped checks are documented with a reason.
- `TASKS.md` and `MOMENTUM.md` reflect the outcome when appropriate.

## Promotion Checklist

Before promoting a local task to a GitHub Issue, capture:

- Problem or opportunity.
- Affected area.
- Acceptance criteria.
- Known constraints.
- Suggested verification.
- Links, screenshots, or reproduction steps when useful.

