# Coverage — The integrity register

**Number**: 04-04  
**Source epic**: 04-04  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR2 | A binding whose fragment its requirement no longer contains is reported while it remains unretired | A binding whose fragment its requirement no longer contains is named by integrity entry 9 while that binding is live. | Story 1 | `[integration]` | ✓ |
| 2 | FR2 | stops being reported once it has been knowingly retired | Retiring that same binding removes it from entry 9, which then reports held true, with nothing else in the database changed. | Story 1 | `[integration]` | ✓ |
| 3 | FR2 | stops naming the ones somebody already decided | must NOT — Entry 9 does not name a retired binding whose fragment is still a substring of its requirement. | Story 1 | `[integration]` | ✓ |
| 4 | FR2 | The integrity register goes on naming the bindings somebody still has to decide about | control — A second live binding, broken in the same requirement, is still named after the first is retired, so entry 9 going quiet is the retirement rather than the entry ceasing to look. | Story 1 | `[integration]` | ✓ |
