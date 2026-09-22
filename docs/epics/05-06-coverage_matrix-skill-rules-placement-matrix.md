# Coverage matrix — Skill rules and their placement

**Number**: 05-06  
**Source epic**: 05-06  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR15 | runs the integrity check and treats every violation not marked advisory as a gap, reporting it with the rows it names | The breakdown skill's confirm step runs the integrity check and treats every violation not marked advisory as a gap, reporting it with the rows it names. | Story 5 | `[integration]` | ✓ |
| 2 | FR16 | the draft is rendered as its own items in the same message that asks the question | The rule that a gate renders its draft as its own items in the message that asks the question is in force where its consuming skills read, and nothing a gate decides is written before it is answered. | Story 2 | `[integration]` | ✓ |
| 3 | FR17 | names that outcome as though it had happened | The rule that a rejected outcome is named as though it had happened is in force at both the spec and the breakdown skills. | Story 2 | `[integration]` | ✓ |
| 4 | FR18 | A binding quotes the clause the criterion actually tests, not the nearest verbatim one | The rule that a binding quotes the clause the criterion actually tests, rather than the nearest verbatim one, is in force at the breakdown skill. | Story 2 | `[integration]` | ✓ |
| 5 | FR19 | lists the rows that step writes, under the parent it writes them to, and proposes only what is missing | A resumed step is instructed to list the rows it writes under the parent it writes them to before proposing anything, and to propose only what is missing. | Story 3 | `[integration]` | ✓ |
| 6 | FR20 | the read-backs are batched into one message rather than one message per row | Read-backs are instructed to batch into one message, with each row checked by its label and every closing count taken from the last report rather than from a tally of the calls sent. | Story 3 | `[integration]` | ✓ |
| 7 | FR21 | one observation per story and further categories added to the existing row | One observation per story, with further categories added to the existing row rather than written as a second observation. | Story 4 | `[integration]` | ✓ |
| 8 | FR21 | an unmet criterion rendered in full with what the assessment found | An unmet criterion is rendered in full, with what the assessment actually found, before any gate asking whether to accept a shortfall. | Story 4 | `[integration]` | ✓ |
| 9 | FR21 | coverage pages never added up by hand | Coverage pages are never added up by hand. | Story 4 | `[integration]` | ✓ |
| 10 | FR21 | scratch files left where the repository's ignore rules account for them and removed once the check is made | Scratch files sit where the repository's own ignore rules and the next status check account for them, and are removed once the check is made. | Story 4 | `[integration]` | ✓ |
| 11 | ENV6 | No rule may claim that a badly-formed gate is refused, that a thinking level can be pinned per skill, or that a turn can end by handing off to a fresh context | must NOT — A skill body or a document a skill reads at startup claims that the host refuses a badly-formed gate, that a thinking level can be pinned per skill, or that a turn can end by handing off to a fresh context. | Story 6 | `[integration]` | ✓ |
| 12 | ENV6 | A rule promising a safety net that is not there teaches a run to lean on one that will not catch it | control — A claim of that form planted in a skill body makes the check fail, so the check is shown to discriminate rather than to pass over a corpus it is not reading. | Story 6 | `[integration]` | ✓ |
