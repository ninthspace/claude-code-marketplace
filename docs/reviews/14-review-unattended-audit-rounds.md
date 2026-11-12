# Review: More audit rounds in unattended runs — epics

**Date**: 2026-11-12  
**Source**: docs/epics/57-01-epic-audit-rounds.md, docs/epics/57-02-epic-release.md  
**Reviewers**: Jordan (pm), Bella (dev), Tomas (qa)  
**Findings**: 27 (2 critical, 17 warnings, 8 suggestions), after merging duplicates across the three reports; 0 decided at challenge

## Summary

The personas were picked outside the challenge's `architect` and `test`, and each was given a copy of the spec without its **Challenge** section. No finding repeated one of the challenge's three `Rejected` decisions. All three reviewers found the same two Criticals: the step 5 floor kept the sentence that makes the third audit the last, and the walk-through's control could not fail, because every spec 56 history passed at its third audit with nothing held. Most Warnings are about routes the round record did not name (a scoped round, a whole-story audit, a settled story, an attended resume), the counts **Finishing** needs after the record is deleted, stale records, and doc places the release missed. Two findings reach the spec: deleting the record when a story is blocked loses what a settled story's next audit needs, and a whole-story audit after a pass has no rule at or past the cap or in an attended run.

## Findings

- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: criterion 1's floor keeps step 5's "Otherwise, and after any third audit, that audit is the last of this step's rounds" verbatim, which caps every run at three (`do/SKILL.md:59`)  
  → 57-01 Story 1, criterion 1
- **[Critical]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: the walk-through's control (a single-repeat Repeat stops one of (h)) cannot fail: every spec 56 third audit passed with nothing held, and the round-2 findings were new defects (`56-02:17,20,22,94,96,98`; `56-03:17,20`)  
  → 57-01 Story 1, criterion 6
- **[Warning]** 📋 **Jordan** / 🔍 **Tomas**: Rising count lost "both scoped rounds", so a whole-story audit after a snapshot mismatch or a worktree sibling's fix (`test-runs.md:73,81`) trips it; "scoped round" also names the deferred-run fix audit (`test-runs.md:77`)  
  → 57-01 Story 1, criterion 2
- **[Warning]** 📋 **Jordan** / 🔍 **Tomas**: whether the deferred-run scoped round, and a resumed `fix due` story's scoped audit (`do/SKILL.md:40`), write a record is undefined, so the count includes them  
  → 57-01 Story 1, criteria 1 and 3
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: **Changed** and **Found** need round counts after the record is deleted at close or block, with no durable source (`do/SKILL.md:10,165-166`)  
  → 57-01 Story 1, criteria 3 and 5
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Tomas**: a stop's signal "reusing the tripping finding's class" clashes with one signal per class per story (`do/SKILL.md:130`)  
  → 57-01 Story 1, criterion 2
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: nothing clears stale round records (a session dying between close and delete, a story re-planned with the same number); the restore bullet reads only `scratch/` (`do/SKILL.md:35`)  
  → 57-01 Story 1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: case (i) names no run kind; an attended resume of a story with three records has no stated outcome  
  → 57-01 Story 1, criterion 6
- **[Warning]** 🔍 **Tomas**: no case tests when the stops start or the comparison's strictness; a text starting at the second audit, or using `>=`, passes (a)–(j)  
  → 57-01 Story 1, criterion 6
- **[Warning]** 📋 **Jordan**: FR4's earlier findings, given to a whole-story audit, narrow it to those findings (`auditor.md:56`)  
  → 57-01 Story 1, criterion 4
- **[Warning]** 📋 **Jordan** / 🔍 **Tomas**: deleting the record when a story is blocked loses the count and dismissals a settled story's next audit needs (`do/SKILL.md:179`; case (j))  
  → spec FR3
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: a whole-story audit after a pass has no rule at or past the cap (unattended) or after a second audit with no Critical (attended) (`test-runs.md:73,81`)  
  → spec FR1, FR3
- **[Warning]** 🔍 **Tomas**: the record could be stated in several sections; nothing makes one place own it (the 52-01 `definition-in-two-places` failure)  
  → 57-01 Story 1, criterion 3
