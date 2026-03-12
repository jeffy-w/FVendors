# AGENTS.md

This file guides AI coding agents working in this repository.

## Repository Purpose

`FVendors` is a modular Swift Package that provides lightweight infrastructure building blocks for Apple platform apps. The package is intentionally small and split into focused modules. Changes should preserve that modularity.

## Primary Goals For Agents

- Make the smallest reasonable change that solves the requested task.
- Respect target boundaries instead of adding convenience code in the wrong module.
- Prefer testable, dependency-injected designs over hard-coded behavior.
- Keep public APIs intentional and stable.
- Update tests and documentation when behavior or public usage changes.

## Project Layout

- `Package.swift`: package definition, products, targets, dependencies, and platform requirements.
- `Sources/FVendorsModels`: shared model types and cross-cutting domain enums/errors.
- `Sources/FVendorsClients`: protocol-style client interfaces and test-friendly abstractions.
- `Sources/FVendorsClientsLive`: production implementations for clients.
- `Sources/FVendorsExt`: UI and framework extensions.
- `Sources/FVendors`: umbrella target that re-exports core modules.
- `Tests/FVendorsModelsTests`: tests for model-layer behavior.
- `Tests/FVendorsClientsTests`: tests for clients, request builders, cache behavior, and live-compatible behavior.
- `Docs/en` and `Docs/zh-CN`: user-facing package documentation.

## Module Boundaries

Follow these boundaries unless the task explicitly requires a structural change.

- Put shared value types, error types, and enums in `FVendorsModels`.
- Put abstract client APIs and convenience wrappers in `FVendorsClients`.
- Put concrete production behavior in `FVendorsClientsLive`.
- Put UI/framework extensions in `FVendorsExt`.
- Keep `FVendors` thin; it should primarily re-export modules rather than contain feature logic.

When adding functionality, choose the narrowest target that matches the responsibility.

## Working Style

- Read the relevant target, adjacent tests, and any related docs before editing.
- Preserve existing naming, access control, and file organization when possible.
- Prefer surgical edits over broad refactors.
- Do not move code across modules unless that move is the actual task.
- Avoid introducing new dependencies unless clearly necessary.
- Do not add speculative abstractions or future-proofing without a concrete need.

## Swift Conventions In This Repo

- Match the repository's existing Swift style and formatting.
- Prefer clear, explicit names over terse names.
- Keep public surface area small and deliberate.
- Use `Sendable`-safe designs when working with concurrency-sensitive types.
- Preserve async/await-based APIs where they already exist.
- Keep helper APIs close to the type they support instead of creating generic utility dumping grounds.

## Testing Expectations

This repository already has tests. If you change behavior, add or update focused tests in the nearest test target.

Prefer this order:

1. Add or update the most specific test for the changed behavior.
2. Run the narrowest relevant test set first.
3. Run the broader package test suite if the change affects shared or public behavior.

Typical commands:

```bash
swift build
swift test
```

If you only changed a specific area, still prefer validating that area before suggesting wider verification.

## Documentation Expectations

Update docs when public APIs, usage patterns, or module responsibilities change.

Check these locations when relevant:

- `README.md`
- `README-CN.md`
- `Docs/en/*.md`
- `Docs/zh-CN/*.md`

For internal-only refactors with no user-visible impact, doc updates are usually unnecessary.

## Safe Change Rules

- Do not silently change public API semantics without updating tests and docs.
- Do not weaken platform or Swift version requirements unless explicitly asked.
- Do not collapse module boundaries for convenience.
- Do not add unrelated fixes while touching a file.
- Do not remove tests unless the task specifically requires replacing obsolete coverage.
- Do not edit generated, build, or checkout directories such as `.build/`.

## Preferred Agent Workflow

For most code changes:

1. Read `Package.swift` if target placement or dependencies may matter.
2. Read the relevant source file and adjacent tests.
3. Make the smallest coherent change.
4. Update or add targeted tests.
5. Update docs if public behavior changed.
6. Run relevant verification commands.
7. Summarize changed files, validation performed, and any remaining risks.

## Commands And Environment Notes

- Package manager: Swift Package Manager.
- CI currently runs on GitHub Actions with `swift build` and `swift test`.
- Prefer repo-local commands that work in a standard Swift toolchain.
- Avoid assuming Xcode-only workflows unless the task explicitly asks for them.

## When Unsure

If the request is ambiguous, prefer asking a short clarifying question instead of making a large structural decision.

If you must infer intent, choose the option that:

- preserves module boundaries,
- minimizes API churn,
- keeps behavior testable,
- and requires the fewest unrelated edits.
