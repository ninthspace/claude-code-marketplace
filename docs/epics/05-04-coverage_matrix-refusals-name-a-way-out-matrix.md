# Coverage matrix — Refusals that name a way out

**Number**: 05-04  
**Source epic**: 05-04  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR7 | names the column that missed and the table it points at | A write that misses a parent row returns a message naming the column whose value missed and the table that column points at, for a call carrying several ids. | Story 1 | `[integration]` | ✓ |
| 2 | FR7 | instead of returning the database's bare constraint message | control — A write whose parent rows all exist succeeds unchanged, so the added handling is shown not to intercept a healthy call. | Story 1 | `[integration]` | ✓ |
| 3 | FR8 | A list refuses a scope id that matches no row | must NOT — A list given a scope id that matches no row returns an empty page. | Story 2 | `[integration]` | ✓ |
| 4 | FR8 | rather than returning an empty page that cannot be told apart from a scope which is genuinely empty | control — A list given a scope id naming a real row that holds nothing still returns an empty page, so a scope that is genuinely empty is shown to be distinguishable from one that does not exist. | Story 2 | `[integration]` | ✓ |
| 5 | FR8 | the refusal names that table and the list that takes it | Where the id belongs to a different table, the refusal names that table and names the list that takes the id as a scope. | Story 2 | `[integration]` | ✓ |
| 6 | FR8 | the refusal names that table and the list that takes it | Every scope in the list registry declares the table it points at, and a declaration that disagrees with the schema is caught by a test rather than by a caller. | Story 2 | `[integration]` | ✓ |
| 7 | FR22 | is an unambiguous prefix of exactly one, the refusal offers that row | Where an id matches no row but is an unambiguous prefix of exactly one, the refusal offers that row. | Story 3 | `[integration]` | ✓ |
| 8 | FR22 | is an unambiguous prefix of exactly one, the refusal offers that row | must NOT — An id that is a prefix of two or more rows has one of them offered. | Story 3 | `[integration]` | ✓ |
| 9 | FR22 | rather than reporting only that nothing was found | control — A full id that matches a row is resolved exactly as it is today, with no prefix search behind it. | Story 3 | `[integration]` | ✓ |
| 10 | FR23 | names the arguments it does accept | A refusal for an argument a tool does not accept names the arguments it does accept. | Story 4 | `[integration]` | ✓ |
| 11 | FR23 | having been refused for a missing label without being told which field was missing | A refusal for a missing required argument names which argument is missing. | Story 4 | `[integration]` | ✓ |
| 12 | FR23 | names the arguments it does accept | control — A call carrying only valid arguments succeeds unchanged. | Story 4 | `[integration]` | ✓ |
| 13 | NFR4 | names what to do instead | Every refusal this spec adds names a requirement, a table, a list, an option or an argument that the caller can act on, and not only the fault that was found. | Story 5 | `[unit]` | ✓ |
| 14 | NFR4 | A refusal that reports a fault without a route out is the prose rule it replaced, moved one layer down | control — A refusal message reduced to naming only the fault makes that sweep fail, so the sweep is shown to be reading the messages rather than passing over them. | Story 5 | `[unit]` | ✓ |
