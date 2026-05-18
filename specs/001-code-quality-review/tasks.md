# Tasks: Code Quality Review Gem

**Input**: Design documents from `/specs/001-code-quality-review/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Required per constitution (Section III: Test-Backed Changes)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Library**: `lib/cleo_quality_review/`
- **Tests**: `test/`
- **Executable**: `exe/check_quality`
- **Config**: `config/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Validate existing implementation and align spec with code

- [x] T001 Update spec.md to use `check_quality` instead of `quality_review` per constitution in specs/001-code-quality-review/spec.md
- [x] T002 Run `bundle exec rake test` to verify existing tests pass (49 tests, 144 assertions)

**Checkpoint**: Existing codebase validated, spec aligned with constitution

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extend ParseResult struct and Options parser to support new flags

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Add `exclude` field to ParseResult struct in lib/cleo_quality_review/options.rb
- [x] T004 Add `changed` boolean field to ParseResult struct in lib/cleo_quality_review/options.rb
- [x] T005 [P] Add test for `--only` alias parsing in test/options_test.rb
- [x] T006 [P] Add test for `--exclude` flag parsing in test/options_test.rb
- [x] T007 [P] Add test for `--changed` flag parsing in test/options_test.rb
- [x] T008 Implement `--only` as alias for `--checks` in lib/cleo_quality_review/options.rb
- [x] T009 Implement `--exclude` flag parsing in lib/cleo_quality_review/options.rb
- [x] T010 Implement `--changed` flag parsing in lib/cleo_quality_review/options.rb
- [x] T011 Update help text to document all flags in lib/cleo_quality_review/options.rb

**Checkpoint**: Foundation ready - all new flags parse correctly, tests pass

---

## Phase 3: User Story 1 - Run Quality Review on Changed Files (Priority: P1)

**Goal**: Core review functionality works with explicit files or changed files mode

**Independent Test**: Run `check_quality lib/cleo_quality_review/cli.rb` and verify it analyzes that specific file without git filtering

### Tests for User Story 1

- [x] T012 [P] [US1] Add test: explicit files override git diff behavior in test/target_resolver_test.rb
- [x] T013 [P] [US1] Add test: `--changed` flag forces git diff mode in test/target_resolver_test.rb
- [x] T014 [P] [US1] Add test: no args defaults to changed mode in test/runner_test.rb

### Implementation for User Story 1

- [x] T015 [US1] Modify TargetResolver to accept `changed` flag in lib/cleo_quality_review/target_resolver.rb
- [x] T016 [US1] When explicit files provided and `changed` is false, skip git diff filtering in lib/cleo_quality_review/target_resolver.rb
- [x] T017 [US1] Update Runner to pass `changed` flag to TargetResolver in lib/cleo_quality_review/runner.rb
- [x] T018 [US1] Update CLI to set default `changed: true` when no files provided in lib/cleo_quality_review/cli.rb (handled in Runner)

**Checkpoint**: User Story 1 complete - explicit files work without git filtering, `--changed` works explicitly

---

## Phase 4: User Story 2 - Choose Output Format (Priority: P2)

**Goal**: All three output formats work correctly

**Independent Test**: Run same review with `--format human`, `--format agent`, `--format github` and verify each produces correctly formatted output

### Tests for User Story 2

No new tests needed - existing formatter tests cover this functionality. Verify with:
- [x] T019 [US2] Verify test/formatters/agent_test.rb passes
- [x] T020 [US2] Verify test/formatters/github_test.rb passes
- [x] T021 [US2] Verify test/human_formatter_test.rb passes

### Implementation for User Story 2

No implementation needed - output formats are already complete per research.md.

**Checkpoint**: User Story 2 verified - all formats work correctly

---

## Phase 5: User Story 3 - Filter Tools (Priority: P2)

**Goal**: Users can include only specific tools or exclude tools from analysis

**Independent Test**: Run `check_quality --only reek lib/` and verify only Reek runs; run `check_quality --exclude flog lib/` and verify Flog is skipped

### Tests for User Story 3

