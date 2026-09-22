# Coverage matrix — Server-supplied stamps

**Number**: 05-03  
**Source epic**: 05-03  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR1 | The server supplies the clock for a coverage verification stamp | A verification call supplying no time records a stamp holding the server's clock at the moment of the call, with the binding hash derived alongside it exactly as it is today. | Story 1 | `[integration]` | ✓ |
| 2 | FR1 | Neither tool accepts a time from its caller | must NOT — A call supplying a time for a verification is accepted and the supplied value is stored. | Story 1 | `[integration]` | ✓ |
| 3 | FR1 | each takes a boolean saying the thing happened, and the handler records when | control — The same call with the time omitted succeeds and stores a stamp, so the refusal is shown to discriminate rather than to reject every call of that shape. | Story 1 | `[integration]` | ✓ |
| 4 | FR1 | for a requirement's coverage claim | A claim call supplying no time records the claim with the server's clock, and the claim hash is computed over the bound set exactly as it is today. | Story 2 | `[integration]` | ✓ |
| 5 | FR1 | Neither tool accepts a time from its caller | must NOT — A call supplying a time for a coverage claim is accepted and the supplied value is stored. | Story 2 | `[integration]` | ✓ |
| 6 | FR1 | each takes a boolean saying the thing happened, and the handler records when | control — The same call with the time omitted succeeds and records the claim. | Story 2 | `[integration]` | ✓ |
