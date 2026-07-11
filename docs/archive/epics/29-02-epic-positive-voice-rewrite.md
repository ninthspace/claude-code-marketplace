# Positive Voice Rewrite

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: Epic 29-01-epic-namespace-rename

## Rewrite negatives in execution chain skills
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R1 — Negative→positive rewrite

**Acceptance Criteria**:

- Every negative instruction in do, epics, ralph, and spec triaged as behaviour-shaping, hard constraint, or hint and either rewritten to positive form or preserved with inline rationale [manual]
- Positive rewrites across the four chain skills use consistent terminology for shared concepts (e.g. loop termination, acceptance criteria, progress file handling) [manual]

### Audit and rewrite negatives in do/SKILL.md
**Task**: 1.1
**Description**: 16 occurrences. Triage each, rewrite to positive, preserve load-bearing with inline rationale. Establish the positive vocabulary that epics/ralph/spec will mirror.
**Status**: Complete

### Audit and rewrite negatives in epics/SKILL.md
**Task**: 1.2
**Description**: 13 occurrences. Use consistent terminology with do/SKILL.md for shared concepts (loop termination, acceptance criteria, coverage matrix).
**Status**: Complete

### Audit and rewrite negatives in spec/SKILL.md and ralph/SKILL.md
**Task**: 1.3
**Description**: 4+4 occurrences. Align with vocabulary established in do and epics. Ralph's negatives relate to prompt hygiene (load-bearing per don't-strip list — assess each).
**Status**: Complete
**Retro**: [Pattern worth reusing] Three shared vocabulary patterns ("Bash loops lose context", "cross-project writes corrupt state", "Adoption requires CPM_SESSION_ID") emerged organically and were applied consistently across all four chain skills — a useful template for future cross-skill alignment work.

---

## Rewrite negatives in standalone skills
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R1 — Negative→positive rewrite

**Acceptance Criteria**:

- Every negative instruction in all 14 standalone skill files triaged and either rewritten or preserved with inline rationale [manual]
- No net-new negative instructions introduced in any file [manual]

### Audit and rewrite negatives in high-density standalone skills
**Task**: 2.1
**Description**: party (10), consult (9), quick (9), review (8) — 36 occurrences. These have the most negative instructions among standalone skills.
**Status**: Complete

### Audit and rewrite negatives in remaining standalone skills
**Task**: 2.2
**Description**: library (7), pivot (5), present (5), archive (5), brief (4), retro (4), status (4), architect (4), discover (3), templates (1) — 42 occurrences across 10 files.
**Status**: Complete
**Retro**: [Scope surprise] Actual occurrence count (124 across 14 standalone files) was significantly higher than the epic's estimate of 42+36=78 — the grep patterns matched more negatives than the initial audit counted.

---

## Verification pass
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: R1 — Negative→positive rewrite

**Acceptance Criteria**:

- Grep for `Don't|Do not|Never|Avoid` across all `cpm2/skills/*/SKILL.md` returns only entries with inline load-bearing rationale [manual]
- No net-new negative instructions introduced during the rewrite (diff comparison) [manual]
- Total token count across skill files has not increased versus pre-rewrite baseline [manual]

### Grep verification and token count check
**Task**: 3.1
**Description**: Confirm every remaining negative has inline rationale, no net-new negatives exist (diff), and total token count has not increased versus pre-rewrite baseline.
**Status**: Complete
**Retro**: [Smooth delivery] Verification was effectively done during Story 1 and 2 gate tasks — Story 3 was a formality that confirmed results already known.

## Lessons

### Scope Surprises

- Story 2: Actual occurrence count (124 across 14 standalone files) was significantly higher than the epic's estimate of 78 — the grep patterns matched more negatives than the initial audit counted.

### Patterns Worth Reusing

- Story 1: Three shared vocabulary patterns ("Bash loops lose context", "cross-project writes corrupt state", "Adoption requires CPM_SESSION_ID") emerged organically and were applied consistently across all four chain skills — a useful template for future cross-skill alignment work.
