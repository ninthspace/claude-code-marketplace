# Test Infrastructure & Smoke Verification

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Pending
**Blocked by**: Epic 31-04-epic-deliverable-generation, Epic 31-05-epic-pipeline-handoffs

## Test harness for skill structural assertions
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: Spec §6d (test infrastructure) — provides the harness that hosts the auto-generated structural tests from prior epics.

**Acceptance Criteria**:

- `cpm2/hooks/tests/test_audit_skill.sh` exists and is executable using existing `test-helpers.sh` patterns `[manual]`
- Auto-generated structural tests from Epics 31-01..05 (commit SHA capture, deliverable structure, citation format, scale values, no-padding placeholder absence, scoped consistency, effort aggregates, plugin version, library wrapper path) are integrated into the suite `[manual]`
- Test suite is discovered and runs cleanly via the existing test runner `[manual]`
- All structural tests pass after Epics 31-01..05 are complete `[manual]`

### Create test harness file
**Task**: 1.1
**Description**: Create `cpm2/hooks/tests/test_audit_skill.sh` using the same patterns as the existing `test_*.sh` files in that directory — source `test-helpers.sh`, define test functions with descriptive names, register them with the runner. Covers the harness-existence criterion.
**Status**: Pending

### Integrate auto-generated structural tests
**Task**: 1.2
**Description**: Move or link the auto-generated structural tests from Epics 31-01..05 into `test_audit_skill.sh` so they live in one suite. Tests cover: commit SHA header (1.5 in 31-02), deliverable path (1.2 in 31-04), deliverable structure (2.2 in 31-04), citation format (3.2 in 31-04), scale values (4.2 in 31-04), no-padding placeholder absence (5.3 in 31-04), scoped consistency (6.2 in 31-04), effort aggregates (7.2 in 31-04), plugin version (1.4 + 2.3 in 31-01), library wrapper path (1.4 in 31-05). Covers the integration criterion.
**Status**: Pending

### Verify suite runs cleanly via existing test runner
**Task**: 1.3
**Description**: Confirm that the existing test runner in `cpm2/hooks/tests/` discovers and runs `test_audit_skill.sh` without modification. If discovery requires an update (e.g. an explicit registration), make the minimal change. Run the full suite and confirm pass status. Covers the runner-discovery and pass criteria.
**Status**: Pending

---

## Manual smoke verification
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: Spec §6 (testing strategy) — covers the dominant `[manual]` verification surface for behavioural criteria.

**Acceptance Criteria**:

- `/cpm2:audit` runs successfully on this repository (claude-code-marketplace), producing a deliverable at `docs/audits/{nn}-audit-{slug}.md` `[manual]`
- `/cpm2:audit` runs successfully on a Laravel fixture project, detecting Laravel + PHP and invoking appropriate tooling `[manual]`
- `/cpm2:audit` runs successfully on a Python fixture project, detecting Python and invoking appropriate tooling `[manual]`
- Non-negotiables verified during smoke runs: `file:line (symbol)` citations present, "Things that look bad but are actually fine" section present, no-padding rule observed (no "Nothing material" placeholders), no-rewrites rule observed (no full-rewrite phrasings) `[manual]`
- All four pipeline handoff options (library, spec, quick, done) exercised at least once across the smoke runs `[manual]`

### Prepare Laravel and Python fixture projects
**Task**: 2.1
**Description**: Identify or create Laravel and Python fixture projects suitable for smoke testing. The fixtures should have at least one stack-tool gap (e.g. missing `larastan` or `mypy`) to exercise graceful degradation. Document the fixture paths.
**Status**: Pending

### Run smoke test on this repository
**Task**: 2.2
**Description**: Run `/cpm2:audit` on the claude-code-marketplace repo. Inspect the produced deliverable for orient phase coverage, sweep completeness, citation format, structure, and non-negotiables. Document observed findings count, durations, and any gaps. Covers criteria 1 and 4.
**Status**: Pending

### Run smoke test on Laravel fixture
**Task**: 2.3
**Description**: Run `/cpm2:audit` on the Laravel fixture. Confirm Laravel + PHP both detected; confirm `larastan`/`pint`/`composer audit` invocation (or graceful degradation if any missing). Document results. Covers criterion 2.
**Status**: Pending

### Run smoke test on Python fixture
**Task**: 2.4
**Description**: Run `/cpm2:audit` on the Python fixture. Confirm Python detected; confirm `pip-audit`/`ruff`/`mypy` invocation (or graceful degradation). Document results. Covers criterion 3.
**Status**: Pending

### Verify non-negotiables and exercise all four pipeline handoffs
**Task**: 2.5
**Description**: Across the three smoke runs, exercise each handoff option (library, spec, quick, done) at least once. Confirm: library handoff produces wrapper entry; spec handoff invokes `/cpm2:spec` with the audit path; quick handoff invokes `/cpm2:quick` with the audit path; done ends cleanly. Document handoff outcomes. Covers criterion 5.
**Status**: Pending

---
