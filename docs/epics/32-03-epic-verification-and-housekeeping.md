# Verification & Housekeeping

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Date**: 2026-05-28
**Status**: Pending
**Blocked by**: Epic 32-01-epic-shared-convention-alignment, Epic 32-02-epic-skill-behavioural-alignment

## Literalism & tool-use verification pass
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: R6 — Literalism & tool-use verification pass

**Acceptance Criteria**:

- `spec`/`discover`/`architect` codebase-grounding sections are verified to require Read/Glob/Grep before user-facing answers; gaps remediated minimally [manual]
- "apply to every X"-style instructions across the touched skills are verified to state scope explicitly [manual]
- must NOT add new behavioural instructions — verification only; a documented no-change outcome is acceptable [manual]

### Verify codebase-grounding tool-use in spec/discover/architect
**Task**: 1.1
**Description**: Confirm each requires Read/Glob/Grep before answering; remediate minimally only if a gap exists. Covers R6 criterion 1.
**Status**: Pending

### Verify literalism scoping across touched files
**Task**: 1.2
**Description**: Check "apply to every X" instructions state scope; record findings. Verification-only, no new directives. Covers R6 criteria 2–3.
**Status**: Pending

---

## Model identity bump
**Story**: 2
**Status**: Pending
**Blocked by**: —
**Satisfies**: R4 — Model identity bump

**Acceptance Criteria**:

- `plugin.json` description and any README references reflect Opus 4.8 [manual]
- must NOT alter `plugin.json` version or keywords; hook suite stays green [unit]

### Update plugin.json description and README model references
**Task**: 2.1
**Description**: Change the "Opus 4.7+" wording to Opus 4.8 in the manifest description and README; leave version and keywords untouched. Covers R4 criterion 1.
**Status**: Pending

### Run the hook test suite to confirm green
**Task**: 2.2
**Description**: Run `cpm2/hooks/tests/run-all-tests.sh`; confirm version `0.1.0` + keyword assertions still pass. Reuses the existing suite (retro guidance) rather than writing new tests. Covers R4 must-NOT [unit].
**Status**: Pending

---

## Over-engineering & hard-coding guardrails for do/quick
**Story**: 3
**Status**: Pending
**Blocked by**: —
**Satisfies**: R7 — Over-engineering & hard-coding guardrails (could-have)

**Acceptance Criteria**:

- `do` and `quick` carry a minimal-change guardrail and a "solve generally, don't hard-code to tests" note, in positive prose [manual]
- must NOT introduce ALL-CAPS/forceful language (style fidelity holds) [manual]

### Add minimal-change + solve-generally guardrails to do and quick
**Task**: 3.1
**Description**: Insert positive-prose guardrails (scope discipline; general solutions over hard-coding to tests) into both skills, matching cpm2's existing voice. Covers R7.
**Status**: Pending

---
