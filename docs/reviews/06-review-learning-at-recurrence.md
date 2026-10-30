# Review: Learning at recurrence (epics 48-01 to 48-08)

**Date**: 2026-10-30  
**Source**: docs/epics/48-01-epic-signal-contract.md … docs/epics/48-08-epic-user-checks.md  
**Reviewers**: Jordan (Product Manager), Bella (Senior Developer), Tomas (QA Engineer)  
**Findings**: 31 (1 critical, 22 warnings, 8 suggestions)

## Summary

The three reviewers each read all eight epics, since they come from one spec. The plan held up on parallelism and on its use of the contract; the findings were about edge cases in the signal lifecycle, criteria that could pass with nothing built, tasks that did not name the sections they change, the `docs/quick/` case, and a word budget with no headroom. Every Warning was fixable in the Pending stories; the one Critical reaches back into spec NFR1.

## Findings

- **[Critical]** 🏗 **Bella**: the seven files total exactly 10,978 words, NFR1 allows no growth, the spec adds about 1,100 words and removes about 500, and the count is checked only at release.  
  → 48-07 Story 1, size criterion: going over means reopening Complete epics.
- **[Warning]** 📋 **Jordan**, 🧪 **Tomas**, 💻 **Bella**: a candidate marked ` — raised` when listed is lost if the user never answers, and a declined class is raised again at its next recurrence.  
  → 48-02 Story 2, criterion 2; 48-03 Story 2.
- **[Warning]** 📋 **Jordan**, 🧪 **Tomas**, 💻 **Bella**: nothing removes `do`'s walk-through case and Finishing rule for a library-lesson recurrence, which AD6 replaces.  
  → 48-02.
- **[Warning]** 💻 **Bella**: Story 1's grep control needs Finishing's recurrence rule deleted, which was Story 2's scope.  
  → 48-02 Story 1, criterion 3.
- **[Warning]** 📋 **Jordan**: Story 1's task named step 5, Audit and Finishing, but the triggers are written in **When a criterion looks wrong** and **When to stop**.  
  → 48-02 Story 1, task 1.1.
- **[Warning]** 🧪 **Tomas**, 💻 **Bella**, 📋 **Jordan**: a signal on a `docs/quick/` record has no criterion and no reference form.  
  → 48-01 Story 1, criterion 3; 48-02 Story 1.
- **[Warning]** 📋 **Jordan**, 💻 **Bella**: "audit-relevant failures" in worktree mode is undefined; worktree subagents are not audited.  
  → 48-02 Story 1, criterion 4.
- **[Warning]** 🧪 **Tomas**: several signals on one story, and a re-slugged signal after a rejected match, have no criterion.  
  → 48-02 Story 2.
- **[Warning]** 💻 **Bella**: the lessons file to write is not named; this repository's lessons file is numbered and DPM-era, so `do` could create a second one; file creation, `scope` and `last-reviewed` are not covered.  
  → 48-02 Story 2, criterion 3.
- **[Warning]** 🧪 **Tomas**, 💻 **Bella**: lessons promoted from legacy retros need the old `**Source**` form; `**Promoted**` and `**Scope**` are not said to stay; the duplicate rule ignores lessons without a `**Class**`; the artefact table still names `do` as a retro writer; FR6's contract part has no criterion; Satisfies omits FR7.  
  → 48-01 Story 1.
- **[Warning]** 💻 **Bella**: broad seed slugs with one lesson per class would suppress a second distinct rule of the same class.  
  → 48-01 Story 1, criterion 2.
- **[Warning]** 🧪 **Tomas**, 📋 **Jordan**, 💻 **Bella**: the suspect-record rule reads two ways, would flag historical stories closed before signals existed, and the status grep for FR7 is in no criterion.  
  → 48-03 Story 2, criteria 1 and 3.
- **[Warning]** 📋 **Jordan**, 💻 **Bella**: `learn` has no rule for raised, promoted or declined signals, no `**Class**` for legacy promotions, and the move of the retro text from the contract has no source once 48-01 deletes it; the description, pointer and `learn` row still say retros.  
  → 48-04 Story 1.
- **[Warning]** 🧪 **Tomas**: library lesson "A sweep that reads this repository's own text will read its prose and its planted controls" bears on the sweep; the 48 epics quote the signal template; no criterion reflects it. The two-repository threshold has no control.  
  → 48-05 Story 1, criterion 2.
- **[Warning]** 💻 **Bella**: writing the discussion record breaks "writes nothing in scanned repositories" when the current repository is listed, and the contract names only `party` as a discussion writer.  
  → 48-05 Story 1, criterion 3.
