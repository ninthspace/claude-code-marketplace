# Targeted runs, with the full suite where a story justifies it

**Source spec**: docs/specifications/51-spec-full-suite-when-justified.md  
**Date**: 2026-11-09  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 2), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 3), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 3)  
**Amended**: review 08 (docs/reviews/08-review-targeted-runs.md) and the spec's amendment of 2026-11-09 — the rules move to `shared/test-runs.md`, with the snapshot, the run counter, the flaky and order-dependent branches, waiting and no-change stories, the baseline fix's place and the auditor's extra Warnings carried into every story (2026-11-09)

## The rules file and the run record
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-11-09), 9 findings fixed — the last fix was not audited, at the user's decision
**Blocked by**: —  
**Satisfies**: FR1, FR2, FR3, FR4, NFR3  
**Effort**: high
**Inline change**: the closing-story definition counts a story with only `[user]` criteria left, not only a story waiting on the user, since a user-checks story is blocked by the code story and so is not yet waiting; and the reasons list gains `deleted` and `renamed` (2026-11-09)  
**Signal**: definition-in-two-places — project — the rule for which reruns are full was stated in the trigger list and again in the rerun sentence, with different scope (`cpm-next/shared/test-runs.md`, audit round 1)  

**Acceptance Criteria**:

- `cpm-next/shared/test-runs.md` states the targeted set: cited tests; test files the story added or changed; per changed code file, the tests that call it or reach it through one caller, directly or by the name the framework resolves it by; and tests that iterate its directory, namespace or registry; not counting a test that fakes or mocks it, selected by file path. Control: it says a test file the story adds is in the targeted set, not wide reach `[manual]`
  - Evidence: `cpm-next/shared/test-runs.md` **The targeted set** (lines 7-13) lists cited tests, test files the story added or changed, and per changed code file the tests that call it, reach it through one caller or by the name the framework resolves, and the iterating tests; "A test that fakes or mocks the file does not run it", "selected by file path", and "A test file the story adds is in the set; it is not wide reach" — red: n/a — manual
- `test-runs.md` states the triggers for a full run (a wide-reach file, a changed code file no test runs, a deleted or renamed file) and the wide-reach list with every entry FR1 names, including the observable-change entry found by a grep for the qualified use. Control: it says a symbol added that nothing uses is not wide reach, and a story whose changed code files are all of narrow reach and each run by a test takes a targeted run `[manual]`
  - Evidence: **When the run is full** (lines 15-27) lists a wide-reach file, a changed code file no test runs, deleted or renamed; **Wide reach** (lines 29-39) lists the seven entries including the observable-change entry "found by a grep for its qualified use … not the bare method name"; "A symbol added that nothing uses yet is not wide reach"; the narrow-and-tested control is line 5, "A story takes a targeted run unless this file makes it full" — red: n/a — manual
- `test-runs.md` lists the exempt kinds (the epic doc, the `docs/quick/` record, prose no code, test, test config or build config reads) and says every code, config, fixture, test, view, template, translation or asset file is a code file. It defines the snapshot: changed and untracked non-exempt paths, each with its `git hash-object` blob hash, hashed together. Control: it says a second edit to a file already changed at the previous run changes the snapshot and makes the run stale `[manual]`
  - Evidence: **Exempt files and the snapshot** (lines 41-45) lists the epic doc, the `docs/quick/` record and prose no code, test, test config or build config reads, says every code, config, fixture, test, view, template, translation or asset file is a code file, defines the snapshot with `git hash-object` blob hashes hashed together, and says "a second edit to a file already changed at the previous run changes it" — red: n/a — manual
- `test-runs.md` states FR3's branches: a full run before any fix; a failing full run fixed, with every failed test in each rerun; a passing full run followed by one more targeted run, flaky on a pass, order-dependent on a second failure with full runs until close. It lists the reasons a full run records (`closes epic`, `small change`, `wide reach: {file} ({entry})`, `untested: {file}`, `deleted: {file}`, `renamed: {file}`, `targeted failure: {test}`, `order-dependent: {test}`, `sibling Story {n}`, `merge conflict`, `audit: run too narrow`). Control: a failure in a test the story added or changed triggers no full run `[manual]`
  - Evidence: **A failing targeted run** (lines 47-54): a full run before any fix, a failing full run fixed with every failed test in each rerun, a passing full run then one more targeted run (flaky on a pass, order-dependent on a second failure with full runs until close); **Reasons a full run records** (lines 56-60) lists the eleven reasons, `deleted: {file}` and `renamed: {file}` included; "A failure in a test the story added or changed is fixed without a full run" — red: n/a — manual
