# Review: Independent acceptance tests and real source samples — epics

**Date**: 2026-11-11  
**Source**: docs/epics/56-01-epic-contract-and-plan.md, docs/epics/56-02-epic-test-writer-do-and-audit.md, docs/epics/56-03-epic-release.md  
**Reviewers**: Jordan (pm), Bella (dev), Tomas (qa)  
**Findings**: 34 (5 critical, 22 warnings, 7 suggestions), after merging duplicates across the three reports; 0 decided at challenge

## Summary

The personas were picked outside the challenge's `architect` and `test`, and each was given a copy of the spec without its **Challenge** section. No finding repeated one of the challenge's three `Rejected` decisions. Two findings reach the spec: a `before the build` red written into an `Evidence` line before anything is built reads as evidence to the contract, `do`'s resume and waiting rules and both mods; and the `sample due` story holds test criteria over a sample its own `[user]` criterion supplies, so `do` would start its writer with no sample. The rest were fixed in the epics: a marked schema-first story's writer ran after its code, the auditor's "commit before the story" does not exist in a single build, the release compared docs against a base spec 55 had since moved, the maintenance record has no list of agents, several greps already hit at base, and the writer had no rule on running tests, no path to `plan`'s rules, no way to find a stopped writer's files and no prompt in `do`.

## Findings

- **[Critical]** 🧑‍💻 **Bella** / 🔍 **Tomas**: a `before the build` red written into an `Evidence` line before the build counts as evidence for Complete (`artifacts.md:167`), waiting on the user (`do/SKILL.md:25`), resume (`do/SKILL.md:40`) and both mods (`whats-next/hooks/plan.ts:122`, `cpm-next-progress/hooks/progress.ts:30`)  
  → 56-01 Story 1, criterion 3; 56-02 Story 2 (spec FR8)
- **[Critical]** 🧑‍💻 **Bella**: a migration story is `**Effort**: high`, so marked, yet writers ran "after any schema-first story", after its code  
  → 56-02 Story 2, criterion 1
- **[Critical]** 🧑‍💻 **Bella** / 📋 **Jordan** / 🔍 **Tomas**: "`git show` against the commit before the story" has no commit in a single build (`do/SKILL.md:76`); FR9's "or the diff" was dropped  
  → 56-02 Story 4, criterion 3
