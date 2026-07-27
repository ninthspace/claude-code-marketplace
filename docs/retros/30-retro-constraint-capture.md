# Retro: Constraint Capture and Transmission

**Date**: 2026-07-27
**Source**: docs/specifications/46-spec-environmental-requirements.md
**Stories**: 5/5 complete

## Summary

Epic 46-02 is the authoring half of spec 46: `cpm:brief` stops discarding constraints, and
`cpm:spec` gains an elicitation step, the requirement/restriction split, a falsifiability
refusal, and an inheritance startup check that reaches past the product brief to the problem
brief. Five stories, three new suites, 55 suites green and 1,544 assertions at close.

Almost all of it is prose in a SKILL.md, which is the interesting constraint. A rule written
into a skill has no runtime an assertion can observe, so nearly every criterion here is checked
by grepping the document that carries it — and an assertion over prose catches a rule being
*deleted* while saying nothing about whether a facilitation *honoured* it. The epic's own
suite headers say so out loud. Most of what follows is about the two places that stopped being
true: where an oracle was genuinely available and nearly wasted, and where an assertion looked
like an oracle and was not.

## Observations

### Testing Gaps

- **An oracle that can only see the values it is meant to judge is not an oracle.** Story 2's  
  assertion — that every label the spec template advertises classifies as its name promises —  
  extracted those labels with `grep -o '\*\*ENVX\{0,1\}[0-9][0-9]*'`. That pattern matches only  
  labels which already classify, so a template advertising a label the classifier rejects could  
  never be surfaced by it. Under a mutation renaming `ENV1` to `ENVIRONMENT1` the oracle passed  
  and only its non-vacuity control fired. The fix was to extract by AD1's *whole* label grammar  
  — `[A-Z]+[0-9]+` — and compare a label→class map, with `NFR1` (which must classify empty)  
  in the expected value as an in-line discrimination control. Generalising: when an extractor  
  and the predicate under test share a definition, the extractor has to come from the broader  
  grammar, or the test is a tautology with a fixture.

- **A completeness claim asserted as a count of distinct values silently absorbs the degenerate  
  value.** Story 5 checks that three documents name the same constraints section. Written first  
  as `printf` the three values, `sort -u | grep -c .`, expect `1` — which reads as exactly the  
  claim. But `grep -c .` skips the empty line, so a *one-sided* empty extraction still counts 1  
  and the comparison passes. A mutation renaming the problem brief's section proved it: only  
  the control fired. The assertion covering the criterion that demands non-emptiness was itself  
  vacuous under precisely the mutation that criterion describes. Pairwise equality has no such  
  hole. This is a third form of retro 23's vacuous-extraction trap, and the one that hides best,  
  because the counting form looks *more* rigorous than the equality it replaces.

- **A mutation that changes nothing produces a green run indistinguishable from a mutation that  
  is caught.** Story 1's mutation B targeted a sentence ending `holder for them.`; the real  
  sentence ends `section to hold them.` Nothing was replaced, the suite passed, and the pass  
  meant "not applied", not "not caught". It was visible only because every mutation in this  
  epic printed a cksum and byte delta before the suite ran — retro 23's discipline, paying for  
  itself on its first outing here. Without that line the story would have shipped believing an  
  assertion was proven that had never been exercised.

- **An unbounded section slice can find the right string in the wrong sentence.** The Story 5  
  chain suite sliced Step 3a to read the heading it tells authors to record under. If Step 3a's  
  end anchor were renamed the range runs to EOF — and `spec/SKILL.md` names  
  `## Non-Functional Requirements` *twice*, once in Step 3a and once in the output template. So  
  the over-running slice still yields the correct string, from a sentence that says nothing  
  about Step 3a, and the comparison passes. Adding `assert_slice_bounded` to both slicers in  
  the suite closed it; a mutation renaming the anchor now fails the control. The hazard is  
  specific and worth naming: `head -1` over a slice is only honest while the slice is bounded,  
  and a document that repeats a heading is where that stops being a formality.

### Codebase Discoveries

- **A cross-skill reference had been dangling long enough that fixing it was accidental.**  
  `architect/SKILL.md:78` instructs the reader to summarise the product brief's *constraints* —  
  and the product brief template had no constraints section until Task 1.1 of this epic added  
  one. Nothing failed, nothing warned; the instruction simply named a section that did not  
  exist. Retro 25's consumer check (open the artefact before writing a sentence about it) found  
  it as a side effect of checking something else. The lesson is about direction: that check is  
  usually run to validate what you are *writing*, and it is at least as good at finding what  
  someone already wrote.

- **A new rule can contradict the document it is written into.** Story 3's fail-closed rule says  
  an environmental constraint that cannot be made falsifiable blocks the step. `spec/SKILL.md`'s  
  own Ambiguity termination policy already said the opposite for exactly that case — *"note both  
  options in the spec with a 'TBD' marker and proceed"* — and a TBD sits in prose  
  `coverage-parse.sh` never reads, so the general policy's outcome is the silent drop the new  
  rule exists to prevent. Reading the host document's termination and policy sections *before*  
  adding a rule to it is the check that catches this, and it is not the same check as grepping  
  the test suites.

