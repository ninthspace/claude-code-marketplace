# Proof Recording & Invalidation

**Source spec**: docs/specifications/22-spec-coverage-matrix-proof-tracking.md
**Date**: 2026-02-25
**Status**: Complete
**Blocked by**: Epic 19-epic-coverage-matrix-format

## Record story-level proof in `/cpm:do` verification gates
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: 2. Story-level proof recording

**Acceptance Criteria**:
- When `/cpm:do` verification gate (Step 5) passes for a story, the corresponding coverage matrix rows (matched via "Covered by" column) are updated with `✓` in the Verified column `[manual]`
- Only rows matching the verified story are updated — other stories' rows are untouched `[manual]`
- If the coverage matrix file doesn't exist, `/cpm:do` continues without error and logs a note `[manual]`
- If an Edit to the coverage matrix fails, the issue is flagged to the user rather than silently skipped `[manual]`

### Add proof-writing instructions to Step 5
**Task**: 1.1
**Description**: Add instructions to Step 5 (Verify Acceptance Criteria) for writing ✓ to matching coverage matrix rows after a verification gate passes. Covers the happy path criteria — matching rows via "Covered by" column and updating only those rows.
**Status**: Complete

### Add graceful degradation for coverage matrix writes
**Task**: 1.2
**Description**: Add instructions for handling missing coverage matrix and failed Edit operations. Covers the error-path criteria — continue without blocking execution, flag Edit failures to the user.
**Status**: Complete

**Retro**: [Smooth delivery] Two focused paragraphs added to a single location in Step 5 — happy path and error path cleanly separated.

---

## Record epic-level proof in `/cpm:do` batch summary
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: 3. Epic-level proof recording, 8. Verification summary

**Acceptance Criteria**:
- When `/cpm:do` batch summary (Step 8) epic-level integration check passes, remaining unverified rows in the coverage matrix are marked `✓` `[manual]`
- If the epic-level check identifies gaps, affected rows are not marked verified `[manual]`
- Batch summary includes a count of verified vs. total coverage matrix rows `[manual]`

### Add epic-level proof-writing instructions to Step 8
**Task**: 2.1
**Description**: Add instructions to Step 8 (Batch Summary) for marking remaining unverified rows with ✓ after the epic-level integration check passes. Skip rows for gap-flagged criteria.
**Status**: Complete

### Add verification summary to batch output
**Task**: 2.2
**Description**: Add instructions to Step 8 for presenting a verified vs. total row count as part of the batch summary output to the user.
**Status**: Complete

**Retro**: [Smooth delivery] Two additions to Step 8 — proof recording and verification summary — cleanly separated and placed at natural points in the existing flow.

---

## Add write-time invalidation to `/cpm:pivot`
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: 5. Pivot invalidation

**Acceptance Criteria**:
- When `/cpm:pivot` modifies acceptance criteria in an epic doc, it reads the companion coverage matrix and clears `✓` from affected rows `[manual]`
- Rows for unmodified criteria retain their `✓` verification status `[manual]`

### Add coverage matrix invalidation instructions to `/cpm:pivot`
**Task**: 3.1
**Description**: Add instructions to `/cpm:pivot` cascade handling for reading the companion coverage matrix when acceptance criteria are modified and clearing ✓ from affected rows while preserving unaffected rows.
**Status**: Complete

**Retro**: [Smooth delivery] Single step added to the existing cascade walk — natural extension point, no restructuring needed.

---

## Add read-time drift detection to `/cpm:do`
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: 7. Drift detection

**Acceptance Criteria**:
- During `/cpm:do` Load Context (Step 1), if story criteria in the epic doc differ from the coverage matrix's "Story Criterion (verbatim)" column, the mismatch is flagged to the user `[manual]`

### Add drift detection instructions to Step 1
**Task**: 4.1
**Description**: Add instructions to Step 1 (Load Context) for comparing story criteria text in the epic doc against the coverage matrix's "Story Criterion (verbatim)" column and flagging any mismatches to the user.
**Status**: Complete

**Retro**: [Pattern worth reusing] The drift detection pattern — comparing a cached artifact's text against the live document and flagging divergence — could apply to other CPM artifacts that reference each other (e.g. spec vs. epic, brief vs. spec).

## Lessons

### Smooth Deliveries
- Story 1: Two focused paragraphs added to a single location in Step 5 — happy path and error path cleanly separated.
- Story 2: Two additions to Step 8 — proof recording and verification summary — cleanly separated and placed at natural points in the existing flow.
- Story 3: Single step added to the existing cascade walk — natural extension point, no restructuring needed.

### Patterns Worth Reusing
- Story 4: The drift detection pattern — comparing a cached artifact's text against the live document and flagging divergence — could apply to other CPM artifacts that reference each other (e.g. spec vs. epic, brief vs. spec).