- `cpm-next/shared/artifacts.md` defines `**Test run**` among the fields `do` may add:
  - placement: one line in the header block before `**Acceptance Criteria**` (and in a `docs/quick/` record), with no sub-bullets, rewritten on every run but not by red-pass runs or probes;
  - form: `{n} ({f} full, {t} targeted) — {full | targeted | none} — {command}: {passed} passed, {failed} failed — tree {hash} — {reason or mapping}`;
  - `{failed}` counts failures and errors, a run of zero tests is not a pass, and a run over several runners gives a command and counts per runner;
  - a **Where things live** row names `shared/test-runs.md`, read by `do` and the auditor;
  - the field is not in the story template `plan` writes `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:163` defines the field in **Fields `do` may add to a story** with placement (header block before `**Acceptance Criteria**`, no sub-bullets, rewritten on every run but not by red passes or probes), the form with `{n} ({f} full, {t} targeted)` and `tree {hash}`, failures-and-errors, zero tests not a pass, per-runner commands and counts, and `none`; **Where things live** has the `Test-run rules` row naming `shared/test-runs.md`, written by the maintainer and read by `do` and the auditor; the field is not added to the story template — red: n/a — manual
- `grep -n -i "observer\|seeder\|conftest\|global scope\|hash-object" cpm-next/shared/artifacts.md` finds nothing, while the same grep over `cpm-next/shared/test-runs.md` finds the wide-reach list and the snapshot, so the contract holds only the field `[manual]`
  - Evidence: `grep -n -i "observer\|seeder\|conftest\|global scope\|hash-object" cpm-next/shared/artifacts.md` printed nothing, and the same grep over `cpm-next/shared/test-runs.md` hits lines 34, 36 and 45 (`conftest.py`, observers and global scopes, `git hash-object`) — red: n/a — static
- The new and added lines record no history (`CLAUDE.md`, "A SKILL.md is not a change log") `[manual]`
  - Evidence: read `cpm-next/shared/test-runs.md` and `artifacts.md:163` and the table row; `grep -n -i "was\|used to\|no longer\|previously\|replac\|instead of\|formerly"` over test-runs.md finds "a merge conflict was resolved" and "A snapshot that was not recorded, or no longer matches", both rules; `claude plugin validate cpm-next` — Validation passed — red: n/a — manual

### Write `test-runs.md` and the contract's field
**Task**: 1.1  
**Description**: Add `cpm-next/shared/test-runs.md`; amend `artifacts.md` with the `**Test run**` field and the **Where things live** row.  
**Status**: Complete

---

## `do` runs targeted by default and full where the story justifies it
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-11-09), 7 findings fixed — the last fix was not audited, at the user's decision
**Blocked by**: Story 1  
**Satisfies**: FR1, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR10  
**Effort**: high
**Inline change**: the control on a run that closes no epic (and its Evidence) quotes `do/SKILL.md:29` as "takes a full run only for a story `test-runs.md` makes full", which matches the rules, after the release audit found the broader wording false (2026-11-09)  
**Inline change**: the no-restatement grep drops `hash-object`, which the red pass's existing manifest text in `do/SKILL.md` already holds (2026-11-09)  

**Acceptance Criteria**:

