# Spec: Consolidate cpm-next — fix the contradictions, then say each rule once

**Date**: 2026-11-12  
**Amended**: review 15 (docs/reviews/15-review-plugin-consolidation.md) and the user's decision — FR2 retakes every red and blocks on a `fix needed`; FR3's resumed kind is a whole-story audit; FR5 drops the order-dependent Warning and passes baseline results only when the run holds them; FR4 and FR7 gain the audit-fix and story-level `**Amended**` rules; FR10 keeps the parallel clause in `do`; FR11 places a partly moved place's signal by its text; the Testing Strategy keeps its checks in `{pre}/checks/` (2026-11-12)  
**Amended**: 2026-11-12 — FR2: a resumed `fix due` story retakes the reds taken in a red pass and the fix's red, a held `before the build` red standing on its own check, and names candidate files for the fix's files outside the story (the user's decision after 58-01 Story 2's audit 4)  
**Source**: docs/discussions/25-discussion-plugin-optimisation-survey.md; the user's decisions (2026-11-12): plan the survey as one spec, correctness first; move all four rarely-needed sections into files read only when they apply

## Problem Summary

cpm-next's instructions have grown by accretion: since 0.15.0 `do/SKILL.md` went from 6,415 to 7,989 words, and every spec kept earlier sentences verbatim beside the new ones. A read-only survey (discussion 25) found about 3,600 words that restate a rule its owner already states, say again what a nearby rule implies, or sit in single-line paragraphs that bullets would shorten; about 2,400 more that load on every run though only some runs need them; and contradictions between `do`, `test-runs.md`, the auditor, the contract and the other skills, which the challenge below extended. A `do` run reads `do`, the contract and `test-runs.md` (13,847 words at 479c406); each audit reads the auditor, the contract and `test-runs.md`. The duplication is where this project's audits keep finding the same failures (`fix-not-carried-through`, `definition-in-two-places`, `procedure-gap`).

The work ships in two releases: 0.20.0 fixes the contradictions with the text as it stands; 0.21.0 consolidates, proving it changed nothing.

Places below are cited by section and bold label, with the line at 479c406 in brackets for orientation.

## Functional Requirements

### Must Have

Correctness, released as 0.20.0 (each a change of behaviour):

