# Opt-in Plan Mode via [plan] Tag

**Date**: 2026-03-08
**Status**: Complete

## Context

When `/cpm:do` encountered complex tasks, it called `EnterPlanMode`/`ExitPlanMode` which created a modal interaction boundary — the user had to accept the plan, and after task completion the loop stopped instead of continuing to the next task. This replaced the default with inline planning (no mode switch) and made formal plan mode opt-in via a `[plan]` tag on story headings.

## Acceptance Criteria

### Fix criteria
- cpm:do defaults to inline planning (no EnterPlanMode/ExitPlanMode calls) for tasks whose parent story lacks a `[plan]` tag — Met
- Task loop continues uninterrupted through inline-planned tasks — Met

### Regression criteria
- Formal plan mode still available via `[plan]` tag for genuinely complex stories — Met
- cpm:epics suggests `[plan]` tag for stories that touch architecture, security, or multi-system integration — Met

## Changes Made

- `cpm/skills/do/SKILL.md` — Added `[plan]` tag detection in Step 1 (line 158); rewrote Step 3 (lines 168-194) to default to inline planning with formal plan mode only when `[plan]` tag is present on the story heading; added explicit loop continuation reminder after formal plan mode
- `cpm/skills/epics/SKILL.md` — Added `[plan]` tag suggestion guidance in Step 3 (lines 108-114) with criteria for when to apply it; added `[plan]` guideline entry (line 373) explaining its effect on cpm:do behaviour

## Verification

Read both changed files and confirmed: Step 3 defaults to inline planning without `[plan]`, formal plan mode requires `[plan]` tag, epics skill provides suggestion guidance with clear criteria (architectural, security-sensitive, multi-system integration), and the guideline entry documents the behaviour.

## Retro

**Smooth delivery**: Change delivered as planned — the fix was well-scoped to two files with clear boundaries between the producer (epics) and consumer (do) of the `[plan]` tag.
