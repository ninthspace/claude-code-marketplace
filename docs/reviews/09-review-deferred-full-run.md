# Review: Spec 52 epics — the deferred full run, release

**Date**: 2026-11-10  
**Source**: docs/epics/52-01-epic-deferred-full-run.md, docs/epics/52-02-epic-release.md  
**Reviewers**: Jordan (pm), Bella (dev), Casey (test)  
**Findings**: 41 (4 critical, 29 warnings, 8 suggestions), after merging duplicates across the three reports

## Summary

Every Must Have is named by a story, the line numbers cited hold what the stories say, no two stories share a file, and the order is right. Three of the spec's mechanisms are underdefined, and one grep fails on unchanged text: the story snapshot cannot be recomputed after a commit or on resume, a batch waits forever on a story waiting on the user, and a deferred-run regression's red has no contract form, so the auditor would Warn on every one and block the story on its single scoped round. Several more gaps reach back into the spec: a `fix due` resume, the flaky run's pass, a regression a blocked batch story explains, a scoped round's count and signal, the pass comparison on a resumed baseline, the round-limit sentence, `none` closing stories, the in-run mismatch's audit, and reruns after an FR3 full run. Within the epics, greps lacked floors or matched unchanged text, controls were met by today's text, neighbour passages were unnamed, and NFR2 was unchecked.

## Findings

- **[Critical]** 🧑‍💻 **Bella** / 🧪 **Casey** / 📋 **Jordan**: the story snapshot is not computable: whether its `HEAD` line is kept, and where "the story's own paths" come from after a commit, a worktree merge or a resume, are unstated  
  → 52-01 Story 1, criterion 5 (spec FR4, FR6)
- **[Critical]** 🧑‍💻 **Bella**: a batch's shared deferred run waits on "passed or blocked", which a story waiting on the user never reaches  
  → 52-01 Story 1, criterion 7; Story 2, criterion 5 (spec FR7)
- **[Critical]** 🧑‍💻 **Bella**: the deferred-run regression's red (the failing test's text) has no form in the contract, and auditor check 5 Warns on a red that is not an undo or mutation  
  → 52-01 Story 1, criterion 6; Story 3, criterion 1 (spec FR5)
- **[Critical]** 🧪 **Casey** / 📋 **Jordan**: `grep "deferred" artifacts.md` fails on unchanged text (`**Pivot deferred**`) and cannot see the `full run due` forms  
  → 52-01 Story 1, criterion 9
- **[Warning]** 📋 **Jordan**: FR1's still checkout conflicts with a sibling's fix round in a batch  
  → 52-01 Story 1, criterion 1 (spec FR1, FR7)
- **[Warning]** 🧪 **Casey**: on resume, the pass test compares with a baseline that already holds the story's regression  
  → spec FR4, FR6
- **[Warning]** 🧑‍💻 **Bella** / 📋 **Jordan**: a `fix due` resume does not finish the fix, rerun or retake reds before its audit, and whether that audit is the scoped round is unstated; an in-run mismatch is a later audit in FR4 and a whole-story audit in FR6  
  → spec FR4, FR6
- **[Warning]** 📋 **Jordan**: whether the flaky path's second full run counts as the deferred run's pass  
  → spec FR5
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: a regression a blocked batch story explains, and the rest of a batch after a second failure, have no outcome; "the story that took the deferred run" is undefined for a shared run  
  → spec FR5, FR7
- **[Warning]** 📋 **Jordan**: a scoped round counted in `n findings fixed` with no signal makes status report the story as suspect  
  → spec FR5, FR6
- **[Warning]** 🧑‍💻 **Bella**: step 5's "that audit is the last" contradicts the scoped round  
  → spec FR5; 52-01 Story 2, criterion 2
- **[Warning]** 🧑‍💻 **Bella**: a `none` story that closes its epic: whether its run is deferred  
  → spec FR1
- **[Warning]** 🧑‍💻 **Bella**: reruns after an FR3 full run, for a story with a deferred run due  
  → spec FR3
- **[Warning]** 🧑‍💻 **Bella**: the red retake after an FR5 fix, before or after its scoped audit  
  → spec FR5
- **[Warning]** 🧑‍💻 **Bella**: worktree batches may share files, so a sibling's fix breaks a story snapshot  
  → spec AD3, FR4
- **[Warning]** 🧑‍💻 **Bella**: the pass floor's "the run's stories" and "tests" (files or cases, per runner) are open  
  → spec FR4
- **[Warning]** 🧪 **Casey**: criterion 7's "or are unchanged" lets the feature be missing  
  → 52-01 Story 1, criterion 7
- **[Warning]** 🧪 **Casey** / 📋 **Jordan**: FR1's reasons on the deferred run's `**Test run**` line have no criterion  
  → 52-01 Story 1
- **[Warning]** 🧪 **Casey** / 📋 **Jordan** / 🧑‍💻 **Bella**: FR6's `docs/quick/` clause, and a story with either form being `In Progress`, have no criterion; do:31 is not named  
  → 52-01 Stories 1 and 2
- **[Warning]** 🧪 **Casey**: the scoped prompt's contents in two places  
  → 52-01 Story 1, criterion 5; Story 2, criterion 6
- **[Warning]** 🧑‍💻 **Bella**: test-runs.md:60's mapping rule is a neighbour no criterion names  
  → 52-01 Story 1
- **[Warning]** 🧪 **Casey** / 📋 **Jordan** / 🧑‍💻 **Bella**: Story 2's no-restatement grep has no floor and misses paraphrase; its controls restate rules  
  → 52-01 Story 2, criteria 1, 2, 5 and 9
