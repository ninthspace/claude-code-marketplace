# plan, review and status read what recurred

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 48-01-epic-signal-contract  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## plan and review read lessons, recurring signals and unretired legacy observations
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR6, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/plan/SKILL.md`'s **Lessons** paragraph and `cpm-next/skills/review/SKILL.md`'s context step and lesson check read library lessons, recurring signals and unretired legacy retro observations, and accept a signal reference in a `**Lessons**` line `[manual]`
  - Evidence: `cpm-next/skills/plan/SKILL.md:51` (**Lessons**) reads library lessons, recurring signals and unretired legacy retro observations; `cpm-next/skills/review/SKILL.md:25` (context) reads recurring signals too and `:40` (lesson check) finds them and accepts an entry that is a lesson or a signal reference; the contract (`artifacts.md:161`) already lets a `**Lessons**` line cite a signal reference — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Edit plan and review
**Task**: 1.1  
**Description**: Edit the **Lessons** paragraph of `plan/SKILL.md` and step 1 and the lesson check of `review/SKILL.md`.  
**Status**: Complete

---

## status checks that signals are being written
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30), 5 findings fixed  
**Blocked by**: —  
**Satisfies**: FR7, FR8, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/status/SKILL.md` reports as a suspect record a story with no `**Signal**` that has any of: an indented `- Not met:` line, a ` — blocked:` note, or an `**Audit**` line with findings fixed; it applies this only in an epic where another story holds a `**Signal**:` field (a line starting with that text, not a template quoted in prose), or when the story isn't `Complete`. Control: a `Complete` story whose `**Audit**` reads `pass` with no findings fixed, and a `Complete` story in an epic where no other story holds a `**Signal**:` field, are not reported `[manual]`
  - Evidence: `cpm-next/skills/status/SKILL.md:24` reports a story with no `**Signal**` that has an indented `- Not met:` line, a ` — blocked:` note or an `**Audit**` line with findings fixed, checked only in an epic where another story holds a `**Signal**:` field, or when the story isn't `Complete` (the criterion's cut-off amended: an epic where another story holds a `**Signal**:` field, or a story that isn't `Complete`); a `pass` with no findings fixed is not suspect, and a `Complete` story in an epic where no other story holds a `**Signal**:` field is not checked — red: n/a — manual
- It lists signals marked ` — raised` with no ` — promoted` or ` — declined` mark under **Needs you** as promotion candidates awaiting the user `[manual]`
  - Evidence: `status/SKILL.md:21` lists signals marked ` — raised` with no ` — promoted` or ` — declined` mark as promotion candidates awaiting the user, under the waiting items that reach **Needs you** — red: n/a — manual
- It reports the count of unretired legacy retro observations (bullets under a retro's `## Observations` with no `**Retired` marker) with `/cpm-next:library learn` while any remain, no longer reports a `Complete` epic without a retro, and its **Next** no longer says "once retros have accumulated". Control: `grep -c "Retro waived" cpm-next/skills/status/SKILL.md` returns 1 at `70c789c` and 0 after `[manual]`
  - Evidence: `status/SKILL.md:23` reports the count of unretired legacy observations (bullets under `## Observations` with no `**Retired` marker) with `/cpm-next:library learn`; **Gaps** (`:22`) no longer reports a `Complete` epic without a retro; **Next** (`:35`) says `library learn` while legacy retro observations or raised signals wait. `grep -c "Retro waived" cpm-next/skills/status/SKILL.md`: 1 at `70c789c`, 0 now — red: n/a — manual
- The front matter still reads `model: haiku` and `effort: low` `[manual]`
  - Evidence: `cpm-next/skills/status/SKILL.md` front matter reads `model: haiku` and `effort: low` — red: n/a — manual

**Amended**: the first criterion's cut-off is another story's signal in the epic or a story that isn't `Complete` (2026-10-30) — cited: `docs/specifications/48-spec-learning-at-recurrence.md:43` (back-filling is Won't Have), and `docs/epics/47-07-epic-after-release-fixes.md:15`, a `Complete` story with findings fixed and no signal in an epic that sorts after the Pending 47-06, which an epic-order cut-off would report
**Pivot deferred**: FR8's suspect-record test is narrowed to epics where another story holds a signal, or stories not Complete; closed stories with findings fixed are never checked in a one-story epic or an epic where `do` wrote no signal at all → docs/specifications/48-spec-learning-at-recurrence.md (Story 2, 2026-10-30) — cited: `docs/specifications/48-spec-learning-at-recurrence.md:43`

### Edit status
**Task**: 2.1  
**Description**: Edit the **Read**, **Needs you** and **Next** bullets of `status/SKILL.md`.  
**Status**: Complete

---
