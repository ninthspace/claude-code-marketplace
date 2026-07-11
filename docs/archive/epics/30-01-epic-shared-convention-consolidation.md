# Shared-Convention Consolidation

**Source spec**: docs/specifications/30-spec-cpm2-post-switch-refinements.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: —

## Convert inline Library Check sections to shared references
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R1 — Library Check consolidation

**Acceptance Criteria**:

- Each of `cpm2/skills/{do,quick,epics,retro,review,party,present,consult}/SKILL.md` contains exactly one line matching `Follow the shared \*\*Library Check\*\* procedure with scope keyword` and zero inline procedure bodies (numbered steps starting with `Glob \`docs/library/\*.md\``) [manual]
- Each reference names a scope keyword matching the skill name (e.g. `do` in the `cpm2:do` reference, `quick` in the `cpm2:quick` reference) [manual]
- Section header position in each skill's flow is preserved — Library Check still fires at the same point relative to surrounding startup steps [manual]
- `cpm2/skills/library/SKILL.md` retains its expanded Library Check logic and is unchanged by this story [manual]
- must NOT: no skill loses a skill-specific deep-read instruction or timing note that was not captured in the reference-plus-one-sentence form [manual]

### Convert cpm2:do Library Check to reference form
**Task**: 1.1
**Description**: Replace the Library Check section body in `cpm2/skills/do/SKILL.md` (currently steps 1–4 with graceful-degradation and compaction-resilience notes) with the shared reference line plus one sentence on when to deep-read (during task execution when library content directly affects the current task — e.g. coding standards before writing code, architecture docs before structural decisions). Preserve the section header and its position relative to Template Hint / Test Runner Discovery.
**Status**: Complete

### Convert cpm2:quick Library Check to reference form
**Task**: 1.2
**Description**: Replace the Library Check section body in `cpm2/skills/quick/SKILL.md` with the shared reference line plus one sentence on deep-reading when library content affects the requested change. Preserve section header position.
**Status**: Complete

### Convert cpm2:epics Library Check to reference form
**Task**: 1.3
**Description**: Replace the Library Check section body in `cpm2/skills/epics/SKILL.md` with the shared reference line plus one sentence on deep-reading during Step 2 epic grouping when architecture or coding-standards docs affect epic boundaries. Preserve section header position and surrounding ADR Discovery guidance.
**Status**: Complete

### Convert cpm2:retro Library Check to reference form
**Task**: 1.4
**Description**: Replace the Library Check section body in `cpm2/skills/retro/SKILL.md` with the shared reference line plus one sentence on deep-reading when library content informs the observation synthesis (e.g. engineering principles docs when classifying smooth vs. rough deliveries). Preserve section header position.
**Status**: Complete
**Retro**: [Scope surprise] Retro skill has no startup Library Check — its only library reference is Step 3.5 "Library Write-Back" (a different procedure that feeds observations back into library docs). No change needed.

### Convert cpm2:review Library Check to reference form
**Task**: 1.5
**Description**: Replace the Library Check section body in `cpm2/skills/review/SKILL.md` with the shared reference line plus one sentence on deep-reading when reviewer personas need context from architecture or coding-standards docs. Preserve section header position.
**Status**: Complete

### Convert cpm2:party Library Check to reference form
**Task**: 1.6
**Description**: Replace the Library Check section body in `cpm2/skills/party/SKILL.md` with the shared reference line plus one sentence on deep-reading when agent personas cite documented constraints or prior decisions. Preserve section header position.
**Status**: Complete

### Convert cpm2:present Library Check to reference form
**Task**: 1.7
**Description**: Replace the Library Check section body in `cpm2/skills/present/SKILL.md` with the shared reference line plus one sentence on deep-reading when audience or format choices depend on library context (e.g. brand voice, communication guidelines). Preserve section header position.
**Status**: Complete

### Convert cpm2:consult Library Check to reference form
**Task**: 1.8
**Description**: Replace the Library Check section body in `cpm2/skills/consult/SKILL.md` with the shared reference line plus one sentence on deep-reading when the chosen expert's domain intersects with documented constraints or prior decisions. Preserve section header position.
**Status**: Complete
**Retro**: [Codebase discovery] The consult skill's Library Check used scope keyword `party` instead of `consult` — a copy-paste bug from when it was forked from party. Fixed as part of the consolidation.

### Verify Library Check consolidation via grep
**Task**: 1.9
**Description**: Run `grep -rn "Glob.*docs/library/\*\.md" cpm2/skills/` and confirm the only remaining match is in `cpm2/skills/library/SKILL.md`. Run `grep -rn "Follow the shared \*\*Library Check\*\*" cpm2/skills/` and confirm 12 matches (8 from this story plus the 4 pre-existing references in brief/architect/spec/discover). This is the `[manual]` verification for R1.
**Status**: Complete
**Retro**: [Scope surprise] Expected 12 shared references but got 11 — retro had no startup Library Check (only Library Write-Back), so 7 conversions + 4 pre-existing = 11. Remaining Glob match in retro is the Write-Back step (different procedure). Verification passes.