- **FR1 — One unblocked rule.** `do`'s **The loop** opening (`:45`: a blocker `Complete` with an `**Audit**` line) and the contract's **Status vocabulary** (`:38`: `Complete`) agree on the contract's rule, which both mods apply. `do` refers to it with its reason (an audit's fixes would rework dependents, and a story `do` closes has its `**Audit**` line in the same edit). A `Complete` story with no `**Audit**` line (a converted foreign item, a legacy v3 story, one the user closed by hand) unblocks its dependents. The check after each story (`:63`), a closing condition, is unchanged. — AC: a walk-through of an epic whose blocker is `Complete` with no `**Audit**` line, over the old text (blocked) and the new (unblocked) `[manual]`
- **FR2 — A resumed `fix due` story.** A run that resumes a `fix due` story cannot rebuild the scoped round's inputs (the failure text, the fix's files) once the session that wrote them is gone, so it finishes the fix, takes the fix rerun, retakes every red of the story taken in a red pass and the fix's red (which reds the fix touched cannot be known; a held `before the build` red stands on its own check), and is audited as a whole story, its prompt naming candidates for the fix's files outside the story; that audit stands as the story's scoped round (outside the count, its `missed-regression` signal) as `do`'s resume bullet (`:41`) says, and its `fix needed` blocks the story as a scoped round's does (`test-runs.md` **A second failure**). `test-runs.md` **Every regression** (`:77`), `do`'s **Audit rounds** (`:99`, `:101`), **Audit** (`:132`) and the auditor's **A later audit** say the same. Every scoped round's auditor directory is named `audit-{epic}-{story}-s{n}`, `{n}` counting the story's scoped rounds. — AC: the five places agree, quoted; a walk-through of a resumed `fix due` story `[manual]`
- **FR3 — The auditor knows every prompt `do` sends.** Each item of `do`'s **Audit** list, quoted, has a matching sentence in `auditor.md` **What you are given**, the files on the `**Independent tests**` line among them. **A later audit** names four kinds: after findings; a whole-story audit given dismissed findings only; a resumed story with round records, which gets a whole-story audit with every recorded dismissal as a finding not to raise again, since no record holds a fix's files; a scoped round. — AC: a table pairing each quoted `do` item with its auditor sentence; control: one auditor sentence removed from a copy leaves its row empty `[manual]`
- **FR4 — No test run while code in the checkout is being written.** In a one-checkout batch, subagents write code only and the lead runs each story's tests after the batch (`do`'s parallel rules, `:68`), whatever the suite's isolation; audits that run tests may run together in an isolated suite, no audit fix being made while a test-running audit runs in the checkout, and no red pass runs beside any test run (**Scratch directories and isolation**, `:115`). Isolation is checked before the first fan-out or audit (`:113`). — AC: the three passages agree; a walk-through of a one-checkout batch `[manual]`
- **FR5 — The auditor's checks fire when they should.** A `before the build` red is accepted only when the line has no ` — revised` note for its file, and a revision retakes the red of every independent test in that file in the red pass (`do` **Independent tests**, **A dispute**); the order-dependent Warning in auditor check 5 is removed, since the `**Test run**` line it reads is rewritten on every run and cannot show which run was full; the `existing` conditions include "passed at the baseline", stated once in the contract, and `do`'s **Audit** list gives the auditor the baseline result of each test an `existing` reason cites when the run holds it, and says so when it does not, in which case the condition is not checked. — AC: each place states it; a walk-through of a revised file with two independent tests `[manual]`
- **FR6 — `test-runs.md` is complete.** It points to `do`'s **Audit rounds**, not "step 5's rounds" (**A pass**, **Every regression**); the snapshot comparison is made before the deferred run (**The deferred full run** opening, not **A pass**); its opening (`:5`) says a story's runs before its audit are targeted unless a failing targeted run or an order-dependent story makes them full; a story whose every changed file maps `→ deferred full run` takes a full run before its audit, which stands for the deferred run while its snapshot matches; `audit: run too narrow` is the reason a full run records when it settles that Warning; a skill or agent file, which the harness loads, is a code file, and other prose that only skills read is exempt. — AC: each place states it; a walk-through of a story whose targeted set is empty `[manual]`
- **FR7 — The other skills.** `do`'s opening tells the run to read the contract before the first story; `status` reads raised signals in `docs/archive/epics/` too; `review`'s `all` and empty scopes skip `Withdrawn` and `Superseded` epics; `library` **Learn** marks a signal whose match was declined as declined, as the contract's **Signals** says; the contract says the header `**Amended**` form is written on a document's header (by `plan`, and by `review` amending a document) and the story-field form on a story (by `do`, and by `review` editing a `Pending` story), and that `status` reads the date in either. — AC: each place states it `[manual]`
- **FR8 — `fixed.md` is current.** Rows for `identity-key` at `do` step 4 and auditor check 6 (0.18.0); rows at or below 0.11.0, which no versioned signal can match, removed; rows sorted by file, step and version. — AC: a sweep over a planted corpus (a process signal at each kept row's file, step and class, at a version below the row's and one above, in two planted repositories) leaves out exactly the covered groups; control: a planted signal at a removed row's place, at 0.12.0, is reported `[manual]`

Consolidation, released as 0.21.0 (no change of behaviour):

