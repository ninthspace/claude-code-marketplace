# Opus 5 Review Follow-ups

**Date**: 2026-07-25
**Status**: Complete

## Context

After spec 40 (Opus 5 alignment) closed, a review of the shipped plugin files against Anthropic's published Opus 5 guidance produced six findings. Four were small, concrete edits — two instructions the spec's own sweeps had over-removed, one clause the guidance names that CPM never carried, and an incomplete reference table — so they were applied via quick execution rather than a pivot on a completed spec. The other two findings were assessed and deliberately not acted on: `do`'s negative-only Forbidden phrasings (a deliberate behavioural lock) and R10's lack of a doc basis (context, not a defect).

## Acceptance Criteria

- The Subagent Delegation "Verification of your own work stays inline" bullet carries an explicit instruction not to use subagents to verify or double-check your own work, in addition to its rationale — **Met**
- Subagent Delegation states that one subagent is preferred over several when one suffices, and that spawn counts stay low — **Met**
- The Effort Recommendations table has one row per skill in `cpm/skills/` — 20 rows, including `audit` and `clean` — **Met**
- At least one skill is assigned the `low` effort level — **Met** (four: `archive`, `status`, `templates`, `clean`)
- The `do` scope bullet states both when to check in (different readings would lead to materially different work) and that the whole task gets finished — **Met**
- The scope bullet in `do/SKILL.md` and `quick/SKILL.md` remains byte-identical — **Met**
- The hook suite passes — **Met**

## Changes Made

- `cpm/shared/skill-conventions.md:369` — restored the imperative to the verification bullet: "Do not use subagents to verify, double-check, or second-guess something you just did," ahead of the rationale that spec 40's R10 sweep had left standing alone. The Opus 5 prompting guidance names this instruction in two separate sections as one to keep.
- `cpm/shared/skill-conventions.md` (Subagent Delegation → Rules) — added "If one subagent can complete the task, use one rather than several, and keep spawn counts low." Previously only `review/SKILL.md:142` carried a spawn cap, and only for its own fan-out.
- `cpm/shared/skill-conventions.md` (Effort Recommendations) — added `audit` (high) and `clean` (low), the two skills the table had never covered, and moved `archive`, `status`, and `templates` from medium to low. The table now has one row per skill on disk. This follows the guidance's instruction to use `low` and `medium` liberally as the primary control for token cost — the table previously had no `low` row at all.
- `cpm/skills/do/SKILL.md:472` and `cpm/skills/quick/SKILL.md:64` — restored two clauses the R6 rewrite dropped: check in "only when different readings of the request would lead to materially different work", and "Finish the whole task, and stop short of actions that are clearly beyond what was asked." Applied identically to both files.

## Verification

Hook suite run: `bash cpm/hooks/tests/run-all-tests.sh` — all suites pass, 0 failures.

Byte-identity of the scope bullet re-checked with the property 40-02 Story 4 established: `grep -rh "^- \*\*Scope\*\*: deliver what was asked" cpm/ | sort | uniq -c` reports 2 occurrences of 1 unique line. A wider `grep -rln "deliver what was asked" cpm/` confirms `do` and `quick` are still the only two carriers.

Effort table completeness checked by comparing row count against `ls cpm/skills | wc -l` — 20 and 20.

Retro 13/14's lesson (the named edit site has not been the only site, three epics running) was applied before verification rather than after: greps for other restatements of the subagent verification rule and for a second effort table both came back clean, so no further sites needed the change.

## Retro

**Pattern worth reusing**: The Effort Recommendations table had silently drifted two skills out of date, and the gap was found by a one-command comparison of its row count against `ls cpm/skills | wc -l` — a structural invariant of exactly the kind retro 14 recommended over pinned literals, and a good candidate for a hook-suite assertion so the table cannot fall behind the directory again.
