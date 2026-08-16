# Durable Obsolete — Retire Retro Lessons at the Source

**Date**: 2026-06-17
**Status**: Complete

## Context

Follow-on from #15 (cross-retro selection): widening selection to all retros increases the chance a stale lesson resurfaces. `cpm:do` already had an **Obsolete** disposition, but it only wrote a breadcrumb to the epic doc — the source retro was untouched, so the lesson reappeared and had to be dismissed again every run. This makes Obsolete durable. Sibling feature #3 (promote-to-library) was escalated to `/cpm:spec` and reuses the retirement marker introduced here.

## Acceptance Criteria

- A shared **Retro Retirement** convention exists, defining the marker format and stating that retired observations are excluded from *Retro Awareness* selection; marker is co-located, greppable, reversible. — **Met**
- *Retro Awareness* step 2 excludes any observation carrying a Retired marker when selecting across retros. — **Met**
- `cpm:do`'s **Obsolete** disposition writes the retirement marker to the source retro file (durable); the per-run epic breadcrumb is retained; **Applied**/**Deferred** never write to the source retro. — **Met**
- Autonomous mode behaviour unchanged (auto-defer only → never retires). — **Met** (autonomous path still auto-defers; only Obsolete retires, and it cannot occur without a human disposition)
- cpm plugin version is `2.2.0` (plugin.json + marketplace entry); marketplace version is `3.3.0`. — **Met**

## Changes Made

- `cpm/shared/skill-conventions.md` — added the **Retro Retirement** convention (in-place `**Retired {YYYY-MM-DD}**: {reason}` marker, exclusion from selection, who retires, per-observation granularity with `cpm:archive` for whole-file retirement); updated *Retro Awareness* step 2 to exclude retired observations.
- `cpm/skills/do/SKILL.md` — extended the consumption gate: the **Obsolete** disposition now retires the lesson at its source (new step 5) in addition to the epic breadcrumb; clarified that Applied/Deferred never write to the source retro; aligned step 2 wording with the cross-retro selection.
- `cpm/.claude-plugin/plugin.json` — version `2.1.0` → `2.2.0`.
- `.claude-plugin/marketplace.json` — cpm entry `2.1.0` → `2.2.0`; marketplace `3.2.0` → `3.3.0`.

## Verification

Grepped the edited files to confirm: the **Retro Retirement** convention and marker format are present; *Retro Awareness* step 2 excludes `**Retired` observations; `cpm:do` step 5 writes the marker on Obsolete only. Confirmed versions read `2.2.0` (plugin.json + marketplace cpm entry, line 46) and `3.3.0` (marketplace top-level). No test runner applies — skill-instruction prose, not executable code.

## Retro

**Pattern worth reusing**: The durable-retirement mechanism was a small, in-place marker rather than a new state store — co-locating the retirement decision with the lesson it retires kept it greppable, reversible, and gave #3 (promote-to-library) a primitive to build on instead of inventing its own.
