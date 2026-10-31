# Review: Red passes

**Date**: 2026-10-31  
**Source**: docs/epics/49-01-epic-red-passes.md  
**Reviewers**: Ren, Bella, Casey  
**Findings**: 22 (4 critical, 14 warnings, 4 suggestions)

## Summary

The three reviewers agreed on the four Criticals: the pass's hash could never match, Story 1's cross-file control was circular and could not fail, a worktree's interrupted pass would be restored into the main checkout, and the commit guard keyed on any scratch directory deadlocks worktree mode. The first three are fixed in the epic; the fourth changes spec FR4 and FR5 and waits on the user. Most Warnings were rules today's step 4 holds that the rewrite could drop, ordering gaps, and grep criteria that could not fail.

## Findings

- **[Critical]** 💻 **Bella** / 🔄 **Ren** / 🧪 **Casey**: the hash includes the epic doc, which the `**Scratch**` line and `Evidence` edits change during the pass  
  → Story 2, criterion 3: every pass would mismatch and block its story
- **[Critical]** 🔄 **Ren** / 🧪 **Casey** / 💻 **Bella**: the `existing` control spans files changed by later stories, and `grep existing` already matches  
  → Story 1, criterion 3: circular with 49-02, and cannot fail
- **[Critical]** 💻 **Bella** / 🔄 **Ren** / 🧪 **Casey**: resume restores a worktree subagent's copies into the main checkout  
  → Story 3, criterion 2: overwrites the lead's files with unmerged code
- **[Critical]** 🔄 **Ren** / 💻 **Bella**: the guard refuses any commit while any scratch directory exists, and up to three worktree subagents share one scratch folder  
  → Story 3, criterion 3, with 49-03: a subagent's commit is refused during a sibling's pass, and an out-of-scope directory blocks the lead's commit before each fan-out
- **[Warning]** 🧪 **Casey** / 🔄 **Ren** / 💻 **Bella**: no criterion keeps the Edit-tool undo, the ban on `git checkout`/`stash`/`reset`, the error-doesn't-count rule, the fallback mutation, or who takes the red in each mode  
  → Story 2
- **[Warning]** 🔄 **Ren** / 💻 **Bella**: the inputs probe and the doc read-through come after the reds today, and their fixes would follow the pass  
  → Story 2, criterion 2
- **[Warning]** 💻 **Bella** / 🧪 **Casey**: no hash command named; untracked content, no-HEAD repositories and the hash's durability unaddressed  
  → Story 2, criterion 3
- **[Warning]** 💻 **Bella** / 🧪 **Casey**: a test run writing untracked files gives a false mismatch; "restore what it can" and the directory's fate on mismatch undefined  
  → Story 2, criterion 5
- **[Warning]** 💻 **Bella**: `lines undone` names no file, so step 5's file-level retake cannot be applied after compaction  
  → Story 1, criterion 1
- **[Warning]** 💻 **Bella**: an unchanged test that failed at baseline and passes now gets neither a red nor `existing`  
  → Story 2, criterion 1
- **[Warning]** 🔄 **Ren** / 💻 **Bella**: resume's "add a red to each test-proven criterion lacking one" not updated for `existing`  
  → Story 3
- **[Warning]** 🔄 **Ren** / 🧪 **Casey**: grep criteria name no string or cover only one of the two files  
  → Story 2, criterion 7
- **[Warning]** 🧪 **Casey** / 🔄 **Ren**: `existing` keyed to no tag, "names a control" undefined, "unchanged" ambiguous (function or file), and its severity conflicts with check 5's Critical for a misfitting `n/a`  
  → Story 1, criterion 2
- **[Warning]** 🔄 **Ren** / 💻 **Bella** / 🧪 **Casey**: the delegated pass doesn't say who writes the `**Scratch**` and `Evidence` lines or takes the hash, and contradicts the rule that subagents run only their own tests  
  → Story 3, criterion 5
- **[Warning]** 🔄 **Ren** / 💻 **Bella**: the audit-overlap rule depends on a mode 49-02 Story 2 defines, and a red outside the story still shows in the auditor's `git diff`  
  → Story 3, criterion 4
