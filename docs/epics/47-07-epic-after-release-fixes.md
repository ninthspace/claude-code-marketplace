# Fixes after release

**Source spec**: docs/specifications/47-spec-checks-that-can-fail.md  
**Date**: 2026-10-30  
**Status**: Complete  
**Blocked by**: Epic 47-05-epic-release  
**Retro waived**: observations are in docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md (2026-10-30)  
**Lessons**: docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion that names a mapping with no tag to key it on" (build)

The changes in this epic are already in the working tree, written after epic 47-05 closed. Each story is built by checking that the text meets its criteria, fixing what doesn't, recording `Evidence` and auditing it. The pre-shortening copies of the six skills are in the session scratchpad (`skills-before-opt/`), with a rule inventory per skill in `opt-{skill}/inventory.md`; where they are no longer available, `git show 2f406b1:{path}` and the 47-01 to 47-05 epics' criteria are the comparison.

## A blocked story keeps its status and carries a note
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-30), 3 findings fixed  
**Blocked by**: —  
**Satisfies**: FR17, NFR2  
**Effort**: high

**Acceptance Criteria**:

- The status vocabulary in `cpm-next/shared/artifacts.md` names the three cases that block a story (a `Not met` line, an unresolved audit finding, an unexplained failure), the note ` — blocked: {reason}` after the kept status, when the note comes off, and that a story waiting on the user is not blocked `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:35` names the three cases (a `Not met` line, an audit finding left unresolved, a failure `do` can't explain), the note ` — blocked: {reason}` after the kept status, that the note comes off when the user settles the blocker and nothing else blocks the story, after which `do` resumes it (`do/SKILL.md`, the walk-through's blocked-story case), and that a story waiting on the user is not blocked — red: n/a — manual
- `cpm-next/skills/do/SKILL.md` refers to the note wherever it marks a story blocked or reads a blocked story: the re-read after step 6, the no-argument scope row, the resume rule, the walk-through's failed `[user]` check and its changed-criterion case. Control: `grep -n "blocked" cpm-next/skills/do/SKILL.md` lists every such place, and none tells `do` to write a status value outside the contract's vocabulary `[manual]`
  - Evidence: reading every line of `cpm-next/skills/do/SKILL.md` that matches `blocked` (the matches on "unblocked" mean unblocked by dependency): line 23 (scope row), 25 (waiting definition), 38 (resume), 54, 57 (re-read), 115, 121, 137 (**Needs you**), 143 (changed criterion), 147 (failed `[user]` check) and the new blocked-story case after 147; lines 23, 25, 38, 57, 143 and 147 name the note or the `Not met` line, lines 54, 115, 121 and 137 say "blocked" and fall under the contract's definition at `artifacts.md:35`; none writes a status outside the vocabulary — red: n/a — manual
- The no-argument scope row skips a story carrying the note, and the resume rule lists such a story under **Needs you** instead of auditing and closing it `[manual]`
  - Evidence: `do/SKILL.md:23` skips a story marked blocked (no `Not met` line or ` — blocked:` note); `:38` uses the same test, does not resume such a story until the user settles the blocker, and lists it under **Needs you** with its reason — red: n/a — manual
- The changed-criterion case clears the note only when no other `Not met` line or unresolved finding remains `[manual]`
  - Evidence: `do/SKILL.md:143` clears the note "once no other `Not met` line or unresolved finding remains" — red: n/a — manual
- `docs/maintenance/README.md` records that both mods' `normaliseStatus` read the note by prefix (cite `whats-next/hooks/plan.ts` and `cpm-next-progress/hooks/progress.ts`) and that a bare `Blocked` would read as Pending `[manual]`
  - Evidence: `docs/maintenance/README.md:64` records that both mods' `normaliseStatus` (`whats-next/hooks/plan.ts`, `cpm-next-progress/hooks/progress.ts`) match by prefix, so `In Progress — blocked: …` reads as In Progress, and that a bare `Blocked` would read as Pending — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines of `git diff -U0` for these files read; the history grep returns nothing that records history — red: n/a — manual

### Check and complete the blocked note
**Task**: 1.1  
**Description**: Read the contract, `do/SKILL.md` and the maintenance record against the criteria; fix what falls short.  
**Status**: Complete

---

## A story waits on the user only once its blockers are complete
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-30), 2 findings fixed — the round-2 Warning, an `**Amended**` line, was added after the last audit  
**Blocked by**: Story 1  
**Satisfies**: FR18, NFR2

**Acceptance Criteria**:

- The contract's evidence section and `do`'s scope section define a waiting story with the same four conditions: it is unblocked, by the rule that includes its epic's `**Blocked by**`; it is not marked blocked; at least one criterion lacks `Evidence`; every such criterion is `[user]` or treated as `[user]` `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:148` and `cpm-next/skills/do/SKILL.md:25` state the same four conditions: unblocked (`artifacts.md:36` and `do/SKILL.md:42` now include every item the story's epic's `**Blocked by**` names, so `do` cannot pick such a story under any scope); not marked blocked; at least one criterion lacks `Evidence`; every such criterion is `[user]` or treated as `[user]`. The scope row (`:23`) and the re-read (`:57`) use it; `:137` lists a `[user]` criterion of a story waiting on the user, with its steps — red: n/a — manual
- Control: for `docs/epics/47-06-epic-user-checks.md` as it stands (blocked by 47-05 and 47-07), the definitions give "not waiting" while 47-07 is open, so `do`'s **Needs you** would not yet list its steps `[manual]`
  - Evidence: `docs/epics/47-06-epic-user-checks.md` is blocked by `Epic 47-05-epic-release` and `Epic 47-07-epic-after-release-fixes`; while 47-07 is not `Complete` Story 1 of 47-06 is not unblocked, so it is neither picked under any scope nor waiting, and `do`'s **Needs you** lists no steps for it — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; none records history — red: n/a — manual

**Amended**: the first criterion's first condition reads "it is unblocked, by the rule that includes its epic's `**Blocked by**`" in place of the epic-and-story blockers listed separately (2026-10-30) — cited: FR18 and the audit's finding that the unblocked rule did not check the epic, which left a story neither waiting nor blocked yet pickable (`artifacts.md:36`, `do/SKILL.md:42`)

### Check the waiting definition
**Task**: 2.1  
**Description**: Compare the contract's and `do`'s definitions and the places that use them (scope table, step 3, re-read, Needs you).  
**Status**: Complete

---

## status reports blocked stories and user checks
**Story**: 3  
**Status**: Complete  
**Audit**: pass (2026-10-30), 2 findings fixed  
**Blocked by**: Story 2  
**Satisfies**: FR19, NFR2

**Acceptance Criteria**:

- `cpm-next/skills/status/SKILL.md` lists under **Waiting on the user** stories marked blocked (the note or a `Not met` line) with their reason, and stories waiting on a user check by the contract's four conditions, written out for a Haiku reader `[manual]`
  - Evidence: `cpm-next/skills/status/SKILL.md:21` lists under **Waiting on the user** blocked stories (a ` — blocked:` note or an indented `- Not met:` line) with their reason, and stories waiting on a user check by four written-out conditions that match `cpm-next/shared/artifacts.md:148` (status tests the `[user]` tag, since only `do` can tell which other criteria it treated as `[user]`) — red: n/a — manual
- For each waiting story it gives the steps of each `[user]` criterion without `Evidence` and recommends carrying them out, then `/cpm-next:do {epic}` to record the result; its **Next** list suggests `/cpm-next:do {epic}` to build only for an epic with buildable work `[manual]`
  - Evidence: `status/SKILL.md:21` gives the steps of each `[user]` criterion without `Evidence` and recommends carrying them out and then `/cpm-next:do {epic}` to record the result; `:34` suggests `/cpm-next:do {epic}` to build and says that for an epic whose only open stories wait the **Needs you** line already gives the command — red: n/a — manual
- Control: read against the current `docs/epics/`, the rules put 47-06 in neither list while 47-07 is open, and list 47-07's stories as work in flight `[manual]`
  - Evidence: read against `docs/epics/`: 47-06 Story 1 has epic blockers 47-05 (Complete) and 47-07 (In Progress), so the first condition fails and it is in neither list; 47-07's open stories (Story 3 In Progress, Story 4 Pending) have no `[user]` criteria, so they are work in flight; `Not met` appears in the epics only in criterion and Evidence text, never as an indented `- Not met:` line, so no story is listed as blocked — red: n/a — manual
- The skill's front matter still reads `model: haiku` and `effort: low` `[manual]`
  - Evidence: `status/SKILL.md` front matter reads `model: haiku` and `effort: low` — red: n/a — manual

### Check status
**Task**: 3.1  
**Description**: Read `status/SKILL.md` against the contract and the criteria.  
**Status**: Complete

---

## The skills are shorter and worktree mode is read only when needed
**Story**: 4  
**Status**: Complete  
**Audit**: pass (2026-10-30), 3 findings fixed  
**Blocked by**: Story 3  
**Satisfies**: FR20, NFR1, NFR2  
**Effort**: high

**Acceptance Criteria**:

- `wc -w cpm-next/skills/*/SKILL.md` totals less than the 9,182 words of the pre-shortening copies, and the five NFR1 files total no more than 10,300 `[manual]`
  - Evidence: `cat cpm-next/skills/*/SKILL.md | wc -w` gives 8,346 against 9,182 in the pre-shortening copies (`do` 4,499 to 3,826, `plan` 1,626 to 1,503, `review` 1,042 to 984, `party` 602 to 569, `library` 914 to 841, `status` 499 to 623, with 477 more in `do/worktree.md`); the five NFR1 files (`do`, `plan`, `review`, `auditor`, contract) total 9,514 within 10,300 — red: n/a — manual