---

## Convert inline Roster Loading sections to shared references
**Story**: 2
**Status**: Complete
**Retro**: [Smooth delivery] All three skills converted cleanly. Post-loading introductions (review team count, party roster display, consult agent selection) preserved as separate sentences after the shared reference — correctly distinguished from the loading procedure itself.
**Blocked by**: —
**Satisfies**: R2 — Roster Loading consolidation

**Acceptance Criteria**:

- Each of `cpm2/skills/{review,party,consult}/SKILL.md` contains exactly one line matching `Follow the shared \*\*Roster Loading\*\* procedure` and zero inline procedure bodies (numbered steps starting with `Project override`) [manual]
- Section header position in each skill's flow is preserved [manual]
- No skill-specific context is added to the reference line — Roster Loading behaviour is uniform across skills [manual]

### Convert cpm2:review Roster Loading to reference form
**Task**: 2.1
**Description**: Replace the Roster Loading section body in `cpm2/skills/review/SKILL.md` with the shared reference line. Preserve section header position relative to surrounding startup steps.
**Status**: Complete

### Convert cpm2:party Roster Loading to reference form
**Task**: 2.2
**Description**: Replace the Roster Loading section body in `cpm2/skills/party/SKILL.md` with the shared reference line. Preserve section header position.
**Status**: Complete

### Convert cpm2:consult Roster Loading to reference form
**Task**: 2.3
**Description**: Replace the Roster Loading section body in `cpm2/skills/consult/SKILL.md` with the shared reference line. Preserve section header position.
**Status**: Complete

### Verify Roster Loading consolidation via grep
**Task**: 2.4
**Description**: Run `grep -rn "Project override.*roster\.yaml" cpm2/skills/` and confirm zero matches. Run `grep -rn "Follow the shared \*\*Roster Loading\*\*" cpm2/skills/` and confirm 3 matches (review, party, consult). This is the `[manual]` verification for R2.
**Status**: Complete
**Retro**: [Smooth delivery] Zero inline bodies remain. 7 shared references total (3 new + 4 pre-existing in brief/architect/spec/discover).

---

## Verify token footprint reduction
**Story**: 3
**Status**: Complete
**Retro**: [Smooth delivery] 9,489-byte reduction (6.3x target) confirms the consolidation pattern is high-ROI — removing duplicated procedure bodies saves far more than expected because the bodies included graceful-degradation and compaction-resilience notes on top of the core steps.
**Blocked by**: Story 1, Story 2
**Satisfies**: Non-functional — Token Efficiency

**Acceptance Criteria**:

- Total bytes across `cpm2/skills/*/SKILL.md` decrease versus the Spec-29 baseline (commit 513656c `Complete Opus 4.7 compatibility pass for cpm2 plugin`) [manual]
- Reduction is at least 1,500 bytes (rough proxy for ~500+ tokens saved — actual token win is larger because shared text now reads as one cached region) [manual]

### Measure byte-count delta against Spec-29 baseline
**Task**: 3.1
**Description**: Run `wc -c cpm2/skills/*/SKILL.md | tail -1` before stories 1 and 2 start (capture baseline) and again after both complete. Record both numbers in the task retro. Expected delta: -1,500 bytes or more.
**Status**: Complete
**Retro**: [Smooth delivery] Baseline (commit 513656c): 180,070 bytes across 7 modified files. Current: 170,581 bytes. Delta: -9,489 bytes (6.3x the 1,500-byte target). Largest savings: consult (-2,043), party (-1,907), review (-1,709).

## Lessons

### Smooth Deliveries

- Story 1: Library Check conversion was mechanical — same pattern applied 7 times with skill-specific deep-read guidance as the only variable.
- Story 2: Roster Loading conversion required preserving post-loading introductions (review team count, party roster display, consult agent selection) as separate sentences — correctly distinguishing the loading procedure from what each skill does with the loaded roster.
- Story 3: 9,489-byte reduction (6.3x target) confirms the consolidation pattern is high-ROI — duplicated procedure bodies included graceful-degradation and compaction-resilience notes that inflated the per-skill cost.

### Scope Surprises

- Story 1: Retro skill had no startup Library Check (only Library Write-Back, a different procedure). Expected 8 conversions, delivered 7. The audit over-counted by conflating two different library-related procedures.

### Codebase Discoveries

- Story 1: Consult skill's Library Check used scope keyword `party` instead of `consult` — a copy-paste bug from when it was forked. Fixed as part of the consolidation.
