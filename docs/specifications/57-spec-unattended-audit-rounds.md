# Spec: More audit rounds in unattended runs

**Date**: 2026-11-12  
**Amended**: review 14 (docs/reviews/14-review-unattended-audit-rounds.md) and the user's decision — a blocked story's round record is kept until the story closes, so a story settled at **Finishing** continues its count and dismissals (FR3); a whole-story audit after a pass always runs and counts, and its findings are fixed only while the count is under the run's cap (FR8) (2026-11-12)  
**Source**: conversation (2026-11-12): in the spec 56 `do all` run three stories were blocked after a second audit returned only a Warning, and each time the user chose to fix it and audit a third time, which passed; the user's decisions (2026-11-12): many more audit rounds in unattended runs, capped at five, attended runs unchanged

## Problem Summary

`do` step 5 (`cpm-next/skills/do/SKILL.md:59`) gives a story at most two audits unless the second returns a Critical, which buys a third. A story whose second audit returns only a Warning is marked blocked, and its dependents wait until the user settles it at **Finishing**. In the spec 56 `do all` run this blocked 56-02 Stories 1 and 3 and 56-03 Story 1; each time the user's answer was "fix and audit again", and the third audit passed. The cap exists because an audit that finds something new in each fix never closes (`cpm-next/agents/auditor.md` **A later audit**), so more rounds need a bound, a stop that sees when the fixes are not converging, and a record that survives the session.

## Functional Requirements

### Must Have

- **FR1 — Five rounds when unattended.** At the end of each audit, `do` reads whether the run is unattended as **When to stop and when to keep going** defines it (`do/SKILL.md:146`); audits made during **Finishing**, with the user answering, are attended. In an unattended run, a story whose audit returns `fix needed` with a finding that held has those findings fixed as step 5 says and is audited again, up to five step-5 audits for the story; a fifth that returns `fix needed` ends the rounds as the last audit does now. In an attended run the present rule stands: a third audit only after a Critical in the second, saying in one line why. Each audit after the second, in either run, says in one line its round number and the result of FR2's tests. An audit whose findings all fail the lead's check is a pass. The scoped round of a failing deferred full run (`shared/test-runs.md`, **The deferred full run**) is outside the count. — AC: step 5 states it `[manual]`
- **FR2 — Stops for rounds that do not converge.** In an unattended run, from the third audit on, the rounds end and the story is blocked as after the last audit when either test holds, both read over findings that held after the lead's check:
  - **Repeat**: a finding that held in two earlier rounds, and was fixed after each, holds again (the same defect, at the same file and symbol or criterion). A finding the auditor raises at a new place the earlier finding's "wherever its mistake occurs" covered is not a repeat, and a re-raised dismissed finding is not one either.
  - **Rising count**: the audit's held Critical and Warning findings outnumber the previous audit's, both scoped rounds. Left out of both counts: `missed earlier` Criticals, a Warning settled by making a run or writing the `full run due` suffix, a finding routed through **When a criterion looks wrong**, and a disputed independent test the writer kept.
  The blocked story's signal (**Signals**: one when a story is marked blocked) names the test that stopped it, with the class of the finding that tripped it. — AC: step 5 states both tests, their start, the exclusions and the signal `[manual]`

