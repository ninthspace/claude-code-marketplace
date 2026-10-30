# Lessons checked against criteria

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: —  
**Retro waived**: observations are in docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md (2026-10-30)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 2)  
**Amended**: 2026-10-30 — the amendment reference form above carries the observation's opening words, as the contract now does (spec FR6 amended; built in epic 47-07 Story 5)
**Amended**: 2026-10-30 — Stories 1-3 rewritten after review 02 (docs/reviews/02-review-lessons-checked.md): a stable reference form; scout lists and plan judges; build-practice lessons; review's lesson check moved out of the every-persona list; review derives lessons when the line is absent; recurrence covers quick records, story `**Retro**` lines and retired observations, with a walk-through handler; controls on grep criteria; an NFR2 check per story

A lesson reference, used in the `**Lessons**` line and the `**Recurrence**` marker, is one of:

- `{library path} → "{heading, verbatim}"`
- `{library path} → amendment from {retro path} → "{opening words of the observation}"`
- `{retro path} → "{opening words of the observation}"`

## plan applies bearing lessons and names them on the epic
**Story**: 1  
**Status**: Complete
**Audit**: pass (2026-10-30), 3 findings fixed — the round-3 Warning was settled by the user's decision after the last audit  
**Blocked by**: —  
**Satisfies**: FR6, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/plan/SKILL.md` says that before writing an epic's criteria, `plan` decides which library lessons and unretired retro observations bear on the epic's area. When the project holds more than 20 files in `docs/retros/`, the `scout` agent lists candidate headings and observation openings that match the files, modules or terms the epic touches, and `plan` judges which bear `[manual]`
  - Evidence: `cpm-next/skills/plan/SKILL.md:54` — decide bearing lessons before writing criteria; over 20 files in `docs/retros/`, `scout` lists candidates and `plan` judges — red: n/a — manual
- It says a lesson about what the result must satisfy or how it is checked is reflected in a criterion of the story it applies to, and a lesson about how to build is named without a criterion `[manual]`
  - Evidence: `cpm-next/skills/plan/SKILL.md:54` — a lesson about what the result must satisfy or how it is checked goes into a criterion of its story; a how-to-build lesson is named without one — red: n/a — manual
- It says each bearing lesson is named in the epic's `**Lessons**` line as a lesson reference followed by `(Story {N})` or `(build)`; the line is omitted when no lesson bears, and lessons that do not apply are not recorded `[manual]`
  - Evidence: `plan/SKILL.md:54` — `**Lessons**` line, reference then `(Story {N})` or `(build)`, a lesson listed once per story that reflects it and again as `(build)` when it also bears on building; omitted when none bears; non-applying lessons not recorded — red: n/a — manual
- It says when two lessons conflict, or a library document has been superseded, `plan` follows the newer one and records the choice in the spec's Assumptions `[manual]`
  - Evidence: `plan/SKILL.md:54` — conflicting or superseded: follow the newer, record the choice in the spec's Assumptions — red: n/a — manual
- `cpm-next/shared/artifacts.md` lists `**Lessons**` as an optional epic header field with the three reference forms and the `(Story {N})` / `(build)` suffix. Control: `grep -c '\*\*Lessons\*\*' cpm-next/shared/artifacts.md` returns 0 on the commit before and at least 1 after `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:155` lists `**Lessons**` as an optional epic header field with the three reference forms and both suffixes; `grep -c '\*\*Lessons\*\*' cpm-next/shared/artifacts.md` is 0 at `2f406b1`, 1 now — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines in `git diff -U0 -- cpm-next` read; the history grep over them returns nothing — red: n/a — manual

**Amended**: the second criterion no longer says `do` and the auditor follow a `(build)` lesson (2026-10-30) — cited: the user's decision on 2026-10-30 to drop the clause, since neither `cpm-next/skills/do/SKILL.md` nor `cpm-next/agents/auditor.md` reads the `**Lessons**` line and FR6 requires only that such a lesson needs no criterion

### Add the rule to plan
**Task**: 1.1  
**Description**: Edit step 3 **Epics** in `cpm-next/skills/plan/SKILL.md`.  
**Status**: Complete

### Add the field to the contract
**Task**: 1.2  
**Description**: Edit the epic section of `cpm-next/shared/artifacts.md`.  
**Status**: Complete

---

## review checks stories against bearing lessons
**Story**: 2  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR7, NFR2
**Audit**: pass (2026-10-30)

**Acceptance Criteria**:

- The lesson check is moved out of the bullet list every persona gets (`review/SKILL.md` step 2): that bullet keeps contradictions with an ADR, the library and the code, and the lesson check becomes a separate instruction given to one persona only, the Test Engineer or QA persona when one is picked, otherwise the persona asking "can we build it like this?". No persona is added for it `[manual]`
  - Evidence: `cpm-next/skills/review/SKILL.md:40` keeps contradictions with an ADR, the library and the code; `:42` gives the lesson check to the Test Engineer or QA when picked, otherwise the "can we build it like this?" persona; no persona added — red: n/a — manual
- The lesson instruction tells that persona to check each `(Story {N})` entry on the epic's `**Lessons**` line against a criterion in that story, and to find bearing lessons itself when the epic has no `**Lessons**` line; a bearing lesson no criterion reflects is a Warning, and a `(build)` entry needs no criterion `[manual]`
  - Evidence: `review/SKILL.md:42` — checks each `(Story {N})` entry against a criterion in that story, finds bearing lessons itself when there is no `**Lessons**` line; an unreflected lesson is a Warning; `(build)` needs no criterion — red: n/a — manual
- Control: `grep -c '\*\*Lessons\*\*' cpm-next/skills/review/SKILL.md` returns 0 on the commit before and at least 1 after; and the bullet list in step 2 no longer contains the words "retro lesson" `[manual]`
  - Evidence: `grep -c '\*\*Lessons\*\*' cpm-next/skills/review/SKILL.md` is 0 at `2f406b1`, 1 now; `grep -c "retro lesson" cpm-next/skills/review/SKILL.md` is 0 now — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Move the lesson check to one persona
**Task**: 2.1  
**Description**: Edit step 2 of `cpm-next/skills/review/SKILL.md`.  
**Status**: Complete

---

## do reports a recurring failure
**Story**: 3  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR16, NFR2
**Audit**: pass (2026-10-30)

**Acceptance Criteria**:

- `cpm-next/skills/do/SKILL.md` says that whenever `do` writes a retro observation, a story `**Retro**` line or an observation in a `docs/quick/` record, it checks it against the library and the retro observations it read at the start, including retired ones, and adds `**Recurrence**: {lesson reference}` when one already describes the failure `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:147` — every retro observation, story `**Retro**` line and quick-record observation is checked against the library and retro observations, retired included; `**Recurrence**: {lesson reference}` added on a match — red: n/a — manual
- It says each recurrence goes under **Found**, and a recurrence of a library lesson also goes under **Needs you**, naming the lesson and where a rule would stop it: a criterion rule in `plan`, or a check in the auditor `[manual]`
  - Evidence: `do/SKILL.md:147` — each recurrence under **Found**; a library-lesson recurrence also under **Needs you** with the lesson and where a rule would stop it (criterion rule in `plan`, auditor check) — red: n/a — manual
- The **Needs you** walk-through gains a handler for that item: give the lesson reference and the plugin file the rule would go in, and leave the change to the user, since it is made in the plugin's own repository `[manual]`
  - Evidence: `do/SKILL.md:161` — walk-through handler gives the lesson reference and the plugin file (`skills/plan/SKILL.md` or `agents/auditor.md`) and leaves the change to the user — red: n/a — manual
- `do`'s small-change paragraph applies the lesson rule of Story 1 to a quick record's criteria, by reference to it rather than restating it `[manual]`
  - Evidence: `do/SKILL.md:33` — small-change criteria reflect bearing lessons "as its **Lessons** paragraph says", by reference — red: n/a — manual
- `cpm-next/shared/artifacts.md` defines the `**Recurrence**` marker in the retro section, with the lesson reference forms. Control: `grep -c '\*\*Recurrence\*\*' cpm-next/shared/artifacts.md` returns 0 on the commit before and 1 or more after `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:180` defines `**Recurrence**` in the retro section using the lesson reference forms; `grep -c '\*\*Recurrence\*\*' cpm-next/shared/artifacts.md` is 0 at `2f406b1`, 1 now — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; the history grep returns nothing — red: n/a — manual

### Add the recurrence rule and its handler to do
**Task**: 3.1  
**Description**: Edit **Finishing**, the walk-through and the small-change paragraph in `cpm-next/skills/do/SKILL.md`.  
**Status**: Complete

### Add the marker to the contract
**Task**: 3.2  
**Description**: Edit the retro section of `cpm-next/shared/artifacts.md`.  
**Status**: Complete

---
