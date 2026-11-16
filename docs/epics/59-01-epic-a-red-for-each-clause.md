# A red for each alternative and the control

**Source spec**: docs/specifications/59-spec-lessons-reach-cpm-next.md  
**Date**: 2026-11-15  
**Status**: Complete  
**Blocked by**: —  
**Amended**: the walk table's hash, pinned outcomes and floor; the `**Started**` cut-over; routes, completeness and NFR2 checks; the guides moved to Epic 59-04 (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A procedure names every route that calls it and every input each caller gives" (Story 2), docs/library/01-library-lessons-learned.md → "A walk-through's evidence claims only the agreement its runs show" (Story 2), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 2), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 3), docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "The revert method for a recorded red went through four rounds" (Story 2), docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion that names a mapping with no tag to key it on" (Story 2), docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "An agent receives only its own file as a prompt" (Story 2), docs/epics/58-01-epic-correctness.md → Story 2 → spec-drift (build)

## The walk table, written before the text changes
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR1, FR2, FR4, NFR3  
**Test run**: 0 (0 full, 0 targeted) — none  
**Audit**: pass (2026-11-16)  
**Amended**: rows may name several failed clauses; FR2's two findings pinned; the table's hash and trak's HEAD recorded (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md  
**Amended**: 03-02's clock-arithmetic test is graded as no test double, and the recount under the narrowed FR1 added (2026-11-16) — cited: `scripts/ab.ts:721` in opendaw-trak (`window.__ab.position()` is the page's own code); spec 59 FR1 and FR2 as amended (the user's decision)

**Acceptance Criteria**:

- `.git/cpm-next/checks/59/walk-table.md` gives one row for each of opendaw-trak's six `check-cannot-fail` signals written after 2026-11-13 (`docs/epics/03-01-epic-live-playback-load.md` Stories 3, 7, 8 and 9; `docs/epics/03-02-epic-remake-tooling.md` its two), each row naming the criterion, every clause that failed (quoted from the criterion, or "implied" with the words it is implied by, or "not in the criterion"), the red 0.21.1 accepts for that criterion, and the outcome FR1 and FR2 give per clause (a red required, a test double found, or out of reach, with why). Floor: all six signals have a row; 03-01 Story 9's ceiling-table test is given as a test double found and 03-02's clock-arithmetic test as none, with why (FR2's AC); at least one row's FR1 or FR2 outcome differs from what 0.21.1 accepts. `[manual]`
  - Evidence: `.git/cpm-next/checks/59/walk-table.md` Part A (`:18`–`:36`) holds 9 rows for the six signals (03-01 Stories 3, 7 — four checks on four criteria, 8, 9; 03-02 Stories 1 and 2), each naming the criterion, every failed clause, the red 0.21.1 accepts and the per-clause outcome; row A7 gives 03-01 Story 9's `runLines` fake as a test double found, and row A9 gives 03-02's clock-arithmetic test as none (`window.__ab.position()` is the page's own code, opendaw-trak `scripts/ab.ts:721`, read); `:34` names A1–A4 and A7 as differing from 0.21.1 — red: n/a — manual
- The same file gives one row for each of 03-01's three `criterion-contradicts-input` signals written after 2026-11-13 (Stories 1, 2 and 7), naming the claim, whether it concerns a runtime outside the repository's own code, whether the criterion states it, whether a probe in the session could reach it (a headless browser counting as reachable, not as hardware), and the outcome FR4 gives. `[manual]`
  - Evidence: Part B (`:38`) gives five rows for the three signals: Story 1's `playbackStats` type (a browser API, stated, reachable headless: contradicted by a probe before the build) and its plan choice (own code: out of reach); Story 2's openDAW warm-up loss (third-party engine, reachable, not stated: reached only where stated, so not reached); Story 7's `server.address()` and row rounding (own code: out of reach) — red: n/a — manual
- The same file counts the reds 03-01's test-proven criteria take under 0.21.1 (one per criterion) and under a red per clause, per story and in total, and names each criterion whose count reads two ways; `.git/cpm-next/checks/59/walk-table-narrow.md` regrades Part A and recounts Part C under a red per "or" alternative plus the control (FR1 as amended) and under a red per input path plus the control. `[manual]`
  - Evidence: Part C (`:50`) counts 03-01 at 50 reds under 0.21.1 and 205 under a red per clause, per story, with 32 criteria whose count reads two ways (`:72`–`:105`; `:106` adds Story 8 C2 and C3, two ways on whether they are test-proven); `walk-table-narrow.md` regrades Part A and recounts: 77 under a red per "or" alternative plus the control (catching A1, A2's session-port row and A7) and 127 under a red per input path plus the control, with the criteria that read two ways under each — red: n/a — manual
- The file records opendaw-trak's `git rev-parse HEAD` and `git status --short` when it was read, and Story 1's `Evidence` records the file's `git hash-object`, taken before any task of Story 2 or of Epics 59-02 and 59-03 starts. `[manual]`
  - Evidence: the header records opendaw-trak HEAD f88b8880d5783daed5767b64c538035f9282726a and its `git status --short`, and the pinned copies' hashes (`.git/cpm-next/checks/59/trak/state.txt`); `git hash-object` of `walk-table.md` is dee660adb22fcf552ada51ee73f887d782dd9b4f and of `walk-table-narrow.md` 288c5b592e55f8a6b841546f1dc0ba9a48be7245, taken 2026-11-16 before any task of Story 2 or of Epics 59-02 and 59-03 started (each still `Pending`) — red: n/a — manual

### Write the table from the records
**Task**: 1.1  
**Description**: Read the opendaw-trak epics named at a recorded HEAD, read only, write the table, and record its hash  
**Status**: Complete

---

## Reds for each alternative and the control, and where a red may come from
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR1, FR2, NFR1, NFR2  
**Effort**: high  
**Test run**: 2 (2 full, 0 targeted) — full — claude plugin test cpm-next: 15 passed, 0 failed; claude plugin test cpm-next-models: 20 passed, 0 failed; claude plugin test cpm-next-progress: 108 passed, 0 failed; claude plugin test whats-next: 34 passed, 0 failed — tree 62a710707dea754ae7cebef920c4ba1e1060d537 — untested: cpm-next/skills/do/SKILL.md; untested: cpm-next/skills/do/worktree.md; untested: cpm-next/skills/do/independent-tests.md — cpm-next/skills/do/SKILL.md → deferred full run; cpm-next/skills/do/worktree.md → deferred full run; cpm-next/skills/do/independent-tests.md → deferred full run; cpm-next/shared/artifacts.md, cpm-next/shared/auditor-independent-tests.md → exempt  
**Audit**: pass (2026-11-16), 2 findings fixed  
**Inline change**: criterion 7 runs the mods' parsers with Node's type stripping, `bun` not being installed (2026-11-16)  
**Signal**: definition-in-two-places — project — `do` step 1 wrote `**Started**` "when it has none" while the contract wrote it when the story is first set `In Progress`, so a story resumed after the upgrade would change rules mid-build (cpm-next/skills/do/SKILL.md:61, audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (the condition was restated, differently)  
**Signal**: procedure-gap — project — the resume bullet, the held `before the build` red and the worktree report still counted one red per criterion (cpm-next/skills/do/SKILL.md:53, :70; worktree.md:22; audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A procedure names every route that calls it and every input each caller gives" (three routes that use reds were not given the new count)  
**Signal**: spec-drift — project — criterion 7 named `bun` to run the mods' parsers, which this machine does not have (docs/epics/59-01-epic-a-red-for-each-clause.md Story 2, the parse check) — recurs: docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (a criterion's tool claim was not checked against the machine)  
**Amended**: the `**Started**` line; per-clause completeness; the abandoned pass's owner and every route; NFR2's parse check; the grading's hash and floor (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md  
**Amended**: the clause becomes a red per "or" alternative plus the control, graded against `walk-table-narrow.md` (2026-11-16) — cited: spec 59 FR1 as amended (the user's decision, Story 1's tables)  
**Amended**: the contract's word ceiling 3,900 → 4,000 (2026-11-16) — cited: spec 59 NFR1 as amended

**Acceptance Criteria**:
- `cpm-next/shared/artifacts.md` **Evidence against each criterion** states the red rule once: a test-proven criterion takes one red, plus one for each further alternative it joins with "or", plus one for its control when it names one; conditions joined by "and", listed, or stated with "when" or "unless" take none of their own, and the values one assertion compares together are one. It gives the `Evidence` form for several reds (one line per red, its alternative or `control` named in brackets after the test), says a test-proven criterion's evidence is incomplete without each of its reds, and says `existing` is judged per red. `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:175` (**Reds a criterion takes**): one red, plus one per further alternative joined by "or", plus one for a named control; "and", lists, "when"/"unless" take none; one assertion's compared values are one; one `Evidence` line per red, a criterion with more than one naming each red's alternative (its first included) or `control` in brackets, one with a single red needing none; `existing` per red; `:173` "incomplete without each of its red results" — red: n/a — static
- The contract's **Fields `do` may add to a story** gives `**Started**: cpm-next {version} ({YYYY-MM-DD})`, also in a `docs/quick/` record, and says a story with no such line, or one below 0.22.0, keeps one red per criterion; `do` step 1 writes it when it first sets the story `In Progress`, and leaves an existing line alone on resume. `[manual]`
  - Evidence: `artifacts.md:201` gives `**Started**: cpm-next {version} ({YYYY-MM-DD})`, also in a `docs/quick/` record, written at step 1 and never rewritten; `:175` keeps one red per criterion with no such line or below 0.22.0; `do/SKILL.md:61` writes it when the story is set `In Progress` from `Pending`, so a story resumed after the upgrade keeps no line — red: n/a — static
- Control on the definition: `grep -rn` for its key words (`further alternative`, `compares together`) over `cpm-next/` hits the contract only, and `do/SKILL.md`, `worktree.md`, `independent-tests.md`, `auditor-independent-tests.md` and `auditor.md` name the contract's rule where they use it. `[manual]`
  - Evidence: `grep -rn 'further alternative\|compares together' cpm-next/` hits `artifacts.md:175` only; `do/SKILL.md:70`, `worktree.md:21`, `independent-tests.md:10` and `auditor-independent-tests.md:12` name **Reds a criterion takes** and hold none of its terms; `auditor.md` uses the rule in Story 3 — red: n/a — static
- `cpm-next/skills/do/SKILL.md` step 4 takes the reds the contract's rule gives for each test-proven criterion on a story started under 0.22.0, each red's undone lines or mutation lying in the code that produces the value the cited assertion reads; a test double between that code and the assertion that the criterion does not name as its seam is a finding; stubbing the criterion's own code to return a wrong value stays a mutation; undoing a refactor's lines may be replaced by a mutation anywhere in that code. A test found unable to fail on its code abandons the pass: the lead compares the manifest, restores the files, removes the directory by its literal path and the `**Scratch**` line, fixes the test (or has an independent test disputed, a test already disputed blocking the story), retakes step 4's run and starts a new pass. Routes, each named: a single build, the one-checkout batch's hand-off (the red-pass subagent is given each criterion's reds and reports a test it cannot fail; the lead abandons), a worktree build, a resumed story, a fix that retakes a red, a small change, and Finishing's `[user]` route that takes step 4. `[manual]`
  - Evidence: `do/SKILL.md:70` takes the reds the contract gives; `:73` puts the undo or mutation where the contract's rule does, "never in a test double the criterion does not name as its seam", the stub sentence kept; `:74` abandons the pass (copy back, compare the manifest, delete the directory and `**Scratch**` line, fix or dispute, retake step 4's run, new pass), the hand-off subagent reports and stops while the lead abandons, and names the seven routes; `:96` hands the subagent each criterion's reds; the resume bullet (`:53`) takes a pass for each red the contract gives that is not yet recorded; `:70` counts a held `before the build` red as its alternative's, the others still taken; `:77` and `:80` speak per red; a test already disputed is left to `independent-tests.md`'s "Each test is disputed once… or be marked blocked" — red: n/a — static
- `cpm-next/skills/do/independent-tests.md` says a held `before the build` red stands for the alternative its failing assertion proves and the criterion's other reds are taken in the pass; `cpm-next/shared/auditor-independent-tests.md` reads a held red the same way; `cpm-next/skills/do/worktree.md` gives the subagent that takes a pass each criterion's reds. `[manual]`
  - Evidence: `independent-tests.md:10` "the red for the alternative its failing assertion proves… the criterion's other reds are taken in the red pass"; `auditor-independent-tests.md:12` the same; `worktree.md:21` takes the pass "with the reds the contract's **Reds a criterion takes** gives each criterion" and `:22` reports "each red the contract gives each test-proven one" — red: n/a — static
- Graded against the walk tables, `walk-table.md`'s `git hash-object` equal to the one Story 1's `Evidence` records: reading the new text, `walk-table-narrow.md`'s outcomes under FR1 as amended hold (03-01 Story 3's "or in a group's chain" and Story 7's session-port control each take a red; Story 9's test double is a finding; 03-02's clock-arithmetic test is not one), and a criterion with no "or" and no control takes one red. Control: read against the 0.21.1 text (`git show 88ee1e1:cpm-next/skills/do/SKILL.md`), 03-01 Story 3 and Story 7's session-port criterion each take one red and Story 9's fake is accepted. `[manual]`
  - Evidence: `git hash-object .git/cpm-next/checks/59/walk-table.md` = dee660adb22fcf552ada51ee73f887d782dd9b4f, as Story 1 records. Read against `artifacts.md:175` and `do/SKILL.md:73`: 03-01 Story 3's criterion ("…as a part insert or in a group's chain", pinned 03-01 `:114`) takes a second red for its "or" alternative; Story 7's criterion 6 names its control and takes a control red; Story 9's `runLines` fake is a test double standing between the code and the assertion, a finding; 03-02's `window.__ab.position()` is the page's own code, not a double; a criterion with no "or" and no control takes one. Control: `git show 88ee1e1:cpm-next/skills/do/SKILL.md` holds "A red is required for every test-proven criterion" (one per criterion) and "mutate a covered line instead, which may lie outside the story" with no limit on a double, so Story 3 and Story 7's criterion take one red each and Story 9's fake is accepted — red: n/a — manual
- A copy of opendaw-trak 03-01 with one criterion given three `Evidence` lines in the bracketed form and a story given `**Started**` and `**Probed**` lines, read through `cpm-next-progress/hooks/progress.ts` and `whats-next/hooks/plan.ts` (each module's parse function, run with `bun`), gives the same story and criterion statuses as the unchanged copy. `[manual]`
  - Evidence: `node check.ts` (Node 24's type stripping; `bun` is not installed) over the pinned 03-01 and a copy with one criterion's `Evidence` line (`:27`) replaced by `[base]`, `[or in a group]` and `[control]` lines and Story 2 given `**Started**` and `**Probed**` lines: `cpm-next-progress/hooks/progress.ts` `parseEpic`/`storyStatus`/`countCriteria` and `whats-next/hooks/plan.ts` `parseEpic`/`isWaitingOnUser` give the same per-story results for both (`progress same: true`, `whats-next same: true`; script at the run directory's `nfr2/check.ts`) — red: n/a — manual
- `wc -w` gives `do/SKILL.md` at most 7,450, the contract at most 4,000, `independent-tests.md` at most 820, `worktree.md` at most 680. `[manual]`
  - Evidence: `wc -w`: `do/SKILL.md` 7,310, the contract 3,936 (ceiling 4,000 by spec 59's NFR1 amendment), `independent-tests.md` 793, `worktree.md` 659 — red: n/a — static
- `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next, and `claude plugin validate cpm-next` and `claude plugin validate .` pass. `[manual]`
  - Evidence: `claude plugin test`: cpm-next 15, cpm-next-models 20, cpm-next-progress 108, whats-next 34 passed, 0 failed; `claude plugin validate cpm-next` and `claude plugin validate .` passed — red: n/a — manual

### The contract's red rule, Evidence form and Started line
**Task**: 2.1  
**Description**: The red rule, the several-red Evidence form, completeness and `existing` per red, and the `**Started**` field  
**Status**: Complete

### do step 1 and step 4 and their routes
**Task**: 2.2  
**Description**: Step 1's `**Started**` line; step 4's reds per alternative and control, the code the red comes from, the abandoned pass; every route; worktree.md, independent-tests.md, auditor-independent-tests.md  
**Status**: Complete

### Grading and parse checks
**Task**: 2.3  
**Description**: Grade against the table, run the mods' parsers over the copy, count words, run the suites  
**Status**: Complete

---

## The auditor checks each red
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR3, NFR1  
**Test run**: 3 (3 full, 0 targeted) — full — claude plugin test cpm-next: 15 passed, 0 failed; claude plugin test cpm-next-models: 20 passed, 0 failed; claude plugin test cpm-next-progress: 108 passed, 0 failed; claude plugin test whats-next: 34 passed, 0 failed — tree 27b180d1471516a7718a4edb5e9535a12a681f9e — closes epic; untested: cpm-next/agents/auditor.md — cpm-next/agents/auditor.md → deferred full run  
**Audit**: pass (2026-11-16), 3 findings fixed  
**Amended**: `auditor-independent-tests.md` named; the guides moved to Epic 59-04 (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md

**Signal**: check-cannot-fail — project — check 5 flagged only a red whose mutation lay in a test double, so a real-code red with a fake between that code and the assertion (walk-table A7, the case FR2 exists for) passed (cpm-next/agents/auditor.md:42, audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (the check passed on the very case it was for)  
**Signal**: fix-not-carried-through — project — the auditor's other lines and its independent-tests file still read one red and one `Evidence` line per criterion (cpm-next/agents/auditor.md:35, :37, :41, :78; cpm-next/shared/auditor-independent-tests.md:9; audit rounds 1 and 2) — recurs: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (the change stopped at the bullet it was made in)  

**Acceptance Criteria**:

- `cpm-next/agents/auditor.md` check 5, on a story whose `**Started**` line gives 0.22.0 or later, raises a Warning for an alternative or control of a test-proven criterion with no red and for a red taken through a test double the criterion does not name as its seam, and raises a criterion that reads two ways on what it joins with "or" or on its control as a wording finding settled by **Inline change**, not a missing red; on a story with no such line it checks one red per criterion, as before. It refers to the contract for the rule and holds none of its terms. `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:42` (**Reds**): a Warning for a red "missing where the contract's **Reds a criterion takes** gives one" (the contract's rule reading the story's `**Started**` line, including the no-line case), for "a cited test whose assertion reads its value through a test double that rule makes a finding, wherever its red was taken" (walk-table row A7: the red taken in real code at `load-ceiling.ts`, the `runLines` fake between `pinLines` and the assertion, is a Warning under this text and none under 0.21.1's), and for a criterion "that reads two ways on what it joins with \"or\" or on its control, settled by **Inline change** rather than counted as a missing red"; `:35` (check 1) reads each of a criterion's `Evidence` lines and finds a test that does not exercise the alternative or `control` its bracket names; `:41`, `:37` and `:78` read reds and `Evidence` lines per line, not one per criterion; no other singular reading is left (a whole-word search for the singular "`Evidence` line" in `auditor.md` and `auditor-independent-tests.md` hits only `:36`, `:46` and `:78`, each about any one line); `grep -rn 'further alternative\|compares together' cpm-next/` hits only `artifacts.md:175`, so the auditor holds none of the rule's terms — red: n/a — static
- `cpm-next/shared/auditor-independent-tests.md` accepts a held `before the build` red for its alternative only, as the contract says. `[manual]`
  - Evidence: `cpm-next/shared/auditor-independent-tests.md:12`: a held `before the build` red "stands for the alternative its failing assertion proves, the criterion's other reds being taken in the red pass (the contract's **Reds a criterion takes**)" (written in Story 2, read here); `:9` now reads "none of whose `Evidence` lines cites that test" — red: n/a — static
- `wc -w` gives `auditor.md` at most 2,150; `claude plugin test` passes for the four plugins. `[manual]`
  - Evidence: `wc -w cpm-next/agents/auditor.md` 2,069; `claude plugin test`: cpm-next 15, cpm-next-models 20, cpm-next-progress 108, whats-next 34 passed, 0 failed — red: n/a — manual

### Auditor check 5
**Task**: 3.1  
**Description**: The per-red Warnings, the wording finding and the cut-over in check 5; the held red in auditor-independent-tests.md  
**Status**: Complete

---
