# The test-writer, and how do, the runs and the auditor use it

**Source spec**: docs/specifications/56-spec-independent-acceptance-tests.md  
**Date**: 2026-11-11  
**Status**: Pending  
**Blocked by**: Epic 56-01-epic-contract-and-plan  
**Amended**: review 13 (docs/reviews/13-review-independent-tests.md) — the writer runs no tests, gets `plan`'s path, writes from the documentation when a sample is due, names its files by the story and freezes the clock; `do` gives the writer its prompt and directory, runs a marked schema-first story's writer before its code, caps the returns, rewrites the blobs after the last return and after a worktree commit, and names the field's files to the auditor; a revision rewrites the blob and excuses nothing else; `test-runs.md` covers every rule that reads a failure as someone else's; the auditor checks against the story's diff when there is no commit; greps that already hit at base replaced; Story 3 after Stories 2 and 4; the pre-build red held in the run directory until step 3, after the spec's FR8 amendment (2026-11-11)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 3), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 4), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 3), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 4), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 3), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/02-library-planning-time-lessons.md → "Read what iterates a set before adding a member to it" (Story 3), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (build), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (build)

**Base.** `{base}` is `0a4e609`; every diff is `git diff {base}`. The history check is 56-01's. A grep that gives a count "in the added lines" runs over `git diff {base} -U0 -- {file} | grep '^+'`, so text already in the file at `{base}` does not satisfy it.

## The test-writer agent
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR5, NFR1, NFR3

**Acceptance Criteria**:

- `cpm-next/agents/test-writer.md` exists with frontmatter `name: test-writer`, `model: opus`, a `description` saying `/cpm-next:do` starts it, and tools `Read, Grep, Glob, Bash, Write, Edit`; `claude plugin validate cpm-next` passes `[manual]`
- The agent file states its inputs (the story, the spec with **Data Sources**, the sample paths, the absolute paths of the contract and of `plan/SKILL.md` for its Epics paragraph's control and floor rules, the test command and formatter, its scratch directory, a stopped writer's files) and that it has none of the conversation `[manual]`
- It states what it writes, over every criterion a test proves: tests only through the boundary the story names (entry point, outbound seam, stored state), asserting only what the criteria, spec and samples state; at least one test per test-proven criterion; a check that each sample's identity values are unique; the identity and conservation criteria built from the sample, with colliding records added where it has none; the clock frozen at the sample's date where the sample holds dates; with a source whose bullet reads `sample due`, fixtures from the documentation's examples, with colliding records added; `plan`'s control and floor rules applied to its own tests, by reference to that paragraph `[manual]`
- It states its limits: it writes only new files (tests and fixtures), each with `{epic file stem}-{story}` in its path, in a directory the project's full run covers, checked against the test-runner config; it may replace or delete a stopped writer's files it was given; it edits no file it did not create; it runs the project's formatter on its files; it runs no tests. Positive greps in the file: `{epic file stem}-{story}` 1, `runs no tests` 1. Control: a sentence giving it leave to edit an existing test, factory, base test case or config, planted in a copy of the file, is found by reading the limits paragraph, and the shipped file holds none `[manual]`
- It states its report: each file written, and for each test the criterion it proves `[manual]`
- It names the contract's forms without restating them: `grep -cF "{path} {blob}"` and `grep -cF "sample due: {"` over the file give 0 `[manual]`
- The file is read with the history check, and none of it records history `[manual]`

### Write the agent
**Task**: 1.1  
**Description**: Write `cpm-next/agents/test-writer.md`.  
**Status**: Pending

---

## Do runs the writer before the build and holds the builder to its tests
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR6, FR7, FR8, FR11, FR12, NFR1, NFR3  
**Effort**: high

**Acceptance Criteria**:

- `do/SKILL.md` states the order for every story whose field reads `due`: the test-writer (`subagent_type` `cpm-next:test-writer`) is started before any of the story's code is written; in a batch, one per marked story, in parallel, after any schema-first story and before fan-out, and a schema-first story that is itself marked has its writer run before the lead builds it `[manual]`
- It states the writer's prompt, as **Audit** lists the auditor's: the story, the spec, the sample paths, the absolute paths of the contract and of `plan/SKILL.md`, the test command and formatter, a fresh writer directory under the run directory (**Scratch directories and isolation** names it beside the auditor's), and on a resumed story the files a stopped writer left, found by the story's `{epic file stem}-{story}` in their paths `[manual]`
- It states the pre-build run: the lead checks the writer's report against the files and runs each story's independent tests, one story at a time and never beside another test run; the run does not rewrite `**Test run**`; a test that errors for a cause other than the boundary not existing goes back to the writer; a passing test is kept when it is a must-not or never criterion's or asserts behaviour the code already has, and otherwise goes back to the writer; each test goes back at most once for each cause, after which an error marks the story blocked with a signal and a pass raises its criterion through **When a criterion looks wrong**. Floor: the rule that two test runs never overlap in one checkout (`{base}` `do/SKILL.md:90`) is unchanged `[manual]`
- It states the field's rewrite in the contract's form, over every file the writer wrote, after the last return to the writer and, in worktree mode, after the commit before fan-out `[manual]`
- It states the `before the build` red by reference to the contract: when it applies; that the lead holds each in the run directory until step 3 writes it into the criterion's `Evidence` line, and writes no `Evidence` line before the build; and that every other independent test, and one whose red was lost when a run stopped, takes its red in the red pass. Floor: step 4's red pass rules at `{base}` are all still there; `grep -cF "red: {message} — before the build"` over `do/SKILL.md` gives 0 `[manual]`
- It states the builder's limits over every file on the field: none is edited, the simplifier and the project's formatters are not run over them, and each criterion an independent test proves cites it in `Evidence`. It states the dispute route: a citation may not be a `file:line` the story wrote; the lead, never a parallel subagent, starts a fresh writer with the inputs above, the test and the citation; a revision rewrites that file's blob on the field and appends the ` — revised` note, and takes the red pass; one dispute per test, after which the story builds to it or is marked blocked with a signal `[manual]`
- **Audit**'s list of what the auditor is given adds the files on the story's `**Independent tests**` line, in every build mode `[manual]`
- Step 4's list of unexpected inputs adds records colliding on an attribute that is not their key and the same identity twice in one delivery. Floor: `empty, missing, null, non-numeric, boundary` is still there `[manual]`
- It states the unavailable case: the field is rewritten `skipped — test-writer unavailable`, the story is built as unmarked, and **Found** says so `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/skills/do/SKILL.md` are read with the history check, and none records history `[manual]`

### Edit do's loop, parallel rules, audit prompt, scratch directories and criterion route
**Task**: 2.1  
**Description**: Edit **The loop** steps 1 to 5, the parallel rules, **Scratch directories and isolation**, **Audit** and **When a criterion looks wrong** in `cpm-next/skills/do/SKILL.md`.  
**Status**: Pending

---

## The runs know whose tests these are
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 2, Story 4  
**Satisfies**: FR10, NFR1, NFR3  
**Effort**: high

**Acceptance Criteria**:

- `shared/test-runs.md`'s targeted set adds the files on the story's `**Independent tests**` line, for every story with that line, in either build mode. Floor: the three bullets at `{base}` are all still there `[manual]`
- It states once that a failing test in a file on the line of a story not yet Complete belongs to that story, and every rule that reads a failure as another story's or as pre-existing follows it: the baseline (`do/SKILL.md` **Before the first story**, and the finish line's "failing at the baseline"), **A failing targeted run** (a test the story did not add), and **The deferred full run**'s **A pass**, **A failure** and **Every regression**; the story closes only when its own independent tests pass. Each of those six places names the rule or refers to it, found by reading; in the added lines, `belongs to that story` 1 `[manual]`
- Wide reach's shared-test-setup bullet adds that a fixture or factory file a story's writer or builder added, read only by that story's tests, is not wide reach, the writer's files committed before fan-out included. Floor: the seven wide-reach bullets at `{base}` are all still there `[manual]`
- The rule is stated in `test-runs.md` only: `grep -n -i "independent test" cpm-next/skills/do/SKILL.md cpm-next/agents/auditor.md` hits are read, and none states the baseline or regression rule; a sentence restating it, planted in a copy of `do/SKILL.md`, is found by the same grep `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/shared/test-runs.md cpm-next/skills/do/SKILL.md` from this story are read with the history check, and none records history `[manual]`

### Edit test-runs.md
**Task**: 3.1  
**Description**: Edit **The targeted set**, **Wide reach**, **A failing targeted run** and **The deferred full run** in `cpm-next/shared/test-runs.md`, and the baseline bullet and finish line in `do/SKILL.md` by reference.  
**Status**: Pending

---

## The auditor checks the independent tests
**Story**: 4  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR9, FR11, FR12, NFR1, NFR3

**Acceptance Criteria**:

- `auditor.md`'s allowed git commands add `git hash-object`. Floor: `git diff`, `git status`, `git log` and `git show` are still listed `[manual]`
- Check 5 states each Critical: a file on the field whose blob differs from the one recorded on the field (a revision having rewritten it); a marked story whose field still reads `due`; a criterion an independent test proves whose `Evidence` line does not cite that test; a change the story made to shared test setup, test-runner config, factories or environment, or code that branches on the test environment or names a sample's values, that changes what an independent test checks. In check 5's added lines: `hash-object` 1, `still reads \`due\`` 1, `does not cite that test` 1, `test environment` 1 `[manual]`
- Check 5 states when a `before the build` red is accepted: the file still matches its blob; the boundary existed at the story's start, read from the commit before the story where there is one and otherwise from the story's diff (the entry point not added by it); and the failure text is what the cited assertion prints; and that the undo and mutation Warning does not apply to it. Floor: the red-pass Warnings at `{base}` (`auditor.md:24`) are all still there `[manual]`
- Check 6's list of unexpected inputs adds records colliding on an attribute that is not their key and the same identity twice in one delivery. Floor: `Empty, missing, null, non-numeric, NaN and boundary` is still there `[manual]`
- The auditor states that `skipped — test-writer unavailable` is not a finding `[manual]`
- It names the contract's forms without restating them: `grep -cF "{path} {blob}"` and `grep -cF "red: {message} — before the build"` over `auditor.md` give 0 `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/agents/auditor.md` are read with the history check, and none records history `[manual]`

### Edit the auditor
**Task**: 4.1  
**Description**: Edit the allowed commands and checks 5 and 6 in `cpm-next/agents/auditor.md`.  
**Status**: Pending

---
