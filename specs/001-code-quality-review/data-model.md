# Data Model: Code Quality Review Gem

**Date**: 2026-05-18 | **Spec**: [spec.md](./spec.md)

## Entities

### Run

A single execution of the quality review.

| Field | Type | Description |
|-------|------|-------------|
| timestamp | Integer | Epoch time identifying this run |
| format | Symbol | Output format (:human, :agent, :github) |
| checks | Array<String> | List of check names executed |
| target_files | Array<String> | Paths to files analyzed |
| findings | Array<Result> | All findings from all checks |
| artifacts_path | String | Path to `tmp/quality_checks/[timestamp]/` |

**Existing Implementation**: `Run` struct in `lib/cleo_quality_review/runner.rb`

### Result (Finding)

A single quality issue identified by a tool.

| Field | Type | Description |
|-------|------|-------------|
| tool | String | Tool name (reek, flog, fasterer) |
| check | String | Specific check type (e.g., "FeatureEnvy", "Complexity") |
| timestamp | Integer | When finding was generated |
| result | String | Description of the issue |
| filepath | String | File containing the issue |
| line | Integer | Line number (may be nil) |

**Existing Implementation**: `Result` struct in `lib/cleo_quality_review/result.rb`

### CheckOutput

Output from a single quality check tool.

| Field | Type | Description |
|-------|------|-------------|
| check_name | String | Name of the check tool |
| extension | String | File extension for raw output |
| raw_output | String | Raw tool output (JSON or text) |
| results | Array<Result> | Parsed findings |

**Existing Implementation**: `CheckOutput` struct in `lib/cleo_quality_review/checks/quality_check.rb`

### Tool (QualityCheck)

An analysis component that examines files.

| Field | Type | Description |
|-------|------|-------------|
| name | String | Tool identifier (reek, flog, fasterer) |
| command | Method | Generates shell command for files |
| parse | Method | Parses raw output into Results |

**Existing Implementation**: `QualityCheck` base class with subclasses for each tool

### Configuration

User-configurable settings for scans.

| Field | Type | Description |
|-------|------|-------------|
| include_patterns | Array<String> | Glob patterns for files to include |
| exclude_patterns | Array<String> | Glob patterns for files to exclude |
| inherit_from | Array<String> | Paths to inherited config files |

**Existing Implementation**: `Configuration` class in `lib/cleo_quality_review/configuration.rb`

### ParseResult (Options)

Parsed command-line arguments.

| Field | Type | Description |
|-------|------|-------------|
| format | Symbol | Output format |
| checks | Array<String> | Requested checks (or empty for all) |
| files | Array<String> | Explicit file paths |
| only | Array<String> | Tools to include (alias for checks) |
| exclude | Array<String> | Tools to exclude |
| changed | Boolean | Whether to use git diff mode |

**Existing Implementation**: `ParseResult` struct in `lib/cleo_quality_review/options.rb`
**Gaps**: Missing `only`, `exclude`, `changed` fields

## Entity Relationships

```
Run
├── has many: CheckOutput (one per tool executed)
│   └── has many: Result (findings from that tool)
├── uses: Configuration (for file filtering)
└── uses: ParseResult (from CLI)

CheckRegistry
└── maps: tool names → QualityCheck subclasses

TargetResolver
├── uses: Configuration (include/exclude patterns)
├── uses: ParseResult.files (explicit paths)
└── uses: ParseResult.changed (git diff mode)
```

## State Transitions

### Run Lifecycle

```
Created → Resolving Files → Running Checks → Formatting Output → Complete
           │                 │
           └─ No Files ──────┴─ Check Error ──→ Failed (with partial results)
```

### Finding Severity

Findings have implicit severity based on tool:
- **MUST-fix**: Not currently implemented (all findings are advisory)
- **SHOULD-fix**: All current findings

**Note**: Spec mentions MUST/SHOULD severity levels. Current implementation does not distinguish severity. This may be a gap to address or a decision to document that severity is determined by the consuming system.
