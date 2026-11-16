# Runtime claims probed before the build

**Source spec**: docs/specifications/59-spec-lessons-reach-cpm-next.md  
**Date**: 2026-11-15  
**Status**: Complete  
**Blocked by**: Epic 59-01-epic-a-red-for-each-clause  
**Amended**: the cut-over, the quick record, the worktree route, re-probing by date, a user's keep recorded, a grading control and NFR2 (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md  
**Lessons**: docs/library/01-library-lessons-learned.md → "Ask the runtime the question rather than modelling its answer" (Story 1), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (Story 1), docs/library/01-library-lessons-learned.md → "A procedure names every route that calls it and every input each caller gives" (Story 1), docs/library/01-library-lessons-learned.md → "A walk-through's evidence claims only the agreement its runs show" (Story 1)

## The lead probes runtime claims at step 1
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR4, NFR1, NFR2  
**Effort**: high  
**Test run**: 2 (2 full, 0 targeted) — full — claude plugin test cpm-next: 15 passed, 0 failed; claude plugin test cpm-next-models: 20 passed, 0 failed; claude plugin test cpm-next-progress: 108 passed, 0 failed; claude plugin test whats-next: 34 passed, 0 failed — tree aa694df9fc44541072ae8b08777bd55bfb28dcea — untested: cpm-next/skills/do/SKILL.md — cpm-next/skills/do/SKILL.md → deferred full run; cpm-next/shared/artifacts.md → exempt  
**Audit**: pass (2026-11-16), 1 finding fixed  
**Amended**: the cut-over, the quick record, every route named, re-probing, a kept criterion recorded, the grading control (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md  
**Amended**: the contract's word ceiling 3,900 → 4,000 (2026-11-16) — cited: spec 59 NFR1 as amended  
**Amended**: `do/SKILL.md`'s ceiling 7,450 → 7,550 and the contract's 4,000 → 4,100 (2026-11-16) — cited: spec 59 NFR1 as amended

**Signal**: definition-in-two-places — project — step 1 restated the contract's `**Started**` gate as "started under 0.22.0", which reads as the opposite gate or as 0.22.0 only (cpm-next/skills/do/SKILL.md:61, audit round 1) — recurs: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (the gate was restated, differently)  

**Acceptance Criteria**:

- `cpm-next/shared/artifacts.md` gives the `**Probed**` form once (**Fields `do` may add to a story**: `{claim} → {observed} ({how})` or `{claim} → unprobed: {credentials | deploy | hardware | a person}`, entries separated by `;`, then `({YYYY-MM-DD})`), also in a `docs/quick/` record, and adds `probe: {what was run} → {observed}` to `**Amended**`'s and `**Inline change**`'s cited forms. `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:202` gives `**Probed**: {claim} → {observed} ({how}); {claim} → unprobed: {credentials | deploy | hardware | a person}; … ({YYYY-MM-DD})`, also in a `docs/quick/` record, with the claims it covers and the four reasons; `:203` adds `— cited: probe: {what was run} → {observed}` to `**Inline change**` and `:204` adds `probe: …` to `**Amended**`'s `cited:` — red: n/a — static
- `cpm-next/skills/do/SKILL.md` step 1 has the lead, on a story whose `**Started**` line gives 0.22.0 or later, before the independent tests are written and before any fan-out, list each claim the story's criteria make about a runtime outside the repository's own code (a browser API, a third-party engine or library at run time, a checkout of one the repository builds against, the operating system), probe each in the session and write the `**Probed**` line; a claim about the repository's own code is not listed; `unprobed` takes only the contract's four reasons; a story whose criteria make no such claim gets no line. Routes, each named: a single build, a one-checkout batch and a worktree batch (the lead probes every story before fan-out), a resumed story with a `**Probed**` line (probed again only for a criterion whose `**Amended**` or `**Inline change**` line is dated after the `**Probed**` line), a criterion amended during the build that adds a runtime claim (probed before the build goes on), and a small change (the line in its record). `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:61` (step 1): the lead probes, on the stories the contract's `**Probed**` field covers (its `**Started**` gate, `artifacts.md:202`, not restated), before any independent test and before any fan-out, each claim the contract's `**Probed**` field covers and writes the line; the own-code exclusion and the four `unprobed` reasons are the contract's (`:202`), referred to, not restated; routes named: a batch, one-checkout or worktree (the lead probes every story before fan-out), a resumed story (again only for a criterion whose `**Amended**` or `**Inline change**` is dated after the line), a criterion amended during the build that adds a claim, a small change's record; a single build is the step's own path; a probe's script and output go in the run directory, and a later probe adds its entries and moves the line's date — red: n/a — static
- **When a criterion looks wrong** accepts a probe as a citation, and a contradicted claim is settled through it before any test or code is written: an **Inline change**, a question with the user present, or an amendment unattended; a criterion the user keeps after seeing the probe gets an `**Amended**` line citing the probe and the user's decision. Control: the 0.21.1 text's citation list (`file:line`, `FRn`, a conflicting criterion) holds no probe. `[manual]`
  - Evidence: `do/SKILL.md:199` accepts "a probe whose observation contradicts it (step 1's, or one made during the build), cited as the contract's `probe:` form"; `:61` sends a contradicted claim through **When a criterion looks wrong** before any test or code; `:202` gives a criterion the user keeps against its probe an `**Amended**` line citing the probe and the decision. Control: `git show 88ee1e1:cpm-next/skills/do/SKILL.md` lists only "a `file:line`, a named spec requirement (`FR3`, `AD1`), or another criterion in the same epic" — red: n/a — static
- Graded against Epic 59-01 Story 1's table, whose `git hash-object` equals the one that story's `Evidence` records: reading the new text, Story 1's `playbackStats` claim is probed and contradicted before the build, Story 2's is reached only where its criterion states the claim, and Story 7's is not listed (the repository's own code), each as the table gives. Control: read against the 0.21.1 text (`git show 88ee1e1:cpm-next/skills/do/SKILL.md`), none of the three is probed before the build. `[manual]`
  - Evidence: `git hash-object .git/cpm-next/checks/59/walk-table.md` = dee660adb22fcf552ada51ee73f887d782dd9b4f, as 59-01 Story 1 records. Read against `do/SKILL.md:61` and `artifacts.md:202`: Part B's B1 (03-01 Story 1, `playbackStats` given as a number, a browser API stated in the criterion) is a listed claim, probed headless before the build and contradicted; B2 (Story 2's openDAW warm-up loss, a third-party engine the criterion does not state) is not a claim of the criterion, so not listed; B3/B4 (Story 7's `server.address()` and row rounding) are the repository's own code, not listed. Control: the 0.21.1 text (`git show 88ee1e1`) has no step that asks a runtime before the build — its only probes are the `[browser]` probe and the auditor's probe scripts — so none of the three is probed before the build — red: n/a — manual
- `wc -w` gives `do/SKILL.md` at most 7,550 and the contract at most 4,100. `[manual]`
  - Evidence: `wc -w`: `do/SKILL.md` 7,486 (ceiling 7,550), the contract 4,061 (ceiling 4,100), both by spec 59's NFR1 amendment — red: n/a — static
- `claude plugin test` passes for the four plugins, and both `claude plugin validate` runs pass. `[manual]`
  - Evidence: `claude plugin test`: cpm-next 15, cpm-next-models 20, cpm-next-progress 108, whats-next 34 passed, 0 failed (the fix rerun after audit round 1); `claude plugin validate cpm-next` and `claude plugin validate .` passed — red: n/a — manual

### The contract's forms
**Task**: 1.1  
**Description**: The `**Probed**` field and the probe citation  
**Status**: Complete

### Step 1's probe and When a criterion looks wrong
**Task**: 1.2  
**Description**: The lead's probe before independent tests and fan-out, its routes, and the probe as a citation  
**Status**: Complete

---

## The auditor reads the probes
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR5, NFR1  
**Test run**: 1 (1 full, 0 targeted) — full — claude plugin test cpm-next: 15 passed, 0 failed; claude plugin test cpm-next-models: 20 passed, 0 failed; claude plugin test cpm-next-progress: 108 passed, 0 failed; claude plugin test whats-next: 34 passed, 0 failed — tree 482c9218621f411fa6816a863bec012cfd40c273 — closes epic; untested: cpm-next/agents/auditor.md; untested: cpm-next/skills/do/SKILL.md — cpm-next/agents/auditor.md → deferred full run; cpm-next/skills/do/SKILL.md → deferred full run; cpm-next/shared/artifacts.md → exempt  
**Audit**: pass (2026-11-16)  
**Amended**: the cut-over and a kept criterion's record (2026-11-15) — cited: docs/reviews/16-review-lessons-reach-cpm-next.md

**Acceptance Criteria**:

- `cpm-next/agents/auditor.md` check 1 (**Each criterion against its evidence**), on a story whose `**Started**` line gives 0.22.0 or later, raises a Warning for a runtime claim of the contract's kind with no `**Probed**` entry, for an `unprobed` reason outside the contract's four, and for a criterion its own probe contradicts that stands with no `**Amended**` or `**Inline change**` line citing the probe; a claim about the repository's own code is not one. `do`'s **Audit** list and the auditor's **What you are given** both name the `**Started**` and `**Probed**` lines, so the prompt and the receiver match. `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:36` (check 1): "On a story the contract's `**Probed**` field covers, a Warning: a claim of its kind with no entry, an `unprobed` reason outside its four, or a criterion its own probe contradicts that stands with no `**Amended**` or `**Inline change**` line citing the probe; a claim about the repository's own code is not one" (the gate and the four reasons referred to, `artifacts.md:202`); `do/SKILL.md:152` (**Audit** list) and `auditor.md:21` (**What you are given**) both read "the story's `**Started**` and `**Probed**` lines, or that it has neither". Also `artifacts.md:202` now says the line is "added to by a later probe (`do` step 1)", matching `do/SKILL.md:61` (59-02 Story 1 audit round 2's Suggestion) — red: n/a — static
- `wc -w` gives `auditor.md` at most 2,150 and `do/SKILL.md` at most 7,550; `claude plugin test` passes for the four plugins. `[manual]`
  - Evidence: `wc -w`: `auditor.md` 2,134 (ceiling 2,150), `do/SKILL.md` 7,498 (ceiling 7,550), the contract 4,071 after this story's `:202` clause (ceiling 4,100); `claude plugin test`: cpm-next 15, cpm-next-models 20, cpm-next-progress 108, whats-next 34 passed, 0 failed — red: n/a — manual

### Auditor check 1 and the prompt
**Task**: 2.1  
**Description**: The probe Warnings in check 1, and the two lines in the Audit list and What you are given  
**Status**: Complete

---
