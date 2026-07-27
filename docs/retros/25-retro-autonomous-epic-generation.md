# Retro: Autonomous Epic Generation

**Date**: 2026-07-26
**Source**: docs/epics/45-01-epic-autonomous-epic-generation.md
**Stories**: 4/4 complete

## Summary

`cpm:epics` gained an `### Autonomous Mode` section covering all six of its `AskUserQuestion`
gates: approve-your-own-proposal at five, AD5's *propagate, never invent* at the sixth, a
bounded write surface, and a per-gate breadcrumb. `cpm:ralph`'s prompt template gained a
one-sentence reference to it — a reference, not a copy. All nine coverage rows are verified,
`--verdict` returns 0, and the hook suite runs 40 files green with the new suite at 68
assertions.

The epic found three defects and every one of them was **a claim about another part of the
system, asserted without reading that part**: a rule that described its own scope wrongly, a
breadcrumb credited to a consumer that does not read it, and a precedent cited for a
requirement it does not contain. All three were found by the end-to-end read at a story gate,
all three with the suite green, and all three were fixed the same way — by turning the claim
into something a test can check.

This is retro 21's finding sharpened. Retro 21 said structural assertions confirm words exist
and never that a condition was honoured. What this epic adds is *which* words: the ones
describing something the author did not open.

## Observations

### Codebase Discoveries

- **A rule stated unconditionally in the sentence that introduces it, and conditionally in  
  the paragraph that ends it.** The autonomous branch opened with "the run's gates **do not  
  block**" and closed by naming a gate with no disposition. Both sentences were written in  
  the same sitting, twenty lines apart, and the suite was green across them. Retro 21  
  recorded this shape across three files and three stories; the interesting part here is that  
  it reproduced *within a single section* — proximity is not a defence, because the error is  
  in the scope of a claim rather than in its propagation. Fixed to "the gates listed below".

- **A named consumer that does not consume, for the third epic running.** The  
  `**Must-NOT proposed (unreviewed)**` breadcrumb was defined as "visible to the next reader  
  and to `/cpm:pivot`". `cpm/skills/pivot/SKILL.md` contains no breadcrumb field at all —  
  only `cpm:do` writes them, and `cpm:retro` reads exactly one. Retro 21 found this with  
  `cpm:status`, retro 22 with "drift detection", and this one was written by someone who had  
  disposed of both lessons at the gate that morning. Reading the retro is not the same  
  control as running the grep. The corrected sentence now says plainly that nothing parses  
  the field, and is paired with an assertion that greps the skills tree — so the claim is  
  checked as a *fact* rather than asserted as a sentence, and a future consumer fails the  
  test rather than silently vindicating the prose.

- **A precedent cited for a requirement it does not contain.** The write-surface rule said a  
  source gap is recorded and not repaired "exactly as the Termination — Blocker condition  
  already requires". Blocker actually says "flag the gap for resolution via `cpm:pivot` **or  
  a spec update**" — and a spec update is precisely the remedy NFR3 forbids — while its  
  trigger is a user who is not present in an autonomous run. Half the cited precedent  
  contradicted the rule citing it. This is the same failure as the consumer claim with the  
  direction reversed: there, a downstream reader was invented; here, an upstream authority  
  was. Both read as evidence and neither was checked. Fixed by claiming only Blocker's  
  record-and-flag half and naming the divergence, with an assertion on each side of it.

### Patterns Worth Reusing

- **Derive the two sides of a completeness claim from opposite ends and assert them equal.**  
  Gate sites were counted from the skill's body; dispositions were counted from the branch;  
  the must-NOT ("leave no gate site without a disposition") is the assertion that those two  
  numbers agree. A seventh gate raises the first and not the second; a deleted row lowers the  
  second and not the first, and both directions have a control. A single count taken from  
  either side alone is satisfiable by a matched pair of mistakes, which is exactly what  
  "every gate is covered" means when a human says it.

- **A three-way inventory beats a two-way one when the categories are not obvious.** Retro  
  22's rule inventory was taken before the first edit here and returned seven  
  `AskUserQuestion` mentions, of which six are gates and one is prose *about* the gates. The  
  count that mattered was therefore 7 − 1, and a test counting raw mentions would have been  
  wrong by one in a way no reviewer would spot. The excluded mention is excluded by its own  
  line in the predicate and asserted separately to still be prose, so adding a category is a  
  visible edit rather than a silent adjustment.

- **Promote a helper on its second use, not its third.** `assert_slice_bounded` existed as a  
  local function in `test-ralph-promise.sh` from retro 24's finding. This epic needed the  
  same shape and moved it into `test-helpers.sh` during the story's refactoring pass, then  
  proved by mutation that the extracted version still fails on a widened slice. Four call  
  sites now share one implementation, and retro 24's recommendation 4 — "the pattern belongs  
  anywhere a sed/awk range feeds assert_contains" — is enforceable rather than aspirational.

### Testing Gaps

- **The retro-trigger flag set does not fire on the thing that finds the defects.** The  
  signals `cpm:do` accumulates are fail-then-continue, repeated TDD red cycles, test  
  failures, a blocked story, and an inline-change breadcrumb. None of them fired in this  
  epic, and the flag set was empty at Step 8 — while three real defects had been found and  
  fixed at three consecutive story gates. Retro 21 already called that read "load-bearing  
  rather than diligent" and it has now produced defects at eight consecutive gates across two  
  specs. A source that reliable belongs in the signal set; as it stands, an epic whose reads  
  found the most is indistinguishable at Step 8 from one that found nothing. This retro was  
  generated by overriding the auto-skip, which is permitted but should not have been the  
  mechanism.

## Recommendations

1. **Before writing any sentence that names another artefact — a consumer, a precedent, a  
   guarantee — open that artefact.** Three defects, one cause. The grep costs seconds; found  
   later it costs a criterion, and this is now the third consecutive epic in which a  
   documented consumer turned out not to consume.

2. **Where a claim about another artefact must be made, assert the fact rather than the  
   sentence.** "Nothing parses this field today" is paired with a grep over `cpm/skills/`;  
   the sentence cannot rot without the test failing. Prefer this to any wording, however  
   carefully hedged.

3. **Check a rule's opening scope against its own closing paragraph.** The unconditional/  
   conditional split reproduced inside one section. When a section ends with an exception,  
   re-read its first sentence before the story closes.

4. **Add the story-gate read to `cpm:do`'s retro-trigger signal set** — something along the  
   lines of "a story gate's end-to-end read found a defect the suite did not". It is the  
   repo's most productive defect source and currently contributes nothing to the decision  
   about whether a retro gets written.

5. **Spec 45's NFR5 and epic 45-03's Task 3.3 both quote the prompt template as 2,736  
   characters. It is now 2,858.** Task 1.2's clause added 122, and the existing length  
   assertion forced the stated figure in `ralph/SKILL.md` to be corrected at the time. 45-03  
   re-measures, so this is a stale quotation in two planning documents rather than a defect —  
   flagged rather than edited, since neither is this epic's to change.

6. Epics 45-02 (independent) and 45-03 (blocked by 45-01 and 45-02) inherit all of the above.  
   45-03 in particular carries the row this retro's first three findings are about: extract  
   the command the prompt names, run it, and compare the codes — the correspondence, not the  
   two halves.