- **Parser constants that are named are assertable.** `coverage-parse.sh:212` sets  
  `CPM_MD_NFR_HEADING='## Non-Functional Requirements'` as a variable rather than inlining the  
  string into its awk program. That single choice is what made the last hop of the chain a real  
  oracle: the heading `cpm:spec` tells authors to record under is compared against the heading  
  the parser actually reads, both extracted. Had the literal been buried in the awk source, the  
  hop would have been self-assessed. Worth carrying forward when writing parsers — a named  
  constant is a testing affordance, not just style.

- **`spec/SKILL.md`'s output template never documented the label grammar at all.**  
  `coverage-parse.sh` has always required `- **FR1 — Title.** prose`, and the template showed no  
  labels of any kind. Task 2.2 closed it for the environmental classes plus one `NFR1` example  
  line, because that was what the story's scope reached. `FRn` remains undocumented in the  
  template it is required by. Flagged during the epic and deliberately not widened into it.

### Patterns Worth Reusing

- **Scope an assertion to a section, then pair it with a control that the legitimate site  
  survives.** Story 4 hit retro 23's `assert_not_contains` trap twice from opposite directions:  
  "most recent" is forbidden in the new section and legitimate at `spec/SKILL.md:18`; "product  
  brief" is unavoidable in the sentence ruling it out. Scoping to the section fixes both — but  
  scoping alone would also pass if someone satisfied the must-NOT by deleting the *legitimate*  
  site. The paired control ("the Input section still resolves its own input by recency,  
  untouched") is what makes the narrowing correct rather than merely narrow, and a mutation  
  deleting that site proved it fires.

- **Count-plus-direction beats a filtered `assert_not_contains`.** Where the section must  
  mention a forbidden concept in order to forbid it, assert *how many times* it appears and  
  *which way* the one mention points — "mentions recency exactly once", then "and that mention  
  forbids it". Filtering the known sentence out of the haystack instead couples the assertion to  
  that sentence's wording, so a harmless rewording reads as a routing change. A second mention  
  is what the defect actually looks like.

- **Prove a correspondence oracle with a two-sided mutation, not only one-sided ones.** Story  
  5's suite claims it checks that two documents *agree*, rather than pinning either to a  
  literal. One-sided mutations (rename the writer; rename the reader) prove it fires. Only the  
  two-sided mutation — rename both, consistently — proves the claim, by requiring the suite to  
  stay **green**. It also caught that the first attempt at that mutation was incomplete: the  
  section named the directory in prose as well as in the glob, so half the read side had not  
  moved. A mutation expected to pass is as informative as one expected to fail, and this epic  
  had no other way to distinguish an oracle from a well-dressed literal.

- **Reserve an oracle for the story whose criterion it is.** Story 4's plan named the  
  correspondence check, stated that it was Story 5's criterion 1 verbatim, and explicitly  
  declined to spend it. Without that note the natural move is to write the strongest available  
  assertion where it first occurs to you, leaving the integration story asserting nothing new.  
  Cheap to do — one paragraph in a plan — and it is what gave Story 5 something to be.

### Scope Surprises

- **Two Change Type Decision gates, neither anticipated at breakdown, both resolved as inline  
  edits.** An epic whose stories add rules to a document that carries its own policy rules  
  should expect to amend those rules — the enumeration at `spec/SKILL.md:17` went stale the  
  moment Task 1.1 added a section to the brief template, and the Ambiguity carve-out was forced  
  by Story 3's fail-closed rule. Both were small; neither was in the plan. Worth pricing into  
  the next epic of this shape rather than treating each as an interruption.

## Recommendations

1. **When a test extracts the values it then classifies, extract by the broader grammar.** If  
   the extractor's pattern and the predicate under test share a definition, the assertion cannot  
   fail. Add a value that must classify *negatively* to the expected result, in line, so the  
   assertion discriminates without a separate control.

2. **Assert completeness as equality, not as a count of distinct values.** `sort -u | wc`-style  
   claims read as rigorous and silently absorb the empty string. Prefer pairwise equality, each  
   side guarded by its own non-empty control.

3. **Bound every section slice before extracting from it — especially with `head -1`.** The  
   sibling suites already do this via `assert_slice_bounded`; the new suite did not until Step  
   5b. In a document that names the same heading twice, an unbounded slice fails silently and  
   in the passing direction.

4. **Keep mutation deltas printed, and treat a zero delta as a failed mutation.** It cost one  
   line per mutation and caught a mutation that had never applied. Consider making a zero-byte,  
   zero-cksum delta an explicit error rather than something a reader has to notice.

5. **Prove correspondence suites with a two-sided mutation.** Any suite claiming to check that  
   two documents agree should include one mutation that changes both consistently and is  
   expected to stay green. Without it, "this is an oracle, not a pinned literal" is a claim in a  
   comment header.