- **FR9 — Each rule stated once.** In `do`, `worktree.md`, `plan`, `review`, `library`, `status`, the contract, `test-runs.md`, the auditor and `test-writer.md`, a rule its owner states (AD4) is referred to, not restated; a clause a nearby general rule implies is removed, with the derivation recorded; single-line paragraphs of more than 150 words become parallel bullets under their bold labels. Exceptions that stay as they are: `do`'s **Audit** list and the test-writer's prompt (each the sender's half of a pair the receiver mirrors); `do` step 4's self-check, which restates the auditor's checks the lead must apply without loading `auditor.md`; `review`'s persona checklist; `status`'s waiting-on-the-user test, which Haiku applies; the red-pass manifest, whose exclusions differ from the snapshot's. A restatement that disagrees with its owner is a correctness item, raised under **Needs you**, not a cut. — AC: per file, the rule inventory and walk-throughs (Testing Strategy) show nothing lost, and for each rule a story made single, a grep for its key phrases hits only its owner, with a planted restatement as control `[manual]`
- **FR10 — Four sections load on demand.** `do`'s **Independent tests** moves to `do/independent-tests.md`, read when a story in scope has an `**Independent tests**` line other than `skipped`; `do`'s `[browser]` handling (its **Before the first story** probe, step 3's `[browser]` bullet and **Finishing**'s browser item; the parallel rule's one-line browser clause stays, its pointer being longer than it) to `do/browser.md`, read when the scope holds a `[browser]` criterion, an `**Amended**` line's included; `library`'s **Sweep**, **Back-fill** and **Consolidate** to `library/sweep.md` and `library/consolidate.md`, read for those arguments; the auditor's independent-test checks to `shared/auditor-independent-tests.md`, which the auditor reads itself, from the contract's directory, whenever the story has an `**Independent tests**` line other than `skipped`. Each point of use keeps a one-line pointer that names the file and says to read it again if it is not in context. — AC: each file exists; each point of use has its pointer; `claude plugin validate cpm-next` passes with no warning; no rule is in both places `[manual]`
- **FR11 — The sweep follows moved sections.** `library/sweep.md` holds a table of moved places (the old file and step, the new file), and places a signal naming a wholly moved place at the new one, and one naming a partly moved place by its text, as **Sweep** places a signal that names no step, before grouping and before reading `fixed.md`; `fixed.md` rows name the new place beside the old. — AC: a planted signal at `do/SKILL.md` **Independent tests** groups with one at `do/independent-tests.md`, and a row naming the new place covers both `[manual]`

### Should Have

- **FR12 — Docs and releases.** 0.20.0 after FR1–FR8 and 0.21.0 after FR9–FR11 (`plugin.json`, `marketplace.json`), each bumped only in its release's last story; README `(0.20.0)` and `(0.21.0)` bullets, a Size bullet with every file's count before and after, and an **Upgrading** note for each; `docs/maintenance/README.md` records the on-demand files and what reads them, and corrects every place that named a moved section (its **The browser checks** and **Browser test tools** bullets among them); the root README and guides change where they state something FR1–FR8 changed or name a moved section. — AC: each named file states it `[manual]`

### Won't Have (this iteration)

- A change to any parsed form, field name, header-block placement, status word, auditor check number, or bold label another file names.
- New behaviour beyond FR1–FR8 and FR11.
- A move of shared rules into the contract (the Needs-you walk, `[user]` placement, identity criteria).
- A trim of `review`'s persona checklist, of `status`'s waiting test, or of the red-pass manifest into the snapshot.
- A cut in `party` or `scout`, or a move of `do`'s small-change paragraph.

## Non-Functional Requirements

- **NFR1**: Word ceilings after 0.21.0 (`wc -w`), from 479c406: `do/SKILL.md` 7,989 → ≤ 6,450; `worktree.md` 670 → ≤ 650; `artifacts.md` 3,669 → ≤ 3,450; `fixed.md` 774 → ≤ 400; `test-runs.md` 2,189 → ≤ 1,950; `auditor.md` 1,989 → ≤ 1,700; `test-writer.md` 989 → ≤ 950; `plan` 2,282 → ≤ 2,150; `review` 1,467 → ≤ 1,450; `library` 2,315 → ≤ 1,350; `status` 914 → ≤ 900. The words cut (not moved) from a `do` run's every-run load (`do`, the contract, `test-runs.md`) are at least 1,000, and the words moved out of it are reported separately. A ceiling that cannot be met without losing a rule is a `Not met`, never a reason to cut one.
- **NFR2**: `claude plugin validate cpm-next` and `claude plugin validate .` pass with no new warning, and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next, with the count at 479c406 or more.
- **NFR3**: No added sentence records history (`CLAUDE.md`, "A SKILL.md is not a change log"); the added lines are grepped for `no longer`, `instead`, `rather than`, `used to`, `previously`, `now`, `replaced`, `in place of`, `formerly`, `earlier`, `anymore`, `moved`, `0.20`, `0.21`, `spec 58`, each hit accounted for.
- **NFR4**: Every parsed form is unchanged, compared region by region with 479c406 by `diff` after extracting each: the contract's template code blocks; the sentences that place `**Test run**` and `**Independent tests**` in the header block; the `**Scratch**` field; the criteria-reading paragraph; the review record's **Source** and **Date**; the `**Amended**` forms; the **Challenge** section's form; the `**Signal**` form and its marks; the `**Audit**` forms; the `**Test run**` mapping; the ` — blocked:` note.

## Architecture Decisions

### AD1: Correctness before consolidation, in two releases
Each contradiction is fixed in its own story against the text as it stands, audited, and released as 0.20.0; consolidation follows as 0.21.0. Cutting first would hide which reading a fix chose, and a consolidation audit could not tell a deliberate change from a lost rule; a regression in real use can be traced to one release. Each version bump is the last edit of its release, since a pushed bump reloads open sessions. Rejected: one pass that fixes while it cuts, and one release for both.

### AD2: An inventory, walk-throughs in fresh agents, and a final check across files
Prose has no test suite, so each consolidation story proves itself three ways (Testing Strategy): a scripted rule inventory of the text after 0.20.0, each mapping naming every condition of its rule; walk-throughs, each run by a fresh subagent given only the text and the case, compared by a fixed outcome tuple; and, after the last consolidation story, one story that re-checks every mapping across files and re-runs every walk-through over the final text together, since a rule mapped to its owner in one story can be cut from the owner in the next. Rejected: reading alone, word counts alone, and per-story checks with no final pass.

### AD3: On-demand files where a mechanical trigger decides
A section moves only when a run can tell from the epic doc or the arguments, before reading it, whether it applies; each point of use keeps a pointer, so a file lost to compaction is read again. The auditor's file sits in `shared/`, because every `.md` in `agents/` is loaded as an agent, and the auditor reads it on its own trigger, since its checks catch `do`'s lapses. Rejected: moving the small-change paragraph (little saving), moving shared rules into the contract (every skill loads more), and `do` passing the auditor's file path (the audited party would decide whether it is checked).

### AD4: Owners
The contract owns forms and the vocabulary every skill shares (blocked, waiting on the user, `existing`, signals); `test-runs.md` owns runs, snapshots, the deferred full run and failure sorting; the auditor owns what it checks and how severe a finding is; each skill owns its procedure. A sentence found in two places stays with its owner and becomes a reference elsewhere, except the pairs and self-checks FR9 lists.

## Scope

### In Scope
`cpm-next/skills/{do,plan,review,library,status}/SKILL.md`, `cpm-next/skills/do/worktree.md`, the new `do/independent-tests.md`, `do/browser.md`, `library/sweep.md`, `library/consolidate.md`, `shared/auditor-independent-tests.md`; `cpm-next/shared/{artifacts,test-runs,fixed}.md`; `cpm-next/agents/{auditor,test-writer}.md`; the docs and versions in FR12.

### Out of Scope
`party`, `scout`, the mods' code, `cpm-next/hooks/`, the contract's parsed forms.

## Testing Strategy

`claude plugin validate` and `claude plugin test` for NFR2; `wc -w` for NFR1; region `diff` for NFR4. Each correctness story is checked by the walk-through its FR names, over the text before and after, the old outcome being its control.

Each consolidation story is checked by:

- **The rule inventory.** A script in `{pre}/checks/` (`{pre}` being `{git common dir}/cpm-next/pre-0.21/`, which outlives the session) splits the file as it stands after 0.20.0 into rule units: each bullet, and each sentence of running text outside code spans and backticked forms. The inventory, written to `{pre}/checks/` and named to the auditor, maps each unit to the line that now carries it, the owner file and line it refers to, or the general rule that implies it with the derivation; a mapping names every condition of its unit. Control: a copy of the new text with one condition dropped from a merged sentence in a passage the story changed leaves that unit's mapping incomplete.
- **The walk-throughs** that read the story's files (the table below), each a case written once to `{pre}/checks/cases/` with its `{pre}` tuple computed once, run by a fresh subagent given only the case and the paths it may read, before (the 0.20.0 text) and after, a mismatch run again once and counted only if it repeats, compared by the outcome tuple: the fields written and their forms, the runs and their kinds, the audits and their prompts, the files created or deleted, and the **Needs you** and **Found** items. Control: one walk-through over a copy with one clause dropped from a passage the story changed gives a different tuple.

| Case | Reads |
|---|---|
| W1 a single build: targeted run, red pass, audit pass, close (constructed on `docs/epics/55-01-epic-rows-and-meta.md` Story 5) | `do`, `test-runs.md`, contract, auditor |
| W2 a story whose targeted set is empty, with a deferred full run that stands (`docs/epics/56-01-epic-contract-and-plan.md` Story 2) | `do`, `test-runs.md` |
| W3 a failing deferred run, a regression fixed under a scoped round (constructed) | `do`, `test-runs.md`, auditor |
| W4 a resume of a `full run due` story with a changed snapshot, and of a `fix due` story (constructed) | `do`, `test-runs.md`, auditor |
| W5 attended audit rounds: a second-audit Warning blocks, the user settles it at **Finishing**, a third audit (`docs/epics/57-01-epic-audit-rounds.md` Story 1) | `do`, auditor |
| W6 unattended rounds stopped by Repeat (constructed) | `do`, auditor |
| W7 a marked story: pre-build red, a return, a dispute, a revision (constructed) | `do`, `independent-tests.md`, test-writer, auditor, `auditor-independent-tests.md` |
| W8 a one-checkout batch with a shared deferred run (constructed) | `do`, `test-runs.md` |
| W9 a worktree batch with a merge conflict (constructed) | `do`, `worktree.md` |
| W10 a `[browser]` criterion with no browser connected, settled at **Finishing** (constructed) | `do`, `browser.md` |
| W11 a small change (constructed) | `do`, `test-runs.md` |
| W12 a red pass whose manifest mismatches, and a stopped pass restored (constructed) | `do` |
| W13 a failing targeted run, a full run, then flaky and order-dependent (constructed) | `test-runs.md`, auditor |
| W14 an `existing` reason, used rightly and misused (constructed) | `do`, contract, auditor |
| W15 an unattended criterion that looks wrong: `**Amended**` and `**Pivot deferred**` (constructed) | `do` |
| W16 signal routing: a recurrence, a declined match, a joined candidate (`docs/epics/56-02-epic-test-writer-do-and-audit.md` signals, promoted through `do`'s **Finishing**) | `do`, contract, `library` |
| W17 a sweep over two repositories, with a moved place (constructed) | `library`, `sweep.md`, `fixed.md` |
| W18 an import, a back-fill and a consolidate (constructed) | `library`, `consolidate.md`, contract |
| W19 a `plan` of a spec with a data source and no sample, a user-checks epic and lessons (constructed) | `plan`, contract |
| W20 a review finding decided at challenge, and one reopened (constructed) | `review`, contract |
| W21 a `status` report: a story waiting on the user, a raised signal in an archived epic, a review covering an epic (constructed) | `status`, contract |

## Assumptions

- FR1: `do` writes `Complete` and `**Audit**` in one edit, so the `**Audit**`-line condition changes only stories `do` did not close, which no audit will rework.
- FR4: in a one-checkout batch no subagent result stands anyway, since the lead's run after the batch is the story's run; banning subagent test runs there loses nothing.
- FR6: the plugin's own skill and agent files are code because the harness loads them; this matches how the 56 and 57 runs mapped `do/SKILL.md` and the agent files as untested.
- The word ceilings are the survey's estimates less a margin for the text FR1–FR8 add.
- The 18 `fixed.md` rows at or below 0.11.0 stay in git history and the README log.
- The releases are built in two runs (the user's decision, 2026-11-12): 58-01 and 58-02, then commit, push and use 0.20.0, then 58-03 to 58-06.

## Challenge
**Personas**: architect, qa (2026-11-12)

- architect / qa: `agents/auditor-independent-tests.md` would load as an agent (validate warns; every install gains a bogus agent) → Folded in: FR10, AD3 (the file in `shared/`)
- architect / qa: moving sections that `fixed.md` rows, `do` and the sweep name splits sweep groups and contradicts Won't Have → Folded in: FR11 (a table of moved places), FR8 (rows name the new place), Won't Have narrowed to bold labels
- qa: the inventory's base (479c406) leaves the correctness fixes unprotected → Folded in: Testing Strategy (the inventory is of the text after 0.20.0), AD2
- qa: no check across files, so a rule mapped to its owner can be cut from the owner later → Folded in: AD2 (a final cross-file story)
- qa: the spec dropped the source's rejections of trimming `review`'s checklist and merging the manifest with the snapshot → Folded in: Won't Have, FR9's exceptions
- architect: the prompt lists and step 4's self-check are deliberate pairs, which "refer, not restate" would break → Folded in: FR9's exceptions, AD4
- architect / qa: FR2's premise was wrong (`fix due` is written before the fix) and a resume cannot rebuild the scoped round's inputs; every scoped round's directory was unnamed → Folded in: FR2 (a whole-story audit stands as the scoped round; `s{n}` directories)
- qa: a resumed story with round records is a fourth prompt kind → Folded in: FR3
- architect: parallel audits running tests are a second overlap; isolation covers state, not half-written code → Folded in: FR4 (no test run while code is written; audits may run together)
- architect: the new `existing` condition needs the baseline, which the auditor is not given → Folded in: FR5 (`do` passes each cited test's baseline result)
- qa: the ` — revised` rule works per file, but a dispute retakes one test's red → Folded in: FR5 (a revision retakes every independent test's red in the file)
- qa: FR7's items left the reading to the builder → Folded in: FR6, FR7 (each decision stated)
- qa: a story whose targeted set is empty has no rule, and plugin prose is classified three ways → Folded in: FR6
- architect / qa: FR5's sweep check passes whatever is done (no process signal exists) → Folded in: FR8 (a planted corpus with a control)
- architect / qa: the on-demand files' triggers were stated only where first met; a compacted file is lost; a `[browser]` criterion can arrive by amendment → Folded in: FR10 (a pointer at each point of use; amendments included)
- architect / qa: the audited party decided whether the auditor read its checks → Folded in: FR10, AD3 (the auditor's own trigger)
- architect: NFR4's method and its list of parsed forms → Folded in: NFR4 (region extraction; the full list)
- architect / qa: the ceilings left no margin while correctness adds words, and part of the saving is a move → Folded in: NFR1 (looser ceilings; cut and moved reported apart; a miss is `Not met`)
- architect: line citations go stale after the first story → Folded in: places cited by section, lines for orientation
- architect / qa: the inventory's splitter breaks paths and forms, its size is unworkable, "mapped" is undefined, and the control is not blind → Folded in: Testing Strategy (a scripted splitter outside code spans, mappings naming every condition, a dropped-clause control in a changed passage)
- qa: the walk-throughs leave files and the riskiest rules unexercised, "same outcome" is undefined and the judge is the author → Folded in: Testing Strategy (21 cases mapped to files, fresh subagents, an outcome tuple)
- qa: three cited histories do not say what the spec assumed (no review has a decided-at-challenge finding; 57-01 Story 1 is attended; 56-02's promotion was `do`'s) → Folded in: the table (W5 attended, W16 through `do`, W20 constructed)
- architect / qa: one release for fixes and a 25% cut; bumps mid-run reload sessions → Folded in: AD1, FR12 (two releases, each bump last)
- qa: FR6's `existing` fix reached the contract and auditor but not `do` → Folded in: FR5 (stated once in the contract)
- architect / qa: FR12's docs rule forbade correcting places FR10 moves → Folded in: FR12
- architect: `status` runs on Haiku and has no walk-through → Folded in: FR9's exceptions, W21
- qa: FR8's scope included `party` and `scout` → Folded in: FR9's file list
- qa: "paragraph" references break when paragraphs become bullets → Folded in: FR9 (bold labels kept; references to them updated with the edit)
- qa: NFR3's word list was narrower than 57's → Folded in: NFR3
- architect: give `audit: run too narrow` a rule → Folded in: FR6
- qa: the Independent tests move saves less than claimed, since `plan` marks every high-effort story → Rejected: the user chose to move all four sections (2026-11-12), and the pointer costs one read when it applies; NFR1 reports the moved words apart so the saving is not overstated — confirmed by the user (2026-11-12)
- architect: wait for 0.20.0 to be used before 0.21.0 → Folded in: Assumptions (the user may run the epics in two runs)
