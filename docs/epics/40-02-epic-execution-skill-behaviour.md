# Execution Skill Behavioural Edits

**Source spec**: docs/specifications/40-spec-opus-5-alignment.md
**Date**: 2026-07-24
**Status**: Complete
**Blocked by**: Epic 40-01-epic-shared-conventions-realignment
**Retro applied**: 11 · Codebase discovery · Applied — grep for every site restating a behaviour before editing; Story 2's removal cascades into three places and Story 3 sweeps two skills, so named line numbers are not trusted as the full surface.
**Retro applied**: 11 · Pattern worth reusing · Applied — Story 4's scope-constraint instruction is written byte-identically into `quick` and `do` and verified with a single grep, reusing the shape Stories 4–5 of epic 40-01 established.
**Retro applied**: 03 · Codebase discovery · Applied — before closing Story 2, grep `ralph/SKILL.md` (override table and generated prompt) for any restatement of `do` Step 8's epic-level verification or retro flag set, since the generated prompt is the operative copy.
**Retro applied**: 03 · Pattern worth reusing · Applied — this run has no test command, so Step 5b's third precondition fires live on the epic's own gates; that is treated as evidence for Story 1's criteria rather than reading the prose alone.

Verification triage (R2) across `do`, `quick`, and `epics`, plus the scope constraint (R6) in `quick` and `do`.

**Triage finding (2026-07-24)**: The skill files were read before this breakdown. Applying the spec's artefact-production test, R2's removal surface is concentrated almost entirely in `do`. In `epics/SKILL.md` every occurrence of "confirm" is a user gate, and Step 3d/Step 4 verification produces the coverage matrix and cross-epic gap list — artefact-producing, retained. In `quick`, Step 4's criterion-by-criterion assessment feeds the completion record's `## Acceptance Criteria` and `## Verification` sections — also artefact-producing. Story 3 is therefore shaped as a triage with a documented outcome rather than an assumed deletion, following the precedent R11 sets for a documented no-change result.

**Pivot applied (2026-07-24)**: `/cpm:pivot` on R2 resolved the Step 5b retest tension in favour of retention — R2's own artefact-production test exempts the retest, because its output drives a revert of the working tree and is recorded in the `**Simplifier outcomes**:` line. R2 now lists the retest among its *retained* verifications and the spec's architecture decision gained a "Reading the rule" clause covering control-flow outputs. Story 1 was re-scoped from removal to retention accordingly, and its two removal tasks collapsed into one. R2's remaining removal is epic-level spec re-verification (Story 2) plus any "confirm/re-check before reporting" phrasing (Story 3).

## Retain the Step 5b retest and record its exemption
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2 — Verification scaffolding triage in `do`, `quick`, and `epics`

**Acceptance Criteria**:

- The Step 5b **Retest** block, its revert-on-failure branch, and the `reverted` simplifier outcome are retained unchanged [manual]
- Step 5b's third precondition is retained unchanged, including its rationale citing the retest [manual]
- An inline note records that the retest was assessed under R2's artefact-production test and exempted, so a future alignment pass can tell a deliberate retention from an oversight [manual]
- must NOT weaken any verification whose output is written to an artefact or drives a revert [manual]

*Resolution (2026-07-24)*: this story was originally scoped as a removal and blocked pending a pivot. R2 classified the Step 5b retest as model self-verification, but reading `do/SKILL.md:301,310–313` showed it is the only check catching a refactor that silently changed behaviour — and Step 5b's own third precondition says so explicitly. The pivot amended R2 rather than the skill: the retest's consumer is a revert decision and a recorded simplifier outcome, not the model's confidence, so the artefact-production test retains it. The story now records that judgement inline so it is not re-litigated.

**Retro**: [Codebase discovery] Step 5b is genuinely single-sourced in `do` — a grep of `ralph/SKILL.md` for the retest, revert, and simplifier-outcome terms returned nothing, so the coupled-restatement risk retro 03 flags applies to Step 8 rather than to the refactoring pass.

### Record the retest exemption inline in `do/SKILL.md`
**Task**: 1.1
**Description**: Covers all four criteria. The retest, its revert branch, the `reverted` outcome, and precondition 3 are all left as they stand; the only edit is a one-line note naming the exemption and its reason.
**Status**: Complete

