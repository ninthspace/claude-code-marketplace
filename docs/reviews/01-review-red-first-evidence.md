# Review: Red-first evidence

**Date**: 2026-10-30  
**Source**: docs/epics/47-01-epic-red-first-evidence.md  
**Reviewers**: Ren, Bella, Casey  
**Findings**: 15 (3 critical, 9 warnings, 3 suggestions)

## Summary

The epic covers FR1-FR5 and its `**Satisfies**` lines are accurate. All three reviewers found the same Critical: Story 1's undo method (`git show HEAD:{path} > {path}` "and back") overwrites uncommitted work, empties a new file, and contradicts the library lesson the epic cites. Story 1 also left the auditor's remaining test runs (do:100, auditor:56) and fix tests in step 5 untouched, so the auditor would still be told to reproduce reds. All Critical and Warning findings were fixed in the Pending stories, except one that departs from FR1's wording, which waits on the user.

## Findings

- **[Critical]** 📅 **Ren**, 💻 **Bella**, 🧪 **Casey**: restoring from HEAD discards earlier stories' and the user's uncommitted edits (`do` leaves commits to the user, do:108), empties a file the story created, has nothing to restore "back" from, and contradicts library 01 "A control mutation needs a revert that cannot take the tree with it"  
  → Story 1, criterion 3
- **[Critical]** 💻 **Bella**: undoing a whole file usually produces an error (undefined method), which the same rule says does not count; the undo-then-mutate order of AD2 is in no criterion  
  → Story 1, criteria 1 and 3
- **[Critical]** 💻 **Bella**, 🧪 **Casey**, 📅 **Ren**: do:100 ("runs one only to show that it can't fail"), step 5 ("a test that fails without it") and auditor:56 ("fails without the fix") keep the auditor reproducing reds; Story 3 froze auditor:56 and no story touched do:100  
  → Story 1, Story 3 criterion 5
- **[Warning]** 📅 **Ren**: FR1's scope (tags the Testing Strategy maps to a suite, untagged legacy criteria) is in no criterion  
  → Story 1, criterion 1
- **[Warning]** 📅 **Ren**, 💻 **Bella**: no owner for the red in worktree mode (the lead writes `Evidence`, do:88), in the write-code-only fallback, or for fix tests  
  → Story 1
- **[Warning]** 💻 **Bella**: a subagent mutating in the shared checkout reaches sibling stories' tests; the criterion narrowed FR1's batch rule to the lead only  
  → Story 1, criterion 2
- **[Warning]** 💻 **Bella**: a run interrupted mid-mutation leaves the broken line on disk  
  → Story 1, resume
- **[Warning]** 📅 **Ren**, 💻 **Bella**, 🧪 **Casey**: the grep criterion passes if the old sentence stays and the new rule uses other words, and fails if the rule drops the phrase  
  → Story 1, criterion 5
- **[Warning]** 🧪 **Casey**: undo leaves refactor, characterisation and unchanged-code tests green, and "only its own story's lines" forbids the mutation they need  
  → Story 1, criteria 1-2
- **[Warning]** 🧪 **Casey**: no green rerun after restore, and no failure text recorded, so a failed restore, a flaky red or an error-as-red is invisible  
  → Story 1, Story 3
- **[Warning]** 📅 **Ren**, 💻 **Bella**, 🧪 **Casey**: no mapping from `n/a` reason to tag; `user` and `browser-observed` refer to tags epic 47-04 defines  
  → Story 2, Story 3 criterion 3
- **[Warning]** 🧪 **Casey**: Story 4's control falls short of the lessons it cites (remove the condition and run the same inputs, in the same fixture; a floor on a set comparison)  
  → Story 4, criterion 1
- **[Suggestion]** 📅 **Ren**, 💻 **Bella**: Story 1 should be `**Effort**: high`  
  → Story 1
- **[Suggestion]** 💻 **Bella**: the small-change path (do:33) writes criteria too and gets no negative-criterion rule  
  → Story 4
- **[Suggestion]** 📅 **Ren**: the epic's own negative criteria name no control; Story 2's `mutation of {line}` differs from FR2's `mutation`  
  → Stories 1, 3

## Remediation

- Fixed: HEAD restore → Story 1 now copies the file to the scratch directory, edits with the Edit tool, copies it back, and reruns green; git restore commands are forbidden
- Fixed: undo produces an error → Story 1 gives the order: undo first, mutate where undo leaves green or errors
- Fixed: auditor still reproducing reds → Story 1 task 1.2 amends step 5 and do:100; Story 3 criterion 5 now changes auditor:56 to read the fix test's recorded red
- Fixed: FR1 scope → Story 1 criterion 1 names it
- Fixed: owner of the red → Story 1 names builder, lead after a batch, or worktree subagent reporting it
- Fixed: subagent mutation in a shared checkout → Story 1 says never a subagent while siblings run
- Fixed: interrupted mutation → resume restores from a left-behind scratch copy
- Fixed: grep criteria → each now asserts the old sentence is gone, with the count on the commit before as the control
- Fixed: undo leaves tests green → mutation of any covered line is allowed where undo proves nothing (see Needs you)
- Fixed: green rerun and failure text → both are in the literal red form and in Story 3's checks
- Fixed: `n/a` mapping → Story 2 defines it in the contract, checked only on tagged criteria; the contract may name `[user]` and `[browser]` before 47-04 defines them, since both ship in one release
- Fixed: Story 4 control → criterion now requires removing the condition with the same inputs in the same fixture, and a floor for set comparisons
- Fixed (suggestion applied with its Warning): Story 1 `**Effort**: high`; small-change path in Story 4 task 4.2; controls on the epic's own negative criteria; one literal red form at the top of the epic
- Needs you: FR1 says the builder "undoes or mutates only its own story's lines"; Story 1 now allows mutating any covered line where undoing the story's lines proves nothing → user chose (2026-10-30) to amend FR1 to "any line the cited test covers" through `/cpm-next:plan`; Story 1 stays as amended
- Not acted on: epics 47-01 to 47-04 share files with no `**Blocked by**` → `do` builds stories that share files one at a time already (do/SKILL.md, parallel rule)
- Not acted on: a mutation going live in a running dev server or a cached route making an undo look green → the mutation lasts one test run, and tests do not read the route cache by default
- Not acted on: NFR1 has no per-epic word budget → 47-05 checks the total; recorded as a suggestion
