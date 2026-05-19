# Research: Code Quality Review Gem

**Date**: 2026-05-18 | **Spec**: [spec.md](./spec.md)

## Executive Summary

The codebase is substantially implemented. Key gaps are CLI naming (`check_quality` vs spec's `quality_review`), missing `--only`/`--exclude` flags (currently `--checks`), and no `--changed` flag (default behavior instead). Most spec requirements map directly to existing code.

## Existing Implementation Analysis

### What Exists

| Spec Requirement | Status | Implementation Location |
|------------------|--------|------------------------|
| FR-001: File paths/globs | Complete | `TargetResolver`, `Options` (`--files` flag) |
| FR-002: Tool identification | Complete | `CheckRegistry` maps tools to file types |
| FR-003: Tool execution | Complete | `QualityCheck` base class, `Runner` |
| FR-004: Aggregate outputs | Complete | `Runner.run()` collects `CheckOutput` structs |
| FR-005: LLM formatting | Complete | `LlmClient`, `PromptBuilder`, `Formatters::Human` |
| FR-006: Three output formats | Complete | `Formatters::Human`, `Agent`, `Github` |
| FR-007: Run storage in tmp | Complete | `RunArtifacts` with epoch-based namespacing |
| FR-008: `--only` flag | Partial | Uses `--checks` instead of `--only` |
| FR-009: `--exclude` flag | Missing | No exclusion flag exists |
| FR-010: `--changed` flag | Implicit | Default behavior, no explicit flag |
| FR-011: Rails/non-Rails | Complete | Pure Ruby, no Rails dependencies |
| FR-012: CLI command name | Mismatch | Executable is `check_quality`, not `quality_review` |

### Architecture Assessment

The existing architecture follows constitution principles:
- **Library-first**: Core logic in `lib/cleo_quality_review/`, thin CLI in `exe/`
- **Stable contracts**: JSON output for agent format, GitHub annotations for CI
- **Test-backed**: 16 test files covering major components
- **Configurable**: `.cleo_quality_review.yaml` with include/exclude patterns

## Decisions

### Decision 1: CLI Command Name

**Decision**: Retain `check_quality` name per constitution (Section II)

**Rationale**: The constitution explicitly states "`check_quality` command is the primary public interface." Changing to `quality_review` would violate stable CLI contracts.

**Spec Update Needed**: Update spec to reference `check_quality` instead of `quality_review`.

### Decision 2: Tool Filtering Flags

**Decision**: Add `--only` as alias for `--checks`, add new `--exclude` flag

**Rationale**: 
- `--checks` already provides include functionality (FR-008)
- Adding `--only` as alias maintains backwards compatibility
- `--exclude` is genuinely missing (FR-009)

**Alternatives Considered**:
- Replace `--checks` with `--only` (breaks existing users)
- Keep only `--checks` (doesn't match spec language)

### Decision 3: Changed Files Flag

**Decision**: Add explicit `--changed` flag, make explicit paths the default when provided

**Rationale**: 
- Current default behavior is git diff, which matches `--changed` semantics
- Spec expects explicit `--changed` flag for clarity
- When files are explicitly provided, should not filter to git changes

**Alternatives Considered**:
- Keep implicit behavior only (less explicit for users)
- Always require `--changed` (breaks backwards compatibility)

### Decision 4: Configuration File Name

**Decision**: Retain `.cleo_quality_review.yaml` per constitution (Section IV)

**Rationale**: Constitution mandates this specific file name. Spec doesn't specify config file name.

## Technical Clarifications Resolved

### LLM Provider Configuration

Current implementation supports:
- `openai` provider via `OPEN_AI_API_KEY` (default)
- Custom providers via `LlmProviderRegistry.register(:name, provider)`

No changes needed - spec assumption about "LLM configured and accessible" is satisfied.

### Main Branch Name

Current implementation uses `origin/main` via `BASE_REF` constant in `TargetResolver`. 
Constitution allows configurability - current implementation is appropriate.

### Tmp Directory Location

Current: `tmp/quality_checks/[timestamp]/` in project directory.
This matches spec assumption about project-local tmp directory.
