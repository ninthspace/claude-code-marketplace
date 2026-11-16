# Spec: Lessons learned in one repository reach cpm-next

**Date**: 2026-11-15  
**Amended**: 2026-11-15 — FR1 and FR4: a story's `**Started**` line, written at step 1, decides which rules apply (review 16, the user's decision); FR6 and FR7: lessons are collected by owner text, reported once and left out by a `declined` row, one repository is enough when a signal's `recurs:` names the lesson, and a recurring signal carries the version that uncovers a fix (review 16, the user's decision); FR4 and FR5 name the four `unprobed` reasons AD3 gives  
**Amended**: 2026-11-16 — NFR1: `library/sweep.md` 1,550 → 1,650, the folder form of `sweep add` and the `docs/cpm/` folders drafted at 1,598 (Epic 59-03 Story 3), as NFR1 allows  
**Amended**: 2026-11-16 — NFR1: `do/SKILL.md` 7,450 → 7,550 and the contract 4,000 → 4,100, the probe rule drafted at 7,461 and 4,061 with 59-02 Story 2 and 59-03 Story 3 still to add (Epic 59-02 Story 1), as NFR1 allows  
**Amended**: 2026-11-16 — NFR1: the contract's ceiling raised to 4,000, the red rule and the `**Started**` field drafted at 3,917 with `**Probed**` still to come (Epic 59-01 Story 2), as NFR1 allows  
**Amended**: 2026-11-16 — FR1 narrowed from a red per clause to a red per alternative joined by "or" plus the control (a red per input path, 127 reds, was measured and rejected too), after the walk table found a red per clause took 205 reds on opendaw-trak 03-01 against 50, with 32 criteria counting two ways (Epic 59-01 Story 1; the user's decision); FR2's AC no longer counts 03-02's clock-arithmetic test as a test double (`scripts/ab.ts:721`)  
**Source**: conversation (2026-11-15): the user's report that lessons learned in one repository keep repeating because they are never swept; the user's decisions (a red per clause; runtime claims probed in `do` before the build; `sweep add` offered when a lesson is promoted, and taking a parent folder)

## Problem Summary

A lesson a project learns about how cpm-next plans and checks is promoted into that project's `docs/library/` as a `project` lesson. Nothing carries it to cpm-next, and cpm-next's own steps, which a project lesson cannot change, keep producing the failure.

opendaw-trak shows it. Of the six lessons in its `docs/library/lessons-learned.md`, four are about criteria, checks and reds (`criterion-contradicts-input`, `check-cannot-fail`, `unchecked-input`, `evidence-without-red`) and two about its own code (`shared-state-collision`, `overwrite-loses-data`). Two of the four were promoted on 2026-11-13, cited on the `**Lessons**` line of every later epic, and still recurred:

- `check-cannot-fail`, 6 signals after promotion (03-01 Stories 3, 7, 8 and 9; 03-02 two): a clause of a criterion had no input that broke it, a test read a value a fake produced, or a check read lists that were empty. The lesson asks for "a red for each rule"; `do` step 4 takes one red per criterion, and when undoing lines leaves the test green it mutates "a covered line instead, which may lie outside the story" (`cpm-next/skills/do/SKILL.md:73`).
- `criterion-contradicts-input`, 3 signals after promotion (03-01 Stories 1, 2 and 7): a criterion stated what a browser API returns or when an engine starts measuring, and the build found otherwise and amended; Story 7's two were about the repository's own code. `do` has no step that asks a runtime before the build.

This repository learned the same lessons on its own (`docs/library/01-library-lessons-learned.md`: "A control is only a control once you have watched it fail, and read why", with no `**Class**`; "Ask the runtime the question rather than modelling its answer", with none; "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs", `spec-drift`).

`/cpm-next:library sweep` is the one route from a project to cpm-next. It reads only `process` signals and reports a group only when two listed repositories show it. Three repositories are listed (`~/.claude/cpm-next/repos.txt`), and 2 of the 19 repositories under `~/Work/git` that have a `docs/library/`. The listed repositories hold 166 signals; trak's four `process` signals each came from trak alone, so the threshold kept them out, and its lessons are not read at all.

## Functional Requirements

### Must Have

- **FR1 — A red for each alternative and the control.** `do` step 4's red pass takes, for a test-proven criterion, one red, plus one for each further alternative the criterion joins with "or" (each an input the code must handle on its own), plus one for its control when it names one (a must-not, must-not-change or never criterion's control, or text saying `control`). Conditions joined by "and", listed, or stated with "when" or "unless" take no red of their own, and the values one assertion compares together are one. `existing` is judged per red. An independent test's held `before the build` red stands for the alternative its failing assertion proves. The rule applies to a story whose `**Started**` line, which `do` writes at step 1 (`**Started**: cpm-next {version} ({YYYY-MM-DD})`), gives 0.22.0 or later; a story with no such line, or an earlier version, keeps one red per criterion. — AC: the contract states the rule once (**Evidence against each criterion**), with one `Evidence` line per red naming its alternative or `control` in brackets; `do` step 4, its red-pass hand-off and `worktree.md` refer to it; graded against the walk tables (`.git/cpm-next/checks/59/walk-table.md` and `walk-table-narrow.md`), the rule requires a red for 03-01 Story 3's "or in a group's chain" and for Story 7's session-port check, and 03-01 takes 77 reds against 50 under 0.21.1 (`walk-table-narrow.md`) `[manual]`
- **FR2 — A red comes from the code the assertion reads.** A red's undone lines or mutation lie in the code that produces the value the cited assertion reads; a test double the test uses in place of that code, between it and the assertion, is a finding unless the criterion names it as the seam. Stubbing the clause's own code to return a wrong value is still a mutation (`do/SKILL.md:73`), and undoing a refactor's lines may be replaced by a mutation anywhere in the clause's code. A test found unable to fail on its clause's code abandons the pass (files restored, directory removed, the `**Scratch**` line gone), is fixed, or disputed when it is an independent test (`independent-tests.md`), retakes step 4's run, and starts a new pass. — AC: `do` step 4 and `independent-tests.md` say it; the walk table gives opendaw-trak 03-01 Story 9's ceiling-table test as a finding under the new text, and 03-02's clock-arithmetic test as none (`window.__ab.position()` is the page's own code, `scripts/ab.ts:721`) `[manual]`
- **FR3 — The auditor checks reds per clause.** `cpm-next/agents/auditor.md` check 5 raises a Warning for a clause with no red and for a red taken through a test double the criterion does not name as its seam; a criterion whose clauses read two ways is raised as a wording finding, settled by **Inline change**, not as a missing red. — AC: check 5 says it, referring to the contract `[manual]`
- **FR4 — Runtime claims are probed before the build.** At step 1, before the independent tests are written and before any fan-out, the lead lists each claim a story's criteria make about a runtime outside the repository's own code (a browser API, a third-party engine or library at run time, including a checkout of one the repository builds against, the operating system) and asks it with a probe in the session, recording each in a `**Probed**` line. A claim the probe contradicts goes through **When a criterion looks wrong**, the probe being a citation (`probe: {what was run} → {observed}`), before any test or code is written. A claim is recorded `unprobed` only when the probe needs credentials, a deploy, hardware the session lacks, or a person. A story whose criteria make no such claim has no line, and a story whose `**Started**` line is missing or below 0.22.0 takes no probe. — AC: `do`, the contract (the `**Probed**` form and the probe citation in **When a criterion looks wrong** and `**Amended**`'s `cited:`) say it; the walk table gives 03-01 Story 1's `playbackStats` claim as contradicted by the probe before the build, Story 2's as reached only where its criterion states the claim, and Story 7's as out of reach (the repository's own code) `[manual]`
- **FR5 — The auditor reads the probes.** The auditor raises a Warning for a runtime claim of FR4's kind with no `**Probed**` entry, for an `unprobed` reason outside FR4's four, and for a criterion its own probe contradicts that stands with no `**Amended**`, `**Inline change**` or recorded user decision. — AC: `auditor.md` says it in the check that reads criteria against their evidence `[manual]`
- **FR6 — The sweep reads promoted lessons.** `sweep` also reads each listed repository's library lessons (each `##` entry in a `docs/library/` file ending in `lessons-learned.md`, classed or not, an `## Amendment` block excepted) and collects one whose owner text ("The layer that owns it", "Owned by", or `**Scope**`) names a cpm-next skill or agent (`plan`, `do`, `review`, the auditor, the test-writer, or a v3 skill's counterpart). It places the lesson at each cpm-next file and step that text names, matching a lesson with no `**Class**` by reading, and groups it with signals and other lessons as now. It also reads `project` signals whose `recurs:` names a collected lesson. A group is reported from one repository when a signal's `recurs:` names one of its lessons (a recurrence can only be written after the lesson exists), or holds a `process` signal with a `recurs:` suffix; otherwise it needs two repositories, the plugin's own repository counting toward two but never reported alone. A lesson the maintainer judges is not cpm-next's is left out by a `declined` row (FR7). Lesson titles and text are under the issue draft's rule as signals are, and an entry from one repository gives no repository count. — AC: `sweep.md` says it and `library/SKILL.md`'s finish line refers to it; following the source `sweep.md` by hand over this repository and opendaw-trak at a recorded HEAD, with a scratch copy of the list, reports trak's `check-cannot-fail` and `criterion-contradicts-input` lessons, and reports its `shared-state-collision` and `overwrite-loses-data` lessons until a `declined` row for each is added, after which they are left out `[manual]`
- **FR7 — Fixes cover lessons, and a recurrence uncovers.** `shared/fixed.md` gains a release date and an outcome per row: a fix, or `declined` for a lesson the maintainer judges is not cpm-next's. A fix row covers a lesson placed at its file and step, of its class or `any` (a lesson with no `**Class**` by reading), when the row's date is after the lesson's `**Promoted**` date (the same day does not cover; a lesson with no `**Promoted**` date is covered by no fix row); a `declined` row covers it whatever the dates. `do` writes ` — cpm-next {version}` on every signal with a `recurs:` suffix, `project` signals included, and a signal recurring on a covered lesson whose version is at or above the row's uncovers it, the group then being reported with that signal. A group is left out only when every member is covered. — AC: `fixed.md` has the columns, every row dated from its release; the contract's **Signals** and `do`'s **Signals** say the version on a recurring signal; `sweep.md` says the rule; planted cases in a scratch repository give: a lesson promoted the day before a row is covered, the same day not, one with no `**Promoted**` not, a `declined` row covers, a recurrence at the row's version uncovers, one below it does not, and a group with one covered and one uncovered member is reported `[manual]`
- **FR8 — Repositories reach the list.** `sweep add {path}` given an existing folder that is not a git repository adds each git repository directly under it that holds `docs/epics/`, `docs/archive/epics/`, `docs/quick/`, `docs/retros/`, `docs/library/` or `docs/cpm/`, naming each added and each skipped as already listed; a path that does not exist, or a git repository, is added as now. A repository holding only `docs/library/` or `docs/cpm/` is read, not reported as empty. `do`'s Finishing suggests `sweep add` once per run, when the run finished a spec or wrote a lesson and the list does not hold the repository, replacing its present spec-finished line; `library learn` ends with the same suggestion when it wrote a lesson. — AC: `sweep.md`, `do`'s Finishing and `library`'s **Learn** say it, `do` in one rule; following the source `sweep.md` by hand with a scratch copy of the list, `sweep add /Users/chris/Work/git` adds the repositories that qualify and names those skipped `[manual]`
- **FR9 — Release 0.22.0.** `cpm-next/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` give 0.22.0; `cpm-next/README.md` has a 0.22.0 bullet per change, a Size bullet and **Upgrading to 0.22.0**; the three guides say what changed where they describe the red pass, the build or the sweep, with stamps at 0.22.0; `shared/fixed.md` gains a row for each change at the file and step it fixes. — AC: each file says so; `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next, and `claude plugin validate cpm-next` and `claude plugin validate .` pass `[manual]`

### Won't Have (this iteration)

- Reclassifying past `project` signals as `process`, or changing how `do` chooses between them; FR6 reads lessons instead.
- `plan` probing runtimes while it writes criteria (the user chose `do`).
- Adding repositories to the list without the user (the user chose a suggestion).
- A probe of claims about the repository's own code; reading the code is the existing route.

## Non-Functional Requirements

- **NFR1**: words, by `wc -w`, at most: `do/SKILL.md` 7,550 (7,128 now); the contract 4,100 (3,702); `auditor.md` 2,150 (2,000); `library/sweep.md` 1,650 (1,188); `library/SKILL.md` 1,330 (1,297); `fixed.md` 550 (301); `independent-tests.md` 820 (771); `worktree.md` 680 (645). Re-budgeted, by amendment, once the epics are drafted, never by terser rules.
- **NFR2**: every parsed form reads as before: `Evidence`, `**Signal**` and `**Test run**` lines written before 0.22.0 are valid, and `**Probed**` is one header-block line that the mods drop like any unknown field.
- **NFR3**: the walk tables report, for opendaw-trak 03-01, the reds its criteria take under 0.21.1, under a red per clause and under FR1, so the cost of the rule is known before release; FR1 keeps 03-01 at no more than 1.6 times its 0.21.1 reds.

## Architecture Decisions

### AD1: The red rule is defined once, in the contract
`do`, the auditor, `worktree.md` and `independent-tests.md` refer to the contract's definition. A red per clause was measured and rejected (Epic 59-01 Story 1: 4.1 times the reds, 32 criteria counting two ways); a red per input path regardless of its joining word was measured at 2.5 times for one conditional catch more and rejected; a red per "or" alternative plus the control costs 1.5 times and keeps the catches from an untested alternative or control. It depends on wording: a criterion that means separate inputs joins them with "or". `plan` splitting every multi-rule criterion was not chosen by the user; `plan` is not changed.

### AD2: Several reds are several `Evidence` lines
A criterion with several clauses carries one `Evidence` line per clause, each naming its clause in brackets after the test. The mods test only whether a criterion has an `Evidence` line (`cpm-next-progress/hooks/progress.ts:187`, `whats-next/hooks/plan.ts:122`), so either form parses; one line per clause keeps each red beside its clause for the auditor and a reader.

### AD3: The probe record is a story field
`**Probed**: {claim} → {observed} ({how}) | {claim} → unprobed: {credentials | deploy | hardware | a person}; … ({YYYY-MM-DD})`, one line in the story's header block, written by the lead at step 1. A probe is not proof that a criterion is met, and it is taken before any code exists, so it is not an `Evidence` line.

### AD4: Lessons are matched to fixes by date
A library lesson carries a `**Promoted**` date and no cpm-next version, so `fixed.md` rows gain the release date from the commit that set the release's version. Versioning each lesson was rejected as a form change in every project.

### AD5: A recurrence keeps a covered lesson visible
A row that covers a lesson would hide the next failure of the same kind, which is the problem this spec solves; so a signal recurring on the lesson at or after the row's version uncovers it. Signals carry no date, and an epic's date is its planning date, so the version a recurring signal carries decides it.

### AD6: A story records the version it began under
`**Started**: cpm-next {version} ({YYYY-MM-DD})`, written by `do` at step 1, tells `do` and the auditor which rules a story follows. Judging by the `**Probed**` line was rejected: a story with no runtime claim has none.

### AD7: The maintainer separates cpm-next's lessons from a project's
No text filter tells a lesson about cpm-next's steps from one about the project's own code: both name `do` as owner. The sweep reports both, and a `declined` row in `fixed.md` leaves a project's lesson out from then on.

## Scope

### In Scope
`cpm-next/skills/do/SKILL.md` (step 1, step 4, **When a criterion looks wrong**, **Signals**, the **Audit** list, Finishing), `cpm-next/skills/do/worktree.md`, `cpm-next/skills/do/independent-tests.md`, `cpm-next/shared/auditor-independent-tests.md`, `cpm-next/shared/artifacts.md`, `cpm-next/agents/auditor.md`, `cpm-next/skills/library/sweep.md`, `cpm-next/skills/library/SKILL.md`, `cpm-next/shared/fixed.md`, the README, the three guides, `docs/maintenance/README.md` where it records these files.

### Out of Scope
`plan`, `review`, `status`, the mods, and any change in a scanned repository.

## Testing Strategy

The test command is `claude plugin test {plugin}` for cpm-next, cpm-next-models, cpm-next-progress and whats-next (177 tests at 0.21.1), with `claude plugin validate cpm-next` and `claude plugin validate .`. The changes are instructions, proved `[manual]`: by reading the text against each criterion; by the walk table, written from the opendaw-trak records before any text changes and graded after; and, for the sweep, by following the source `sweep.md` by hand (the installed copy is the previous release) over this repository and opendaw-trak at recorded HEADs, read only, with a scratch copy of the repository list and absolute paths; planted cases live in a scratch repository on that copy.

## Assumptions

- A probe runs only what the session can run without credentials, a deploy, hardware or a person it lacks; the criterion stands while a claim is unprobed.
- The two-repository threshold stays for a `process` signal that has not recurred; one with a `recurs:` suffix has, like a promoted lesson.
- Neither repository's library is edited; a lesson the maintainer judges not cpm-next's is declined in `fixed.md`, since the sweep never writes in a scanned repository.
- 0.22.0, since the red pass and the probe change what `do` does.

## Challenge
**Personas**: architect, test, pm (2026-11-15)

- test / architect: FR2's ban on reds "in a stub" contradicted `do/SKILL.md:73`, broke the refactor fallback, and had no route back when a test must be fixed mid-pass → Folded in: FR2 (a test double in place of the code the assertion reads; the pass is abandoned, the test fixed or disputed, the run retaken)
- test: FR2's walk would find a red in 03-01 Story 9 through real code (`scripts/load-ceiling.ts:189-191`) → Folded in: FR2 (the red comes from the code producing the value the assertion reads; a double between is a finding)
- test: FR1's clause definition missed "or" (03-01 Story 3) and "judged too" implied by "for the three" (Story 8) → Folded in: FR1 ("and" or "or"); the walk table records Story 8's implied clause as the table finds it
- test / architect / pm: FR1 multiplies reds with no limit and no cut-over for stories begun earlier → Folded in: FR1 (one assertion's compared values are one clause; stories begun under 0.22.0), NFR3
- test: FR1 said nothing of independent tests or `existing` → Folded in: FR1
- architect: the red-pass hand-off and `worktree.md` need the clause list → Folded in: FR1, Scope
- test: the walk ACs graded themselves against reds the epic no longer holds → Folded in: the walk table, written before any text change (Testing Strategy, Epic 59-01 Story 1)
- test / pm: the walks covered only the cases the fixes fit; 03-02's two were left out → Folded in: FR1, FR2 (all six signals in the table)
- test / architect: FR4's walk failed on Story 7 (the repository's own code) and on Story 2 (the claim not in the criterion) → Folded in: FR4's AC claims Story 1, Story 2 only where stated, Story 7 out of reach
- test: "no probe in the session can reach" was an open escape → Folded in: FR4, FR5 (three named reasons, judged by the auditor)
- architect / test: the probe's place and runner, after the test-writer and inside fan-out → Folded in: FR4 (step 1, by the lead, before independent tests and fan-out)
- architect: a probe can't be cited in **When a criterion looks wrong** or `**Amended**` → Folded in: FR4
- architect: FR5's Warning fired on a criterion the user kept or amended, and named the wrong check → Folded in: FR5
- pm / architect / test: FR6's filter collected nearly every lesson, and one repository then reported each one forever → Folded in: FR6 (owning-layer text names a cpm-next skill; one repository only with a recurrence after promotion; the plugin's repository never alone), FR7 (`declined`) — superseded (2026-11-15): the owner-text filter separates none of trak's lessons (review 16); every collected lesson is reported once and a `declined` row leaves it out, AD7
- pm / architect / test: this repository's matching lessons have no `**Class**`, so FR6 never collected them → Folded in: FR6 (classed or not, matched by reading)
- architect / test: one place per lesson leaves a fix at another step never covering it → Folded in: FR6 (each layer the lesson names), FR7
- pm / architect / test: a dated row hides a lesson for good once it covers it → Folded in: FR7, AD5
- pm / architect: FR6's AC is cancelled by FR9's rows → Folded in: FR6's AC runs before the rows exist
- pm: issue drafts' privacy rule did not cover lesson text, and "1 repository" points at whose project it is → Folded in: FR6
- pm / architect: the evidence was wrong (all signals `project`; trak not listed; AD2's rationale) → Folded in: Problem Summary, AD2
- pm: the two-repository threshold, not the class, hid trak's `process` signals → Folded in: FR6 (a `process` signal with `recurs:` reports from one repository), Assumptions
- pm / architect: FR8's folder test caught a new repository, two suggestions could print in one run, skipping and refusing disagreed, and `docs/cpm/` repositories never qualified → Folded in: FR8
- test: FR8's AC needed a scratch list, and the list's path is fixed → Folded in: FR6, FR8 (`HOME` pointing at a scratch directory) — superseded (2026-11-15): a changed `HOME` loses the plugin installs and the installed copy is the previous release, so the source `sweep.md` is followed by hand with a scratch copy of the list and absolute paths (review 16)
- pm: cost is untracked; NFR1 caps words, not runs → Folded in: NFR3
- architect: NFR1 too tight for the new text → Folded in: NFR1 (raised; re-budgeted by amendment after drafting)
