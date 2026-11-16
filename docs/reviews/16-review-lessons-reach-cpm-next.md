# Review: Lessons learned in one repository reach cpm-next — epics

**Date**: 2026-11-15  
**Source**: docs/epics/59-01-epic-a-red-for-each-clause.md, docs/epics/59-02-epic-runtime-claims-probed-before-the-build.md, docs/epics/59-03-epic-the-sweep-reads-lessons.md, docs/epics/59-04-epic-release-0-22.md  
**Reviewers**: Ren, Bella, Tomas  
**Findings**: 30 (5 critical, 19 warnings, 6 suggestions)

## Summary

Three personas the challenge did not use (sm, dev, qa) reviewed the four epics from a copy of spec 59 without its **Challenge** section. All three found the same two spec-level faults: FR6's owner-text filter separated none of opendaw-trak's lessons about its own code from those about cpm-next, and FR1's cut-over had nothing to read. The user settled both (report, then decline; a `**Started**` line), spec 59 was amended, and every epic was rewritten with the remaining fixes. Nothing waits on the user.

## Findings

- **[Critical]** 🔍 **Tomas**: FR6's filter collects trak's `shared-state-collision` and `overwrite-loses-data` lessons, whose owner text names `do` and `review` and which have recurred after promotion, so 59-03 Story 1's "not reported alone" fails on a correct build (also Ren, Bella)  
  → Story 1 (59-03), criterion 4: the criterion can only pass by narrowing the filter until it does
- **[Critical]** 💻 **Bella**: this repository's matching lessons ("A control is only a control…", "Ask the runtime…") have no owner text, `**Class**` or `**Promoted**`, so FR6 never collects them (also Ren, Tomas)  
  → Story 1 (59-03), criterion 4: "with this repository's matching lessons beside them" cannot be met
- **[Critical]** 💻 **Bella**: no story records the version its step 1 ran under, so FR1's cut-over and FR4's probe have nothing to read on resume or at audit (also Ren, Tomas)  
  → Story 2 (59-01), criterion 1; Stories 1 and 2 (59-02)
- **[Critical]** 💻 **Bella**: a run with `HOME` at a scratch directory loses the plugin installs, the installed copy is 0.21.1 not the source, and `~/Work/git` expands into the scratch directory (also Ren, Tomas)  
  → Stories 1, 2 and 3 (59-03), the run criteria
- **[Critical]** 🔍 **Tomas**: the walk-table grading can pass on a table rewritten to match the new text: mtimes record only the last write, the controls are true by construction, and 59-02's grading has none  
  → Story 1 and Story 2 (59-01), Story 1 (59-02), the grading criteria
- **[Warning]** 🔍 **Tomas**: 59-03 had no `**Blocked by**`, yet the table must precede any change under `cpm-next/` (also Ren, Bella)  
  → 59-03 header
- **[Warning]** 🔍 **Tomas**: FR2's two pinned findings (03-01 Story 9, 03-02's clock test) are not required by the table, and a row allowed one failed clause where Story 7's signal names four (also Ren, Bella)  
  → Story 1 (59-01), criterion 1
- **[Warning]** 💻 **Bella**: the abandoned pass on the hand-off route has no owner (the subagent may not touch the directory), the manifest is not compared first, and an already-disputed independent test has no route (also Ren)  
  → Story 2 (59-01), criterion 2
- **[Warning]** 🔍 **Tomas**: the small-change route and Finishing's `[user]` route that takes step 4 are missing from the routes  
  → Story 2 (59-01), criterion 2
- **[Warning]** 💻 **Bella**: the contract's completeness rules ("incomplete without its red") must become per clause, and no criterion names them  
  → Story 2 (59-01)
- **[Warning]** 🔍 **Tomas**: `cpm-next/shared/auditor-independent-tests.md:12` reads a held red and is not in scope (also Ren)  
  → Story 3 (59-01)
- **[Warning]** 💻 **Bella**: NFR2 is claimed but nothing parses a story with several `Evidence` lines or a `**Probed**` line through the mods (also Ren, Tomas)  
  → Story 2 (59-01), Story 1 (59-02)
