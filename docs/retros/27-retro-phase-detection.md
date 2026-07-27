# Retro: Phase Detection and the Completion Promise

**Date**: 2026-07-27
**Source**: docs/epics/45-03-epic-phase-detection.md
**Stories**: 6/6 complete

## Summary

`cpm:ralph` can now be pointed at a spec and told to finish it. `coverage-rollup.sh --verdict`
gained a fourth exit code so "no matrix names this spec yet" is distinguishable from "the check
could not run"; the loop's phase judgement is a stated contract that reads two fields out of the
roll-up's records and computes nothing; the prompt carries both phases with a four-way branch on
that code; spec mode emits its own promise tag; and `[plan]` tags on epics phase 1 writes are
stripped before phase 2 runs `/cpm:do` over them. All 17 coverage rows are verified, the epic's
`--verdict` exits 0, and the spec roll-up reads `19 0 15 4` — 0 untraced throughout, with the
remaining four requirements belonging to epic 45-04.

Four new suites, 61 assertions, and the through-line is that **every one of this epic's design
decisions was made by reading the test surface first**. Four suites locate the prompt template by
grepping one sentence; that fact, discovered before any prose was written, is what made spec mode
two substitutions into the existing template rather than a second template. Retro 26's disposition
asked for exactly this grep, and it paid three times — twice by finding a net that pinned wording
about to become false, once by making the right design obvious.

## Observations

### Codebase Discoveries

- **A variable can have a use, a documented interpolation, and no definition — and read as  
  correct.** `{completion_promise}` was written into the state file's frontmatter by Step 3 and  
  named nowhere else; `ALL_EPICS_COMPLETE` reached that field only because the template happened  
  to contain the string. Nothing was wrong until a *second* value was needed, at which point the  
  binding had to be invented before it could be varied. A placeholder consumed in one place and  
  defined in none is invisible to review precisely because the single value in flight is always  
  the right one.

- **Four suites treat one sentence as an interface without saying so.** `Run /cpm:do on epics` is  
  the extraction key in `test-ralph-promise.sh`, `test-ralph-autonomous-wiring.sh`,  
  `test-aggregation-labelling.sh` and `test-epics-autonomous-mode.sh`, and a single stated  
  `**Length: N characters**` figure is read by two of them with `grep -oE`, which breaks silently  
  the moment a second figure exists. Neither fact is recorded anywhere near the template. The  
  first draft of spec mode's assembly instruction quoted that opening sentence while describing  
  the substitution — a second copy in the file — and "there is exactly one prompt template line"  
  caught it on the first run.

- **The script stated its exit codes in three places.** Header comment, `usage()` text, and the  
  branches that return them. Adding a fourth code made all three wrong at once; two were repaired  
  and only one was asserted. Retro 26's "two readers of the same thing" has a mirror image worth  
  naming separately: two *writers* of the same table, where nothing forces them to agree.

### Patterns Worth Reusing

- **Discriminate a named field by varying the axes independently.** The phase contract says the  
  loop reads `SUMMARY`'s `untraced` field. Asserting that the document says "untraced" proves  
  nothing. What proves it: three fixtures — all traced and verified, one untraced, one unverified  
  — and the rule that the named field must *move* between the first pair and *hold still* across  
  the second. `untraced` is the only `SUMMARY` field with that shape, so naming `delivered`  
  instead (which reads perfectly) fails on real output. Name the two axes the requirement  
  distinguishes, then find the measurement that separates them.

- **Build one fixture per situation the document names, not one per outcome.** Story 5's  
  assertions are of the form *the code a spec-with-no-matrix actually returns is the code whose  
  branch says "go back to phase 1"*. The fixture encodes the situation, the script decides the  
  code, and the prompt is asked whether it agrees — so the 44-03 defect (a branch on a code  
  nothing returns) fails by construction. Fixtures indexed by expected exit code would have  
  passed it.

- **An ordering rule about prose is a comparison of offsets.** "Do not begin phase 2 while a  
  generated epic still carries the tag" looks like it needs a running loop. It needs  
  `grep -bo`: the strip sentence's position against the phase-2 sentence's, both read out of the  
  clause, with a control that swaps them. Claims about what happens first are often checkable  
  without executing anything.

