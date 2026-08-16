# Add completion-awareness to cpm:pivot

**Date**: 2026-02-22
**Status**: Complete

## Context

Party mode discussion identified that cpm:pivot's cascade in Step 3 had no awareness of whether downstream epics or stories were already completed. This meant users could unknowingly amend the historical record of delivered work, or miss the opportunity to generate fresh epics for a forward pivot. The change adds completion detection and an intent-routing question to the existing Step 3 structure.

## Acceptance Criteria

- Step 3 includes a preamble that checks whether all downstream epics are fully complete — Met
- When all epics are complete, the user is asked their intent: amend history vs. new iteration — Met
- "New iteration" intent skips the cascade and offers handoff to cpm:epics — Met
- During cascade, individual stories marked complete get a visible warning — Met
- Completion detection covers `[x]` checkboxes and `**Status**: done/completed` markers — Met
- No new steps added — changes fit within existing Step 3 structure — Met

## Changes Made

- `cpm/skills/pivot/SKILL.md` — Added "Completion-Aware Preamble" subsection to Step 3 with epic-level completion detection, intent question (amend history vs pivot forward), and cpm:epics handoff. Added per-story completion detection (step 3b) and completed-story warning (step 3d) to the cascade walk. Re-lettered cascade sub-steps to accommodate new items.

## Verification

Full file re-read confirmed all six acceptance criteria are met. The preamble subsection sits cleanly before the cascade walk, the intent question offers two clear paths, and per-story warnings integrate into the existing gate workflow without adding new top-level steps.
