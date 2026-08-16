# Two more ungated writes, and the gate check goes corpus-wide

**Date**: 2026-08-12  
**Status**: Complete

## Context

`docs/quick/30-quick-spec-writing-steps-gate-spec.md` fixed this defect in `spec` and left the check
scoped to one file. Auditing the other 22 skills — every heading block that proposes, writes rows,
and is reached by no gate — turned up two more, and tightening the gate marker mid-run turned up a
third.

Coverage is derived from the file rather than transcribed, in three clauses:

- a block **gates itself**, naming `AskUserQuestion`; **or**
- a `###`-or-shallower block is reached by a **blanket rule in the skill's `## Process` preamble**;  
  **or**
- it is uncovered — and a `####` block is **never** reached by a blanket rule, which is the  
  ambiguity the original defect turned on.

`epics` failed recoverably: a gate arrives at the end of `#### Approach tags`, so the run does not
stall, but `create_story_criterion` has already run and the "accept, modify or refuse" proposal is a
row before the question is asked. Its sibling block gates explicitly, which is what made this an
omission rather than deliberate reliance on Step 3's gate.

`retro` did not fail recoverably. It wrote `retro_waived_at` and `retro_waived_reason` guarded only
by the prose *"confirm before waiving"*, `retro` has no blanket rule at all — its Process preamble is
one line — and the skill says of this very write that it *"writes a waiver and does not lift one"*.

`present`'s `### 5. Record it` delegates its confirmation to the shared **Artifact Publishing**
procedure — *"separately confirmed, and never assumed from the draft having been approved"* — a real
gate the check cannot see. It is exempt with that reason recorded, following `skills-resume.test.js`,
which already carries the exempt-with-reason model.

## Acceptance Criteria

**Fix criteria** (the broken behaviour is resolved):

- `epics`' `#### Acceptance criteria` gates with `AskUserQuestion` before the criteria are written  
  `[unit]` — **Met**
- `retro`'s Step T2 gates with `AskUserQuestion` before the waiver write `[unit]` — **Met**

**Regression criteria** (the original bug cannot recur):

- Every skill `skillNames()` returns is checked, and an uncovered proposing write is reported by  
  skill and heading `[unit]` — **Met**
- Coverage is derived from the file — self-gate, or a blanket rule in the `## Process` preamble  
  reaching `###` and no deeper — rather than from a transcribed list `[unit]` — **Met**
- `present`'s `### 5. Record it` is exempt with its reason, and an exempt block that stops  
  delegating to a separately-confirmed procedure fails the check `[unit]` — **Met**
- The check is non-vacuous: an empty corpus, a block enumeration matching nothing, and a planted  
  ungated block each complain `[unit]` — **Met**

## Changes Made

- `dpm/skills/epics/SKILL.md` — `#### Acceptance criteria` gates the story's criteria with  
  `AskUserQuestion` before writing any of them, and the proposed rejections ride that gate: accept,  
  modify and refuse are the dispositions it offers.
- `dpm/skills/retro/SKILL.md` — Step T2 gates on which epics to waive and writes only what the gate  
  returns.
- `dpm/skills/archive/SKILL.md` — **not in the original scope.** Tightening the gate marker (below)  
  surfaced Phase 4's *"Gate each unit on its own"* as a gate instruction with no mechanism named,  
  the same class as the other three. Two words rather than a fourth exemption.
- `dpm/tests/support/skills.js` — `blocks()` and `ungated()`, one implementation for both scopes.
- `dpm/tests/skills-gates.test.js` — new, five tests over `skillNames()`.
- `dpm/tests/skill-spec.test.js` — its local copy replaced by the shared `ungated()`.

## Verification

`node --test "dpm/**/*.test.js"` from the repo root: **636 pass, 0 fail** (631 before).

Four mutations driven, each reverted:

| mutation | result |
|---|---|
| `retro` Step T2's gate removed | 1 fail — `retro ### Step T2: Confirm and waive proposes and writes with no gate` |
| `epics`' criteria gate removed | 1 fail — `epics #### Acceptance criteria proposes and writes with no gate` |
| heading parse changed `#{2,4}` → `#{5,6}` | 5 fail — floor names it: `0 heading blocks parsed across 23 skills` |
| the gate marker loosened to accept the bare word *gate* | **not caught** — see below |

**Two defects in the check were found by driving it, not by reading it.**

The gate marker started as `/AskUserQuestion|\bgate\b|on approval/i`, and the `epics` mutation
passed under it: removing the gate left the sentence *below* it — *"Step 3's own gate closes the
step"* — still matching. A block could lose its gate while prose explaining the gating rule kept it
green. That is retro 40's vacuous regex, in the opposite direction: the pattern matched something,
just never the thing. Tightened to `AskUserQuestion` alone, which is also the honest rule, since
soft prose is the shape the defect takes.

The corpus controls were built by copying the live corpus and adding to it, so the `retro` mutation
failed three tests rather than one and the controls' own messages said nothing about the mechanisms
they were written for. They now run on synthetic corpora — an ungated block beside a gated one, and
`present` alone for the exemption — so each names one mechanism and a real regression fails one test.

## Retro

**Testing gap**: both defects in this check survived reading and were caught only by mutation — a
gate pattern that matched neighbouring prose about gates, and controls coupled to live state that
turned one regression into three failures; a check built to catch soft prose is itself the kind of
thing that passes on soft evidence, so drive it before trusting it.