---

## Remove epic-level spec re-verification from `do` Step 8 [plan]
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2 — Verification scaffolding triage in `do`, `quick`, and `epics`

**Acceptance Criteria**:

- Step 8 item 1's epic-level verification against the source spec is removed [manual]
- The removal carries a one-line inline rationale [manual]
- **Epic-level proof recording** is retained — remaining unverified coverage-matrix rows are still marked `✓` — with its trigger re-anchored now that the verification it was gated on is gone [manual]
- The retro-trigger flag set's "epic-level spec gap" entry (Step 8 items 2 and 3) is resolved consistently with the removal [manual]
- must NOT weaken any verification whose output is written to an artefact [manual]

*`[plan]` because the removal cascades into three places — the proof-recording trigger, the retro flag set, and the batch summary — and the re-anchoring is a design decision rather than a deletion.*

**Retro**: [Scope surprise] The epic doc's "cascades into three places" undercounted a six-site surface, and Tasks 2.1 and 2.2 turned out to be one inseparable text region rather than two edits — the task split described the reasoning, not the edit boundary.

### Remove the epic-level spec verification from Step 8 item 1
**Task**: 2.1
**Description**: Covers criteria 1–2, leaving the Epic-level proof recording sub-block in place.
**Status**: Complete

### Re-anchor epic-level proof recording
**Task**: 2.2
**Description**: Covers criterion 3 and the must-NOT. The sub-block currently fires "After the epic-level verification passes (no gaps found)" — a trigger that no longer exists after Task 2.1.
**Status**: Complete

### Resolve the epic-level spec gap trigger in the retro flag set
**Task**: 2.3
**Description**: Covers criterion 4 across Step 8 items 2 and 3, where the gap is added to the flag set and read to decide mandatory retro generation.
**Status**: Complete

---

## Triage verification language in `quick` and `epics`
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2 — Verification scaffolding triage in `do`, `quick`, and `epics`; Architecture Decision — verification triage by artefact-production test

**Acceptance Criteria**:

- Every verification site in `quick/SKILL.md` and `epics/SKILL.md` is classified by the artefact-production test: retained when its output is written into an artefact a human or downstream skill reads, removed when its only consumer is the model's own confidence [manual]
- Any "confirm/re-check before reporting" phrasing found is removed with a one-line inline rationale [manual]
- `quick`'s Step 4 criterion-by-criterion assessment, its test execution, and the completion record's `## Acceptance Criteria` and `## Verification` sections are retained unchanged [manual]
- `epics`' Step 3d coverage matrix construction and Step 4 cross-epic gap check are retained unchanged [manual]
- A no-change outcome for either skill is acceptable, recorded with its reasoning rather than left as a silent skip [manual]

**Retro**: [Codebase discovery] R2 names its removal target by phrasing — "confirm/re-check before reporting" — but `epics/SKILL.md:274` matches that wording while being a retained gate, so the artefact test rather than a phrase grep had to do the classifying, and both skills came out no-change.

### Triage `quick/SKILL.md` against the artefact-production test
**Task**: 3.1
**Description**: Covers criteria 1–3 and 5 for `quick`; the expected outcome is retention, recorded with its reasoning.
**Status**: Complete

**Triage outcome — no change (2026-07-24)**: all verification-language sites in `quick/SKILL.md` were classified against the artefact-production test and every one is retained. Roughly twenty-five are not verification at all — each `confirm` in Step 1a's diagnosis gate, Step 2's proposal gate, and Step 3's references to the *confirmed proposal* is either an `AskUserQuestion` gate or a pointer to the spec file that gate produced. The remainder are artefact-producing: Step 1a's reproduce/verify-hypothesis pair yields the diagnosis written to the progress file and presented for confirmation, and Step 4's criterion-by-criterion assessment plus its test execution feed the completion record's `## Acceptance Criteria` and `## Verification` sections. No site had the model's own confidence as its only consumer, and no "confirm/re-check before reporting" phrasing is present, so nothing was removed and no inline rationale was warranted.

