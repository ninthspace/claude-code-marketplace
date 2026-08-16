# Retro Synthesis overwrite fix

**Date**: 2026-06-07
**Status**: Complete

## Context

A `/cpm:consult` session (discussion record 21) diagnosed that `/cpm:do` was overwriting the same retro file (e.g. `11-retro-awareness-protocol.md`) on every run instead of creating a new numbered file. Root cause: the shared Retro Synthesis write path reused the filename the startup consumption gate had loaded as "the most recent retro," rather than recomputing `{nn}` and `{slug}`. Fixed via quick execution as a two-file prompt change.

## Acceptance Criteria

### Fix criteria

- Retro Synthesis step 4 instructs deriving `{nn}` and `{slug}` fresh at write time, independent of any filename in context from a consumption/awareness read — **Met**
- `/cpm:do`'s Retro Check surfaces the selected retro's filename, `**Source**:` and `**Date**:` at the disposition gate — **Met**

### Regression criteria

- Retro Synthesis step 5 carries a no-overwrite guard: target path must not pre-exist; an existing path means `{nn}` was miscomputed → recompute, never overwrite — **Met**
- The guard is scoped: a repeated slug across runs of the same epic is explicitly called out as normal; only an existing full path is the error — **Met**

## Changes Made

- `cpm/shared/skill-conventions.md` — Retro Synthesis step 4 rewritten to "recompute both here, never inherit them," explicitly separating the consumed retro from the written retro; step 5 gained a no-overwrite guard, scoped so a recurring slug is normal and only an existing full path signals a miscomputed `{nn}`.
- `cpm/skills/do/SKILL.md` — Retro Check gate step 1 now requires naming the selected retro (filename · `**Source**:` · `**Date**:`) at the gate, so recency-only selection is visible and a mis-pick is never silent.

## Verification

Read both edited regions after the change (`skill-conventions.md` steps 4–5, `do/SKILL.md` gate step 1) and confirmed each criterion against the rendered text. No test runner applies (markdown prompt files; `Test command: none`). The core fix lives in the shared procedure that both `/cpm:do` (Step 8) and `/cpm:retro` call, so both paths are corrected by the single edit. No ADRs present.

## Retro

**Pattern worth reusing**: The original instruction stated the positive rule ("use Numbering to assign `{nn}`") but never forbade the anti-pattern it could collapse into (reusing a filename already in context from a read). Agent-prompt steps that both *read* one instance and *write* another are prone to conflating the two — stating the explicit "the file you consume is never the file you write" negative alongside the positive rule is what actually closes the gap.