- `cpm-next/skills/do/SKILL.md` reads `shared/test-runs.md` (two levels above its directory) before a story's step 4 and decides the run by it, naming the file and not restating its lists. It writes the `**Test run**` line on every run (in a `docs/quick/` record too). Control: it says a story whose changed code files are all of narrow reach, each run by a test, takes a targeted run `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:53` (step 4) "Read `shared/test-runs.md` and decide the story's run by it (a story takes a targeted run unless it makes the run full), run it, write the `**Test run**` line (in a `docs/quick/` record too)"; `:29` points to `shared/test-runs.md` beside the contract; the lists are in that file, not in `do` — red: n/a — manual
- `grep -n -i "observer\|seeder\|conftest\|global scope" cpm-next/skills/do/SKILL.md cpm-next/agents/auditor.md` finds nothing, while the same grep over `cpm-next/shared/test-runs.md` finds the lists, so they are not restated `[manual]`
  - Evidence: `grep -n -i "observer\|seeder\|conftest\|global scope" cpm-next/skills/do/SKILL.md cpm-next/agents/auditor.md` printed nothing; over `cpm-next/shared/test-runs.md` it hits lines 34 and 36 (`conftest.py`, observers, global scopes) — red: n/a — static
- Steps 4 and 5 apply `test-runs.md`'s FR3 branches to a failing targeted run. Control: a failure in a test the story added or changed triggers no full run `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:53` "A failing targeted run follows `test-runs.md`'s failing-run rules, in this step and step 5"; the branches and the added-or-changed-test control are `cpm-next/shared/test-runs.md` **A failing targeted run** — red: n/a — manual
- `do` defines a story that closes an epic: at its step 4 run, every other story in the epic is Complete or has only `[user]` criteria (or criteria treated as `[user]`) left. That story, and a small change, run full on every run in steps 4 and 5 and close only on a passing full run against the code being closed. A story whose diff holds no non-exempt file takes no run and records `none`. Control: a story that would otherwise run targeted runs full when it closes its epic, and a story not closing its epic runs targeted though it is the only story the run builds `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:53`: "A story closes its epic when, at its step 4 run, every other story in the epic is Complete or has only `[user]` criteria (or criteria treated as `[user]`) left; it and a small change run full on every run in this step and step 5, and close only on a passing full run against the code being closed. … A story whose diff holds no non-exempt file takes no run and writes `none`"; `test-runs.md` **When the run is full** says a story takes a targeted run unless the file makes it full, and the only story the run builds is not full for that reason — red: n/a — manual
- **Scope and finish line** says:
  - a result stands while a fresh snapshot hashes the same as the one in the `**Test run**` line;
  - only a full run stands for the baseline;
  - the finish line needs every story the run closed to have closed on a passing run of its kind, and every epic it closed to have closed on a passing full run, with no separate end-of-run full run.
  
  Steps 4 and 5 say a fix rerun is the story's targeted set, the fix's tests, the tests running any newly changed code file and every test that failed in the previous run, and is full when the fix has wide reach or the story closes its epic or is a small change. Control: a run is repeated after a second edit to a file already changed at the previous run, and a run that closes no epic takes a full run only for a story `test-runs.md` makes full `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:29` (baseline, snapshot, "A run that closes no epic takes a full run only for a story `test-runs.md` makes full", every epic closed on a passing full run, no separate end-of-run run); `:53` "running again after any change to a non-exempt file"; `:58` (step 5) "a fix rerun is the one `test-runs.md` gives"; the second-edit control is `test-runs.md` **Exempt files and the snapshot** — red: n/a — manual
