# Coverage — Supersession and warrant on a criterion

**Number**: 04-03  
**Source epic**: 04-03  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR6 | A story criterion an amendment has overtaken can be marked superseded rather than rewritten | update_story_criterion sets superseded_at and superseded_reason together, and the criterion's own text is unchanged by that call. | Story 1 | `[integration]` |  |
| 2 | FR6 | so the epic goes on recording what it actually delivered | list_story_criterion omits a superseded criterion by default and returns it when include_superseded is passed. | Story 1 | `[integration]` |  |
| 3 | FR6 | A story criterion an amendment has overtaken can be marked superseded rather than rewritten | must NOT — A row must not exist with superseded_at set and superseded_reason null. | Story 1 | `[integration]` |  |
| 4 | FR6 | so the epic goes on recording what it actually delivered | must NOT — Superseding a criterion must not clear the verification of bindings on other criteria of the same story. | Story 1 | `[integration]` |  |
| 5 | FR6 | so the epic goes on recording what it actually delivered | control — The same call passing the criterion's text back byte-identical leaves its bindings' verification standing, so a cleared mark is the supersession rather than a trigger firing on any write. | Story 1 | `[integration]` |  |
| 6 | FR6a | The criterion and the bindings that hang off it go quiet together | Superseding a criterion retires every binding hanging off it, each carrying a reason that names the supersession. | Story 2 | `[integration]` | ✓ |
| 7 | FR6a | without the rows being destroyed | Those bindings are still readable under include_retired, with their spec_fragment intact. | Story 2 | `[integration]` | ✓ |
| 8 | FR6a | A superseded criterion's bindings stop counting toward its requirement's coverage | must NOT — A superseded criterion's bindings must not remain in the set a completeness claim hashes over, so a requirement claimed before the supersession is unclaimed by it. | Story 2 | `[integration]` | ✓ |
| 9 | FR6a | The criterion and the bindings that hang off it go quiet together | control — Bindings on a live criterion of the same story are untouched, so the retirement follows the criterion rather than the story. | Story 2 | `[integration]` | ✓ |
| 10 | FR6a | because a binding to a criterion nobody is claiming any more is a binding that accounts for nothing | control — The supersession-driven retirement satisfies the paired-reason constraint, which is the one retirement path where no caller supplies the reason. | Story 2 | `[integration]` | ✓ |
| 11 | FR7 | A story criterion whose warrant is an accepted decision rather than requirement text is traceable | update_story_criterion sets warrant_adr_id, and refuses an id that does not name an accepted decision. | Story 3 | `[integration]` | ✓ |
| 12 | FR7 | the roll-up separates it from a criterion nobody bound | The roll-up reads a criterion carrying a warrant and no binding as accounted for, and one carrying neither as unbound. | Story 3 | `[integration]` | ✓ |
| 13 | FR7 | a criterion that is written, tested and verified must not read as an unbound gap | must NOT — A criterion carrying a warrant must not be reported as an unbound gap. | Story 3 | `[integration]` | ✓ |
| 14 | FR7 | the roll-up separates it from a criterion nobody bound | control — A criterion carrying neither a warrant nor a live binding is reported as an unbound gap, so the exemption above is the warrant rather than the report going quiet. | Story 3 | `[integration]` | ✓ |
| 15 | FR7 | A decision constrains a story exactly as a requirement does | control — A criterion carrying both a warrant and a live binding still counts its binding, so a warrant does not substitute for a binding where requirement text exists to quote. | Story 3 | `[integration]` | ✓ |
