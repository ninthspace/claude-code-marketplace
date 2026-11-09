# Review: Spec 51 epics — targeted runs, release, user checks

**Date**: 2026-11-09  
**Source**: docs/epics/51-01-epic-targeted-runs.md, docs/epics/51-02-epic-release.md, docs/epics/51-03-epic-user-checks.md  
**Reviewers**: Jordan (pm), Bella (dev), Casey (test)  
**Findings**: 34 (6 critical, 22 warnings, 6 suggestions), after merging duplicates across the three reports

## Summary

Every Must Have is named by a story, the `[user]` checks are confined to 51-03, and the blocking order is right. Two of the spec's mechanisms are wrong as written. FR4's exempt-file grep exempts nearly every code file, because tests reach classes and views by name or URL, not path. Its `git status --porcelain` note cannot see a second edit to an already-modified file. FR3's order-dependent outcome loops. These, and several gaps in FR1, FR5, FR6, FR7, FR10 and NFR3, reach back into the spec. Within the epics, criteria lacked FR1's untested-file trigger, floors for the grep sweeps and the no-restatement rule, and coverage of whole passages. Story 3 could drift from Story 2's hand-over, Story 2 was one task over nine requirements, and 51-03's checks could pass without proving their requirement.

## Findings

- **[Critical]** 🧑‍💻 **Bella** / 📋 **Jordan**: FR4's exempt-file grep ("files no test, test config or build step names") exempts nearly every class and view, since tests reach them by `::class`, URL or view name, and it contradicts its own control  
  → 51-01 Story 1, criterion 2; Story 2, criterion 4: builders can read it two ways; a code edit would not make a run stale
- **[Critical]** 🧑‍💻 **Bella** / 📋 **Jordan**: the `git status --porcelain` note does not change when an already-modified file is edited again, so it cannot detect the change it exists for; the red pass's blob-hash manifest can  
  → 51-01 Story 2, criterion 4: a fix after the closing story's full run could pass as standing
- **[Critical]** 🧑‍💻 **Bella** / 🧪 **Casey**: FR3's order-dependent outcome loops: the targeted set keeps failing, each change triggers another full run, and the story cannot close on a passing run of its kind; flaky and order-dependent are not told apart  
  → 51-01 Story 2, criterion 2
- **[Critical]** 🧪 **Casey** / 📋 **Jordan**: FR1's trigger "a changed code file no test runs takes a full run" was in no criterion, and "code file" is undefined (an empty targeted set has no rule)  
  → 51-01 Story 1, criterion 1; Story 2, criterion 1
- **[Critical]** 🧪 **Casey** / 📋 **Jordan** / 🧑‍💻 **Bella**: 51-03's planted-regression check cannot happen as written (a regression planted before or between runs is a baseline failure), and has no exact steps  
  → 51-03 Story 1, criterion 5
- **[Critical]** 📋 **Jordan**: nothing stopped the auditor, handed a targeted result, from running the full suite itself in an isolated suite, putting the cost back on every story  
  → 51-01 Story 3, criterion 1
- **[Warning]** 🧪 **Casey**: "the tests that run it" can be read as direct callers only or as tests reaching it through a caller; this decides whether a service change runs its feature tests  
  → 51-01 Story 1, criterion 1 (spec FR1)
- **[Warning]** 🧪 **Casey**: the targeted set and the exempt rule miss tests that iterate a directory, namespace or registry (Pest `arch()`, snapshot and route-list sweeps)  
  → 51-01 Story 1 (spec FR1, FR4)
- **[Warning]** 📋 **Jordan**: "behaviour of an existing symbol" is undefined, and a grep for a bare method name (`handle`, `save`) over-triggers  
  → 51-01 Story 1, criterion 1 (spec FR1)
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella**: the `**Test run**` form hides errors and empty runs, and has one command for several runners  
  → 51-01 Story 1, criterion 3
- **[Warning]** 🧑‍💻 **Bella**: run counts for **Changed** exist only in the conversation, since the line is rewritten each run, and compaction loses them  
  → 51-01 Story 2 (spec FR2, FR10)
- **[Warning]** 📋 **Jordan**: a story waiting on the user keeps the closing story off its full run; and 🧑‍💻 **Bella**: a user-checks story answered in a later session closes its epic and so pays a full run over code no file has changed since the release epic's full run  
  → 51-01 Story 2, criterion 3 (spec FR5)
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella**: FR6's baseline rule has no control, no path when the epic has no next story this run builds (blocked, `[user]`-only, another scope), and its fix is not "a failure the story's full run showed", so the auditor would call it scope creep  
  → 51-01 Story 2, criterion 5 (spec FR6)
- **[Warning]** 🧪 **Casey**: the auditor's Warning list misses a targeted run on a closing story or small change, and on a story with an untested code file  
  → 51-01 Story 3, criterion 2 (spec FR7)
- **[Warning]** 🧑‍💻 **Bella**: with only a run-coverage Warning, whether a second audit follows the run, and how the `**Audit**` line counts it, is unstated  
  → 51-01 Story 2, criterion 6 (spec FR7)
- **[Warning]** 🧑‍💻 **Bella**: the contract is read by every skill, so NFR3's lists cost plan, review, status, library and party too  
  → 51-01 Story 1 (spec NFR3, AD3)
