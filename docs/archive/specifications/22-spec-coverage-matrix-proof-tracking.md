# Spec: Coverage Matrix Proof Tracking

**Date**: 2026-02-25
**Discussion**: docs/discussions/09-discussion-coverage-matrix-proof-tracking.md

## Problem Summary

The CPM coverage matrix — created by `/cpm:epics` — maps spec requirements to story acceptance criteria as a static planning artifact. It answers "did we plan for every requirement?" but never records whether those requirements were actually proven during execution. After `/cpm:do` completes an epic, proof of requirement satisfaction lives only in the ephemeral conversation and the progress file (which is deleted post-session). There is no persistent, structured record connecting "we planned to cover requirement X" to "requirement X was verified." This spec extends the coverage matrix from a planning artifact to a living proof record, and adds invalidation rules so the proof stays trustworthy when criteria change.

## Functional Requirements

### Must Have

1. **Verification column in coverage matrix** — The coverage matrix format (produced by `/cpm:epics`) includes a "Verified" column. Initial value for all rows is empty. Verified rows display `✓`.
   - Coverage matrix template in `/cpm:epics` includes a "Verified" column
   - Initial value for all rows is empty (unverified)

2. **Story-level proof recording** — When `/cpm:do` completes a verification gate (Step 5) and all acceptance criteria pass for a story, it updates the corresponding coverage matrix rows with `✓`.
   - When `/cpm:do` verification gate passes, corresponding coverage matrix rows are updated with `✓`
   - Only rows matching the verified story (via the "Covered by" column) are updated
   - If coverage matrix doesn't exist, `/cpm:do` continues without error

3. **Epic-level proof recording** — When `/cpm:do` completes the batch summary (Step 8) and the epic-level integration check passes, it marks remaining unverified rows with `✓`.
   - When `/cpm:do` batch summary epic-level check passes, remaining unverified rows are marked `✓`
   - If the epic-level check identifies gaps, affected rows are not marked

4. **Invalidation principle in coverage document** — The coverage matrix document includes a blockquote verification rule after the metadata fields and before the table.
   - Coverage matrix includes a blockquote verification rule after metadata, before the table
   - Rule text states verification is bound to criterion text and resets on modification

5. **Write-time invalidation in `/cpm:pivot`** — When `/cpm:pivot` modifies acceptance criteria in an epic doc, it reads the companion coverage matrix and clears verification status for affected rows.
   - When `/cpm:pivot` modifies acceptance criteria, it clears `✓` from affected coverage matrix rows
   - Rows for unmodified criteria retain their verification status

### Should Have

6. **Write-time invalidation in `/cpm:epics`** — When `/cpm:epics` regenerates or modifies an epic (e.g. re-running against a revised spec), the coverage matrix verification column resets for affected rows.
   - When `/cpm:epics` regenerates an epic, the coverage matrix verification column resets for affected rows

7. **Read-time drift detection in `/cpm:do`** — During Load Context (Step 1), `/cpm:do` compares story criteria in the epic doc against the coverage matrix's "Story Criterion (verbatim)" column. If they don't match, flag the mismatch to the user.
   - During `/cpm:do` Load Context, if story criteria in epic doc differ from coverage matrix criterion text, user is flagged

### Could Have

8. **Verification summary in batch output** — After Step 8, `/cpm:do` presents a summary view of the coverage matrix's verification state as part of the batch summary report.
   - Batch summary includes a count of verified vs. total coverage matrix rows

### Won't Have (this iteration)

- **Automated checksum-based invalidation** — Text-matching checksums at read time to auto-invalidate changed criteria. The simpler write-time clearing approach is sufficient.
- **Cross-epic coverage dashboard** — An aggregated view of verification state across multiple epics.

## Non-Functional Requirements

### Data Integrity
- Verification status must never be written to the wrong row. A `✓` on row N must correspond to the story that actually verified that criterion.
- Invalidation must be row-scoped — clearing proof for Story 2's criteria must not affect Story 1's proof.

