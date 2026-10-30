# library learn promotes from signals

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 48-01-epic-signal-contract  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## learn works from recurring signals and legacy retros
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 7 findings fixed — the round-3 Warning was fixed after the last audit and accepted unaudited by the user (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR5, FR7, FR9, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/skills/library/SKILL.md` Learn collects recurring `project` signals with no ` — promoted` or ` — declined` mark and unretired legacy retro observations, proposes the owning layer for each, writes `project` lessons with a `**Class**` (chosen by the slug rule for a legacy observation) and the contract's `**Source**` form, marks promoted signals ` — promoted` and declined ones ` — declined`, and lists `process` candidates without writing them `[manual]`
  - Evidence: `cpm-next/skills/library/SKILL.md:33-:36` (Learn steps 1-4) collect every recurring signal, `project` or `process`, with no ` — promoted` or ` — declined` mark and every unretired legacy observation; propose the owning layer; write `project` lessons (and observations about this codebase) in the contract's form with a `**Class**` chosen by the contract's slug rule, legacy observations included; mark promoted signals and declined ones (a second multi-select question collects the declines, `project` signals only); and list a `process` signal or an observation naming a cpm-next rule as a candidate with its file and step, writing and marking nothing for it — red: n/a — manual
- It skips a lesson whose `**Class**` and rule are already in the library, and reports it as already promoted; an older lesson with no `**Class**` is compared by reading. Control: two signals of one class and rule from different epics produce one lesson, not two `[manual]`
  - Evidence: `library/SKILL.md:34` (step 2) and `:36` (step 4) do not write a lesson whose `**Class**` and rule are in the library, or whose `**Recurrence**` names one, compare a lesson with no `**Class**` or an older retro-path-only amendment by reading, and still mark the signals promoted or retire the observation. Control: two signals of one class and rule from different epics are one lesson, since the second matches the first's `**Class**` and rule — red: n/a — manual
- `library/SKILL.md` holds the retro observation bullet form, the `**Retired` marker and the legacy recurrence rule, taken from `cpm-next/shared/artifacts.md` at `70c789c` and worded for reading existing retros only; line 10's pointer, the `learn` row's done-when and the front-matter description name signals as well as retros `[manual]`
  - Evidence: `library/SKILL.md:38` (**Legacy retros**) holds the observation bullet form with its category groups, the `**Retired` marker and the `**Recurrence**` rule, taken from `artifacts.md` at `70c789c` (`git show 70c789c:cpm-next/shared/artifacts.md`) and worded for existing retros; `:10` (pointer), the `learn` row (`:19`) and the description (`:3`) name signals as well as retros — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Edit Learn and take over the retro format
**Task**: 1.1  
**Description**: Edit the description, the pointer, the argument table and Learn in `library/SKILL.md`.  
**Status**: Complete

---
