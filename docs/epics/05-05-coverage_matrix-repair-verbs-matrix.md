# Coverage matrix — Repair verbs

**Number**: 05-05  
**Source epic**: 05-05  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR11 | an observation written twice | An observation written twice can be withdrawn, and the withdrawn row stops appearing in the lists that gather observations. | Story 1 | `[integration]` | ✓ |
| 2 | FR11 | Three mistakes a run can make are undoable | control — A live observation under the same retro is unaffected by its sibling's withdrawal and goes on being returned. | Story 1 | `[integration]` | ✓ |
| 3 | FR11 | a dependency edge written the wrong way round | A dependency edge written the wrong way round can be removed, and the correct edge can then be written without the first closing a cycle over it. | Story 2 | `[integration]` | ✓ |
| 4 | FR11 | With no withdrawal verb the only recovery is a second row | control — Removing one edge leaves every other edge of that kind in place and readable. | Story 2 | `[integration]` | ✓ |
| 5 | FR11 | a binding attached to the wrong story | A binding attached to the wrong story can be removed, and the count at the place that reads bindings falls by exactly one. | Story 3 | `[integration]` | ✓ |
| 6 | FR11 | With no withdrawal verb the only recovery is a second row | control — The coverage row itself and its bindings to other stories survive the removal unchanged. | Story 3 | `[integration]` | ✓ |
