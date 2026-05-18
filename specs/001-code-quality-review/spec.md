# Feature Specification: Code Quality Review Gem

**Feature Branch**: `001-code-quality-review`

**Created**: 2026-05-18

**Status**: Draft

**Input**: User description: "Ruby gem for scanning code quality issues, comparing local changes against main branch, with CLI interface, multiple output formats, and configurable tools"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run Quality Review on Changed Files (Priority: P1)

A developer wants to check their local code changes for quality issues before committing or submitting a pull request. They run `quality_review` on their changed files to get actionable feedback on what needs to be fixed.

**Why this priority**: This is the core functionality - without the ability to review files, the gem provides no value.

**Independent Test**: Can be fully tested by running `quality_review foo.rb` on a file with known quality issues and verifying the report identifies them.

**Acceptance Scenarios**:

1. **Given** a Ruby file with quality issues, **When** the user runs `quality_review foo.rb`, **Then** the system outputs a report listing issues found with various severity levels.
2. **Given** multiple files matching a glob pattern, **When** the user runs `quality_review bar/**/*.rb`, **Then** all matching files are analyzed and results aggregated
3. **Given** a file with no quality issues, **When** the user runs `quality_review clean.rb`, **Then** the system outputs a success message indicating no issues found
4. **Given** a glob pattern that doesn't match any known tools, **When** the user runs `quality_review clean.rb`, **Then** the system outputs a success message indicating no issues found

---

### User Story 2 - Choose Output Format (Priority: P2)

A developer or CI system needs the quality review output in a specific format suitable for their use case - human-readable for terminal use, structured for AI agents, or annotated for GitHub Actions.

**Why this priority**: Output flexibility enables the gem to be used across different contexts (local dev, CI/CD, AI-assisted coding).

**Independent Test**: Can be tested by running the same review with different format flags and verifying each produces correctly formatted output.

**Acceptance Scenarios**:

1. **Given** a file with issues, **When** the user runs `quality_review --format human foo.rb`, **Then** the output is formatted for human readability with colors and clear structure
2. **Given** a file with issues, **When** the user runs `quality_review --format agent foo.rb`, **Then** the output is structured for AI agent consumption
3. **Given** a file with issues, **When** the user runs `quality_review --format github foo.rb`, **Then** the output uses GitHub Actions annotation format

---

### User Story 3 - Filter Tools (Priority: P2)

A developer wants to focus on specific quality aspects by including or excluding certain analysis tools from the review.

**Why this priority**: Filtering allows developers to address issues incrementally and reduces noise when focusing on specific concerns.

**Independent Test**: Can be tested by running with tool filters and verifying only the specified tools produce output.

**Acceptance Scenarios**:

1. **Given** multiple tools are available, **When** the user runs `quality_review --only rubocop foo.rb`, **Then** only RuboCop analysis is performed
2. **Given** multiple tools are available, **When** the user runs `quality_review --exclude brakeman foo.rb`, **Then** all tools except Brakeman are run
3. **Given** an invalid tool name, **When** the user runs `quality_review --only invalid_tool foo.rb`, **Then** the system displays an error listing available tools

---

### User Story 4 - Compare Against Main Branch (Priority: P3)

A developer wants to review only the files that have changed compared to the main branch, ensuring they address quality issues in their changes before merging.

**Why this priority**: Comparing against main reduces scope to relevant changes and integrates with typical git workflows.

**Independent Test**: Can be tested by creating a branch with changes and verifying only changed files are analyzed.

**Acceptance Scenarios**:

1. **Given** files changed on the current branch, **When** the user runs `quality_review --changed`, **Then** only files differing from main are analyzed
2. **Given** no files changed from main, **When** the user runs `quality_review --changed`, **Then** the system indicates no changed files to review

---

### Edge Cases

- What happens when a specified file does not exist? System displays feedback indicating that there were no errors because no files were matching
- What happens when no tools are configured for a file type? System skips the file, logging that there were no tools to apply.
- What happens when a tool fails during analysis? System continues with remaining tools and reports the failure in tmp/
- What happens when the tmp directory is not writable? System fails gracefully with a permissions error.
- What happens when glob pattern matches no files? System displays "no matching files" message.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST accept file paths and glob patterns as command line arguments
- **FR-002**: System MUST identify the appropriate analysis tools for each file type
- **FR-003**: System MUST execute each applicable tool against the target files
- **FR-004**: System MUST aggregate tool outputs 
- **FR-005**: System MUST format final output via LLM for consistency and clarity (unless tool reports are empty).
- **FR-006**: System MUST support three output formats: human-readable, agent-structured, and GitHub Actions
- **FR-007**: System MUST store each run in a tmp directory namespaced by epoch timestamp for uniqueness
- **FR-008**: System MUST allow tools to be explicitly included via `--only` flag
- **FR-009**: System MUST allow tools to be explicitly excluded via `--exclude` flag
- **FR-010**: System MUST compare local changes against main branch when `--changed` flag is used
- **FR-011**: System MUST work in both Rails and non-Rails Ruby projects
- **FR-012**: System MUST provide a `quality_review` CLI command as the primary interface

### Key Entities

- **Run**: A single execution of the quality review, identified by epoch timestamp, containing tool results and final output
- **Tool**: An analysis component that examines files and produces findings (e.g., RuboCop, Brakeman, Reek)
- **Finding**: A single quality issue identified by a tool, with severity (MUST/SHOULD), location, and description
- **Report**: The formatted output combining all findings, produced in the requested format

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can review a single file in under 30 seconds for typical file sizes
- **SC-002**: Users can identify all MUST-fix issues in a single review run
- **SC-003**: Output is actionable - users understand what to fix and why for each finding
- **SC-004**: 95% of review runs complete without errors when given valid input
- **SC-005**: Tool filtering reduces review time proportionally to tools excluded
- **SC-006**: GitHub Actions output integrates seamlessly with PR annotations

## Assumptions

- Users have Ruby installed and can install gems via Bundler or gem install
- Analysis tools (RuboCop, etc.) are either bundled or available as dependencies
- The LLM for output formatting is configured and accessible (API key or local model)
- Users have git available when using the `--changed` flag
- The main branch is named `main` (configurable if needed)
- Tmp directory follows system conventions (`/tmp` on Unix, or project-local)