- **[Warning]** 💻 **Bella**: `**Probed**` has no place in a `docs/quick/` record, though the small-change route is listed (also Ren)  
  → Story 1 (59-02), criterion 1
- **[Warning]** 🔄 **Ren**: a "recorded user decision" has no field, so a criterion the user keeps always draws the Warning  
  → Story 2 (59-02), criterion 1
- **[Warning]** 🔍 **Tomas**: a criterion amended mid-build that adds a runtime claim has no probe route; re-probing "since its date" reads two ways on the same day (also Bella)  
  → Story 1 (59-02), criterion 2
- **[Warning]** 💻 **Bella**: a signal's date is undefined (signals carry none; an epic's date is its planning date), the sweep reads only `process` signals though every recurrence on trak's lessons is `project`, and a lesson with no `**Promoted**` has no rule (also Ren, Tomas)  
  → Stories 1 and 2 (59-03)
- **[Warning]** 💻 **Bella**: "before Story 2's 0.22.0 rows" names the wrong story; the rows come in 59-04 (also Ren, Tomas)  
  → Story 1 (59-03), criterion 4
- **[Warning]** 💻 **Bella**: the planted cases have no stated place, though the scanned repositories stay unchanged (also Ren, Tomas)  
  → Stories 1 and 2 (59-03)
- **[Warning]** 🔄 **Ren**: Stories 2 and 3 of 59-03 both edit `sweep.md` with no `**Blocked by**` between them  
  → Story 3 (59-03)
- **[Warning]** 🔍 **Tomas**: 59-03 Story 2 has no mixed-group case, no must-not-change control that `process` signals are still covered by version, and an uncovering rule keyed to an epic's date  
  → Story 2 (59-03)
- **[Warning]** 💻 **Bella**: the Finishing suggestion is placed before the Needs you items in which a lesson is written; replacing the line drops the plain `sweep` suggestion for a listed repository (also Ren, Tomas)  
  → Story 3 (59-03), criterion 2
- **[Warning]** 🔍 **Tomas**: `sweep add` has no control for a non-repository or a repository with none of the folders, no expected count, and "read" for `docs/cpm/` is undefined (also Ren)  
  → Story 3 (59-03), criterion 1
- **[Warning]** 💻 **Bella**: a row "dated" from a release commit that does not exist yet; trak's lessons are placed at `plan` and `review`, which no 0.22.0 row names, and nothing checks the sweep after release (also Ren, Tomas)  
  → Story 1 (59-04), criterion 3
- **[Warning]** 🔄 **Ren**: FR6 to FR8 get no row and no stated reason  
  → Story 1 (59-04), criterion 3
- **[Suggestion]** 🔍 **Tomas**: the walk-through lesson is on Story 1 but bears on the grading in 59-01 Story 2 and 59-02 Story 1; retro 11's revert, vocabulary and own-file observations and the recurring `spec-drift` on ceilings are not listed  
  → **Lessons** lines of 59-01, 59-02, 59-03
- **[Suggestion]** 💻 **Bella**: the spec says three `unprobed` reasons in FR4 and FR5 and four in AD3 (also Ren)  
  → spec 59 FR4, FR5
- **[Suggestion]** 💻 **Bella**: 59-01 Story 3 and 59-04 both edit the three guides; criteria bundle `wc -w` with the suites (also Ren)  
  → Story 3 (59-01), Story 1 (59-04)
- **[Suggestion]** 🔍 **Tomas**: `docs/maintenance/README.md:106` and `:100` should name the new forms and columns  
  → Story 1 (59-04), criterion 2
- **[Suggestion]** 🔍 **Tomas**: pin trak's HEAD and snapshot its `git status`, since its tree is dirty and 03-02 is being edited  
  → Story 1 (59-01), Story 1 (59-03)
- **[Suggestion]** 🔄 **Ren**: `## Amendment` blocks in a lessons file are not lessons  
  → Story 1 (59-03), criterion 1

