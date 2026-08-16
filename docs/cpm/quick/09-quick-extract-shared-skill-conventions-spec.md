# Extract Shared Skill Conventions

**Date**: 2026-03-28
**Status**: Complete

## Context

The 4 facilitation skills (spec, brief, architect, discover) had a lazy Perspectives pattern that buried roster-loading instructions at the bottom of each SKILL.md. Combined with section-level examples using generic role names ("The architect might..."), this led to the LLM inventing agent names and roles instead of using the actual roster. Extracted common procedures into a shared document loaded at session start, following the pattern already used successfully by party/consult/review.

## Acceptance Criteria

- Shared doc has Roster Loading (project override then plugin default), Perspectives pattern, and Library Check procedure — Met
- sessionstart hook outputs shared conventions into context — Met (both session-start.sh and session-start-compact.sh)
- All 4 facilitation skills reference shared Perspectives instead of duplicating the section — Met
- Section-level perspective hints use roster format (`{icon} **{displayName}**`) not generic roles like "The architect" — Met
- party/consult/review continue working unchanged (already load roster upfront) — Met

## Changes Made

- `cpm/shared/skill-conventions.md` (new) — Shared procedures for Roster Loading, Perspectives, and Library Check
- `cpm/hooks/session-start.sh` — Added 6 lines to derive plugin root and cat shared conventions
- `cpm/hooks/session-start-compact.sh` — Same addition for compaction/clear events
- `cpm/skills/spec/SKILL.md` — Added Roster Loading startup step, replaced Library Check with shared reference, updated Sections 4/5 perspective hints, removed standalone Perspectives section
- `cpm/skills/brief/SKILL.md` — Same pattern: Roster Loading startup, shared Library Check, updated Phases 2/5 perspective hints, removed Perspectives section
- `cpm/skills/architect/SKILL.md` — Same pattern: Roster Loading startup, shared Library Check, updated Phase 2 perspective hint, removed Perspectives section
- `cpm/skills/discover/SKILL.md` — Same pattern: Roster Loading startup, shared Library Check, updated Phases 1/5 perspective hints, removed Perspectives section

## Verification

- Grep confirmed all 4 skills reference shared Perspectives procedure (11 references across sections)
- Grep confirmed zero remaining standalone `## Perspectives` sections in any skill
- Grep confirmed zero remaining generic role patterns ("The architect might", "The PM might", etc.)
- Grep confirmed party/consult/review retain their own roster loading unchanged
- Both hook scripts confirmed to reference shared conventions file

## Retro

**Pattern worth reusing**: The shared conventions approach (load once at session start, reference from skills) could be extended to deduplicate other common blocks across all 10 skills — State Management, Retro Check, Output Path Convention, and Test Approach Tags all follow the same duplication pattern.