- **FR3 — Round state outlives the session.** After each audit the lead writes the round's record in `{git common dir}/cpm-next/rounds/{epic file stem}-{story}/r{n}` (`quick-{nn}/` for a small change): the findings as the auditor wrote them, the lead's verdict on each (held, or dismissed with the reason), and FR2's results. The story's round count is the number of records there. The directory is deleted by its literal path when the story closes; a blocked story keeps it, so a story settled at **Finishing** continues its count and its dismissals. A resumed story, and one audited again as a whole story (`test-runs.md:73`, a resume, a worktree sibling's fix), continues its count from the records. — AC: step 5 or **Scratch directories and isolation** states the path, the contents, the count and the deletion; the resume bullet in **Before the first story** reads it `[manual]`
- **FR4 — Every later audit sees all earlier dismissals.** Each audit after the first gets what a later audit gets now (the previous audit's findings as it wrote them, the files the latest fix changed) and every finding dismissed in any earlier round, with its reason, from the records. — AC: **Audit** states it `[manual]`
- **FR5 — The rounds are visible.** **Changed** gives each story's round count, and **Found** names each story that passed at its fourth or fifth audit or was stopped by an FR2 test. — AC: **Finishing** states it `[manual]`
- **FR6 — The rule works on the cases that motivated it.** A walk-through over these cases gives the outcome the new text produces and the line that produces it: (a) attended, a second audit with a Warning only → blocked after two; (b) attended, a second audit with a Critical → a third; (c) unattended, held counts 3, 2, 1, 1, 1 → five audits, blocked on the fifth; (d) unattended, a finding held and fixed in rounds 1 and 2 holds again in round 3 → stopped at three by Repeat; (e) unattended, held counts 3, 1, 2 → stopped at three by Rising count; (f) a round whose findings all fail the lead's check → a pass; (g) the scoped deferred-run round → not counted; (h) the three spec 56 histories (56-02 Stories 1 and 3, 56-03 Story 1) → no stop, a pass at the third audit; (i) a story resumed after its third audit → its fourth; (j) a blocked story the user settles at **Finishing** → attended rules. A text that fails (d), (e) or (h) fails the check. — AC: the walk-through is in the story's `Evidence` `[manual]`

- **FR8 — A whole-story audit after a pass.** When a story that passed must be audited again as a whole story (a snapshot mismatch, `test-runs.md:73`; a worktree sibling's fix, `:81`), the audit always runs and is counted. Its `fix needed` is fixed and audited again only while the count is under the run's cap (five unattended; three attended); at or past it the story is blocked as after the last audit. Rising count never compares it. — AC: step 5 states it, and FR6's walk-through covers it `[manual]`

### Should Have

- **FR7 — Docs and release.** cpm-next goes to 0.19.0 (`plugin.json`, `marketplace.json`); the cpm-next README gains `(0.19.0)` bullets under **Additions** with a Size bullet, and an **Upgrading to 0.19.0** note; the places outside the skill files that describe the round rule describe it again: root `README.md:93`, `cpm-next-training-guide.html:1112-1113`, `cpm-next-onboarding.html:497`, `cpm-next-presentation.html:498` (SVG text) and `:507`. — AC: each named place states it, by reading `[manual]`

### Won't Have (this iteration)

- More rounds in an attended run, or an immediate ask when an attended story is blocked.
- A change to the scoped deferred-full-run round or its "second failure" rule.
- A cap set per project or per story, or a run-level cost cap.
- A field on the story recording rounds.

## Non-Functional Requirements

- **NFR1**: No added sentence in a SKILL.md or agent file records history (`CLAUDE.md`, "A SKILL.md is not a change log"); the added lines (`git diff -U0 | grep '^+'`) are grepped for `no longer`, `instead`, `rather than`, `used to`, `previously`, `now`, each hit accounted for.
- **NFR2**: `claude plugin validate cpm-next` and `claude plugin validate .` pass, and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next.
- **NFR3**: The round rule (the caps, which runs take each, the two tests and the record) is stated once in the plugin's skill and agent files, in `do/SKILL.md` step 5 and the record's place; `test-runs.md:73,77,79` and `auditor.md` **A later audit** refer to step 5 and stay unchanged; the READMEs and guides describe it for readers.
- **NFR4**: `wc -w` over `do/SKILL.md` at `1493fb6` and after; the README's Size bullet gives both.

## Architecture Decisions

### AD1: The cap depends on who is watching
In every run a story whose rounds end unresolved is marked blocked and settled at **Finishing**. An attended user is there to settle it in a few minutes and may not want more Opus rounds spent first; an unattended run's blocked story waits for the run's end, with its dependents, so the rounds go where they save that wait (the user's decision, 2026-11-12). More rounds in a batch also hold the batch's shared deferred run and serialise its checkout longer; that cost is accepted for unattended runs. Rejected: more rounds everywhere, and asking at once in an unattended run (nobody is there).

### AD2: Convergence, judged by the lead over held findings
A fix carried to too few places is the commonest later finding and the cheapest to close, so a repeat stops the rounds only after the same finding has been fixed twice and holds a third time. A rising count compares scoped rounds only (from the third audit on), since a first audit covers the whole story. Both tests read findings the lead already checks against the code, so neither needs auditor output beyond what it gives. The lead's judgement is visible: each round's record keeps every verdict and its reason, and FR4 shows every dismissal to the next auditor, who may show a reason wrong. Rejected: no cap with only the tests (unbounded cost per story), and a stop on any single repeat (it blocks the case the rounds exist for).

### AD3: Round state in the git common directory
The epic doc is the run's only state for the user, so the record is not a story field; it lives beside the red pass's scratch directories, in `{git common dir}/cpm-next/`, which outlives the session and is shared by worktrees. Rejected: a field on the story (every mod and the contract would carry it), and resetting the count on resume (the cap would have no bound across sessions).

## Scope

### In Scope
`cpm-next/skills/do/SKILL.md` (step 5, **Before the first story**'s resume bullet, **Audit**, **Scratch directories and isolation**, **Finishing**); the docs and versions in FR7.

### Out of Scope
`cpm-next/agents/auditor.md` (**A later audit** has no round number and already holds back a dismissed finding the prompt lists), `shared/test-runs.md` (its references to step 5's rounds read correctly), `shared/artifacts.md` (`n findings fixed` counts every round's findings), the mods (none reads rounds).

## Testing Strategy

Prose changes are checked by reading each changed passage against its requirement, by the FR6 walk-through, and by `grep` for every place that states the round rule, each hit accounted for (`[manual]`); `claude plugin validate` and `claude plugin test` for NFR2; `wc -w` for NFR4.

## Assumptions

- A fix in rounds three to five runs at the effort step 5 sets now (`high`, or `xhigh` for a story already at `high`).
- No `process` signal names this failure (`grep` over this repository's and `/Users/chris/Work/git/nativephp`'s `docs/`, 2026-11-12), so `cpm-next/shared/fixed.md` gains no row.
- A stop's signal reuses the tripping finding's class (`fix-not-carried-through` or `fix-introduced-defect` usually), both library lessons, so a recurrence goes under **Found** only.
- A finding that contradicts a criterion still goes through **When a criterion looks wrong** in any round.

## Challenge
**Personas**: architect, test (2026-11-12)

- architect / test: the round count and earlier findings live in session scratch, so a resume or a compaction restarts the rounds and the repeat test reads nothing → Folded in: FR3, AD3 (records in the git common directory, the count continued on resume and whole-story re-audits)
- architect / test: a repeat on one finding stops the commonest, cheapest case, a fix not carried to every place → Folded in: FR2, AD2 (a repeat needs the same finding fixed twice; a new place is not a repeat)
- test: the repeat test never required the repeated finding to hold → Folded in: FR2 (both tests read held findings)
- architect / test: every criterion was a presence check, so a rule that never fires or always fires passes → Folded in: FR6 (a walk-through over ten cases, three of which fail the check if mishandled)
- architect: an unattended round 2 Critical could be stopped where an attended run would get a third → Folded in: FR2 (no test before the third audit)
- architect / test: the rising count compared a whole-story audit with a scoped one, and its exclusions were unstated → Folded in: FR2, AD2 (scoped rounds only; exclusions listed)
- architect / test: the lead judges its own fixes, dismissals could keep a story going, and a re-raised dismissal could count as a repeat → Folded in: FR2, FR3, FR4, AD2 (every verdict recorded, every dismissal shown to the next auditor, a re-raised dismissal not a repeat)
- architect / test: a later auditor saw only the previous round's dismissals → Folded in: FR4
- architect / test: whole-story re-audits re-enter step 5 with no word on the count → Folded in: FR3 (the count continues)
- architect / test: AD1 claimed an attended run asks at the end of the rounds; it marks the story blocked like any run → Folded in: AD1 restated
- architect / test: the attended/unattended reading mid-run and during **Finishing** was undefined → Folded in: FR1 (read at each audit's end; **Finishing** audits are attended)
- architect / test: the stop's signal had no class or kind and could duplicate the blocked signal → Folded in: FR2, Assumptions (the blocked signal names the test and reuses the finding's class)
- architect / test: where the findings are kept, and in what form, was unstated → Folded in: FR3
- architect: a batch's shared deferred run waits on a story's extra rounds and its checkout is serialised longer → Folded in: AD1 (cost accepted)
- architect / test: NFR3 conflicted with the docs, and the stale places were unnamed → Folded in: NFR3, FR7 (places named; the docs describe for readers)
- test: "the files the fixes changed" was ambiguous across rounds → Folded in: FR4 (the latest fix's files)
- architect / test: a story passing at round 5 looks like one passing at round 2; the tests leave no trace when they don't fire → Folded in: FR1 (each later audit's line), FR3 (the record), FR5
- test: `fix needed` with no held finding, and a round with all findings dropped, were undefined → Folded in: FR1 (a pass)
- test: S6, more rounds mean more unattended criterion amendments; block such findings from round 3 → Rejected: the criterion route is unchanged by round, and its citation rule already limits it; a finding that contradicts a criterion is no likelier in a later round — confirmed by the user (2026-11-12)
- architect / test: cost per run is unbounded and the story timings widen → Rejected: a run-level cap is out of this iteration (Won't Have); FR5 makes the rounds visible so the cap can be re-judged — confirmed by the user (2026-11-12)
- architect: a scoped deferred-run round after five step-5 rounds adds one more audit → Rejected: it is a different trigger (a failing full run) with its own cap (A second failure), kept as is by Won't Have — confirmed by the user (2026-11-12)
- architect / test: NFR1's `now` and NFR4's measure were loose → Folded in: NFR1 (added lines), NFR4 (named file)
- test: the `fixed.md` assumption cited no check → Folded in: Assumptions
- test: FR3's auditor criterion was vacuous → Folded in: removed; auditor.md out of scope with its reason
- test: the attended rule's "saying in one line why" could be lost in a rewrite → Folded in: FR1
