# Red-first evidence

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/library/01-library-lessons-learned.md#a-control-mutation-needs-a-revert-that-cannot-take-the-tree-with-it, docs/library/01-library-lessons-learned.md#a-control-is-only-a-control-once-you-have-watched-it-fail-and-read-why, docs/library/01-library-lessons-learned.md#a-must-not-stated-as-an-equality-is-a-change-detector-and-a-set-comparison-needs-a-floor, docs/library/01-library-lessons-learned.md#a-check-that-passes-may-be-passing-for-a-reason-other-than-the-one-you-want  
**Amended**: 2026-10-30 — Story 4's first criterion changed after its first audit: the control is the check failing with the forbidden outcome present, and the floor names members, not a size — cited: docs/library/01-library-lessons-learned.md:103 ("asserting the set is non-empty is not enough"); no upstream document disagrees (FR5 asks only for a control)
**Amended**: 2026-10-30 — Stories 1-4 rewritten after review 01 (docs/reviews/01-review-red-first-evidence.md): revert by scratch copy, not git; undo-then-mutate order; who takes the red in each build mode; fix tests and the auditor's remaining test runs; tag-to-reason mapping; controls on this epic's negative criteria

The red-result line used throughout this epic is, literally:
`Evidence: {test name, file:line} ({command}) — red: {failure text, shortened} with {lines undone | mutation of {file:line}: {change}}; green after restore`
and for a criterion no test proves:
`Evidence: {proof} — red: n/a — {manual | user | browser-observed | static}`

## do records the red result for each test-proven criterion
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 4 findings fixed — the round-4 Warning was fixed after the last audit and accepted unaudited by the user (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR1, FR4, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `do` step 4's sentence "For each test the story added, confirm it fails without the change: undo the line it covers and run it, or show why it must." is replaced by a rule that applies to every criterion a test proves, that is, any criterion whose tag the project's Testing Strategy maps to a suite, and any untagged criterion a test proves. Control: `grep -c "undo the line it covers and run it" cpm-next/skills/do/SKILL.md` returns 0 after the change and 1 on the commit before it `[manual]`
  - Evidence: `grep -c "undo the line it covers and run it" cpm-next/skills/do/SKILL.md` — 1 at `2f406b1`, 0 now; step 4 (`do/SKILL.md:49`) applies the rule to every criterion a test proves, by tag mapped to a suite or untagged — red: n/a — manual
- The rule records the red in the criterion's `Evidence` line in the literal form above, naming the cited test, the failure text and the change made; it says an error (missing class, method, route or table) does not count and a stub that returns a wrong value does `[manual]`
  - Evidence: `do/SKILL.md:49` appends the red to the `Evidence` line "as the contract shows" (`artifacts.md:134`), says an error (missing class, method, route or table) doesn't count and a wrong-value stub does — red: n/a — manual
- The rule gives the order: undo the lines the test covers first; where that leaves the test green (a refactor, a characterisation test, a test over code the story did not change) or makes it error, mutate the covered line instead `[manual]`
  - Evidence: `do/SKILL.md:49` — undo the covered lines first; where that leaves it green (refactor, characterisation test, unchanged code) or errors, mutate a covered line — red: n/a — manual
- The rule gives the method: copy the file to the scratch directory, make the change with the Edit tool, run only the cited test, read its failure text, copy the file back, and run the test again to see it green. It forbids `git checkout`, `git show … >`, `git stash` and `reset` for this. Control: the sentence names the copy-back and the green rerun, so a builder who skips either has no `green after restore` to write `[manual]`
  - Evidence: `do/SKILL.md:49` — copy each file once into a scratch directory made for this red alone, at a path that keeps its repo location, then undo (copying back before any mutation) or mutate with the Edit tool, read the failure, copy back, run green again, delete the scratch directory and the story's `**Scratch**` line, which is written first and names the directory (one that remains marks an interrupted red); forbids `git checkout`, `git show … >`, `git stash`, `reset`. Without the copy-back and rerun there is no `green after restore` to write — red: n/a — manual
- The rule says the red is taken after the simplifier pass, and says who takes it: in a single build, the builder; in a parallel batch in one checkout, the lead, after the batch, never a subagent while siblings run; in worktree mode, the subagent in its own worktree, reporting the red line with its other evidence `[manual]`
  - Evidence: `do/SKILL.md:49` — after the simplifier pass; builder in a single build, lead after the batch (never a subagent while siblings run), subagent in its own worktree (the lead after merging where subagents write code only); worktree report list at `do/SKILL.md:88` adds the red — red: n/a — manual
- Step 5 says each fix test gets a red recorded the same way, in the `Evidence` line of the criterion the finding concerns, or, for a finding with no criterion, in the findings list handed to the next audit `[manual]`
  - Evidence: `do/SKILL.md:50` — fix tests get a red per step 4, in the criterion's `Evidence` line or the findings list handed to the next audit — red: n/a — manual
- **Audit**'s "it reads the tests, and runs one only to show that it can't fail" becomes: it reads the tests and their recorded red results, and runs none to reproduce a red. Control: `grep -c "runs one only to show that it can't fail" cpm-next/skills/do/SKILL.md` returns 0 after, 1 before `[manual]`
  - Evidence: `grep -c "runs one only to show that it can't fail" cpm-next/skills/do/SKILL.md` — 1 at `2f406b1`, 0 now; `do/SKILL.md:100` now reads "reads the tests and their recorded red results, and runs none to reproduce a red" — red: n/a — manual
- The resume rule in **Before the first story** adds a red result to an evidenced, unaudited story before it is audited, and restores any file whose scratch copy from an interrupted red was left behind `[manual]`
  - Evidence: `do/SKILL.md:40` adds a red to each test-proven criterion lacking one before the audit, and restores any file an interrupted red left mutated — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines in `git diff -U0 -- cpm-next` read; `grep -nE "no longer|used to|previously|0\.[0-9]+\.[0-9]|retro [0-9]|ice-"` over them returns nothing — red: n/a — manual

### Replace step 4's sentence with the recorded-red rule
**Task**: 1.1  
**Description**: Edit step 4 of `cpm-next/skills/do/SKILL.md`, and the worktree subagent report list.  
**Status**: Complete

### Fix tests and the auditor's prompt
**Task**: 1.2  
**Description**: Edit step 5 and **Audit** in `cpm-next/skills/do/SKILL.md`.  
**Status**: Complete

### Extend the resume rule
**Task**: 1.3  
**Description**: Edit the "Resume honestly" bullet in **Before the first story**.  
**Status**: Complete

---

## The contract shows the red result and maps n/a reasons to tags
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30), 2 findings fixed  
**Blocked by**: —  
**Satisfies**: FR2  
**Effort**: low