- **Read the number out of the artefact, including inside controls.** A mutation control pinned  
  `692` to prove a stated length could disagree with its block. Story 6 changed the clause, the  
  figure became `984`, the `sed` stopped matching — and the control failed rather than silently  
  passing, which is the good outcome, but only because the two are compared. Controls carry  
  literals as readily as assertions do.

### Testing Gaps

- **A net that needs a new allowed phrasing per sentence has stopped being a rule.** The file-wide  
  ban on the token `untraced` in `test-ralph-promise.sh` began as a sound structural claim —  
  `ralph` never derives requirement state — and degenerated as spec mode made the untraced count a  
  legitimate subject throughout the skill. It was **deleted, not extended**. What it was for is  
  covered without vocabulary by the three structural nets beside it (no matrix glob, no Verified  
  column, no requirement list) and sharply by a sentence-scoped predicate in the new suite.  
  Extending the allowlist a fourth time would have produced a net that passes on anything already  
  written and fails only on wording.

- **A whole-file scan for a rule about instructions cannot be done with tokens.** Promoting that  
  sentence-scoped predicate to the whole skill was tried and abandoned: "an untraced count" and  
  "count the rows" differ by part of speech, not by vocabulary, and the denial phrasings needed to  
  keep the legitimate sentences clean were themselves becoming an allowlist. Scope the predicate to  
  the block where the rule is operative and defend the rest structurally.

- **Two test-side extractors reported more than the thing they extracted.** Reading digits out of  
  `Exit 4 means phase 1` returned the `1` from "phase 1" as a routed code, which put a  
  read-failure code in the phase-1 set and failed a disjointness assertion against a correct  
  document. An unbounded `sum` matched inside `SUMMARY`, flagging the very record the contract is  
  supposed to name. Both were found by a control or an assertion failing on correct input — the  
  same class of defect as retro 26's, and it is now four epics running where the defects were in  
  the assertions rather than the subject.

### Criteria Gaps

- **The NFR5 criterion measures the figure that did not change.** "The template's stated  
  `**Length: N characters**` figure matches its actual length" is satisfied by an epic-mode  
  template line that is byte-identical after this epic, while the thing AD3 costed — the assembled  
  *spec-mode* prompt — grew from nothing to 3,656 characters. Both new clause blocks state and  
  assert their own lengths, and the assembled figure is recorded in the skill, but the criterion as  
  written could have been met with the cost entirely unmeasured. A budget criterion should name the  
  artefact that carries the budget, which for a two-mode prompt is two artefacts.

## Recommendations

1. **Grep the suites before designing, not before editing.** Retro 26 asked for this as a guard  
   against breaking a net. This epic shows the stronger use: knowing which strings four suites key  
   off *determined* the design, and the cheapest correct design was the one that left them intact.  
   When several suites extract by the same string, that string is an interface — treat a change to  
   it as an interface change, not a wording change.

2. **When a placeholder gains a second value, look for its definition first.** `{completion_promise}`  
   had none. The generalisation: any `{...}` in a template that has never varied is a candidate for  
   having no binding at all, and the moment it needs to vary is the moment to check.

3. **Prefer deleting a degenerating net to extending it.** Record the deletion and where the  
   purpose went, as this epic did on Task 3.1 — the risk of deletion is that nothing replaces it,  
   which is a documentation problem rather than a reason to keep an allowlist growing.

4. **Write the control's mutation against a value read from the document.** Three controls this  
   epic carried a literal; one went stale within the same epic. `stated_for` reads it back, and the  
   fix cost one line.

5. **Nothing in spec 45 has been run as a loop.** Four epics of prose about autonomous execution  
   are asserted as prose. Epic 45-04 is the last chance in this spec to say plainly what would have  
   to be true for someone to trust it, and the honest statement is that the suites verify the  
   instructions are present, ordered, bounded, and consistent with the script — not that a loop  
   obeys them.
