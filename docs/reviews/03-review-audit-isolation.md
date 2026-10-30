# Review: Audit isolation

**Date**: 2026-10-30  
**Source**: docs/epics/47-03-epic-audit-isolation.md  
**Reviewers**: Ren, Sable, Bella  
**Findings**: 15 (5 critical, 8 warnings, 2 suggestions)

## Summary

As written, the epic would not have prevented the collisions it targets. The isolation check it reused misses fake disks, SQLite files and caches. It treats `--parallel` as isolation, which does not cover a single test run. It never runs in a single-story build. Epic 47-01's "scratch directory" was defined nowhere, and after 47-01 the auditor's directory had no stated purpose. The epic and 47-01 also edit the same paragraphs. Each finding was fixed in Story 1, except one cheaper alternative to FR9, which waits on the user.

## Findings

- **[Critical]** 📅 **Ren**, 💻 **Bella**, ⚙️ **Sable**: 47-01's builder "scratch directory" is defined nowhere, and after 47-01 the auditor's directory has no stated purpose; the two must differ so the lead's reds and an auditor never share files  
  → Story 1, criterion 1
- **[Critical]** ⚙️ **Sable**: the reused isolation check (`do/SKILL.md:80`) misses fake disks (`storage/framework/testing/disks`), SQLite database files, file caches, compiled views and result caches, so the fake-disk collision passes as isolated  
  → Story 1, criterion 3
- **[Critical]** ⚙️ **Sable**: the check counts `php artisan test --parallel` as isolation, but an auditor's single test run without the flag shares the lead's database and disk  
  → Story 1, criterion 3
- **[Critical]** ⚙️ **Sable**, 💻 **Bella**: 47-01's red mutates source in the checkout, so an audit running at the same time reads or runs mutated code, even with an isolated suite  
  → Story 1
- **[Critical]** 💻 **Bella**, 📅 **Ren**: the epic edits the same **Audit** paragraph and auditor sections as 47-01 with `**Blocked by**: —`  
  → epic header
- **[Warning]** ⚙️ **Sable**, 💻 **Bella**, 📅 **Ren**: the isolation check runs only in worktree mode or for stories left one at a time, so a single-story run never makes it  
  → Story 1, criterion 3
- **[Warning]** ⚙️ **Sable**: `do` cannot see when a background auditor runs tests; the rule must be "while any auditor is still running"  
  → Story 1, criterion 3
- **[Warning]** ⚙️ **Sable**, 💻 **Bella**: "the lead runs no tests" narrows FR9's "no tests in the checkout"; in-checkout builder subagents are not covered  
  → Story 1, criterion 3
- **[Warning]** ⚙️ **Sable**, 💻 **Bella**: "never two full-suite runs" binds only `do`; check 8 lets each auditor run the full suite  
  → Story 1, criterion 4
- **[Warning]** ⚙️ **Sable**, 💻 **Bella**, 📅 **Ren**: who creates the directory, its location, its name for a small change, and a fresh directory per audit round are all unstated  
  → Story 1, criterion 1
- **[Warning]** 💻 **Bella**, ⚙️ **Sable**: "allow writes … rest of the paragraph unchanged" cannot hold, since "Do not edit, create or delete files" must change; "nowhere else" conflicts with test runs that write inside the repository  
  → Story 1, criterion 2
- **[Warning]** 📅 **Ren**: criteria 2 and 5 are negative with no control  
  → Story 1
- **[Warning]** 📅 **Ren**: serialising slows every unisolated project. After 47-01 the auditor reproduces no reds, so a cheaper rule is possible: in an unisolated suite the auditor runs no tests, and audits stay parallel  
  → Story 1, criterion 3 (FR9)
- **[Suggestion]** ⚙️ **Sable**: the isolation criteria are Laravel-only; add JS and Python cases, and point `TMPDIR` at the auditor's directory  
  → Story 1
- **[Suggestion]** 📅 **Ren**: `high` effort is heavy for prose edits  
  → Story 1

## Remediation

- Fixed: undefined directories → one definition: a run directory under the scratchpad (or `mktemp -d`), a builder directory per story for reds, and a fresh auditor directory per round, all created by the lead and passed as absolute paths
- Fixed: incomplete isolation check → isolation now means every test process, including a single run, gets its own database and its own copy of every file tests write, with no fixed port; worktree mode uses the same definition
- Fixed: `--parallel` counted as isolation → the definition covers a single run without the flag
- Fixed: mutation during an audit → no red is taken in the checkout while any auditor is running, isolated or not
- Fixed: shared paragraphs → the epic is blocked by 47-01
- Fixed: check never made → it is made once per run before the first audit
- Fixed: invisible auditor tests → the rule reads "while any auditor is still running"
- Fixed: lead only → the rule covers the lead and subagents
- Fixed: auditor full suite → check 8 runs it only with no given result and an isolated suite
- Fixed: directory details → covered in criterion 1, including small changes and rounds
- Fixed: read-only sentence → the criterion names the sentence to amend, with a `git diff` control on what else changes
- Fixed: missing controls → grep before/after on the replaced parallel-audit sentence; `git diff` scope on `auditor.md`
- Fixed (with its Critical): `TMPDIR` points at the auditor's directory; the isolation definition is stated in terms of state kinds rather than Laravel tools
- Needs you: Ren's cheaper alternative to FR9 → user chose (2026-10-30): in an unisolated suite audits stay parallel and the auditor runs no tests; Story 1 amended; FR9 to be amended through `/cpm-next:plan`
- Not acted on: `high` effort → concurrency rules are where a mistake is hard to see, which is what `high` is for
