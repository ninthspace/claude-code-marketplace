# Shared Conventions Realignment

**Source spec**: docs/specifications/40-spec-opus-5-alignment.md
**Date**: 2026-07-24
**Status**: Complete
**Blocked by**: —

All load-bearing Opus 5 edits to `cpm/shared/skill-conventions.md`, plus the propagation each one requires into referencing skills. Placed first because the spec's Sequencing decision is explicit that per-skill edits should write against final convention wording.

## Re-balance the Subagent Delegation convention for Opus 5
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R1 (shared half) — Subagent delegation re-balanced for Opus 5; Maintainability NFR (reversal naming)

**Acceptance Criteria**:

- `Subagent Delegation` no longer states that the model under-delegates or that fan-out is "load-bearing" [manual]
- Delegation is framed as warranted only for large, genuinely independent, parallelisable work [manual]
- An explicit "do not delegate work completable in a handful of tool calls" clause is present [manual]
- A "do not use subagents to verify or double-check your own work" clause is present [manual]
- Both the "Delegate (fan-out) when" and "Work inline when" lists are retained [manual]
- must NOT remove the "Work inline when" list or the self-contained-prompt rules [manual]
- The section names spec 32 as the spec it reverses and why, so the 29 → 32 → 40 chain reads as a deliberate sequence [manual]

*Every criterion is `[manual]`: prompt content has no runtime oracle — verification is reading the resulting instruction text.*

**Retro**: [Codebase discovery] The "fan-out is expected" framing lived at two sites — the section intro and the Delegate-list lead-in — so a single-site reading of criterion 1 would have left half the drift in place.

### Rewrite the section's framing paragraph
**Task**: 1.1
**Description**: Replaces the "spawns few subagents by default / fan-out guidance is load-bearing" claim with the Opus 5 position. Covers criteria 1–2 and carries the spec-32 reversal note.
**Status**: Complete

### Amend the fan-out and inline lists
**Task**: 1.2
**Description**: Adds the handful-of-tool-calls and no-self-verification clauses to the delegate list while leaving "Work inline when" and the self-contained-prompt rules intact. Covers criteria 3–5 and the must-NOT.
**Status**: Complete

---

## Correct the Effort Recommendations table and note
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R3 — Effort Recommendations table and effort note corrected for Opus 5

**Acceptance Criteria**:

- Effort note states thinking is **on** by default on Opus 5 and can be disabled only at effort `high` or below [manual]
- The "extended thinking is off by default" premise and the strict-adherence rationale are both removed from the note [manual]
- 4.8 strict-adherence rationales removed from every tier of the table [manual]
- The ten `xhigh` facilitation skills are re-assessed, with rationales rewritten for any level that changes [manual]
- must NOT downgrade `do`, `epics`, `ralph`, or `quick` below their coding/agentic starting point (`xhigh` for `do`/`epics`/`ralph`, `high` for `quick`) [manual]

*Decision (2026-07-24): R3's parenthetical lists `quick` among the skills retaining `xhigh`, but the table has it at `high`. Confirmed with Chris — `quick` holds at `high`; the must-NOT floor is per-skill, not a uniform `xhigh`.*

**Retro**: [Criteria gap] "The ten `xhigh` facilitation skills are re-assessed" set a direction but no destinations, so the seven new levels were a judgement call made during implementation rather than a decision the criterion carried.

### Rewrite the effort note
**Task**: 2.1
**Description**: Covers criteria 1–2 — thinking on by default, disable only at `high` or below, and removal of the off-by-default premise plus the strict-adherence rationale.
**Status**: Complete

### Re-level and re-rationalise the skill table
**Task**: 2.2
**Description**: Covers criteria 3–4 and the must-NOT floor. Re-assesses the ten `xhigh` facilitation skills; `do`/`epics`/`ralph` hold at `xhigh`, `quick` holds at `high`.
**Status**: Complete

---

## Add response-length and narration conventions
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: R4 — Response-length and narration conventions; Style Fidelity NFR

**Acceptance Criteria**:

- A new shared convention section covering conversational output is present [manual]
- The section states that default responses run longer than prior models' and that effort does not reliably shorten them, so length must be prompted explicitly [manual]
- A conciseness instruction plus a short tone reminder sit near the end of the conventions document [manual]
- Narration-cadence guidance describes the update shape wanted between `AskUserQuestion` gates, expressed as positive examples of the desired style rather than prohibitions [manual]
- Additions match CPM's positive-prose voice — no XML behavioural blocks, no ALL-CAPS, no CRITICAL/MUST framing [manual]