- **Before the first story** says a baseline failure that a story closed on a targeted run in an In Progress epic explains is fixed in the next story this run builds in that epic. That fix is named in its audit prompt with the failing test, or, when the run builds none there, it goes under **Needs you** with a signal. Control: a baseline failure no such story explains is accepted as pre-existing `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:38` (**Before the first story**): a baseline failure a story closed on a targeted run in an In Progress epic explains is fixed in the next story built there, named in its audit prompt, or listed under **Needs you** with a signal; "A baseline failure no such story explains is pre-existing" — red: n/a — manual
- **Audit** says:
  - the prompt quotes the `**Test run**` line, gives the path of `test-runs.md`, and lists targeted tests as coverage, not for the auditor to run;
  - it names fixes made outside the story's files with the test whose failure each answers;
  - the items it hands over are the ones Story 3's `auditor.md` **What you are given** names.
  
  Step 5 says a Warning about a missing or too narrow run is settled by making the run, with no test and no red. A passing run fixes that finding and it needs no further round of its own, and only a failure it shows is fixed through step 5 `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:98-99` (**Audit**: the `**Test run**` line, the path of `shared/test-runs.md`, targeted tests as coverage not for the auditor to run, fixes made outside the story's files with the test each answers); `:58` (step 5) "A Warning that the run was missing or too narrow is settled by making the run, which needs no test and no red: when it passes, that finding is fixed and needs no further round of its own"; Story 3 names the same items in `auditor.md` — red: n/a — manual
- In the parallel rules, the lead's run after a batch is the union of the stories' targeted sets, or full when any story justifies one or the batch closes an epic. Each story's line names a sibling that forced a full run, and a one-checkout subagent's own-story run is its targeted run. `cpm-next/skills/do/worktree.md` says:
  - the subagent's prompt gives the paths of the contract and `test-runs.md`;
  - the lead's run after merging is the batch run, and is the one handed to each audit; a story that must run full leaves its run and red pass to the lead;
  - each story's tests are its targeted set;
  - after resolving a merge conflict the lead runs the full suite as the batch's run `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:65` (the lead's run after a batch is the union of targeted sets, full when a story justifies one or the batch closes an epic, a sibling named in each line) and `:66` (a subagent's own-story run is its targeted run); `cpm-next/skills/do/worktree.md:18` (the contract and `test-runs.md` paths), `:24` (the lead's run after merging is handed to each audit; after a conflict, full as the batch's run); `:14` (each story's targeted set) — red: n/a — manual
- Every sentence in `do/SKILL.md` and `worktree.md` that names the full suite or a test run applies to both kinds. `grep -n -i "full suite\|full-suite\|full run\|the suite\|test run\|tests run\|its tests\|run no test\|running it again"` over both files shows each hit is a baseline, wide-reach, untested-file, FR3, closing-story, small-change, parallel-batch or merge-conflict full run, or a rule written for either kind. Floor, each of which must read this way:
  - the overlap rule reads "two test runs, full or targeted, or a test run and a red pass";
  - the red pass's standing result is "full or targeted";
  - the resume bullet takes a step 4 run before its red pass and audit, and says a line whose snapshot no longer matches never stands;
  - a full run covers every test runner the baseline used, and a cited browser test is in the targeted set;
  - **Finishing**'s **Changed** reports full and targeted run counts from the lines, in place of a bare "test result against the baseline";
  - **Finishing**'s "take step 4" applies the run rule;
  - `worktree.md`'s "runs each story's tests" and "both stories' tests" read as targeted sets `[manual]`
  - Evidence: `grep -n -i "full suite\|full-suite\|full run\|the suite\|test run\|tests run\|its tests\|run no test\|running it again"` over `do/SKILL.md` and `worktree.md`, each hit read and each consistent with the rule: baseline (`SKILL.md:29`, `:37`, `:38`), small change (`:31`), resume (`:40`), step 4 (`:53`), the red pass's stand-for-the-audit sentence (`:56`, "full or targeted"), the mismatch rule and step 5 (`:57`, `:58`), the batch run (`:65`, `:66`), the overlap rule (`:90`, "two test runs, full or targeted, or a test run and a red pass"), the audit list (`:98`, `:99`, `:103`) and **Changed** (`:149`); `worktree.md:14`, `:19`, `:22`, `:24`, `:26`. A full run covers every runner the baseline used (`:53`); a cited `[browser]` test is in the targeted set (`:49`) — red: n/a — static
- The added lines record no history `[manual]`
  - Evidence: read the added lines of `git diff -U0 -- cpm-next/skills/do`; none records history (the hits for "no longer matches", "replaces" and "was given" are a rule or pre-existing wording) — red: n/a — manual
- `claude plugin validate cpm-next` passes `[manual]`
  - Evidence: `claude plugin validate cpm-next` — Validation passed; `claude plugin test` cpm-next 15, cpm-next-models 19, cpm-next-progress 54, whats-next 32 passed, 0 failed — red: n/a — manual

### Run choice, reruns, the closing story and the baseline
**Task**: 2.1  
**Description**: Amend `do/SKILL.md` **Scope and finish line**, **Before the first story** and steps 3 to 6.  
**Status**: Complete

