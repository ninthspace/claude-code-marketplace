# Consolidate do

**Source spec**: docs/specifications/58-spec-plugin-consolidation.md  
**Date**: 2026-11-12  
**Status**: Pending  
**Blocked by**: Epic 58-02-epic-release-0-20  
**Amended**: review 15 (docs/reviews/15-review-plugin-consolidation.md) — the base copy written and checked at this epic's start, the checks kept where a later session finds them, walk-throughs with a fixed tuple, a noise rule and path limits, mappings judged by a fresh agent, the history check over new files, every point of use and every long paragraph listed, the exceptions bounded, labels other files name protected, W16 added, a validate warning that already exists allowed (2026-11-12)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 2), docs/library/01-library-lessons-learned.md → "A procedure names every route that calls it and every input each caller gives" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 2), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (build), docs/library/04-library-model-specific-accommodations.md → "A delegated finding is spot-checked in the file before it is acted on" (build)

**Runs.** This epic starts the second run, after 0.20.0 is committed, pushed and used (the user's decision, 2026-11-12).

**Checks.** These hold for 58-03 to 58-06.

- **`{pre}`** is `{git common dir}/cpm-next/pre-0.21/`. 58-03 Story 1's first step copies, with Bash `cp`, the 11 in-scope files at their repository paths: `cpm-next/skills/{do,plan,review,library,status}/SKILL.md`, `cpm-next/skills/do/worktree.md`, `cpm-next/shared/{artifacts,test-runs,fixed}.md`, `cpm-next/agents/{auditor,test-writer}.md`. It names under **Found** any difference between them and the files 58-02 closed with. `{pre}/checks/` holds every script, inventory, case text and `{pre}` outcome tuple these epics write, so a later session finds them; nothing here is under `scratch/` or `rounds/`. The directory is the run's own and is deleted by its literal, quoted absolute path after 58-06 Story 2 closes.
- **Walk-throughs.** A case is written once to `{pre}/checks/cases/W{n}.md`, with its expected outcome tuple over `{pre}` computed once (run twice by fresh subagents; a difference between the two is resolved by a third, and recorded). A walk-through is a fresh subagent given the case and the paths it may read, allowed no other; for an on-demand file it is given `SKILL.md` only and receives the file only when it asks for it by name. It reports the tuple: the fields written and their forms, the runs and their kinds, the audits with their kind and prompt items, the files created or deleted, and the **Needs you** and **Found** items, each a short sorted list. A mismatch with the `{pre}` tuple is run again once and counts only if it repeats. A control's difference must be in the field the dropped clause governs.
- **The inventory** is as the spec's Testing Strategy defines it, the script in `{pre}/checks/`. Each mapping quotes the text it points to (not only a line number) and names every condition of its unit; a fresh subagent given a sample of 30 units and their mappings, the changed passages' units among them, judges each "every condition carried" or not, and the story fixes every "not".
- **The history check** greps the added lines (`diff -N {pre}/{file} {file} | grep '^>'`, a new file diffed against nothing) for the words NFR3 lists, each hit accounted for in the `Evidence` line.
- **Labels other files name stay**: the steps and bold labels `fixed.md` rows, `test-runs.md`, `worktree.md`, the auditor and the mods name, checked by grepping each in the new text.

## Independent tests and browser handling load on demand
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR10, NFR3  
**Effort**: high

**Acceptance Criteria**:

- `{pre}` is written as **Checks** says, holding the 11 files; any difference from 58-02's close is under **Found** `[manual]`
- `cpm-next/skills/do/independent-tests.md` holds `do`'s **Independent tests** section and `cpm-next/skills/do/browser.md` its `[browser]` handling (the **Before the first story** probe, step 3's `[browser]` bullet, **Finishing**'s browser item), each starting with its trigger. `do/SKILL.md` keeps a one-line pointer at each point of use, naming the file, its trigger (an `**Independent tests**` line other than `skipped`; a `[browser]` criterion, an `**Amended**` line's included) and "read it again if it is not in context": for `independent-tests.md`, step 1, step 4's red-pass exception, step 5's audit-finding rule, the parallel rules and **Audit**; for `browser.md`, **Before the first story**, step 3 and **Finishing**. Step 3's `[user]` bullet, which refers to the `[browser]` bullet's `- Waiting on user:` line, names its form itself. The parallel rule's one-line browser clause stays in `do` `[manual]`
- An inventory of the moved units maps each to exactly one file; control: one unit planted in both files is reported twice `[manual]`
- W7 and W10 give the same tuple over `{pre}` and the new text; control: W10 over a copy with step 3's pointer removed gives a tuple missing the `[browser]` check in its runs field (W7 reads the auditor's checks from `auditor.md` until 58-04 moves them) `[manual]`
- `claude plugin validate cpm-next` passes with no new warning; the added lines, the two new files among them, are read with the history check, and none records history `[manual]`

### Move the two sections
**Task**: 1.1  
**Description**: Write `{pre}`, `do/independent-tests.md`, `do/browser.md` and the pointers in `do/SKILL.md`.  
**Status**: Pending

---

## Say each rule in do once
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR9, NFR1, NFR3  
**Effort**: high

**Acceptance Criteria**:

- In `do/SKILL.md` and `worktree.md`, each rule the contract, `test-runs.md` or the auditor owns is referred to, not restated, and each clause a nearby rule implies is removed with its derivation in the inventory. Every line over 150 words (a script lists them; at `{pre}` they include the opening's baseline paragraph and small-change paragraph, the cleanup and resume bullets, step 4's run and red-pass bullets, step 5, the red-pass hand-off bullet, **Audit rounds**' stops and record, and **Signals**) becomes parallel bullets under its bold label, or is named in the `Evidence` line with why it stays. FR9's exceptions stay word for word, by `diff` against `{pre}`: `do`'s **Audit** list, the writer's prompt in `independent-tests.md`, step 4's first bullet (the inputs and the read of help text, docs and `Evidence`) and the red-pass manifest sentence `[manual]`
- The inventory maps every rule unit of `{pre}`'s `do/SKILL.md` and `worktree.md`, none unmapped, as **Checks** says. Control: a copy of the new text with one condition dropped from a merged sentence in step 5 leaves that unit's mapping incomplete `[manual]`
- The walk-throughs that read `do` or `worktree.md` (W1–W16) give the same tuple over `{pre}` and the new text. Control: W4 over a copy with one clause dropped from the resume bullet gives a tuple that differs in its audits field `[manual]`
- These rules are stated only by their owner, each by a grep for its key phrases over `cpm-next/skills cpm-next/agents cpm-next/shared`, FR9's exceptions excluded by name: the targeted-before, full-after summary (`test-runs.md`); a story closing its epic (`test-runs.md`); the `none` story (`test-runs.md`); a result standing by snapshot (`test-runs.md`); waiting on the user (contract); the blocked mark (contract); the `Waiting on user` line (contract); the `existing` conditions (contract); the auditor's own test-running rules (auditor). Floor: each grep hits its owner once. Control: one phrase planted in a copy of `do/SKILL.md` is found `[manual]`
- Every label **Checks** protects is still in the new text `[manual]`
- `wc -w`: `do/SKILL.md` ≤ 6,450 and `worktree.md` ≤ 650; a miss is a `Not met`, never a reason to cut a rule `[manual]`
- The added lines are read with the history check, and none records history `[manual]`

### Consolidate do and worktree
**Task**: 2.1  
**Description**: Edit `do/SKILL.md` and `do/worktree.md`, with the inventory and walk-throughs.  
**Status**: Pending

---