- **[Warning]** 📋 **Jordan**: FR3 was placed in step 4 only; a targeted fix rerun in step 5 needs it too  
  → 51-01 Story 2, criterion 2
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🧪 **Casey**: Stories 2 and 3 run in parallel but must agree on the audit hand-over and the Warning a run settles  
  → 51-01 Story 3, Blocked by
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: Story 2 is one task over nine requirements and eight sections  
  → 51-01 Story 2, Task 2.1
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: the sweep's allowed hits omit the wide-reach and FR3 full runs; its pattern misses "full run", "its tests", "run no test", "running it again"; its floor omits **Finishing**'s **Changed** and "take step 4", and `worktree.md`'s "each story's tests"  
  → 51-01 Story 2, criterion 8
- **[Warning]** 🧪 **Casey** / 🧑‍💻 **Bella**: "states once" and "by reference, not restating them" had no floor  
  → 51-01 Stories 1 and 2
- **[Warning]** 🧑‍💻 **Bella**: the resume run's order against the red pass was unstated; the worktree subagent lacks the contract path to find its targeted set  
  → 51-01 Story 2, criteria 7 and 8
- **[Warning]** 📋 **Jordan** / 🧪 **Casey**: the auditor criteria named checks 1 and 8, not 3 and 5, and had no floor naming the sentences that must change  
  → 51-01 Story 3, criteria 1 and 4
- **[Warning]** 📋 **Jordan** / 🧪 **Casey** / 🧑‍💻 **Bella**: the release floor missed the end-of-run, standing-rule, resume, red-pass, agents-table, worktree, field-table and **Changed** passages, `cpm-next/README.md:9`, and the stale mod versions in two version lines  
  → 51-02 Story 1, criteria 1 and 2
- **[Warning]** 🧪 **Casey**: nothing feeds a `**Test run**` line to the mods, so NFR2's "they ignore it" cannot fail  
  → 51-02 Story 1 (NFR2)
- **[Warning]** 🧑‍💻 **Bella**: `git diff -- …` reads nothing once 51-01 is committed; diff against a fixed base  
  → 51-02 Story 1, criterion 5
- **[Warning]** 🧑‍💻 **Bella**: no size check, though the last releases recorded one  
  → 51-02 Story 1
- **[Warning]** 📋 **Jordan** / 🧪 **Casey** / 🧑‍💻 **Bella**: 51-03's checks lack exact steps and controls, can pass without the behaviour (c3's fix half, c5's loose bound), may legitimately run full (c1's action class), need a second epic for the single-story check, and leave FR3, FR4, FR6, FR7 and FR9 unobserved  
  → 51-03 Story 1
- **[Suggestion]** 📋 **Jordan**: say plainly in the README that one-story runs in fresh sessions still pay a full baseline each
- **[Suggestion]** 🧑‍💻 **Bella**: give the full form a fixed set of reason values; say red-pass runs and probes don't rewrite the line; classify a deleted or renamed file
- **[Suggestion]** 🧑‍💻 **Bella**: Story 1 sets the definitions everything rests on; make it `**Effort**: high`
- **[Suggestion]** 🧪 **Casey**: say a targeted run selects tests by file path, not a name filter
- **[Suggestion]** 🧪 **Casey**: add a date or tree marker to the line so the auditor can tell an earlier session's line
- **[Suggestion]** 🧑‍💻 **Bella**: the line rewritten each run makes the whats-next note go stale more often; note it in the maintenance record

## Remediation

- Fixed: FR1's untested-file trigger → 51-01 Story 1 criterion 1 and Story 2 criterion 1 state it
- Fixed: the auditor running a further suite → 51-01 Story 3 criterion 1: given a targeted result it runs no further suite and reports a gap as a Warning
- Fixed: the run record's form → 51-01 Story 1 criterion 3: failures include errors, zero tests is not a pass, per-runner commands and counts, placed before `**Acceptance Criteria**`
- Fixed: FR3 in step 5 → 51-01 Story 2 criterion 2 names steps 4 and 5
- Fixed: Stories 2 and 3 drifting → Story 3 blocked by Story 2; Story 2 criterion 6 and Story 3 criterion 1 cross-check the hand-over
- Fixed: one task → Story 2 has tasks 2.1 to 2.3
- Fixed: the sweep's pattern, allowed hits and floor → 51-01 Story 2 criterion 8 widened
- Fixed: no-restatement floor → 51-01 Story 2 gains a grep criterion over `do` and the auditor with the contract as floor
- Fixed: resume order and worktree contract path → 51-01 Story 2 criteria 7 and 8
- Fixed: auditor checks and sites → 51-01 Story 3 criteria 1 and 4
- Fixed: release floor, `cpm-next/README.md:9`, version lines, mods probe, fixed diff base, size check, no `fixed.md` row, split checks → 51-02 Story 1
- Fixed (Suggestion applied with the fix): 51-01 Story 1 `**Effort**: high`
- Fixed (user's decision, 2026-11-09, through `/cpm-next:plan`): FR4's exempt definition and change detection, FR3's order-dependent loop, "code file" and the empty set, "tests that run it" through one caller, iterating tests, "behaviour" defined, run counts kept on disk, FR5 for waiting and no-change stories, FR6's baseline path and its audit scope, FR7's two extra Warnings and a run that settles one, NFR3's cost → spec 51 amended; 51-01 rewritten with `shared/test-runs.md` in Story 1
- Fixed: 51-03's checks → rewritten over one scratch Laravel fixture with a fixed story order, controls and counts read from the `**Test run**` lines
- Not acted on: the remaining Suggestions → recorded only
