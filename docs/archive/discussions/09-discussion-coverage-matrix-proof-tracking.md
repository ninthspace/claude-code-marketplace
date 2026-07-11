# Discussion: Coverage Matrix Proof Tracking

**Date**: 2026-02-25
**Agents**: Jordan, Margot, Bella, Tomas, Casey, Priya

## Discussion Highlights

### Problem Statement
The coverage matrix (created by `/cpm:epics`) is currently a static planning artifact — it maps spec requirements to story acceptance criteria but is never updated during execution. After `/cpm:do` completes, there is no persistent record of whether requirements were actually proven. Proof currently lives only in the ephemeral conversation and the progress file (which is deleted after the session).

### Key Decision: Add Verification Tracking to the Coverage Matrix
The team unanimously agreed the coverage matrix is the natural home for proof tracking. It already owns the "planned" side of traceability (spec requirement → story criterion); extending it to own the "proven" side closes the loop.

**Objective 1**: Add a verification column to the coverage matrix, updated by `/cpm:do` during verification gates and batch summary.

**Objective 2**: Add an invalidation rule embedded in the coverage document itself — scoped at row level, not document level. If a row's story criterion changes, that row's verification status is cleared.

### Verification Granularity
Casey identified two levels of proof:
1. **Story-level verification** — individual verification gates check acceptance criteria
2. **Epic-level confirmation** — Step 8 batch summary checks the epic as a whole against the spec

The coverage matrix should capture both levels.

### Invalidation Design (Layered Approach)
The team identified the full mutation surface for epic docs:
1. `/cpm:pivot` — modifies stories and acceptance criteria directly
2. `/cpm:do` — updates status fields and adds retro observations (metadata, not criteria)
3. `/cpm:epics` — re-running against a revised spec
4. Direct user edits — outside any CPM skill

This led to a three-layer invalidation design:

**Layer 1 — Principle**: The invalidation rule lives in the coverage document itself, as a discoverable header note. Single source of truth for the rule. "Verification status is bound to the criterion text. Any modification to a criterion or its spec mapping resets that row's verification to unverified."

**Layer 2 — Write-time enforcement**: Any skill that modifies acceptance criteria (`/cpm:pivot`, `/cpm:epics`, etc.) checks the companion coverage matrix and clears verification for affected rows.

**Layer 3 — Read-time safety net**: `/cpm:do` performs a lightweight sanity check during Load Context — if story criteria in the epic doc don't match what the coverage matrix expects, flag the mismatch to the user rather than trusting stale proof. This catches out-of-band edits.

### Implementation Phasing
Jordan recommended shipping Layers 1 and 2 first, with Layer 3 (read-time validation) as a fast follow.

### Architectural Notes
- Margot: the rule should live with the data (in the coverage document), not scattered across skill files
- Bella: the write path is straightforward — coverage matrix is a markdown table, editing cells is simple string replacement via Edit tool
- Bella: git history provides the "when" — no need for timestamps in the verification column
- Tomas: row-level invalidation prevents unnecessary re-verification of unaffected stories

## Next Action
Proceed to `/cpm:spec` to formally specify the verification tracking feature.
