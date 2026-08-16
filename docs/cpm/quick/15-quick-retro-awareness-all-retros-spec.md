# Retro Awareness — Select Across All Retros

**Date**: 2026-06-17
**Status**: Complete

## Context

Chris flagged that CPM only ever consumed the single most-recent retro. Investigation confirmed both consumption paths — the shared *Retro Awareness* procedure (used by 9 skills) and `cpm:do`'s stronger consumption gate — read only the highest-prefix retro file, so an on-topic lesson from an older retro is silently shadowed by whatever epic happened to finish last. Reworked to select relevant observations across all retros while preserving signal.

## Acceptance Criteria

- The shared *Retro Awareness* procedure globs all retros and surfaces the most relevant observations across them, capped, with recency only as a tiebreaker — no longer reads solely the highest-prefix file. — **Met**
- The procedure states how relevance is judged (source/domain + the skill's relevant categories) and that the set is capped to honour "two sharp observations beat ten vague ones". — **Met**
- `cpm:do`'s gate considers observations from all retros; its `**Retro applied**` breadcrumb still records each observation's source retro number. — **Met**
- `cpm:review` incorporation references the selected cross-retro observations, not the most-recent file. — **Met**
- Graceful degradation unchanged: no retros → skip silently; malformed → fall back to filename context; never blocks. — **Met**
- cpm plugin version is `2.1.0` in both `plugin.json` and the marketplace entry; marketplace version is `3.2.0`. — **Met**

## Changes Made

- `cpm/shared/skill-conventions.md` — rewrote *Retro Awareness* step 2 to gather and select observations across all retros (source/domain + category relevance, recency as tiebreaker, capped to ≈3–5); updated steps 3–4 wording; added an intro paragraph explaining why newest ≠ most relevant; softened a now-stale "most recent retro file" phrase in the Retro Synthesis consumed-vs-written guard for consistency.
- `cpm/skills/do/SKILL.md` — updated the retro consumption gate step 1 to select across all retros per the shared procedure rather than consuming only the highest-prefix file; breadcrumb (step 4) already records each observation's source retro number per disposition, so provenance stays auditable.
- `cpm/skills/review/SKILL.md` — changed the "All categories" incorporation line from "the most recent retro's observations" to the selected cross-retro observations.
- `cpm/.claude-plugin/plugin.json` — version `2.0.1` → `2.1.0`.
- `.claude-plugin/marketplace.json` — cpm entry `2.0.1` → `2.1.0`; marketplace `3.1.0` → `3.2.0`.

## Verification

Grepped the three consumption-path files for "most recent retro" / "highest prefix" — the only remaining references are the new explanatory intro and the (now softened) synthesis guard, both correct by design. Confirmed versions read `2.1.0` (plugin.json + marketplace cpm entry) and `3.2.0` (marketplace top-level). No test runner applies — the change is skill-instruction prose, not executable code covered by the `cpm/hooks/tests/` suites.

## Retro

**Codebase discovery**: The "most recent retro only" limitation lived in one shared procedure plus two hardcoded overrides (`do`, `review`) — fixing the shared convention propagated to all 9 delegating skills automatically, so the blast radius was far smaller than the symptom suggested.
