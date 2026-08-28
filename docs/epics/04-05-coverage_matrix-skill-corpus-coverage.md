# Coverage — The skills

**Number**: 04-05  
**Source epic**: 04-05  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR5 | The pivot names the bindings its own amendment broke, at the point of the edit | A pivot run amending a requirement's text names every binding whose fragment the amended text no longer contains, and names no others. | Story 1 | `[feature]` | ✓ |
| 2 | FR5 | gates the retirement of each one separately | Each named binding is offered under its own approval: a run that approves one of two retires that one. | Story 1 | `[feature]` | ✓ |
| 3 | FR5 | gates the retirement of each one separately | must NOT — The pivot does not retire a binding the run did not approve. | Story 1 | `[feature]` | ✓ |
| 4 | FR5 | the skill holds the text before and the text after | must NOT — The pivot does not recover the bindings by reading a generated markdown file instead of calling the list tool. | Story 1 | `[unit]` | ✓ |
| 5 | FR5 | The pivot names the bindings its own amendment broke, at the point of the edit | control — A run amending a requirement whose bound fragments all survive names no binding and offers no retirement, so naming nothing is the amendment rather than a step that never ran. | Story 1 | `[feature]` | ✓ |
| 6 | FR8 | The breakdown steers a fragment toward the clause carrying the obligation rather than the connective wording around it. | The breakdown skill's coverage step instructs that a fragment be quoted from the clause carrying the obligation, and says why connective phrasing is the fragment an amendment breaks. | Story 2 | `[unit]` | ✓ |
| 7 | FR8 | The breakdown steers a fragment toward the clause carrying the obligation rather than the connective wording around it. | A breakdown run over a requirement whose obligation and connective wording are separable binds the obligation clause. | Story 2 | `[feature]` | ✓ |
| 8 | FR8 | a fragment quoted from it is the one most likely to be broken by an edit that changed nothing the criterion was about | must NOT — That instruction must not weaken the existing refusal of a fragment traceable to no spec text. | Story 2 | `[unit]` | ✓ |
| 9 | FR9 | The execution roll-up says whether a requirement's remaining bindings are verified, rather than implying every binding ever made was. | The execution roll-up's sentence names the remaining bindings rather than implying every binding ever made was verified. | Story 3 | `[unit]` | ✓ |
| 10 | FR9 | A count taken over a set that has had rows retired out of it describes what is left | must NOT — The roll-up must not report a count that includes retired bindings. | Story 3 | `[integration]` | ✓ |
