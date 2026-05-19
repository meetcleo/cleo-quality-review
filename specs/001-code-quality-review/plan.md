# Implementation Plan: Code Quality Review Gem

**Branch**: `001-code-quality-review` | **Date**: 2026-05-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-code-quality-review/spec.md`

## Summary

Build a Ruby gem (`cleo_quality_review`) that scans Ruby code for quality issues using multiple analysis tools (Reek, Flog, Fasterer), aggregates findings, and outputs results in human-readable, agent-structured, or GitHub Actions annotation formats. The gem provides a `check_quality` CLI command that supports file path/glob arguments, `--changed` flag for git-diff-based file selection, and `--only`/`--exclude` flags for tool filtering.

## Technical Context

**Language/Version**: Ruby 3.2+

**Primary Dependencies**:
- `reek` - code smell detection
- `flog` - complexity analysis
- `fasterer` - performance suggestions
- LLM provider (OpenAI API) for human-readable formatting

**Storage**: File-based (`tmp/cleo_quality_review/<timestamp>/` for run artifacts)

**Testing**: Minitest with Mocha for mocking, SimpleCov for coverage (90% threshold)

**Target Platform**: Unix-like systems (macOS, Linux) with Ruby installed

**Project Type**: RubyGem library + CLI executable

**Performance Goals**: Single file review < 30 seconds (SC-001), proportional speedup with tool filtering (SC-005)

**Constraints**: Non-human formats (agent, github) MUST work without network access or LLM configuration

**Scale/Scope**: Typical Ruby projects (1k-100k LOC), individual file or project-wide review

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. RubyGem Library First | PASS | Library core in `lib/cleo_quality_review/`, thin CLI in `exe/check_quality` |
| II. Stable CLI Contracts | PASS | Formats defined (human, agent, github); agent format is JSON with stable keys; github uses workflow commands |
| III. Test-Backed Changes | PASS | Minitest suite exists; SimpleCov configured at 90% threshold |
| IV. Configuration and Local Control | PASS | `.cleo_quality_review.yaml` config with RuboCop-like inheritance pattern |

## Project Structure

### Documentation (this feature)

```text
specs/001-code-quality-review/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── cli-contract.md  # CLI interface contract
└── tasks.md             # Phase 2 output (created by /speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── cleo_quality_review.rb           # Main module entry point
└── cleo_quality_review/
    ├── version.rb                   # Gem version
    ├── cli.rb                       # CLI entry point
    ├── options.rb                   # Option parsing
    ├── runner.rb                    # Run orchestration
    ├── run.rb                       # Run value object
    ├── run_artifacts.rb             # Artifact file management
    ├── result.rb                    # Finding value object
    ├── check_registry.rb            # Check name resolution
    ├── target_resolver.rb           # File/git target resolution
    ├── command_runner.rb            # Shell command execution
    ├── configuration.rb             # Config file loading
    ├── formatter.rb                 # Format dispatcher
    ├── formatters/
    │   ├── human.rb                 # LLM-powered human output
    │   ├── agent.rb                 # JSON output for agents
    │   └── github.rb                # GitHub Actions annotations
    ├── checks/
    │   ├── quality_check.rb         # Base check class
    │   ├── reek.rb                  # Reek integration
    │   ├── flog.rb                  # Flog integration
    │   └── fasterer.rb              # Fasterer integration
    ├── llm_client.rb                # LLM abstraction
    ├── llm_config.rb                # LLM configuration
    ├── llm_provider_registry.rb     # Provider lookup
    ├── open_ai_client.rb            # OpenAI implementation
    ├── open_ai_config.rb            # OpenAI configuration
    ├── stub_llm_provider.rb         # Test double
    ├── llm_errors.rb                # LLM error types
    ├── prompt_builder.rb            # Prompt construction
    └── prompt_loader.rb             # Prompt file loading

exe/
└── check_quality                    # CLI executable

config/
└── default.yml                      # Bundled default configuration

prompts/
├── human.md                         # Human format prompt
├── agent.md                         # Agent format instructions
└── github.md                        # GitHub summary prefix

test/
└── lib/
    └── cleo_quality_review/
        ├── *_test.rb                # Unit tests
        ├── formatters/
        │   └── *_test.rb            # Formatter tests
        └── checks/
            └── *_test.rb            # Check tests
```

**Structure Decision**: Single RubyGem project following constitution principle I. Library code in `lib/cleo_quality_review/`, executable in `exe/`, tests in `test/` mirroring lib structure.

## Complexity Tracking

> No constitution violations requiring justification.