**Retro**: [Smooth delivery] Criterion 3's placement requirement made the two-task split fall out naturally — one section where it belonged topically, one at the document's end where the criterion asked for it.

### Add the conversational-output convention section
**Task**: 3.1
**Description**: Covers criteria 1, 2, and 4 — the length premise and the narration-cadence positive examples.
**Status**: Complete

### Place the conciseness instruction and tone reminder near the end of the document
**Task**: 3.2
**Description**: Covers criterion 3, whose placement requirement makes this a distinct edit site from Task 3.1.
**Status**: Complete

---

## Add written-deliverable length calibration
**Story**: 4
**Status**: Complete
**Blocked by**: —
**Satisfies**: R5 — Written deliverable length calibration

**Acceptance Criteria**:

- Length calibration added to the shared conventions, covering every skill that writes a file [manual]
- The instruction states that document length should match what the task needs, without padding, redundant summaries, or boilerplate sections [manual]
- The instruction reaches `present`, `audit`, `spec`, `epics`, `retro` — verified in each [manual]
- must NOT impose fixed word or section counts on any artefact template [manual]

**Retro**: [Codebase discovery] Session-start loading of the shared conventions does not make a new section bite — skills only apply a convention they point at, so a new one needs an explicit reference at each point of use.

### Add the length-calibration instruction to the shared conventions
**Task**: 4.1
**Description**: Covers criteria 1–2 and the must-NOT against fixed word or section counts.
**Status**: Complete

### Verify the instruction reaches the five highest-volume producers
**Task**: 4.2
**Description**: Covers criterion 3 — confirm `present`, `audit`, `spec`, `epics`, `retro` each pick it up, adding a reference where one is missing.
**Status**: Complete

---

## Add the self-correction narration limit
**Story**: 5
**Status**: Complete
**Blocked by**: —
**Satisfies**: R9 *(should-have)* — Self-correction narration limit

**Acceptance Criteria**:

- A shared instruction limits correction narration to errors that would change the user's conclusions or decisions [manual]
- Identical correction-narration wording present across `party`, `consult`, `discover`, `brief`, `spec`, `architect` [manual]

**Retro**: [Pattern worth reusing] Story 4's shape — one shared section plus a byte-identical one-line reference at each point of use — transferred to Story 5 unchanged, and a single grep verifies both the count and the identity the Consistency NFR asks for.

### Add the correction-narration limit to the shared conventions
**Task**: 5.1
**Description**: Covers criterion 1.
**Status**: Complete

### Propagate identical wording to the six facilitation skills
**Task**: 5.2
**Description**: Covers criterion 2 across `party`, `consult`, `discover`, `brief`, `spec`, `architect`. Identical phrasing is the criterion, so this is copy-not-paraphrase.
**Status**: Complete

---

## Verify cross-story integration for Shared Conventions Realignment
**Story**: 6
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5
**Satisfies**: Consistency NFR; Integration Boundaries — Shared → skill coherence

**Acceptance Criteria**:

- R1/R3/R4/R5/R9 wording is consistent with how `do`, `epics`, `review`, and the facilitation skills reference those conventions — verified by cross-reference after the shared edits land [manual]
- R4, R5, and R9 use identical phrasing at every site they appear [manual]
- No skill references a convention section by a name the realignment changed [manual]

*Generated despite no `[integration]` tags in this epic: the spec's Integration Boundaries section names "Shared → skill coherence … verified by cross-reference after the shared edits land" as an explicit boundary, so the work is spec-mandated rather than tag-derived.*

**Inline change**: Criterion 1 initially failed — `review/SKILL.md:142` still carried "fan-out is the expected path here, not an optional optimisation", contradicting the amended `Subagent Delegation` convention. Chris chose to close it here rather than wait for epic 40-03, so 40-03 Story 1 was delivered during this gate and marked Complete in its own epic doc with a matching breadcrumb (2026-07-24).

**Retro**: [Scope surprise] The integration story pulled in work from a downstream epic — the shared-conventions edit invalidated a line 40-03 owned, and the cross-reference check surfaced it a full epic before its planned slot.

### Cross-reference the shared edits against every referencing skill
**Task**: 6.1
**Description**: Single task; the story's three criteria are one reading pass over the skills that cite the amended conventions.
**Status**: Complete

---