- For each of `do`, `plan`, `review`, `party`, `library` and `status`, every rule in the pre-shortening text is still stated, or its removal is listed with the reason the executor does not need it; the list is in the `Evidence` line. Control: a rule dropped with no reason is restored `[manual]`
  - Evidence: each skill's rule inventory is in the session scratchpad (`opt-{skill}/inventory.md`) with the line each rule now lives at. Rules dropped, with reasons: `do`: the attended run's one-line plan (the user can interrupt and the stop rules apply either way), five reasons (why the simplifier runs first, why a haiku story still gets a subagent, why the retro is waived, the auditor's later-audit behaviour, "runs on Haiku"); also the reasons "one audit then covers two stories", "on one machine more of them only slow each other down", "conflicts show up only when the pieces are combined" and the Sonnet/Opus opening of the Audit section; "follow the project's existing conventions" was restored; `plan`: the list of `docs/` subfolders ("`docs/` in full" covers it), the scout lookup examples (the agent's own description lists them), "tasks are the steps inside a story" and "testable criteria" (the contract's epic template and **Done means** cover them); `library`: the front-matter rationale (the contract says it), the Learn rationale, "the Read tool for a path"; `review`: one context sentence about the challenge pass; `status`: "the artefacts are the state"; `party`: none — red: n/a — manual
- `cpm-next/skills/do/worktree.md` holds the worktree batch rules, the conditions for counting a worktree's test results, the subagent prompt additions, the merge procedure and what `--parallel check` reports; `do/SKILL.md` keeps the **Worktree mode** heading, tells `do` to read the file with `--parallel`, `--parallel check`, or when unblocked stories that share files are waiting, and keeps the rule for suggesting the flag `[manual]`
  - Evidence: `cpm-next/skills/do/worktree.md` holds the batch exclusions, when worktree results count, the subagent prompt additions, the merge procedure and `--parallel check`; `do/SKILL.md` keeps the **Worktree mode** heading, says to read the file with `--parallel`, `--parallel check` or when unblocked stories that share files are waiting, and keeps the rule for suggesting the flag — red: n/a — manual
- Every label another file cites still resolves: `**Worktree mode**`, `**Scratch directories and isolation**`, `**Audit**`, `**Before the first story**`, `**When a criterion looks wrong**` in `do`; `**Epics**` and `**Lessons**` in `plan`. Control: `grep -c` for each returns at least 1 in its file `[manual]`
  - Evidence: the headings `### Worktree mode`, `### Scratch directories and isolation`, `## Before the first story`, `## Audit` and `## When a criterion looks wrong` are in `do/SKILL.md` (`grep -n '^##' cpm-next/skills/do/SKILL.md`), and the `**Epics**` and `**Lessons**` paragraphs are in `plan/SKILL.md` (`:47`, `:51`) — red: n/a — manual
- The front matter of each skill keeps `name`, `model` and `effort` unchanged, and each `description` keeps its trigger phrases `[manual]`
  - Evidence: `name`, `model` and `effort` of the six skills compared with the pre-shortening copies: unchanged; the optimisers kept every description trigger phrase — red: n/a — manual
- `cpm-next/README.md`'s 0.9.0 entries record the shorter skills, the word totals as `wc -w` gives them, and `worktree.md` `[manual]`
  - Evidence: `cpm-next/README.md` 0.9.0 entries "Shorter skills" (9,182 to 8,346 words, `worktree.md`) and "The blocked note" — red: n/a — manual
- `claude plugin validate cpm-next` reports no errors `[manual]`
  - Evidence: `claude plugin validate cpm-next` — Validation passed — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; none records history — red: n/a — manual

### Compare each skill with its pre-shortening text
**Task**: 4.1  
**Description**: Walk each skill's rule inventory, or the earlier text, to the current text; restore or list what is missing.  
**Status**: Complete

---

## Library lessons are identified by observation
**Story**: 5  
**Status**: Complete  
**Audit**: pass (2026-10-30)  
**Blocked by**: —  
**Satisfies**: FR6, FR21, NFR2

**Acceptance Criteria**:

- The contract's amendment block gives `**Source**` as `{retro path} → {Category} → "{observation text, verbatim}"`, the same form as a `lessons-learned.md` entry, and its lesson reference for an amendment carries the observation's opening words `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:247` and `:258` give the amendment block's `**Source**` as `{retro path} → {Category} → "{observation text, verbatim}"`, the lessons-learned form; `:161` gives the amendment lesson reference with the opening words — red: n/a — manual
- `cpm-next/skills/library/SKILL.md` Learn compares an older amendment whose `**Source**` gives only a retro path with the observation's text before skipping it, and proposes retiring, as promoted, an observation whose `**Recurrence**` names a library lesson or a retro observation already retired as promoted. Control: two observations from one retro, one already an amendment, are not both skipped under the rule as written `[manual]`
  - Evidence: `cpm-next/skills/library/SKILL.md:34` proposes retiring, as promoted, an observation whose `**Recurrence**` names a library lesson or a retro observation already retired as promoted; `:36` compares an older path-only amendment with the observation's text before skipping. Control: under `:36` as written an amendment whose `**Source**` is only the retro path no longer skips a second observation from that retro unchecked — red: n/a — manual
- No added sentence names a project, retro, version or earlier behaviour `[manual]`
  - Evidence: added lines read; none records history — red: n/a — manual

### Check the identification rules
**Task**: 5.1  
**Description**: Read the contract's library section and `library/SKILL.md` Learn against the criteria.  
**Status**: Complete

---
