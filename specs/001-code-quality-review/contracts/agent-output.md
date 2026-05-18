# Agent Output Contract

**Version**: 1.0.0 | **Status**: Stable

## Overview

The agent output format (`--format agent`) produces a JSON structure designed for consumption by AI coding assistants and automated tools.

## Schema

```json
{
  "run": {
    "timestamp": "<integer>",
    "checks": ["<string>"],
    "target_files": ["<string>"],
    "findings": [
      {
        "tool": "<string>",
        "check": "<string>",
        "filepath": "<string>",
        "line": "<integer|null>",
        "result": "<string>"
      }
    ]
  },
  "check_outputs": [
    {
      "check_name": "<string>",
      "extension": "<string>",
      "raw_output": "<string>"
    }
  ],
  "instructions": "<string>"
}
```

## Field Definitions

### run.timestamp

- **Type**: Integer
- **Description**: Unix epoch timestamp when the run started
- **Example**: `1715990400`

### run.checks

- **Type**: Array of strings
- **Description**: Names of checks that were executed
- **Example**: `["reek", "flog", "fasterer"]`

### run.target_files

- **Type**: Array of strings
- **Description**: Relative paths to files that were analyzed
- **Example**: `["lib/cleo_quality_review/runner.rb", "lib/cleo_quality_review/cli.rb"]`

### run.findings

- **Type**: Array of Finding objects
- **Description**: All quality issues found across all checks

### Finding Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| tool | string | yes | Tool that generated the finding (reek, flog, fasterer) |
| check | string | yes | Specific check type (e.g., "FeatureEnvy", "Complexity", "Performance") |
| filepath | string | yes | Relative path to the file |
| line | integer | no | Line number (may be null if not applicable) |
| result | string | yes | Human-readable description of the issue |

### check_outputs

- **Type**: Array of CheckOutput objects
- **Description**: Raw output from each check tool for debugging/analysis

### CheckOutput Object

| Field | Type | Description |
|-------|------|-------------|
| check_name | string | Name of the check tool |
| extension | string | File extension for raw output (json, txt) |
| raw_output | string | Complete raw output from the tool |

### instructions

- **Type**: String
- **Description**: Agent instructions loaded from prompt template
- **Source**: `prompts/agent.md` or user override

## Stability Guarantees

Per constitution (Section II: Stable CLI Contracts):

- Top-level keys (`run`, `check_outputs`, `instructions`) are stable
- `run.findings` array structure is stable
- New keys may be added without breaking change
- Existing keys will not be removed or renamed without major version bump

## Example Output

```json
{
  "run": {
    "timestamp": 1715990400,
    "checks": ["reek", "flog"],
    "target_files": ["lib/example.rb"],
    "findings": [
      {
        "tool": "reek",
        "check": "FeatureEnvy",
        "filepath": "lib/example.rb",
        "line": 42,
        "result": "Example#process refers to 'other' more than self (maybe move it to another class?)"
      },
      {
        "tool": "flog",
        "check": "Complexity",
        "filepath": "lib/example.rb",
        "line": 10,
        "result": "25.5: Example#complex_method"
      }
    ]
  },
  "check_outputs": [
    {
      "check_name": "reek",
      "extension": "json",
      "raw_output": "[{\"smell_type\":\"FeatureEnvy\",...}]"
    },
    {
      "check_name": "flog",
      "extension": "txt",
      "raw_output": "25.5: Example#complex_method lib/example.rb:10"
    }
  ],
  "instructions": "You are reviewing Ruby code quality findings..."
}
```
