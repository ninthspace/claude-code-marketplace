# Construction Prose Removed from Four Skills

**Date**: 2026-07-28
**Status**: Complete

## Context

`cpm/skills/ralph/SKILL.md` was reviewed for content describing how the document came to
be rather than what the skill does. It had it, and so did three other skills. This record
holds the sweep's evidence; CLAUDE.md holds the rule it produced.

The distinction used throughout: **operation** is what the skill does, plus the rationale a
maintainer needs in order not to break a rule. **Construction** is the document's
biography — what a past spec decided, what used to be in a step, why an earlier design was
wrong, why a paragraph is worded as it is. The test is not "prose versus instructions" but
what the sentence is *about*.

## What was removed

| File | Passages | Bytes | Before → after |
|---|---:|---:|---|
| `cpm/skills/ralph/SKILL.md` | 12 | 2,017 | 51,131 → 49,114 |
| `cpm/skills/do/SKILL.md` | 2 | 757 | 74,499 → 73,740 |
| `cpm/skills/review/SKILL.md` | 1 | 268 | 26,237 → 26,120 |
| `cpm/skills/inspect/SKILL.md` | 1 | 279 | 13,777 → 13,688 |

Three of the four non-ralph passages were added in `6088274` (spec 40's Opus 5 alignment);
the fourth in `177c61f` (spec 42's retirement). Both commits were removing or overruling
something and wrote the removal into the skill as they went. Two of ralph's twelve were
added in the same session that later removed them.

Not every passage was deleted outright. Where one carried a live claim inside a historical
wrapper, the claim was restated without the history:

- `ralph:94` — an incident narration became a general property: *"A hook can be installed  
  and registered throughout a run in which it deletes the state file at the first iteration  
  boundary — step 2 passes the whole time."*
- `review:167` — a spec-32 Won't-Have citation became the reason the cap sits in curation  
  rather than in finding: *"a cap the finders can see is a cap they stop short of, and what  
  goes unfound cannot be curated back."*
- `inspect:259` — *"An earlier version of this skill resolved provenance mechanically…"*  
  became the property itself: a join that links every file to some record is reproducible,  
  says nothing, and reports that emptiness as "no orphan changes".
- `do:380` needed nothing relocated. Its tail appeared to carry a live fact — that the retro  
  flag set takes no epic-level spec gap — but `do:351` defines that set as a closed list of  
  five signals. A sentence saying a closed enumeration does not contain something only makes  
  sense as a record that it once did.

## Why scanning did not find it

Two metrics were run before anything was read. Both ranked clean files at the top and missed
every passage that was actually construction.

| Metric | Top-ranked skill | Verdict on reading |
|---|---|---|
| Citations of numbered artefacts (`retro N`, `spec N`, `Story N`, `ADn`) | `epics`, 20 hits | Clean — all 20 are template placeholders and cross-reference formats |
| Bolded-commentary volume (`^\*\*` lead-ins as % of file bytes) | `ralph` 39%, `status` 27%, `epics` 24% | `status`' 25 commentary paragraphs are all operational instructions |

ralph did rank first on the second metric, but its problem was narrative paragraphs rather
than commentary density, so the ranking was right for the wrong reason and gave no way to
tell `status` apart from it. Both metrics scored the four `do`/`review`/`inspect` passages
below every clean file.

This is a specific instance of a general rule: a grep is a proxy for a quality judgement,
not a substitute for one.

## Test coupling

Every candidate was checked against `cpm/hooks/tests/` before removal. None of the four
non-ralph passages was pinned; the single `Spec 32` hit is unrelated prose in
`fixtures/coverage-baseline-46.tsv`. The only bounded slice over the three files —
`test-target-fails-closed.sh:68`, spanning `do`'s criterion-assessment list — is nowhere
near either cut.

ralph was the opposite case and worth recording: **seven bounded `sed` slices across four
suites**, where deleting a paragraph inside one changes its non-empty line count and can
trip a `min` bound. All seven were mapped before any cut and all seven stayed in range.

Two apparent prose pins turned out to be **comments rather than assertions** —
`test-ralph-autonomous-wiring.sh:103` ("around 1100") and
`test-ralph-two-phase-prompt.sh:15` ("Story 5 runs the command"). A third was the reverse: a
heading was load-bearing while its body was not, because
`test-ralph-promise-modes.sh:125` builds a mutated fixture with
`awk '/^#### One promise per mode/ {...}'`.

## Changes Made

- Four skill files edited; 3,321 bytes removed net of the restatements above.
- `CLAUDE.md` — added "A SKILL.md is not a change log": the rule, the test that decides it,  
  and the reach argument.

No test was modified. `run-all-tests.sh` green throughout.

## Retro

**Codebase discovery**: the generator is a false analogy with a rule that is correct.
Several skills instruct their *runtime output* to record a decided absence — `do` records a
skipped Step 5b pass and its reason in the progress file, logs a retro auto-skip reason, and
reports "No criteria amended" rather than omitting the block. Each of those has a specific
next reader who would otherwise misread silence as "did not happen". The failure is applying
the same instinct to the skill file one directory over, usually in the same session, usually
right after a spec removed something. A coverage-matrix note is read once, by the next
person working that epic; a skill note is loaded on every invocation, in every project the
plugin is installed in.

**Pattern worth reusing**: the clean skills are the ones no recent spec has cut anything out
of. Removal is what generates this content, so the review is worth running after a spec that
retires or overrules something, not on a schedule.
