# do records signals and finds recurrences

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 48-01-epic-signal-contract  
**Lessons**: docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion promised that `do` and the auditor would follow a lesson" (build)  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## do writes a signal where a failure is found, and stops writing retros
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR1, FR2, FR7, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/skills/do/SKILL.md` writes a `**Signal**` on the story, or in the `docs/quick/` record, when an audit finding holds, when a story is marked blocked (in step 5 and in **When to stop**, including blocked on a test failure), and when it writes an `**Amended**`, `**Inline change**` or `**Pivot deferred**` line (**When a criterion looks wrong**); one per class per story; a `process` signal names the cpm-next file and step `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:105` (**Signals**) writes a `**Signal**` on the story or in the `docs/quick/` record when an audit finding holds, when a story is marked blocked and when an `**Amended**`, `**Inline change**` or `**Pivot deferred**` line is written, one per class per story, a `process` signal naming the cpm-next file and step; the triggers are tied in at step 5 (`:54`), **When to stop** (`:119`) and **When a criterion looks wrong** (`:125`, `:129`); the small-change paragraph (`:31`) sends signals to the record — red: n/a — manual
- Before writing a slug, `do` greps `^\*\*Signal\*\*:` lines in `docs/epics/`, `docs/archive/epics/` and `docs/quick/`, library `**Class**` lines and the contract's seeds, and reuses one that fits `[manual]`
  - Evidence: `do/SKILL.md:105` — before writing a slug, grep the `**Signal**:` lines in `docs/epics/`, `docs/archive/epics/` and `docs/quick/`, the library's `**Class**` lines and the contract's seed slugs, and reuse one that fits — red: n/a — manual
- An unresolved finding that concerns no criterion becomes a signal, and Suggestions are not recorded. `do` writes no retro at epic completion, no `**Retro waived**`, no story `**Retro**` line, and keeps no recurrence rule for retro lines or walk-through case for a library-lesson recurrence. Control: `grep -c "Retro waived\|\*\*Retro\*\*\|recurrence of a library lesson" cpm-next/skills/do/SKILL.md` returns at least 1 at `70c789c` and 0 after `[manual]`
  - Evidence: `do/SKILL.md:54` records an unresolved finding that concerns no criterion as a signal; `:101` says Suggestions are neither fixed nor recorded; step 6 no longer adds a `**Retro**` line and Finishing has no retro, `**Retro waived**` or recurrence paragraph and no walk-through case for a library-lesson recurrence. `grep -c "Retro waived\|\*\*Retro\*\*\|recurrence of a library lesson" cpm-next/skills/do/SKILL.md`: 6 at `70c789c`, 0 now — red: n/a — manual
- `cpm-next/skills/do/worktree.md` has each subagent report the failures it met (a test failing for a reason it can't explain, a criterion it can't meet, a wording fix it made) for the lead to record as signals `[manual]`
  - Evidence: `cpm-next/skills/do/worktree.md:20` (the report bullet) has each subagent report the failures it met (a test failing for a reason it can't explain, a criterion it can't meet, a wording fix it made) for the lead to record as signals — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines of `git diff -U0` read; the history grep over them returns nothing — red: n/a — manual

### Add signal capture and remove the retro steps
**Task**: 1.1  
**Description**: Edit the small-change paragraph, step 5, the Audit section, **When to stop**, **When a criterion looks wrong**, Finishing and the walk-through of `do/SKILL.md`, and the subagent report in `worktree.md`.  
**Status**: Complete

---

## do finds a recurrence and routes it
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30), 5 findings fixed — the round-3 Warning was fixed after the last audit and accepted unaudited by the user (2026-10-30)  
**Blocked by**: Story 1  
**Satisfies**: FR3, FR4, FR5, FR6, FR11, NFR2  
**Effort**: high

**Acceptance Criteria**:

- After writing each signal, separately for each signal on a story, `do` checks in order: a library lesson with that `**Class**` (or one that describes the failure, for a lesson with none); a signal with that slug in a different epic or quick record, `docs/archive/` included; an unretired legacy retro observation; it reads both to confirm and appends the contract's ` — recurs:` suffix with a one-clause reason. A rejected `**Class**` or signal match gives the signal a different slug, matched once more under that slug, and a rejected description match carries on down the order. Control: a match within the same epic, or a rejected match, adds no suffix `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:109` (**Signals**, after writing each signal, separately) checks in order a library lesson with that `**Class**` (or one describing the failure, for a lesson with none), a signal with that slug in a different epic or quick record with `docs/archive/` included, and an unretired legacy retro observation; reads both to confirm; appends the ` — recurs:` suffix with a one-clause reason; a match within the same epic is not a recurrence; a rejected `**Class**` or signal match gives a different slug, matched once more, and a rejected description match carries on down the order; the legacy observations are read once per run or, with more than 20 retro files, `scout` lists those matching the signal's terms — red: n/a — manual
- A recurring `project` signal with no library lesson, whose matches carry no ` — declined` or ` — promoted` mark, goes under **Needs you** with the matching signals and the proposed constraint, and is marked ` — raised` when listed; a `process` signal and a recurrence of a library lesson go under **Found** only. A new signal matching a declined one is marked declined too and not raised. Control: a signal never matched, or matching a declined or promoted one, is not put to the user `[manual]`
  - Evidence: `do/SKILL.md:111` — a recurring `project` signal with no library lesson and no match carrying ` — declined` or ` — promoted` goes under **Needs you** with the matches and the constraint, marked ` — raised`; a signal matching a declined one is marked declined and not raised; a `process` signal and a recurrence of a library lesson go under **Found** only; a signal that never recurs is never reported — red: n/a — manual
- On a yes the walk-through writes an entry to `docs/library/lessons-learned.md` in the contract's form, creating the file with its front-matter when missing and updating its `scope` union and `last-reviewed`, and marks the matched signals promoted; on a no it marks them declined. It writes no amendment to any other library document `[manual]`
  - Evidence: `do/SKILL.md:151` (walk-through) on a yes writes an entry in the library's `lessons-learned.md` in the contract's form unless the library already holds a lesson with that `**Class**` or one describing the rule, creating the file with front-matter, adding to `scope` and setting `last-reviewed` (an existing file with no front-matter keeps its header), and marks the candidate and each signal it matched promoted; on a no marks them declined; a signal that matches a candidate still waiting for its answer, or a signal listed with or joined to it, joins it (`do/SKILL.md:111`) and gets its mark, and one matching an answered candidate takes the answer (declined after a no; under **Found** after a yes); it writes no amendment to any other library document — red: n/a — manual
- **Before the first story** reads library lessons, recurring signals and unretired legacy retro observations `[manual]`
  - Evidence: `do/SKILL.md:35` (**Before the first story**) reads library lessons, signals that recur and unretired legacy retro observations; the retro-line recurrence rule is gone (`grep -c "\*\*Recurrence\*\*" cpm-next/skills/do/SKILL.md` is 0; the phrase "recurrence of a library lesson" no longer appears in `do/SKILL.md`, so Story 1's control (`grep -c "Retro waived\|\*\*Retro\*\*\|recurrence of a library lesson"`) still returns 0) — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Add matching, routing and the walk-through case
**Task**: 2.1  
**Description**: Edit **Before the first story**, Finishing and the walk-through of `do/SKILL.md`.  
**Status**: Complete

---
