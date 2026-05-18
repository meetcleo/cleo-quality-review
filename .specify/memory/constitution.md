<!--
Sync Impact Report
Version change: template -> 1.0.0
Modified principles:
- Placeholder Principle 1 -> I. RubyGem Library First
- Placeholder Principle 2 -> II. Stable CLI Contracts
- Placeholder Principle 3 -> III. Test-Backed Changes
- Placeholder Principle 4 -> IV. Configuration and Local Control
- Placeholder Principle 5 -> V. Release Safety and Simplicity
Added sections:
- RubyGem Project Standards
- Development Workflow and Quality Gates
Removed sections:
- None
Templates requiring updates:
- Reviewed: .specify/templates/plan-template.md; generic Constitution Check remains suitable.
- Reviewed: .specify/templates/spec-template.md; no project-specific change required.
- Pending: .specify/templates/tasks-template.md still describes tests as optional, while this
  constitution requires tests for behaviour changes.
Follow-up TODOs:
- None
-->

# Cleo Quality Review Constitution

## Core Principles

### I. RubyGem Library First

Cleo Quality Review MUST remain a focused RubyGem with a small, testable library core and a
thin executable entry point. Reusable behaviour MUST live under `lib/cleo_quality_review`,
inside the `CleoQualityReview` namespace, and the executable in `exe/check_quality` MUST only
parse inputs, delegate to the library, and translate errors into process output.

New functionality MUST fit the existing gem shape before introducing new frameworks, services,
or long-running processes. Dependencies MUST be justified by clear value over Ruby standard
library facilities or existing gem dependencies.

### II. Stable CLI Contracts

The `check_quality` command is the primary public interface. Its supported formats, exit
behaviour, environment variables, and output contracts MUST be treated as release-facing API.

Machine-readable output, especially `--format agent`, MUST remain valid JSON with stable top-level
keys unless a breaking change is explicitly documented. GitHub output MUST remain compatible with
GitHub workflow annotation syntax. Human output MAY use an LLM provider, but normal non-human
formats MUST work without network access or secret configuration.

Errors MUST be actionable: invalid options, missing paths, unsupported providers, and invalid
configuration MUST fail with concise messages on stderr and non-zero exit status.

### III. Test-Backed Changes

Every behaviour change MUST include focused Minitest coverage before it is considered complete.
Tests MUST cover public contracts, parser normalisation, config merging, path selection, and
failure modes touched by the change.

Bug fixes MUST add a regression test that fails without the fix. Refactors MAY avoid new tests
only when existing tests already exercise the changed contract and the refactor does not alter
observable behaviour. The full suite MUST pass with `bundle exec rake test` before merge or
release.

### IV. Configuration and Local Control

Repository users MUST be able to control scanned files without changing gem code. The project
configuration file is `.cleo_quality_review.yaml`, and its shape MUST remain RuboCop-like:
`inherit_from` plus `AllCops.Include` and `AllCops.Exclude`.

The gem MUST load bundled defaults first, then explicit inherited files, then the local repository
configuration. Relative inherited paths MUST resolve from the declaring config file. User-level
paths using `~` MUST be supported. Missing inherited files and invalid YAML MUST fail loudly.

Defaults MUST be conservative: scan Ruby source by default, avoid generated or vendored trees, and
allow users to opt in additional Ruby-like extensions such as `.rake`.

## Governance

This constitution supersedes informal project practices. Specifications, implementation plans,
tasks, and reviews MUST check their work against these rules.

Amendments require an explicit constitution change that includes the Sync Impact Report, a semantic
version update, and a short rationale. Versioning follows these rules:

- MAJOR: Removes or redefines a core principle, or permits behaviour previously forbidden.
- MINOR: Adds a principle, adds a required quality gate, or materially expands project standards.
- PATCH: Clarifies wording without changing obligations.

Pull requests that violate the constitution MUST either be changed to comply or include a documented
exception with scope, rationale, and follow-up plan. Exceptions MUST NOT be used for release safety,
test coverage, or package integrity gates.

**Version**: 1.0.0 | **Ratified**: 2026-05-18 | **Last Amended**: 2026-05-18