**Acceptance Criteria**:

- The example under "Evidence against each criterion" in `cpm-next/shared/artifacts.md` shows both literal forms at the top of this epic `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:134` and `:136` show both literal forms — red: n/a — manual
- The contract maps each `n/a` reason to the criterion it fits: `manual` to a `[manual]` criterion, `user` to `[user]`, `browser-observed` to a `[browser]` criterion checked with claude-in-chrome, `static` to a `[manual]` or untagged criterion proven by reading code or by `grep` with no test. It says a criterion a test proves takes no `n/a`, and that the mapping is checked only on tagged criteria `[manual]`
  - Evidence: `artifacts.md:141` maps `manual`, `static`, `user` and `browser-observed` to the tags they fit (`static` also an untagged criterion proven by reading or `grep`), says a test-proven criterion takes no `n/a`, and says the fit is checked only on tagged criteria — red: n/a — manual
- The sentence after the example says a test-proven criterion's evidence is incomplete without its red result `[manual]`
  - Evidence: `artifacts.md:141` opens "A test-proven criterion's evidence is incomplete without its red result" — red: n/a — manual

**Amended**: Story 2's second criterion limits `static` to a `[manual]` or untagged criterion and says a test-proven criterion takes no `n/a` (2026-10-30) — cited: Story 3's third criterion, whose Critical for a reason that doesn't fit its tag cannot be applied to a `static` reason with no tag; no upstream document disagrees (FR2 asks for each reason mapped to the tag it fits, and giving `static` a tag is closer to that than leaving it with none)

### Extend the evidence example
**Task**: 2.1  
**Description**: Edit the evidence section of `cpm-next/shared/artifacts.md`.  
**Status**: Complete

---