- **[Warning]** 🔍 **Tomas**: the "stated once" grep misses "five times" and "Repeat", and has no floor  
  → 57-01 Story 1, criterion 7
- **[Warning]** 🔍 **Tomas**: `check-cannot-fail` bears on both epics and is listed on neither; "a must-NOT … needs a floor" bears on 57-01  
  → both **Lessons** lines
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: the release's place list and search miss the later-audit inputs (`cpm-next-training-guide.html:1111`), per-round directories (`:1119`), resume (`:1038`), unattended runs (`:1166-1167`; `cpm-next-onboarding.html:524-535`; `cpm-next-presentation.html:633`), **Changed** (`:1200`) and blocked stories (`:487`)  
  → 57-02 Story 1, criterion 3
- **[Warning]** 🔍 **Tomas**: the new README bullet and Upgrading note are not read against step 5  
  → 57-02 Story 1, criterion 3
- **[Warning]** 🔍 **Tomas**: "never a fourth" = 0 passes if the sentence is deleted; no positive floor  
  → 57-02 Story 1, criterion 3
- **[Warning]** 🧑‍💻 **Bella**: the presentation's `:498` SVG text has no room for a longer rule, and the tag check won't catch an overflow  
  → 57-02 Story 1, criterion 3
- **[Suggestion]** 📋 **Jordan** / 🔍 **Tomas**: an attended third audit has no stop results to report
- **[Suggestion]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: the `guard.ts` grep is true at base and tests nothing; check the record is not under `scratch/`
- **[Suggestion]** 📋 **Jordan** / 🔍 **Tomas**: the maintenance record should name the rounds location and its coupling to the guard (`docs/maintenance/README.md:96`)
- **[Suggestion]** 🧑‍💻 **Bella**: list the history check's expected hits on single-line paragraphs (`do/SKILL.md:40,122`)
- **[Suggestion]** 🧑‍💻 **Bella**: copy the scratch directory's deletion wording for `rounds/`
- **[Suggestion]** 🧑‍💻 **Bella**: give `r{n}`'s form, and tie the auditor directory's `n` to the record's
- **[Suggestion]** 🧑‍💻 **Bella**: step 5 grows long; consider a sub-block
- **[Suggestion]** 📋 **Jordan**: the Upgrading note should give the extra Opus cost per unattended story

## Remediation

- Fixed: the floor exempts both cap sentences → 57-01 Story 1 criterion 1
- Fixed: the control is a constructed case (k), with (l) and controls for the start and `>=` → 57-01 Story 1 criterion 8
- Fixed: Rising count compares only audits scoped to earlier findings → 57-01 Story 1 criterion 3
- Fixed: the deferred-run scoped round writes no record; a `fix due` scoped audit excluded → 57-01 Story 1 criteria 1 and 4
- Fixed: a run-directory tally written before deletion → 57-01 Story 1 criteria 4 and 7
- Fixed: the stop's name appended to the existing signal → 57-01 Story 1 criterion 3
- Fixed: stale records cleared before the first story, with a control → 57-01 Story 1 criterion 5
- Fixed: case (i) in both run kinds → 57-01 Story 1 criterion 8
- Fixed: a whole-story audit gets earlier dismissals only as not-to-re-raise → 57-01 Story 1 criterion 6
- Fixed: one place owns the record; `cpm-next/rounds/` exactly once → 57-01 Story 1 criterion 4
- Fixed: the "stated once" grep widened, with a floor → 57-01 Story 1 criterion 9
- Fixed: the lessons → both **Lessons** lines
- Fixed: the release's places, search, README reading, floor per place and SVG length cap → 57-02 Story 1 criterion 3
- Fixed (Suggestions applied with fixes): the attended third audit's line, the guard grep replaced, the maintenance record bullet, the history check's expected hits, the deletion wording
- Fixed (user's decision, 2026-11-12, through `/cpm-next:plan`): the record kept until the story closes → spec FR3 amended; 57-01 Story 1 criterion 4
- Fixed (user's decision, 2026-11-12, through `/cpm-next:plan`): a whole-story audit after a pass always runs and counts, fixed only under the cap → spec FR8 added; 57-01 Story 1 criterion 2 and the walk-through's cases (m) and (n)
- Not acted on: the remaining Suggestions → recorded only
