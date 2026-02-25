# Coverage Matrix: Proof Recording & Invalidation

**Source spec**: docs/specifications/22-spec-coverage-matrix-proof-tracking.md
**Epic**: docs/epics/20-epic-proof-recording-invalidation.md
**Date**: 2026-02-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | 2. Story-level proof | When `/cpm:do` verification gate passes, corresponding coverage matrix rows are updated with `✓` | When `/cpm:do` verification gate (Step 5) passes for a story, the corresponding coverage matrix rows (matched via "Covered by" column) are updated with `✓` in the Verified column | Story 1 | `[manual]` | ✓ |
| 2 | 2. Story-level proof | Only rows matching the verified story (via the "Covered by" column) are updated | Only rows matching the verified story are updated — other stories' rows are untouched | Story 1 | `[manual]` | ✓ |
| 3 | 2. Story-level proof | If coverage matrix doesn't exist, `/cpm:do` continues without error | If the coverage matrix file doesn't exist, `/cpm:do` continues without error and logs a note | Story 1 | `[manual]` | ✓ |
| 4 | 3. Epic-level proof | When `/cpm:do` batch summary epic-level check passes, remaining unverified rows are marked `✓` | When `/cpm:do` batch summary (Step 8) epic-level integration check passes, remaining unverified rows in the coverage matrix are marked `✓` | Story 2 | `[manual]` | ✓ |
| 5 | 3. Epic-level proof | If the epic-level check identifies gaps, affected rows are not marked | If the epic-level check identifies gaps, affected rows are not marked verified | Story 2 | `[manual]` | ✓ |
| 6 | 5. Pivot invalidation | When `/cpm:pivot` modifies acceptance criteria, it clears `✓` from affected coverage matrix rows | When `/cpm:pivot` modifies acceptance criteria in an epic doc, it reads the companion coverage matrix and clears `✓` from affected rows | Story 3 | `[manual]` | ✓ |
| 7 | 5. Pivot invalidation | Rows for unmodified criteria retain their verification status | Rows for unmodified criteria retain their `✓` verification status | Story 3 | `[manual]` | ✓ |
| 8 | 7. Drift detection | During `/cpm:do` Load Context, if story criteria in epic doc differ from coverage matrix criterion text, user is flagged | During `/cpm:do` Load Context (Step 1), if story criteria in the epic doc differ from the coverage matrix's "Story Criterion (verbatim)" column, the mismatch is flagged to the user | Story 4 | `[manual]` | ✓ |
| 9 | 8. Verification summary | Batch summary includes a count of verified vs. total coverage matrix rows | Batch summary includes a count of verified vs. total coverage matrix rows | Story 2 | `[manual]` | ✓ |