### Reliability
- If the coverage matrix file doesn't exist or can't be parsed, `/cpm:do` must degrade gracefully — log a note and continue execution. Proof tracking is additive; it must never block task execution.
- If an Edit to the coverage matrix fails (e.g. the row text doesn't match), flag the issue to the user rather than silently skipping.

### Consistency
- All skills that write to the coverage matrix must use the same column format and verification marker syntax (`✓`). No skill-specific variations.

## Architecture Decisions

### Verification Column Format
**Choice**: Single "Verified" column with `✓` (verified) or empty (unverified). No distinction between story-level and epic-level verification.
**Rationale**: Simplicity. The user cares about "was this proven?" not "at which level was it proven?" A single column keeps the table narrow and the Edit tool's string matching reliable.
**Alternatives considered**: Two separate columns (Story Verified / Epic Verified) — rejected as added complexity for marginal benefit. Single column with two-phase markers (e.g. "Story N" → "✓ Story N") — rejected as over-specific.

### Invalidation Rule Placement
**Choice**: Blockquote header note in the coverage matrix document, positioned after the metadata fields and before the table.
**Rationale**: The rule lives with the data it governs. Anyone opening the file immediately sees the contract. Skills that modify criteria can reference the document's own rule rather than carrying duplicate logic.
**Alternatives considered**: YAML front-matter field — rejected as less visible and harder for skills to reference naturally. Rule embedded only in skill files — rejected as scattered and easy to miss when adding new skills.

## Scope

### In Scope
- Coverage matrix format change in `/cpm:epics` (add Verified column + invalidation rule header note)
- `/cpm:do` verification gate writing proof to coverage matrix (Step 5)
- `/cpm:do` batch summary writing epic-level proof to coverage matrix (Step 8)
- `/cpm:pivot` clearing verification for affected rows when criteria change
- `/cpm:epics` clearing verification when regenerating (should-have)
- `/cpm:do` read-time drift detection during Load Context (should-have)
- Verification summary in batch output (could-have)

### Out of Scope
- Checksum-based automatic invalidation at read time
- Cross-epic coverage dashboard or aggregation views
- Changes to skills other than `/cpm:do`, `/cpm:epics`, and `/cpm:pivot`
- Changes to hook scripts or test infrastructure

### Deferred
- Extending proof tracking to other CPM artifacts (e.g. spec-level verification)
- Visual or reporting tooling for coverage matrix state

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. Verification column | Coverage matrix template includes "Verified" column | `[manual]` |
| 1. Verification column | Initial value for all rows is empty | `[manual]` |
| 2. Story-level proof | Verification gate pass updates corresponding rows with ✓ | `[manual]` |
| 2. Story-level proof | Only rows matching the verified story are updated | `[manual]` |
| 2. Story-level proof | Missing coverage matrix doesn't block execution | `[manual]` |
| 3. Epic-level proof | Batch summary pass marks remaining unverified rows ✓ | `[manual]` |
| 3. Epic-level proof | Rows for gap-flagged criteria are not marked | `[manual]` |
| 4. Invalidation principle | Blockquote rule present after metadata, before table | `[manual]` |
| 4. Invalidation principle | Rule text states binding to criterion text | `[manual]` |
| 5. Pivot invalidation | Modified criteria rows have ✓ cleared | `[manual]` |
| 5. Pivot invalidation | Unmodified criteria rows retain ✓ | `[manual]` |
| 6. Epics invalidation | Regenerated epic resets affected verification | `[manual]` |
| 7. Drift detection | Mismatched criteria text flagged to user | `[manual]` |
| 8. Verification summary | Batch summary includes verified/total count | `[manual]` |

### Integration Boundaries
- **`/cpm:epics` → coverage matrix file**: Epics skill creates the matrix with the new column format. Format must match what `/cpm:do` and `/cpm:pivot` expect.
- **`/cpm:do` → coverage matrix file**: Do skill reads and writes the matrix during Steps 5 and 8. Must correctly match rows by story reference in "Covered by" column.
- **`/cpm:pivot` → coverage matrix file**: Pivot skill reads the matrix when criteria change and clears affected rows. Must correctly identify corresponding rows.
- **`/cpm:do` → epic doc → coverage matrix** (drift detection): Do skill compares criterion text between epic doc and matrix. "Story Criterion (verbatim)" column must match epic doc text exactly.

### Test Infrastructure
None required. This is a SKILL.md-only change — no new test frameworks, fixtures, or CI configuration needed.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