- **[Warning]** 🧪 **Tomas**: retro 11's lesson that a criterion's tasks must name the file that carries the behaviour bears on 48-06, whose task named no file.  
  → 48-06.
- **[Warning]** 📋 **Jordan**, 🧪 **Tomas**, 💻 **Bella**: 48-08's checks were not exact (no reliable way to plant a failure, no seeded first signal), the rejected-match check could not fail and had no floor, and FR4, FR7 and FR10's controls were not observed.  
  → 48-08 Story 1.
- **[Warning]** 📋 **Jordan**: the user-checks epic names only 48-07, not the epics its checks rely on.  
  → 48-08 header.
- **[Suggestion]** 📋 **Jordan**: 48-06 joins two unrelated requirements; split it.
- **[Suggestion]** 📋 **Jordan**, 💻 **Bella**: 48-07's upgrade-note criterion is garbled, "one bullet per change" can't be counted, and the README command table row for `library` isn't covered.
- **[Suggestion]** 🧪 **Tomas**: 48-05 should say whether the sweep continues after a missing repository, and that `add` creates the directory.
- **[Suggestion]** 🧪 **Tomas**: 48-06 Story 2's status criterion may pass with no change, since `status` already lists Pivot deferred lines.
- **[Suggestion]** 📋 **Jordan**: matching every signal against unretired legacy observations is judgement work in every story with a fix; consider `scout`.
- **[Suggestion]** 📋 **Jordan**: with one repository, process signals never surface beyond **Found**; say so in the upgrade note.
- **[Suggestion]** 🧪 **Tomas**: spec FR7 calls `library` "the only skill that still reads retros", while FR6 has `do`, `plan` and `review` read unretired observations.
- **[Suggestion]** 💻 **Bella**: say whether `docs/archive/epics/` counts in the recurrence search.

## Remediation

- Fixed: raised and declined lifecycle → 48-01 adds ` — promoted`; 48-02 Story 2 marks raised when listed, promoted or declined on the answer, and declines a new signal that matches a declined one; 48-03 Story 2 lists raised-but-unanswered candidates under **Needs you**.
- Fixed: AD6 removals → 48-02 Story 1 removes the walk-through case and Finishing rule, with the grep control extended to "recurrence of a library lesson".
- Fixed: grep control scope → removal moved into 48-02 Story 1.
- Fixed: task sections → 48-02 Story 1's task names the small-change paragraph, **When to stop** and **When a criterion looks wrong**.
- Fixed: quick records → 48-01 adds `{quick path} → {slug}`; 48-02 Story 1 writes signals in quick records.
- Fixed: worktree failures named → 48-02 Story 1, criterion 4.
- Fixed: several signals and re-slugging → 48-02 Story 2, criterion 1, with a control.
- Fixed: lessons file → 48-02 Story 2 writes `docs/library/lessons-learned.md`, creating it with front-matter, updating `scope` and `last-reviewed`.
- Fixed: lesson form, legacy `**Source**`, `**Promoted**`/`**Scope**`, no-class duplicates, artefact table, FR6 statement, Satisfies FR7 → 48-01 Story 1.
- Fixed: narrower slug for a second rule in one class → 48-01 Story 1, criterion 2; duplicates match on class and rule.
- Fixed: suspect-record wording, the cut-off at the first signal, the status grep → 48-03 Story 2.
- Fixed: learn's marks, legacy `**Class**`, the retro text taken from `70c789c`, description and pointer → 48-04 Story 1.
- Fixed: sweep reads only `**Signal**:` field lines at line start, with a control on this repository's 48 epics and on single-repository groups; continues after a missing path; creates the directory → 48-05 Story 1, with a `**Lessons**` line.
- Fixed: discussion record named and allowed in the current repository; contract table names `library sweep` → 48-05 Story 1.
- Fixed: 48-06 split into two stories with named files and a status control, with a `**Lessons**` line.
- Fixed: 48-07 upgrade note split into its own criterion, one bullet per epic, the command table row, the single-repository note.
- Fixed: 48-08 rewritten with planted unmeetable criteria, a hand-written unrelated signal with a floor, the yes and no paths, three sweep repositories and a missing path; blocked by 48-02, 48-05 and 48-07, with a `**Lessons**` line.
- Fixed: `docs/archive/epics/` counts → 48-02.
- Fixed: the word budget → the user chose to measure only, with no limit; 48-07 Story 1's size criterion records before and after counts, with a `**Pivot deferred**` for spec NFR1 (`/cpm-next:plan`).
- Not acted on: `scout` for legacy matching → a build choice for `do`, not a criterion.
- Not acted on: FR7's "only skill" wording → spec text for `/cpm-next:plan`; the epics follow FR6.