### Triage `epics/SKILL.md` against the artefact-production test
**Task**: 3.2
**Description**: Covers criteria 1, 2, 4 and 5 for `epics`; same recording obligation.
**Status**: Complete

**Triage outcome — no change (2026-07-24)**: every verification-language site in `epics/SKILL.md` is retained. The `confirm` occurrences are all `AskUserQuestion` gates (Step 2 grouping, Step 3 stories, Step 3b tasks, Step 3c integration criteria, Step 3d matrix, Step 4 final) or references to what a gate already settled. Step 3d's coverage check produces the matrix and Step 4's cross-epic gap check produces the GAP list that is presented and must be resolved before proceeding — both artefact-producing, and both retained unchanged. Step 3d's regeneration-awareness rule drives the clearing of stale `✓` markers, so it is retained under the pivot's control-flow reading of the artefact test. Nothing was removed, so no inline rationale was warranted.

*Note*: `epics/SKILL.md:274` opens "Before presenting the task tree, read all per-epic coverage matrices" — surface phrasing that matches the "confirm/re-check before reporting" pattern R2 targets, but it is a first-pass comparison producing a gap list rather than a re-check of the model's own conclusion. Classification followed the artefact test, not the phrasing.

---

## Add the scope constraint to `quick` and `do`
**Story**: 4
**Status**: Complete
**Blocked by**: —
**Satisfies**: R6 — Scope constraint for `quick` and `do`

**Acceptance Criteria**:

- Both `quick` and `do` carry the scope-constraint instruction in positive prose [manual]
- The instruction states: deliver what was asked at the scope intended, make routine judgment calls without checking in, raise a better approach in a sentence and continue rather than silently transforming the task [manual]
- `quick` carries it where it governs Step 1 classification and Step 3 execution — bypassing pipeline ceremony for small changes is its entire purpose [manual]
- must NOT conflict with `do`'s existing inline-change breadcrumb behaviour [manual]

**Retro**: [Pattern worth reusing] Retro 11's propagation shape transferred again — a byte-identical instruction plus one skill-specific siting sentence at each end, with a single `grep | sort | uniq -c` proving count and identity together; the siting sentence is what let `do` satisfy the must-NOT explicitly instead of by hope.

### Add the scope-constraint instruction to `quick`
**Task**: 4.1
**Description**: Covers criteria 1–3, sited to govern Step 1 classification and Step 3 execution.
**Status**: Complete

### Add the identical instruction to `do`
**Task**: 4.2
**Description**: Covers criteria 1–2 and the must-NOT; sited so it does not conflict with the inline-change breadcrumb behaviour.
**Status**: Complete

---

## Verify cross-story integration for Execution Skill Behavioural Edits
**Story**: 5
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Satisfies**: Integration Boundaries — verification gate → coverage matrix; Maintainability NFR

**Acceptance Criteria**:

- The story verification gate's pass/fail output still feeds coverage-matrix proof recording unchanged — the gate → matrix contract is intact end to end [manual]
- All four artefact-producing verifications R2 names as retained are present: the story verification gate, its acceptance-criteria pass/fail record in the epic doc, test-command execution for tagged criteria, and coverage-matrix proof recording [manual]
- Every removal across Stories 2–3 carries an inline rationale [manual]
- R6's scope constraint does not contradict R2's retained verification steps in either skill [manual]

**Inline change**: Story 2's Step 8 rationale was extended by one clause to also cover the retro flag-set removal (2026-07-24). Criterion 3 reads "every removal", and the consolidated rationale the Story 2 plan settled on did not reach the flag-set sites — the integration gate caught what both stories' own gates had passed.

**Retro**: [Pattern worth reusing] The integration story earned its slot on a criterion no per-story gate could evaluate — criterion 3 spans Stories 2–3, so a deliberate plan-level decision to consolidate rationales only failed once both stories were done and checkable together.

### Verify the gate → coverage-matrix contract end to end
**Task**: 5.1
**Description**: Covers criteria 1–2, the boundary R2's artefact-production test exists to protect.
**Status**: Complete

### Cross-check removals and the scope constraint
**Task**: 5.2
**Description**: Covers criteria 3–4.
**Status**: Complete

---
