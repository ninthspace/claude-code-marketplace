# Verification & Housekeeping

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Date**: 2026-05-28
**Status**: Complete
**Blocked by**: Epic 32-01-epic-shared-convention-alignment, Epic 32-02-epic-skill-behavioural-alignment

## Literalism & tool-use verification pass
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R6 — Literalism & tool-use verification pass

**Acceptance Criteria**:

- `spec`/`discover`/`architect` codebase-grounding sections are verified to require Read/Glob/Grep before user-facing answers; gaps remediated minimally [manual]
- "apply to every X"-style instructions across the touched skills are verified to state scope explicitly [manual]
- must NOT add new behavioural instructions — verification only; a documented no-change outcome is acceptable [manual]

### Verify codebase-grounding tool-use in spec/discover/architect
**Task**: 1.1
**Description**: Confirm each requires Read/Glob/Grep before answering; remediate minimally only if a gap exists. Covers R6 criterion 1.
**Status**: Complete

### Verify literalism scoping across touched files
**Task**: 1.2
**Description**: Check "apply to every X" instructions state scope; record findings. Verification-only, no new directives. Covers R6 criteria 2–3.
**Status**: Complete

**Retro**: [Smooth delivery] R6 was a clean no-change pass — all three grounding sections already gate exploration before facilitation/proposals, and both surviving "every X" usages were already scoped (one enumerates artifact types inline, the other is an explicit skip-if-irrelevant note). No remediation needed.

---

## Model identity bump
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R4 — Model identity bump

**Acceptance Criteria**:

- `plugin.json` description and any README references reflect Opus 4.8 [manual]
- must NOT alter `plugin.json` version or keywords; hook suite stays green [unit]

### Update plugin.json description and README model references
**Task**: 2.1
**Description**: Change the "Opus 4.7+" wording to Opus 4.8 in the manifest description and README; leave version and keywords untouched. Covers R4 criterion 1.
**Status**: Complete

### Run the hook test suite to confirm green
**Task**: 2.2
**Description**: Run `cpm2/hooks/tests/run-all-tests.sh`; confirm version `0.1.0` + keyword assertions still pass. Reuses the existing suite (retro guidance) rather than writing new tests. Covers R4 must-NOT [unit].
**Status**: Complete

**Retro**: [Testing gap] R4's version/keyword assertions stay green and the manifest bump introduced no new failures, but the full hook suite carries a pre-existing, unrelated failure — `session-start.sh` "Orphan output does not auto-execute deletion" (confirmed present with the R4 edits stashed). Out of scope for this spec (hook logic), but worth a follow-up.

---

## Over-engineering & hard-coding guardrails for do/quick
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: R7 — Over-engineering & hard-coding guardrails (could-have)

**Acceptance Criteria**:

- `do` and `quick` carry a minimal-change guardrail and a "solve generally, don't hard-code to tests" note, in positive prose [manual]
- must NOT introduce ALL-CAPS/forceful language (style fidelity holds) [manual]

### Add minimal-change + solve-generally guardrails to do and quick
**Task**: 3.1
**Description**: Insert positive-prose guardrails (scope discipline; general solutions over hard-coding to tests) into both skills, matching cpm2's existing voice. Covers R7.
**Status**: Complete

**Retro**: [Smooth delivery] Both guardrails dropped cleanly into the existing Guidelines bullet style of `do` and `quick`; positive-prose phrasing matched cpm2's voice with no ALL-CAPS needed.

---

## Lessons

### Smooth Deliveries

- Story 1 (R6): A clean no-change verification pass — all three grounding sections already gate exploration before facilitation/proposals, and both surviving "every X" usages were already scoped. No remediation needed.
- Story 3 (R7): Both guardrails dropped cleanly into the existing Guidelines bullet style of `do`/`quick` in positive prose — no ALL-CAPS required.

### Testing Gaps

- Story 2 (R4): The manifest bump kept version/keywords intact and introduced no new failures, but the full hook suite carries a pre-existing, unrelated failure — `session-start.sh` "Orphan output does not auto-execute deletion" (confirmed present with the R4 edits stashed). Out of scope for this spec (hook logic); recommend a follow-up `/cpm2:quick` to fix the orphan auto-delete behaviour.