### Parallel batches and worktrees
**Task**: 2.2  
**Description**: Amend `do/SKILL.md`'s parallel rules and **Scratch directories and isolation**, and `worktree.md`.  
**Status**: Complete

### Audit hand-over and Finishing
**Task**: 2.3  
**Description**: Amend `do/SKILL.md` **Audit** and **Finishing**.  
**Status**: Complete

---

## The auditor reads the run it was given
**Story**: 3  
**Status**: Complete  
**Audit**: pass (2026-11-09), 3 findings fixed  
**Blocked by**: Story 1, Story 2  
**Satisfies**: FR7, FR8  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/agents/auditor.md` (its opening paragraphs, **What you are given**, checks 1, 5 and 8) says:
  - the prompt gives the story's `**Test run**` line and the path of `test-runs.md`, and **What you are given** names exactly the items `do` **Audit** hands over;
  - a targeted result covers only the tests it ran, and the auditor checks the line's mapping against the test tree rather than searching afresh;
  - given a targeted result it runs no further suite, runs tests only when the suite is isolated or free, and never repeats a run it was given `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:12` ("work from the tests and the run result you were given. Given a targeted result, run no tests either way, and report what the run left out"), `:16` (**What you are given**: the `**Test run**` line, the run's result with targeted tests "listed as coverage, not for you to run", the path of `shared/test-runs.md`, the out-of-story fixes with their tests, and the red pass's matching-manifest statement — the items `do` **Audit** lists at `SKILL.md:98-101`), `:20` (check 1: "a targeted run only the tests it lists"), `:27` (check 8, "run the full suite yourself only when … the story's run was full and no result was given"); the sentence "Running part of it … shows nothing" is gone — red: n/a — static
- The auditor reports as a Warning each of these, by `test-runs.md`:
  - a test an `Evidence` line or a fix cites that is not in the last run's set;
  - a test that runs a changed code file but was left out;
  - a targeted run on a story `test-runs.md` makes full (wide reach, an untested, deleted or renamed code file, closing its epic, a small change, a sibling or merge conflict);
  - no run, or `none`, where `test-runs.md` requires one.
  
  Control: it says a targeted run on a story `test-runs.md` does not make full is not a finding `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:24` (check 5): four Warnings (a cited test not in the last run's set; a test that runs a changed code file but was left out, from the line's mapping against the test tree; a targeted run on a story `test-runs.md` makes full, with its reasons; no run, or `none`, where it requires one) and the control "A targeted run on a story it does not make full is not a finding" — red: n/a — static
- Check 3 says fixes the prompt names as answering a failure the story's full run or the baseline showed, made outside the story's files, are in scope and checked as new code. Control: it still reports other changes the story didn't ask for `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:22` (check 3) ends "The out-of-story fixes the prompt names are in scope: check them as new code"; the earlier sentence "Changes the story didn't ask for" stands — red: n/a — static
- `grep -n -i "full suite\|full-suite\|full run\|the suite" cpm-next/agents/auditor.md` shows no hit that assumes the given result is always full. Floor: each of these sentences now reads for either kind:
  - the opening's "full-suite result you were given";
  - **What you are given**'s "a full-suite run made before the audit";
  - check 1's "The full-suite run the prompt reports already ran those tests";
  - check 8's "Running part of it … shows nothing that result doesn't" `[manual]`
  - Evidence: `grep -n -i "full suite\|full-suite\|full run\|the suite" cpm-next/agents/auditor.md` hits `:12`, `:16`, `:24`, `:25`, `:27`; each read: none assumes the given result is always full; the four named sentences (opening, **What you are given**, check 1, check 8) read for either kind (`:12`, `:16`, `:20`, `:27`) — red: n/a — static
- The added lines record no history `[manual]`
  - Evidence: read the added lines of `git diff -U0 -- cpm-next/agents/auditor.md`; none records history; `claude plugin validate cpm-next` — Validation passed; `grep -n -i "observer\|seeder\|conftest\|global scope" cpm-next/agents/auditor.md` printed nothing — red: n/a — manual

### Amend the auditor
**Task**: 3.1  
**Description**: Amend `auditor.md`.  
**Status**: Complete

---