## The auditor reads the red result instead of breaking lines
**Story**: 3  
**Status**: Complete  
**Audit**: pass (2026-10-30), 3 findings fixed  
**Blocked by**: —  
**Satisfies**: FR3, NFR2  
**Effort**: high

**Acceptance Criteria**:

- Check 5 in `cpm-next/agents/auditor.md` no longer tells the auditor to break a line in a scratch copy or to run a test to show it can fail. Control: `grep -c "break the line in a scratch copy" cpm-next/agents/auditor.md` returns 0 after, 1 before `[manual]`
  - Evidence: `grep -c "break the line in a scratch copy" cpm-next/agents/auditor.md` — 1 at `2f406b1`, 0 now — red: n/a — manual
- Check 5 reports a Warning when a test-proven criterion's red result is missing, names a test other than the one cited, has failure text that shows an error rather than the cited assertion failing, describes an undo or mutation the cited assertion does not depend on, or lacks `green after restore` `[manual]`
  - Evidence: `agents/auditor.md:24` lists the five Warning cases: missing, wrong test, error not assertion, undo or mutation the assertion doesn't depend on, no `green after restore` — red: n/a — manual
- Check 5 reports a Critical when a tagged criterion's `n/a` reason does not match its tag under the contract's mapping `[manual]`
  - Evidence: `agents/auditor.md:24` reports a tagged criterion's `n/a` reason that doesn't fit its tag as Critical under the mapping in the contract, whose path `do`'s prompt gives (`agents/auditor.md:16`, `:24`; `do/SKILL.md:100`) — red: n/a — manual
- Check 5 keeps its existing findings: a test that asserts nothing meaningful, mocks the thing under test, or was weakened, skipped or deleted `[manual]`
  - Evidence: `agents/auditor.md:24` keeps assert-nothing, mocks-the-thing-under-test and weakened, skipped or deleted tests — red: n/a — manual
- The later-audit paragraph's "the test written for it fails without the fix" becomes a check of that fix test's recorded red, in the same terms as check 5; the rest of the paragraph is unchanged `[manual]`
  - Evidence: `agents/auditor.md:56` now reads "has a recorded red (in the criterion's `Evidence` line, or in the findings list for a finding with no criterion), checked as check 5 does"; the rest of the paragraph is unchanged — red: n/a — manual

### Rewrite check 5 and the later-audit sentence
**Task**: 3.1  
**Description**: Edit check 5 and **A later audit** in `cpm-next/agents/auditor.md`.  
**Status**: Complete

---

## plan and small changes give each negative criterion its control
**Story**: 4  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR5, NFR2
**Audit**: pass (2026-10-30), 3 findings fixed

**Acceptance Criteria**:

- The **Epics** paragraph in `cpm-next/skills/plan/SKILL.md` says a criterion stating what must not happen, must not change, or never occurs names in its own text its control: the same inputs, in the same fixture, with the forbidden outcome present, fail the check (remove the guard, or make the forbidden change); and, where it compares a set, a floor that names members the set must contain `[manual]`
  - Evidence: `cpm-next/skills/plan/SKILL.md:52` states the control (same inputs and fixture with the forbidden outcome present fail the check: remove the guard or make the forbidden change) and a floor naming members of a compared set — red: n/a — manual
- The sentence gives the reason in one clause: a negative assertion with no control passes when the feature does nothing `[manual]`
  - Evidence: `plan/SKILL.md:52` closes the rule with "A negative assertion with no control passes when the feature does nothing." — red: n/a — manual
- `do`'s small-change paragraph, which writes criteria for a `docs/quick/` record, applies the same rule by reference to it rather than restating it `[manual]`
  - Evidence: `do/SKILL.md:33` applies the **Epics** paragraph of `skills/plan/SKILL.md` by reference, with its path and all three forms (must not happen, must not change, never occurs), without restating it — red: n/a — manual

### Add the negative-criterion rule to plan
**Task**: 4.1  
**Description**: Edit the **Epics** paragraph of `cpm-next/skills/plan/SKILL.md`.  
**Status**: Complete

### Apply it to small changes
**Task**: 4.2  
**Description**: Edit the small-change paragraph of `cpm-next/skills/do/SKILL.md`.  
**Status**: Complete

---