## Remediation

- Fixed: FR6's filter collects trak's own-code lessons → spec 59 FR6, FR7 and AD7 amended at the user's decision (every collected lesson reported once, a `declined` row leaves it out); 59-03 Story 1 criterion 4 now expects all four reported, and Story 2 criterion 4 leaves the two out after `declined` rows
- Fixed: this repository's lessons can't be collected → 59-03 Story 1 no longer expects them beside trak's
- Fixed: the cut-over has nothing to read → spec 59 FR1, FR4 and AD6 amended at the user's decision; 59-01 Story 2 adds the `**Started**` line, and 59-01 Story 3 and 59-02 Stories 1 and 2 read it
- Fixed: `HOME` runs → the source `sweep.md` is followed by hand with a scratch copy of the list and absolute paths (spec Testing Strategy, 59-03 Stories 1–3, 59-04)
- Fixed: grading could pass on a rewritten table → the table's `git hash-object` recorded and checked, a floor row that differs from 0.21.1, controls read against `git show 88ee1e1`, and a control in 59-02 Story 1
- Fixed: 59-03 unblocked → `**Blocked by**: Epic 59-01-epic-a-red-for-each-clause`; the table's hash taken before 59-02 and 59-03 start
- Fixed: FR2's findings and several failed clauses → 59-01 Story 1 criterion 1
- Fixed: the abandoned pass's owner, the manifest, a disputed test → 59-01 Story 2 criterion 4
- Fixed: missing routes → 59-01 Story 2 criterion 4 names the small change and Finishing's `[user]` route
- Fixed: per-clause completeness → 59-01 Story 2 criterion 1
- Fixed: `auditor-independent-tests.md` → spec Scope; 59-01 Story 2 criterion 5 and Story 3 criterion 2
- Fixed: NFR2 unchecked → 59-01 Story 2 criterion 7 runs both mods' parsers over a copy
- Fixed: `**Probed**` in a quick record → 59-02 Story 1 criterion 1
- Fixed: a kept criterion → 59-02 Story 1 criterion 3 records it in an `**Amended**` line; Story 2 checks for that line
- Fixed: mid-build claims and same-day re-probing → 59-02 Story 1 criterion 2
- Fixed: signal dates, `project` recurrences, no `**Promoted**` → spec FR6 and FR7 (recurrence by `recurs:`, the version on a recurring signal); 59-03 Stories 1 and 2
- Fixed: the wrong rows reference → 59-03 Story 1 criterion 4 names Epic 59-04
- Fixed: planted cases' place → a scratch repository on the scratch copy (59-03 Story 2)
- Fixed: 59-03 Stories 2 and 3 share `sweep.md` → Story 3 blocked by Story 2
- Fixed: the mixed group, the must-not-change control, the date key → 59-03 Story 2 criterion 3
- Fixed: the suggestion's place → after the last Needs you item, keeping the plain `sweep` suggestion (59-03 Story 3 criterion 3)
- Fixed: `sweep add` controls → 59-03 Story 3 criteria 1 and 2 (`docs/cpm/` read as `docs/`, a counted `find`, no non-repository added)
- Fixed: rows' date and placement → 59-04 criterion 3 (dated the day set, checked against the commit) and criterion 4 (the sweep after release names each group left out or still reported)
- Fixed: FR6–8 rows → 59-04 criterion 3 says they fix no failure class
- Fixed: lessons lines → the walk-through lesson moved to the grading stories; retro 11's three observations, "A control is only a control…", the floor lesson, "Two more ways a control fails" and the `spec-drift` signal listed
- Fixed: three `unprobed` reasons → spec 59 FR4 and FR5 name four
- Fixed: guides in two stories, bundled criteria → the guides moved to 59-04; suites split from word counts in 59-01 and 59-02
- Fixed: the maintenance record's lines → 59-04 criterion 2
- Fixed: trak's HEAD → recorded in 59-01 Story 1 and before 59-03 Story 1's run
- Fixed: `## Amendment` blocks → 59-03 Story 1 criterion 1
