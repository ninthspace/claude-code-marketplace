# No Bulk Edits, Clarity Over Speed

**Date**: 2026-04-17
**Status**: Complete

## Context

CPM implementation skills (do, quick, pivot) had speed-first guidelines that could encourage bulk programmatic edits or rushing through changes. Added shared implementation guidelines prohibiting sed/perl/awk for file edits and establishing clarity/correctness as the priority over speed, then aligned individual skill guidelines with this convention.

## Acceptance Criteria

- `skill-conventions.md` contains an "Implementation Guidelines" section that prohibits `sed`/`perl`/`awk` via Bash for file edits and requires Edit tool file-by-file — Met
- `skill-conventions.md` states that clarity and correctness take precedence over speed — Met
- `quick/SKILL.md` guideline no longer presents speed as the primary value — Met
- `do/SKILL.md` guideline balances momentum with correctness — Met
- `pivot/SKILL.md` guideline balances lightness with correctness — Met

## Changes Made

- `cpm/shared/skill-conventions.md` — Added "Implementation Guidelines" section with two subsections: "No bulk programmatic edits" and "Clarity and correctness over speed"
- `cpm/skills/quick/SKILL.md` — Changed "Fast by default" to "Lean by default, correct by design"
- `cpm/skills/do/SKILL.md` — Changed "Keep momentum" to "Keep momentum, but not at the cost of correctness"
- `cpm/skills/pivot/SKILL.md` — Changed "Lighter than re-running" to "Lighter than re-running, but correct"

## Verification

Grepped each file for the expected content. All criteria confirmed present at the correct locations.

## Retro

**Smooth delivery**: Change delivered as planned with no surprises. The shared conventions pattern made this clean — one authoritative section with three skill-level references.