- **[Warning]** 💻 **Bella**: removing "stop when the directory is gone" loses the case of a 0.10.0 line naming a session-scratchpad directory  
  → Story 3, criterion 2
- **[Warning]** 💻 **Bella**: a leftover `quick-{nn}/` is never in scope, so it blocks every commit with no resume path  
  → Story 3, criterion 2
- **[Warning]** 🧪 **Casey**: the file-level retake misses a fix to code the mutated line calls in another file  
  → Story 2, criterion 6
- **[Suggestion]** 🔄 **Ren** / 💻 **Bella**: builder directories have no use left  
  → Story 3, criterion 1
- **[Suggestion]** 🔄 **Ren** / 💻 **Bella**: Story 3 is intricate and has no `**Effort**`  
  → Story 3
- **[Suggestion]** 🧪 **Casey** / 🔄 **Ren**: the retro lesson listed twice under one story pairing; retro 11's vocabulary observation and the library's check and delegation lessons bear but are unlisted  
  → Lessons line
- **[Suggestion]** 🧪 **Casey**: reading by the writer passes a sentence that states the rule wrongly; have a reader who is not the writer read the changed step cold  
  → all `[manual]` criteria

## Remediation

- Fixed: hash includes the epic doc → Story 2 records a per-path `manifest` excluding the epic doc or quick record, kept in the pass directory, and writes `Evidence` lines only after the pass ends
- Fixed: circular, vacuous `existing` control → Story 1 writes one verbatim sentence in the contract; Story 2 repeats it in `do`; 49-02 Story 1 repeats it in the auditor and greps the full sentence across all three files
- Fixed: worktree pass restored into the main checkout → the pass directory records its `tree`; resume restores only into that tree, deletes a directory whose tree is gone, and lists other trees under **Needs you** (Story 3)
- Needs you: the guard deadlocks worktree mode, and an out-of-scope or `quick-{nn}` directory in this tree blocks commits with no resume path → key the guard (49-03, FR5) and resume (FR4) on the `tree` file rather than on any directory and on story scope; a spec change. The user chose to key on the tree, settled by `/cpm-next:plan` on spec 49, which also folds in FR14's `lines undone in {file:lines}` (2026-10-31)
- Fixed: rules the rewrite could drop → Story 2 criterion 4 keeps them
- Fixed: probe and read-through order → Story 2 criterion 2 moves them before the full-suite run
- Fixed: hash command and no-HEAD → Story 2 criterion 3 names `git diff HEAD --name-only`, `git ls-files -o --exclude-standard`, `git hash-object` and the empty tree
- Fixed: false mismatch from test output; mismatch handling → Story 2 criterion 6
- Fixed: `lines undone` names its file → Story 1 criterion 1 (spec FR14's form to follow, under the Needs you item above)
- Fixed: every test-proven criterion takes a red except `existing` → Story 2 criterion 1
- Fixed: resume adds a red or `existing` → Story 3 criterion 4
- Fixed: grep criteria name their strings and both files → Story 2 criterion 8, Story 3 criterion 1
- Fixed: `existing` keyed, control defined, "unchanged" means the test's own body, severity a Warning → Story 1 criterion 2
- Fixed: delegated pass roles → Story 3 criterion 6 (lead writes the `**Scratch**` line and manifest, compares it itself, and writes `Evidence` after checking the reported failures)
- Fixed: audit-overlap rule moved to 49-02 Story 2, which defines the not-free mode, with scope judged from the file list given
- Fixed: a `**Scratch**` line whose directory is gone → Story 3 criterion 3
- Not acted on: a fix to a called function in another file leaves a red stale → accepted; the red still shows the cited test can fail, and the auditor reads the fix
- Fixed: builder directories dropped → Story 3 criterion 1
- Fixed: Story 3 `**Effort**: high`
- Fixed: Lessons line rewritten
- Not acted on: a cold reader for `[manual]` criteria → the auditor already reads each story with none of the builder's reasoning, which is that reader
