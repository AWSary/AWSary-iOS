# AGENTS

## Scope
This guidance applies to the entire repository unless a nested `AGENTS.md` overrides it.

## Project overview
This repository contains multiple components (e.g., iOS app, website, Terraform, utilities). Verify which directory you are working in before making changes.

## General workflow
- Favor small, targeted changes that align with existing patterns.
- Run relevant tests or linters for the area you changed when feasible.
- Document any skipped tests and the reason.

## Coding conventions
- Prefer clear, descriptive names consistent with surrounding code.
- Keep formatting consistent with existing files in each subproject.
- Avoid introducing new dependencies without justification.
- Prefer native Swift and SwiftUI with Apple public APIs. Only suggest third-party code when necessary or with significant advantages, and ask a human before adding any external SDK or codebase.

## iOS (Swift/Xcode)
- Follow existing Swift style and naming conventions.
- Use `@MainActor` or concurrency annotations consistently with neighboring code.
- Avoid force-unwrapping unless the codebase already uses it and it is safe.

## Web (website)
- Follow existing linting/formatting rules.
- Keep accessibility in mind (labels, semantics, contrast).

## Infrastructure (terraform)
- Use existing module patterns and naming conventions.
- Keep variables and outputs documented.

## PR/commit notes
- Summarize user-visible changes.
- Call out any migrations, configuration changes, or manual steps.
