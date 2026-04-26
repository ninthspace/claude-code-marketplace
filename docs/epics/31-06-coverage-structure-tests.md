# Coverage Matrix: Test Infrastructure & Smoke Verification

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Epic**: docs/epics/31-06-epic-structure-tests.md
**Date**: 2026-04-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

> **Note**: Epic 31-06 provides verification infrastructure rather than satisfying spec functional requirements directly. The spec FRs it supports (#5, #11, #12, #13, #14, #16 must-NOT, #17, #19, #20) are covered in the matrices of Epics 31-01..05. This matrix tracks the test-infrastructure obligation from Spec §6d.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| §6d | Test Infrastructure | Existing `cpm2/hooks/tests/` framework (bash + `test-helpers.sh`) extended by a new test suite covering the structural `[unit]` criteria. No new framework needed. Captured as a story for `cpm2:epics`: "Plugin manifest + skill structure tests" covering criteria #5, #11, #12, #13, #14, #16 (must-NOT), #17, #19, #20. | `cpm2/hooks/tests/test_audit_skill.sh` exists and is executable using existing `test-helpers.sh` patterns | Story 1 | (infrastructure) | |
| §6d | Test Infrastructure | (same) | Auto-generated structural tests from Epics 31-01..05 are integrated into the suite | Story 1 | (infrastructure) | |
| §6d | Test Infrastructure | (same) | Test suite is discovered and runs cleanly via the existing test runner | Story 1 | (infrastructure) | |
| §6d | Test Infrastructure | (same) | All structural tests pass after Epics 31-01..05 are complete | Story 1 | (infrastructure) | |

Story 2 is end-to-end smoke verification — exercises all spec requirements behaviourally as part of the dominant `[manual]` verification surface, not as discrete coverage rows.
