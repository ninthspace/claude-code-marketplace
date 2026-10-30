# Rules not instances, and Pivot deferred with its command

**Source spec**: docs/specifications/48-spec-learning-at-recurrence.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 48-02-epic-signals-in-do, Epic 48-03-epic-plan-review-status  
**Lessons**: docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion promised that `do` and the auditor would follow a lesson" (build)  
**Amended**: 2026-10-30 — rewritten after review 06 (docs/reviews/06-review-learning-at-recurrence.md)

## Criteria state the rule, not an instance
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 3 findings fixed  
**Blocked by**: —  
**Satisfies**: FR12, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/plan/SKILL.md`'s **Epics** paragraph states a criterion over the rule it enforces, with the example "every export streams its rows", not "the January export streams its rows" `[manual]`
  - Evidence: `cpm-next/skills/plan/SKILL.md:47` (**Epics**) states each criterion over the rule it enforces, with the example "every export streams its rows", not "the January export streams its rows", names one case only when the requirement is about that case, says a regression for one reported input is written beside the criterion for its rule, and that a control's inputs and a floor's members name instances on purpose — red: n/a — manual
- `cpm-next/skills/review/SKILL.md`'s step 2 list flags a criterion that names an instance where the rule is meant `[manual]`
  - Evidence: `cpm-next/skills/review/SKILL.md:34` (step 2 list) flags criteria that name one instance where their requirement covers every case, with the January-export example, not counting a control's inputs or a floor's members — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Edit plan and review
**Task**: 1.1  
**Description**: Edit the **Epics** paragraph of `plan/SKILL.md` and the step 2 list of `review/SKILL.md`.  
**Status**: Complete

---

## Pivot deferred names the plan run that settles it
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR13, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/do/SKILL.md`'s **Needs you** gives each `**Pivot deferred**` item with `/cpm-next:plan {path of the upstream document}` `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:141` (**Needs you**) gives each `**Pivot deferred**` item with `/cpm-next:plan {path of the upstream document}` — red: n/a — manual
- `cpm-next/skills/status/SKILL.md` lists each `**Pivot deferred**` line with its target document and the `/cpm-next:plan {path}` command; control: `grep -c "cpm-next:plan {" cpm-next/skills/status/SKILL.md` is higher after than at `70c789c` `[manual]`
  - Evidence: `cpm-next/skills/status/SKILL.md:21` lists each `**Pivot deferred**` line with its target document and `/cpm-next:plan {path}`; `grep -c "cpm-next:plan {" cpm-next/skills/status/SKILL.md` is 1 at `70c789c` and 2 now — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Edit do and status
**Task**: 2.1  
**Description**: Edit Finishing in `do/SKILL.md` and the **Waiting on the user** bullet of `status/SKILL.md`.  
**Status**: Complete

---
