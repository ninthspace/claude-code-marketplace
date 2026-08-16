# Retro disposition: separate "not relevant here" from durable retirement

**Date**: 2026-06-24
**Status**: Complete

## Context

A `/cpm:party` discussion (`docs/discussions/22-discussion-retro-disposition-semantics.md`) surfaced that `cpm:do`'s consumption gate conflated two incompatible judgements under "Obsolete": *local irrelevance* ("doesn't apply to this work") and *global retirement* ("no longer true anywhere"). Because Obsolete durably retired the lesson at source, a local judgement silently destroyed still-valid lessons for every future epic. This change separates the two and gives durable retirement a deliberate home. Done via quick execution as a well-defined, pattern-following set of skill-instruction edits.

## Acceptance Criteria

- The `cpm:do` gate's three per-run dispositions are Applied / Deferred / Not relevant here, and none write a `**Retired**` marker to the source retro (all reversible, re-judged next run). — **Met** (`cpm/skills/do/SKILL.md:43,50`)
- "Not relevant here" records only an epic breadcrumb; the prior "Obsolete-as-default-button" behaviour is gone. — **Met** (`do/SKILL.md:43,49`)
- A deliberately-gated in-cycle Obsolete retire remains available in `cpm:do` — a separate confirmed action requiring a typed reason and an explicit "removes for all future runs" warning — and is the only in-cycle path that writes the durable source marker. — **Met** (`do/SKILL.md:44 (new paragraph),50`)
- `cpm:retro` recognises a `retire` action, mutually exclusive with synthesis and `learn`, that lists non-retired observations, takes a selection + confirmation preview, and writes the durable `**Retired**` marker with a reason. — **Met** (`cpm/skills/retro/SKILL.md:14-23,227-246`)
- The shared Retro Retirement convention, `cpm:ralph`'s disposition table, and `cpm/README.md` are all consistent with the new model. — **Met** (`cpm/shared/skill-conventions.md:69`, `cpm/skills/ralph/SKILL.md:230`, `cpm/README.md:273-279`)

## Changes Made

- `cpm/skills/do/SKILL.md` — Retro Check gate: three per-run dispositions (Applied / Deferred / **Not relevant here**), none mutating the source; added a deliberately-confirmed in-cycle **Obsolete** retire (typed reason + "removes for all future runs" warning) as the only in-cycle source-writing path; updated step 1 intro, step 3 options, step 4 breadcrumb values, step 5 retire logic.
- `cpm/shared/skill-conventions.md` — Retro Retirement "who retires": now lists three deliberate paths (`/cpm:retro retire`, `cpm:do` gated Obsolete, promote-to-library) and states that per-run "Not relevant here" is **not** retirement.
- `cpm/skills/retro/SKILL.md` — added the `retire` action: Input now describes three mutually exclusive modes; new "Lesson Retirement (`retire` action)" section (Steps R1/R2) mirroring `learn`; added a guideline on deliberate, reversible retirement vs per-run "Not relevant here".
- `cpm/skills/ralph/SKILL.md` — disposition table row updated to the per-run set; notes durable retirement is never auto-taken (autonomous runs only ever defer).
- `cpm/README.md` — added a `/cpm:retro retire` subsection beside `learn`.

## Verification

No tests cover skill markdown (grep of `cpm/hooks/tests/` for disposition wording was clean), so verification was by inspection. Grepped each acceptance criterion's anchor text across all five files (all matched) and swept for stale `Applied/Deferred/Obsolete` triad references (none remain). Test command: none.

## Retro

**Pattern worth reusing**: Modelling the new `/cpm:retro retire` action directly on the existing `learn` flow (gather → select → preview → write marker) kept the addition small and internally consistent — when a skill needs a sibling action, cloning the nearest established flow beats designing one fresh.
