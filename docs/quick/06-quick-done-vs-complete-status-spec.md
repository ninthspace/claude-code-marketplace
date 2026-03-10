# Fix "Done" vs "Complete" Status Drift in cpm:do

**Date**: 2026-03-10
**Status**: Complete

## Context

The LLM executing `cpm:do` sometimes marked completed story status as "Done" instead of "Complete". The skill's prose used "done" ambiguously near status-update logic, causing the LLM to follow semantic intent rather than the exact status value.

## Acceptance Criteria

- Line 243's AskUserQuestion option says "mark the task as Complete" instead of "mark the task as done" — Met
- Line 436's guideline avoids "done" as a status synonym — Met

## Changes Made

- `cpm/skills/do/SKILL.md` line 243 — Changed "mark the task as done anyway" to "mark the task as Complete anyway"
- `cpm/skills/do/SKILL.md` line 436 — Changed "Acceptance criteria are the definition of done" to "Acceptance criteria gate completion" with explicit `Complete` status reference

## Verification

Grep confirmed both lines now use the exact status value `Complete`. All CPM test suites pass (68/68).

## Retro

**Smooth delivery**: Straightforward prose fix — two targeted edits to eliminate status value ambiguity.
