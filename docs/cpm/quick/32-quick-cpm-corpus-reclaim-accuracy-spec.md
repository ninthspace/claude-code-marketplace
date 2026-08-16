# Correct the CPM reclaim rule in dpm's user-facing documents

**Date**: 2026-08-12  
**Status**: Complete

## Context

`dpm/README.md` told a reader adopting dpm that the first publish would report "the entire
existing corpus as orphaned", and described the rule as anything matching
`<number>-<kind>-<slug>.md` under a projected directory. `orphans()` matches a *kind token* —
`name.includes('-<kind>-')` — against **dpm's own kind names**, restricted to the kinds mapped to
that directory. CPM's word for a document is dpm's kind name for six of the twelve projected
directories and something else for the other six, so the warning was wrong in both directions of
detail. `dpm/MIGRATION.md`, written from the same premise, named four at-risk directories and
moved neither `discussions` nor `reviews` in its `git mv` — seventeen files in this repository
alone.

**The fix landed twice.** The first pass gave the README a per-directory table and had both
documents move only the directories at risk. On review that was rejected as the wrong shape:
the safe/at-risk split is a coincidence of vocabulary, one kind rename moves a directory across
it with nothing to announce the change, and a reader sorting twelve folders by a table has work
to redo on every upgrade. Both documents now state the rule and then say to move all twelve
regardless, and the check follows the instruction rather than the table.

Quick execution rather than the pipeline because it is two documents and a check, with no change
to `dpm/src`.

## Acceptance Criteria

**Fix criteria**

- The rule is stated as the code implements it — a kind token in the directory that kind maps to,  
  not a filename shape — and neither document claims the whole corpus is reported as orphaned —  
  **Met**
- Both documents move all twelve projected directories, so no reader has to judge which are at  
  risk — **Met** (supersedes the original criterion, which asked only that the `git mv` cover the  
  directories the reclaim reaches)
- Both send the corpus to `docs/cpm/`, which is not walked — **Met**

**Regression criteria**

- Adding a document kind, renaming one, or moving a `dir` mapping fails the test rather than  
  leaving the prose quietly wrong — **Met**
- A corpus with nothing at risk, or a document whose command does not parse, is a complaint rather  
  than a pass: an empty enumeration satisfies every per-directory check above — **Met**

## Changes Made

- `dpm/README.md` — the two paragraphs stating the rule are replaced by the rule as the code writes  
  it, with one collision (`spec`/`spec`) and one miss (`plan`/`problem_brief`) as illustration  
  rather than an enumeration; a **Move all twelve regardless** paragraph gives the reason; the  
  `git mv` covers all twelve and the destination changes from `docs/archive/` to `docs/cpm/`, which  
  is where `MIGRATION.md` already sent it and which does not collide with an existing  
  `docs/archive/` left by `/cpm:archive`; `docs/architecture/` is called out as never walked
- `dpm/MIGRATION.md` — the same **Move all twelve** reasoning, placed *before* the command rather  
  than after it; the `git mv` gains `discussions`, `reviews`, `communications`, `audits` and  
  `runbooks`, with a line saying `git mv` fails on a folder you do not have and that most people  
  will drop the last two
- `dpm/tests/cpm-corpus.test.js` *(new)* — four tests. `audit(inputs) → complaints` parses the  
  `git mv` out of each document, *executes* it against a synthetic tree holding one file of every  
  shape CPM writes, and complains about any directory the command missed and any file the first  
  publish would still reclaim; a second test pins the reclaim's own limits (an ADR is never  
  walked, the walk stops one level deep, a hand-kept `docs/epics/README.md` is never a candidate);  
  a third drives every complaint on an invented pair of documents with a stubbed reclaim; a  
  must-NOT holds the floors

## Verification

`node --test "dpm/**/*.test.js"` from the repository root — **640 pass, 0 fail** (636 before).

Four mutations driven and reverted, each checked to have reached the path:

| mutation | result |
|---|---|
| `docs/quick` dropped from the README's `git mv` | test 1 only, twice over — the directory is named as uncovered, *and* `docs/quick/30-quick-auth-spec.md` is named as still reclaimable |
| the README's destination changed to `docs/audits/` | test 1 only — a walked destination, and the two documents no longer agreeing |
| `orphans()`'s token `` `-${kind}-` `` → `` `_${kind}_` `` | test 1 only — *"nothing in the corpus was at risk, so the move proved nothing"*, which is the floor doing its job |
| `problem_brief` renamed to `plan` throughout the seed, making `docs/plans/01-plan-auth.md` newly reclaimable | **all four still pass** — the instruction already covers `docs/plans`, which is the argument for moving all twelve, driven rather than asserted |

The at-risk set is never transcribed into the test: one side of every reconciliation is produced by
running `orphans()`. What the test does *not* check is stated in its docblock — only the `git mv`
block of each document is parsed, and the corpus is one file per shape CPM writes.

The live figures behind the original diagnosis, from this repository's own CPM corpus: 71 of 91
`.md` files reclaimed, across six of the twelve directories.

## Retro

**Scope surprise**: the reclaim rule was read wrongly twice — once by whoever wrote the README, once
by me diagnosing it — both times by reasoning from the filename *shape* rather than running the
function, and a synthetic corpus of one file per shape settled it in a minute; but the more
expensive miss was downstream of that, because getting the six right made a per-directory table
look like the answer, when the fact that the six can change is the reason not to publish a list at
all.
