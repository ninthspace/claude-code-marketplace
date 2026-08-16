# Discussion: Optimising the `cpm:ralph` Loop Prompt

**Date**: 2026-07-27
**Agents**: Margot (Software Architect), Elli (Technical Writer), Tomas (QA Engineer)

**Status**: observations recorded for later review — no change made, no decision taken.

## The artefact under review

`cpm/skills/ralph/SKILL.md`, Step 2. The epic-mode template line is **2,858 characters** and is
fed back verbatim by the stop hook on every iteration (default cap 50). Spec mode substitutes two
clauses into that line — phase clause **984**, completion clause **844** — for an assembled
**3,656**. NFR5 of spec 45 states the figure is a *measurement, not a target*.

Sentence-level size audit of the template line:

| chars | clause |
|---|---|
| 483 | the `cpm:do` retro consumption gate — **restates** the category split in full |
| 227 | the `cpm:do` Change Type Decision gate |
| 198 | counts beside the promise, never inside the tag |
| 175 | what "task complete" means |
| 164 | what counts as a failure for the 3-strike skip rule |
| 150 | ambiguous criteria → mark the story Blocked |
| 140 | never derive the verdict; never emit the promise without running the command |
| 121 | the `cpm:epics` gate — **references** its Autonomous Mode branch, "never restate its rules here" |
| 108 | amend only on a citable contradiction; record a Pivot deferred breadcrumb |
| 95 | make all decisions autonomously |
| ~500 | the epic-scope completion clause (inside the 687-char trailing segment) |

## Observations

### 1. The citable contradiction — restate vs. reference (Margot)

`cpm/skills/do/SKILL.md:56` states that the autonomous category split "is the single source of
truth, so `cpm:ralph` references it rather than maintaining its own list." The template maintains
its own list anyway, in **483 characters**. Two sentences later the `cpm:epics` gate is handled by
reference in **121** — *"take cpm:epics' Autonomous Mode branch, and never restate its rules
here."* One file, two policies, and the expensive one contradicts a source that explicitly claims
ownership.

**Proposed change**: collapse the retro clause to the `cpm:epics` shape. Roughly **−360
characters**, and it removes a copy that can drift from the skill it copies.

### 2. Ordering: the exit condition arrives last (Elli)

The most important instruction in the prompt — how the loop ends — sits at the end, after ~2,100
characters of gate handling. Every iteration is a fresh arrival for the reader, so the reader
meets retro-gate rules before the exit condition.

### 3. The completion clauses duplicate ~340 characters (Elli)

Epic mode and spec mode share two near-identical sentences: *never work that verdict out yourself
from the records*, and *put the counts on their own line beside the promise, never inside the
tag*. Written twice, in a document that spent a story arguing for single-sourcing. If the
reference pattern is right for `cpm:epics`, it is right here.

### 4. The trim is cheap to make and unfalsifiable today (Tomas)

The restatement is not currently doing nothing — the question is whether the category rules are in
context *at the moment the gate fires*. They are: the gate lives inside `cpm:do`, and the loop
invokes `/cpm:do`, so its SKILL.md loads. **That is an argument, not evidence.** Nothing in the
suite can distinguish a working loop from a broken one — spec 45's suites verify that instructions
are present, ordered, and consistent with the script, never that a loop obeys them.

**Position**: make the edit, but not before one real spec-mode run exists to compare against.

## Where the team landed

Agreement that the restate/reference inconsistency is the optimisation worth making, with Margot
and Elli extending it to the duplicated completion sentences — and Tomas holding the trigger,
because the prompt's behaviour has never been observed and a trim is exactly the kind of change
nothing currently in the repository would catch.

## Open questions for the reviewer

1. Does the retro-gate restatement earn its 483 characters, given `cpm:do` claims ownership of the  
   rule and is loaded when the gate fires?
2. Should the two shared completion sentences be single-sourced, and if so where — they must reach  
   the model literally, since the prompt is fed back as a plain user turn outside any skill.
3. Is "exit condition first" worth the churn, given four suites locate the template by its opening  
   sentence and two assert its stated length?
4. Does any of this move before a live loop has been run once?