- **[Warning]** 🧑‍💻 **Bella**: do:161-163 (closing after a user's answer) are not named  
  → 52-01 Story 2
- **[Warning]** 🧑‍💻 **Bella**: the missing-note Warning's settling is open (verdict, count, where named)  
  → 52-01 Story 2, criterion 6
- **[Warning]** 📋 **Jordan**: the finish line's meaning is not kept in Story 2's line 29 criterion  
  → 52-01 Story 2, criterion 8
- **[Warning]** 🧪 **Casey** / 📋 **Jordan**: `sibling` stays in auditor check 5 and the guides  
  → 52-01 Story 3, criterion 1; 52-02
- **[Warning]** 🧪 **Casey**: the left-out exemption is named at check 5 only, not the opening (line 12)  
  → 52-01 Story 3, criterion 1
- **[Warning]** 🧪 **Casey**: Story 3 criterion 2's negative is met by today's text  
  → 52-01 Story 3, criterion 2
- **[Warning]** 🧪 **Casey**: the scoped round does not say the fix's files are in scope  
  → 52-01 Story 3, criterion 3
- **[Warning]** 🧪 **Casey** / 📋 **Jordan** / 🧑‍💻 **Bella**: status's control cannot tell the exemption from one keyed on any suffix; the next action belongs at lines 33-35, and for `fix due` it is an audit, then the run  
  → 52-01 Story 3, criterion 4
- **[Warning]** 🧪 **Casey**: NFR2 is not checked, and the maintenance record's unknown-fields line omits `**Audit**`  
  → 52-02 Story 1
- **[Warning]** 🧪 **Casey** / 📋 **Jordan**: 52-02's grep misses "full test suite" and the `**Audit**` passages  
  → 52-02 Story 1, criterion 2
- **[Warning]** 🧪 **Casey**: "A check that passes may be passing for a reason other than the one you want" bears on Stories 2 and 3 and 52-02, and "Two more ways a control fails" on Story 3, unlisted  
  → 52-01 and 52-02 **Lessons**
- **[Suggestion]** 📋 **Jordan** / 🧑‍💻 **Bella**: fuller **Satisfies**; Story 3 `**Effort**: high`; Story 3's dependence on Story 2 stated
- **[Suggestion]** 🧪 **Casey** / 🧑‍💻 **Bella**: seed `missed-regression` and give its kind
- **[Suggestion]** 🧪 **Casey**: wider history grep
- **[Suggestion]** 📋 **Jordan**: split 52-02's grep and tag-balance proofs; name the tag check's method
- **[Suggestion]** 📋 **Jordan**: a size budget for `do`
- **[Suggestion]** 🧪 **Casey**: controls quote `5faec1b` showing the sentence absent
- **[Suggestion]** 📋 **Jordan**: drop NFR1 from 52-02's **Satisfies**
- **[Suggestion]** 🧑‍💻 **Bella**: the `skipped — auditor unavailable` path for a full story

## Remediation

- Fixed: criterion 9's grep → 52-01 Story 1 criterion 10 reads the fields, greps the new forms with a floor and excludes `**Pivot deferred**`
- Fixed: the escape clause → 52-01 Story 1 criterion 8 requires each line and names the removed fix-rerun rule
- Fixed: the deferred run's `**Test run**` line → 52-01 Story 1 criterion 2
- Fixed: quick records and `In Progress` → 52-01 Story 1 criterion 9, Story 2 criterion 7
- Fixed: the scoped prompt in one place → 52-01 Story 1 criterion 6 owns it; Story 2 criterion 6 and Story 3 criterion 4 refer
- Fixed: test-runs.md:60 → 52-01 Story 1 criterion 3
- Fixed: no-restatement floor and controls by reference → 52-01 epic note and Story 2 criteria 1, 2, 11
- Fixed: do:161-163 → 52-01 Story 2 criterion 8
- Fixed: the missing-note Warning → 52-01 Story 2 criterion 6 (named in the `**Audit**` suffix, no fix round)
- Fixed: the finish line's meaning → 52-01 Story 2 criterion 10
- Fixed: `sibling` → 52-01 Story 1 criterion 7, Story 2 criterion 10, Story 3 criteria 1 and 6, 52-02 criterion 2
- Fixed: the left-out exemption at both lines → 52-01 Story 3 criterion 2
- Fixed: criterion 2's negative → 52-01 Story 3 criterion 3 rests on the added sentences
- Fixed: the fix's files in scope → 52-01 Story 3 criterion 4
- Fixed: status's control, lines and next action → 52-01 Story 3 criterion 5, task 3.1
- Fixed: NFR2 and the maintenance line → 52-02 criteria 5 and 6
- Fixed: 52-02's grep and floor, the split tag check → 52-02 criteria 2 and 3
- Fixed: the lessons → both **Lessons** lines
- Fixed (Suggestions applied with the fixes): **Satisfies**, Story 3 effort and its blocker's reason, the wider history grep, controls quoting `5faec1b`, NFR1 dropped from 52-02, the size bullet stating `do`'s growth
- Fixed (user's decision, 2026-11-10, through `/cpm-next:plan`): spec 52 amended and carried into 52-01 for the story snapshot's definition; the batch trigger and a waiting-on-user story; the deferred-run red form; the `fix due` resume and the in-run mismatch's audit; the flaky run's pass; a blocked batch story's regression and "the story that took the run"; the scoped round's count and signal (`missed-regression` seeded, its kind); the pass comparison on a resumed baseline and the floor's terms; step 5's last-audit sentence; `none` closing stories; reruns after an FR3 full run; the red retake after an FR5 fix; the still checkout in a batch; worktree batches sharing files; the `skipped` auditor path
- Not acted on: a size budget for `do` → recorded only
