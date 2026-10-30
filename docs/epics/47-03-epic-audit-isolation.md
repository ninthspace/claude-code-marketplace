# Audit isolation

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 47-01-epic-red-first-evidence  
**Retro waived**: observations are in docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md (2026-10-30)  
**Amended**: 2026-10-30 — Story 1 rewritten after review 03 (docs/reviews/03-review-audit-isolation.md): one definition for the builder's and the auditor's scratch directories; what counts as an isolated suite; the check made before the first audit; no red taken while an auditor runs; blocked by 47-01, which edits the same paragraphs

## Scratch directories are defined, and tests never overlap where they share state
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 3 findings fixed — the round-2 Warning was fixed after the last audit and accepted unaudited by the user (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR8, FR9, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `cpm-next/skills/do/SKILL.md` defines scratch directories in one place: at the start of a run the lead makes a run directory under the session's scratchpad, or with `mktemp -d` when the session has none, and inside it a builder directory per story (`build-{epic}-{story}`, or `build-quick-{nn}` for a small change) used for the red copies of step 4, and a fresh auditor directory per audit round (`audit-{epic}-{story}-r{n}`, or `audit-quick-{nn}-r{n}`). The lead creates each directory and passes its absolute path; no two builders or auditors share one `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:100` defines the run directory (session scratchpad, else `mktemp -d`), a builder directory per story (`build-{epic}-{story}`, `build-quick-{nn}`) and a fresh auditor directory per round (`audit-{epic}-{story}-r{n}`, `audit-quick-{nn}-r{n}`), made by the lead and passed by absolute path, none shared; no other place defines them — red: n/a — manual
- Step 4's "the scratch directory" (written by epic 47-01) refers to the story's builder directory as defined here `[manual]`
  - Evidence: `do/SKILL.md:49` copies into "a directory made for this red inside the story's builder directory" — red: n/a — manual
- The auditor's prompt in **Audit** includes its directory and says it is for probe scripts, test output and `TMPDIR`; **What you are given** in `cpm-next/agents/auditor.md` lists it `[manual]`
  - Evidence: `do/SKILL.md:108` has the prompt carry "its auditor directory (for probe scripts, test output and `TMPDIR`)"; `cpm-next/agents/auditor.md:16` lists "your directory" — red: n/a — manual
- In `cpm-next/agents/auditor.md`, the sentence "Do not edit, create or delete files" is amended to allow creating and writing files in the given directory only. Control: `git diff` of `auditor.md` for this story touches only that sentence, the sentence allowing test runs, **What you are given**, and the full-suite sentence of check 8 `[manual]`
  - Evidence: `agents/auditor.md:12` now allows creating and writing files in the given directory only. This story's edits to `auditor.md` are lines 12 (the read-only sentence and the sentence allowing test runs), 16 (**What you are given**) and 27 (check 8's full-suite sentence), and no others — red: n/a — manual
- `do` defines an isolated suite for this purpose: every test process, including a single test run without a parallel flag, gets its own database and its own copy of every file tests write (fake disks, SQLite database files, file caches, compiled views, result caches), and no test binds a fixed port. The existing worktree-mode isolation check (`do/SKILL.md`, worktree mode) uses the same definition rather than a second list `[manual]`
  - Evidence: `do/SKILL.md:102` defines an isolated suite (own database and own copy of every file tests write, including a single run without a parallel flag; no fixed port); the worktree paragraph (`do/SKILL.md:80`) says results count only if the suite is isolated "(see **Scratch directories and isolation**)" and keeps only the checks the definition doesn't cover (faked HTTP, queues and mail, build output); a parallel subagent in one checkout runs tests only when the suite is isolated (`do/SKILL.md:60`), so no second test of isolation remains — red: n/a — manual
- `do` makes that isolation check once per run before the first audit, whatever the build mode `[manual]`
  - Evidence: `do/SKILL.md:102` — "Check this once per run, before the first audit, ... whatever the build mode"; the earlier once-per-run sentences in the worktree and batch paragraphs are removed — red: n/a — manual
- The sentence "audits of stories that share no files or state can run in parallel" is replaced, not supplemented, by: with an isolated suite, audits of stories that share no files can run in parallel; otherwise audits run in parallel too, but the auditor is told the suite is not isolated and runs no tests: it reads the tests and the full-suite result it was given. Control: `grep -c "audits of stories that share no files or state can run in parallel" cpm-next/skills/do/SKILL.md` returns 1 before and 0 after `[manual]`
  - Evidence: `grep -c "audits of stories that share no files or state can run in parallel" cpm-next/skills/do/SKILL.md` — 1 at `2f406b1`, 0 now; `do/SKILL.md:108` now reads with an isolated suite, audits of stories that share no files run in parallel, otherwise they run in parallel too with the auditor told the suite is not isolated and running no tests — red: n/a — manual
- `do` says no red is taken (no source file mutated) in the checkout while any auditor is still running, isolated suite or not `[manual]`
  - Evidence: `do/SKILL.md:104` — no red is taken in the checkout while any auditor is running, isolated suite or not — red: n/a — manual
- `do` says two full-suite runs never run at once, and `auditor.md` says the auditor runs tests (check 8's full suite, or a single test) only when `do` says the suite is isolated, and the full suite only when it was given no result `[manual]`
  - Evidence: `do/SKILL.md:104` — two full-suite runs never run at once; `agents/auditor.md:12` runs tests only when the prompt says the suite is isolated and `:27` runs the full suite only then and only when no result was given — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines in `git diff -U0 -- cpm-next` read; the history grep over them returns nothing — red: n/a — manual

**Amended**: 2026-10-30 — in an unisolated suite audits stay parallel and the auditor runs no tests, instead of audits running one at a time (review 03, user's decision; FR9 to be amended by `/cpm-next:plan`)

### Define the directories and the isolation test in do
**Task**: 1.1  
**Description**: Edit **Before the first story**, step 4, worktree mode and **Audit** in `cpm-next/skills/do/SKILL.md`.  
**Status**: Complete

### Amend the auditor's read-only sentence, inputs and check 8
**Task**: 1.2  
**Description**: Edit `cpm-next/agents/auditor.md`.  
**Status**: Complete

---
