# Add "Raise a new spec" option to cpm:pivot preamble

**Date**: 2026-02-22
**Status**: Complete

## Context

Follow-on from the party mode discussion and the previous quick execution (01-quick-pivot-completion-awareness). The team identified that when pivoting a completed spec, users may need a fresh specification rather than just new epics. This adds a third handoff option to the completion-aware preamble, following the same lightweight pattern as the existing cpm:epics handoff.

## Acceptance Criteria

- The preamble intent question includes a third option: "Raise a new spec" with cpm:spec handoff — Met
- The option is documented as only appearing when the amended document is a spec — Met
- The handoff follows the same pattern as the existing cpm:epics handoff — Met

## Changes Made

- `cpm/skills/pivot/SKILL.md` — Added "Raise a new spec" as third option in the preamble AskUserQuestion (line 81), with conditional visibility note. Updated the handoff instruction paragraph (line 83) to cover both "Pivot forward" and "Raise a new spec" paths. Renamed the existing "Pivot forward (new iteration)" to "Pivot forward (new epics)" for clarity against the new option.

## Verification

Re-read of the preamble section (lines 72-89) confirmed all three options are present, the spec-only condition is documented inline, and the handoff paragraph covers both forward paths with the same "tell user to run" pattern.