- **[Critical]** 📋 **Jordan** / 🔍 **Tomas**: `git diff 0a4e609 -- .claude-plugin/marketplace.json` already shows two version lines changed (spec 55's 7220f77, 1d2b141); the README, guides and maintenance record moved too  
  → 56-03 Story 1, criteria 1, 3, 5
- **[Critical]** 🔍 **Tomas** / 🧑‍💻 **Bella** / 📋 **Jordan**: the maintenance record has no list of the agents `do` starts, and its "Unknown fields" bullet, which the criterion edits, had changed since base  
  → 56-03 Story 1, criterion 5
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: the `sample due` user-checks story holds test criteria over the sample its own `[user]` criterion supplies; `do` picks it and starts a writer with no sample; FR2's "own test-writer in new files" dropped  
  → 56-01 Story 2, criterion 2 (spec FR2)
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Tomas**: the writer has Bash and runs in parallel with no rule on running tests (`do/SKILL.md:90`)  
  → 56-02 Stories 1 and 2
- **[Warning]** 🧑‍💻 **Bella**: no criterion for the writer's prompt or its scratch directory  
  → 56-02 Story 2
- **[Warning]** 🧑‍💻 **Bella**: returns to the writer after the field is rewritten leave stale blobs; a worktree commit hook can reformat them  
  → 56-02 Story 2
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Tomas**: whether the pre-build run rewrites `**Test run**` (`artifacts.md:172`); no cap on returns for errors  
  → 56-01 Story 1; 56-02 Story 2
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Tomas**: "untracked files created since the story started" has no recorded start  
  → 56-02 Story 2, criterion 5
- **[Warning]** 🧑‍💻 **Bella** / 🔍 **Tomas**: the writer is told to apply `plan`'s rules but not given `plan/SKILL.md`  
  → 56-02 Story 1
- **[Warning]** 🧑‍💻 **Bella**: the marking rule's high-effort branch reads without the test-proven condition  
  → 56-01 Story 2, criterion 4
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: the `cite` grep hits check 5 five times at base (`auditor.md:24`)  
  → 56-02 Story 4, criterion 2
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: Story 3 checks `auditor.md` while Story 4 could land after it; Story 3's `do` edit escaped the history check  
  → 56-02 Story 3
- **[Warning]** 📋 **Jordan** / 🔍 **Tomas**: "a revision is noted" dropped the blob rewrite, and a ` — revised` note excused any later drift  
  → 56-02 Story 2, criterion 4; Story 4, criterion 2
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella**: two cases unstated: a marked schema-first story, and writers running tests in parallel  
  → 56-02 Story 2
- **[Warning]** 📋 **Jordan**: in worktree mode nothing tells the auditor to read the writer's files from the field  
  → 56-02 Story 2 (`do/SKILL.md:92-110`)
- **[Warning]** 📋 **Jordan** / 🧑‍💻 **Bella** / 🔍 **Tomas**: the "stated once" control ran before the other files existed, covered one form, and `cpm-next/README.md` will quote the form  
  → 56-01 Story 1, criterion 3; 56-02 Stories 1 and 4
- **[Warning]** 🔍 **Tomas**: the ownership rule must also cover **A failing targeted run**, **A pass** and the finish line's "failing at the baseline"; its grep hits existing text  
  → 56-02 Story 3, criterion 2
- **[Warning]** 🔍 **Tomas**: Story 3's "Independent tests" grep is case-sensitive  
  → 56-02 Story 3, criterion 4
- **[Warning]** 🔍 **Tomas**: Story 1's "each `existing` hit a limit" contradicts FR5's "reads the existing code"  
  → 56-02 Story 1, criterion 4
- **[Warning]** 🔍 **Tomas**: the writer's `sample due` case (documentation examples) has no criterion  
  → 56-02 Story 1
- **[Warning]** 🔍 **Tomas**: "the identity included" lets a builder redact every identity; FR1 says one that is personal data  
  → 56-01 Story 1, criterion 1
- **[Warning]** 🔍 **Tomas**: no criterion for freezing the clock at the sample's date  
  → 56-02 Story 1
- **[Warning]** 🔍 **Tomas**: lessons bearing but unlisted: "A check that passes may be passing for a reason other than the one you want" (56-01), "A control is only a control once you have watched it fail" and "Read what iterates a set before adding a member to it" (56-02); "stated once" (56-02 Stories 1 and 4) had no grep  
  → both **Lessons** lines; 56-02 Stories 1 and 4
- **[Warning]** 🔍 **Tomas**: 56-03's guides floor checks only `test-writer`  
  → 56-03 Story 1, criterion 3
- **[Suggestion]** 📋 **Jordan**: split 56-02 Story 2 into the pre-build run and the builder's limits
- **[Suggestion]** 📋 **Jordan**: check the writer edited no tracked file (`git status`)
- **[Suggestion]** 📋 **Jordan**: check `do` does not restate the writer's rules
- **[Suggestion]** 🧑‍💻 **Bella**: drop `Edit` from the writer's tools
- **[Suggestion]** 🧑‍💻 **Bella**: count the writer's files among the story snapshot's paths
- **[Suggestion]** 🔍 **Tomas**: say how the tag check counts void elements
- **[Suggestion]** 🔍 **Tomas**: list "A criterion's factual claim" on 56-03

## Remediation

- Fixed (user's decision, 2026-11-11, through `/cpm-next:plan`): the pre-build red held in the run directory until step 3 → spec FR8 amended; 56-01 Story 1 criterion 3; 56-02 Story 2 criterion 5
- Fixed (user's decision, 2026-11-11, through `/cpm-next:plan`): the `sample due` check as two stories, the marked one blocked by the user's → spec FR2 amended; 56-01 Story 2 criterion 2
- Fixed: a marked schema-first story's writer runs before its code → 56-02 Story 2 criterion 1
- Fixed: the boundary read from the commit before the story or the story's diff → 56-02 Story 4 criterion 3
- Fixed: `{docs-base}` `1d2b141` for the files spec 55 changed → 56-03 base note, criteria 1, 5
- Fixed: the maintenance record's two bullets named, no agent list → 56-03 criterion 5
- Fixed: the writer runs no tests → 56-02 Story 1 criterion 4
- Fixed: the writer's prompt and directory → 56-02 Story 2 criterion 2
- Fixed: blobs after the last return and after a worktree commit → 56-02 Story 2 criterion 4
- Fixed: the pre-build run off `**Test run**`; one return per cause → 56-01 Story 1 criterion 2; 56-02 Story 2 criterion 3
- Fixed: a stopped writer's files found by `{epic file stem}-{story}` in their paths → 56-02 Story 1 criterion 4, Story 2 criterion 2
- Fixed: `plan/SKILL.md`'s path among the writer's inputs → 56-02 Story 1 criterion 2
- Fixed: the marking rule's test-proven condition over both branches → 56-01 Story 2 criterion 4
- Fixed: greps that hit at base replaced with phrases counted in the added lines → 56-02 base note, Story 4 criterion 2, Story 3 criterion 2
- Fixed: Story 3 blocked by Stories 2 and 4; its history check covers its `do` edit → 56-02 Story 3
- Fixed: a revision rewrites the blob; only a blob difference is a Critical → 56-01 Story 1 criterion 2; 56-02 Story 2 criterion 6, Story 4 criterion 2
- Fixed: the field's files handed to the auditor in every build mode → 56-02 Story 2 criterion 7
- Fixed: the "stated once" control over every form after the last edit, with a planted control; per-file 0-hit greps → 56-03 criterion 6; 56-02 Stories 1 and 4
- Fixed: the ownership rule over all six places → 56-02 Story 3 criterion 2
- Fixed: a case-insensitive grep with a planted control → 56-02 Story 3 criterion 4
- Fixed: Story 1's limits checked by positive greps and a planted control → 56-02 Story 1 criterion 4
- Fixed: the writer's `sample due` case and frozen clock → 56-02 Story 1 criterion 3
- Fixed: the redaction rule's identity → 56-01 Story 1 criterion 1
- Fixed: the lessons → both **Lessons** lines and 56-03's
- Fixed: guide floors for every form → 56-03 criterion 3
- Fixed (Suggestions applied with fixes): the tag check's void elements, "A criterion's factual claim" on 56-03
- Not acted on: the remaining Suggestions → recorded only
