# Retro: Body Reads Across the Corpus

**Date**: 2026-08-11  
**Source**: docs/epics/47-12-epic-body-reads.md  
**Stories**: 3/3 complete

## Summary

FR13 bounds reads by default and every one of its original criteria tested the tool. This epic
tested the twenty-three consumers: 105 sites classified, 21 defects fixed, and a standing check that
reads the corpus against the live registry. The failure it closes has no error in it — a withheld
column arrives as an absent field, so the render is well-formed, structurally complete, and simply
says less.

## Observations

### Criteria Gaps

- **The proximity sweep that opened the epic was wrong in both directions, and the story's criteria  
  anticipated only one.** Of the 37 pairs it flagged, seven of `inspect`'s needed no body at all;  
  of the six skills it called clean, two carried a real defect — `artifact` matching a search term  
  against `description`, `consult` reading an agent "for their traits". Reading each step moved sites  
  *both* ways, which is what a proxy cannot do. Where a criterion is written against a sweep's  
  output, say what happens to the sites it exonerated, not only to the ones it accused.

### Testing Gaps

- **A criterion phrased as "the corpus still has N of these" expires the moment the epic succeeds.**  
  Story 1's must-NOT asserted a floor on the defect count; Story 2 fixed all 21 and made it  
  unsatisfiable. The disagreement it was really testing had to be re-grounded on the direction no fix  
  can empty — the sites that ask and do not need. A defect count is evidence, not an invariant.
- **Success can make a check undrivable on its own subject.** By Story 3 the corpus agreed with  
  itself: a block-scoped and a file-scoped reading return the same answer everywhere the answer is  
  `true`, so the construction criterion could only be driven on planted sources. Merging block  
  boundaries in `blocks()` was the mutation that proved the real check reads the block. When the  
  thing under test has been fixed everywhere, plant the input rather than settle for a comment.

## Recommendations

- **Derive the enumeration from the registry, never a transcription.** Half the body declarations are  
  generated — `list.js` copies each list tool's `body` from its matching read tool — so a typed list  
  would have carried sixteen read tools and missed the twenty list tools beside them, reporting a  
  corpus in which two thirds of the sites do not exist.
- **`body: []` is not withholding.** Read as truthy it makes every document kind a site with nothing  
  to ask for, and buries the real sites under sixty entries whose reason is "there is no body".
- **State what a sweep cannot see, in the test.** Four residual gaps are written into  
  `body-corpus.test.js`: `asks` sees the word rather than the call, the needs judgement is recorded  
  rather than derived, reads reached through a shared procedure are attributed to the shared file,  
  and the corpus is `dpm/skills/` and nothing else. A green mark with no stated limits is read as  
  total coverage.
- **A `false` classification carries more weight than a `true` one, so it names the column it does  
  not need and what it uses instead.** A wrong `true` shows up as an argument passed needlessly; a  
  wrong `false` is a render that quietly says less.
