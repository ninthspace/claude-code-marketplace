# Coverage Matrix Format

**Source spec**: docs/specifications/22-spec-coverage-matrix-proof-tracking.md
**Date**: 2026-02-25
**Status**: Complete
**Blocked by**: —

## Add Verified column and invalidation rule to coverage matrix format
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: 1. Verification column, 4. Invalidation principle

**Acceptance Criteria**:
- Coverage matrix template in the Output section includes a "Verified" column after "Spec Test Approach", with initial value empty for all rows `[manual]`
- Coverage matrix template includes a blockquote verification rule after the metadata fields and before the table: `> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.` `[manual]`
- Step 3d instructions reference the new column when building the coverage matrix `[manual]`
- The invalidation rule text is included in the template, not just described in prose `[manual]`

### Update coverage matrix template in Output section
**Task**: 1.1
**Description**: Add "Verified" column to the table header and template rows in the Coverage Matrix Artifacts section. Add blockquote verification rule between metadata fields and table.
**Status**: Complete

### Update Step 3d instructions
**Task**: 1.2
**Description**: Update the Step 3d coverage matrix building instructions to include the Verified column (empty initial value) when constructing the matrix during the production loop.
**Status**: Complete

**Retro**: [Smooth delivery] Both tasks were straightforward template edits to a single file — well-scoped with no surprises.

---

## Add regeneration invalidation to `/cpm:epics`
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: 6. Epics invalidation

**Acceptance Criteria**:
- When `/cpm:epics` regenerates an epic that has an existing coverage matrix, the Verified column is cleared for affected rows `[manual]`
- Instructions specify checking for an existing coverage matrix before overwriting `[manual]`

### Add regeneration check to Step 3d
**Task**: 2.1
**Description**: Add instructions to Step 3d to check for an existing coverage matrix when regenerating an epic. If found, clear the Verified column for affected rows before overwriting.
**Status**: Complete

**Retro**: [Smooth delivery] Single-task story, single-paragraph addition — clear scope made this trivial.

## Lessons

### Smooth Deliveries
- Story 1: Both tasks were straightforward template edits to a single file — well-scoped with no surprises.
- Story 2: Single-task story, single-paragraph addition — clear scope made this trivial.