- [x] T022 [P] [US3] Add test: `--only` filters to specified checks in test/runner_test.rb (already covered by existing --checks tests)
- [x] T023 [P] [US3] Add test: `--exclude` removes specified checks in test/runner_test.rb
- [x] T024 [P] [US3] Add test: invalid tool name in `--only` returns error in test/runner_test.rb (existing in check_registry_test.rb)
- [x] T025 [P] [US3] Add test: `--only` and `--exclude` combined in test/runner_test.rb

### Implementation for User Story 3

- [x] T026 [US3] Implement check exclusion logic in Runner in lib/cleo_quality_review/runner.rb
- [x] T027 [US3] Add validation for invalid tool names in Runner in lib/cleo_quality_review/runner.rb (handled by CheckRegistry)
- [x] T028 [US3] Handle `--only` and `--exclude` combination (exclude takes precedence) in lib/cleo_quality_review/runner.rb

**Checkpoint**: User Story 3 complete - tool filtering works correctly

---

## Phase 6: User Story 4 - Compare Against Main Branch (Priority: P3)

**Goal**: `--changed` flag explicitly triggers git diff comparison

**Independent Test**: Create branch with changes, run `check_quality --changed`, verify only changed files analyzed

### Tests for User Story 4

- [x] T029 [P] [US4] Add test: `--changed` with no git changes shows "no files" message in test/runner_test.rb

### Implementation for User Story 4

- [x] T030 [US4] Add user-friendly message when `--changed` finds no files in lib/cleo_quality_review/runner.rb (returns empty target_files, formatter handles display)

**Checkpoint**: User Story 4 complete - explicit `--changed` flag works correctly

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation

- [ ] T031 Run full test suite with `bundle exec rake test`
- [ ] T032 Manual test: `exe/check_quality --help` shows all new flags
- [ ] T033 Manual test: `exe/check_quality --only reek lib/cleo_quality_review/cli.rb`
- [ ] T034 Manual test: `exe/check_quality --exclude flog lib/cleo_quality_review/cli.rb`
- [ ] T035 Manual test: `exe/check_quality --changed`
- [ ] T036 Manual test: `exe/check_quality lib/cleo_quality_review/cli.rb` (no git filter)
- [ ] T037 Verify agent format JSON matches contracts/agent-output.md schema
- [ ] T038 Update quickstart.md if any examples need correction in specs/001-code-quality-review/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (Phase 3): Can proceed first
  - US2 (Phase 4): Independent, verification only
  - US3 (Phase 5): Can proceed in parallel with US1
  - US4 (Phase 6): Depends on US1 (uses same TargetResolver changes)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundational → US1 (core file targeting)
- **User Story 2 (P2)**: Independent - verification only
- **User Story 3 (P2)**: Foundational → US3 (tool filtering)
- **User Story 4 (P3)**: Foundational + US1 → US4 (builds on changed flag)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation follows TDD cycle
- Story complete before moving to next priority

### Parallel Opportunities

- T005, T006, T007 can run in parallel (test files for different flags)
- T012, T013, T014 can run in parallel (different test scenarios)
- T022, T023, T024, T025 can run in parallel (different test scenarios)
- US1 and US3 can be worked in parallel after Foundational

---

## Parallel Example: Foundational Phase

```bash
# Launch all foundational tests together:
Task T005: "Add test for --only alias parsing in test/options_test.rb"
Task T006: "Add test for --exclude flag parsing in test/options_test.rb"
Task T007: "Add test for --changed flag parsing in test/options_test.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (spec alignment)
2. Complete Phase 2: Foundational (new flags parse)
3. Complete Phase 3: User Story 1 (explicit vs changed files)
4. **STOP and VALIDATE**: Test `check_quality lib/file.rb` vs `check_quality --changed`
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → All flags parse correctly
2. Add User Story 1 → Explicit file targeting works → Demo
3. Add User Story 3 → Tool filtering works → Demo
4. Add User Story 4 → Explicit `--changed` flag → Demo
5. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution requires tests for all behavior changes
