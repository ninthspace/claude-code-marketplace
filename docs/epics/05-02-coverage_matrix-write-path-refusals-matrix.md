# Coverage matrix — Write-path refusals

**Number**: 05-02  
**Source epic**: 05-02  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR2 | does not occur in the text of the requirement it names is refused when it is written | must NOT — A coverage write whose fragment occurs nowhere in the text of the requirement it names is accepted, leaving a row for the integrity register to find later. | Story 1 | `[integration]` |  |
| 2 | FR2 | does not occur in the text of the requirement it names is refused when it is written | control — A coverage write whose fragment does occur in the text of the requirement it names succeeds and stores a row. | Story 1 | `[integration]` |  |
| 3 | FR2 | Where a sibling requirement in the same spec does contain the fragment, the refusal names that requirement | Where a sibling requirement in the same spec does contain the fragment, the refusal names that requirement as the one the fragment belongs to. | Story 1 | `[integration]` |  |
| 4 | FR3 | A story cannot be marked finished while any task beneath it is still outstanding | must NOT — A story with a task still outstanding beneath it is set finished. | Story 2 | `[integration]` |  |
| 5 | FR3 | A story cannot be marked finished while any task beneath it is still outstanding | control — The same story with every task beneath it finished is set finished without objection. | Story 2 | `[integration]` |  |
| 6 | FR3 | The refusal lists the outstanding tasks | The refusal lists every outstanding task beneath that story, so it performs the reconciliation rather than asking for one. | Story 2 | `[integration]` |  |
| 7 | FR4 | must carry a status note explaining why, and a note already on the row counts | must NOT — A story carrying an unverified bound coverage row and no status note is set finished. | Story 3 | `[integration]` |  |
| 8 | FR4 | must carry a status note explaining why, and a note already on the row counts | A status note already stored on the row satisfies the condition without being restated in the closing call, and a note of whitespace alone does not satisfy it. | Story 3 | `[integration]` |  |
| 9 | FR4 | What is refused is the silent close, never the unverified binding itself | control — The same story with a status note is set finished, so the unverified binding is shown not to be what was refused. | Story 3 | `[integration]` |  |
| 10 | FR6 | A requirement ruled out of an iteration is refused unless it records what rules it out | must NOT — A create or an update that would leave a requirement ruled out with no exclusion recorded is accepted. | Story 4 | `[integration]` |  |
| 11 | FR6 | The obligation falls on that priority alone; the other three carry no such duty | control — The same call carrying an exclusion succeeds, and a requirement at any other priority with no exclusion succeeds too. | Story 4 | `[integration]` |  |
| 12 | FR6 | The refusal applies to writes only | An update naming only the priority is judged against the exclusion already stored on the row rather than against the absence of one in its own arguments. | Story 4 | `[integration]` |  |
| 13 | FR12 | A tradeoff naming an option that does not exist is refused | must NOT — A tradeoff naming an option the decision does not hold is accepted. | Story 5 | `[integration]` |  |
| 14 | FR12 | the refusal lists the options the decision actually holds | The refusal lists the options the decision actually holds, so the caller is handed the real set rather than told the one it named is wrong. | Story 5 | `[integration]` |  |
| 15 | FR13 | A second live acceptance criterion with the same text under one story is refused | must NOT — A second live acceptance criterion with the same text under one story is accepted. | Story 5 | `[integration]` |  |
| 16 | FR14 | A binding that would attach a coverage row to a story in a different epic is refused | must NOT — A binding attaching a coverage row to a story in a different epic is accepted. | Story 5 | `[integration]` |  |
| 17 | FR14 | A binding that would attach a coverage row to a story in a different epic is refused | control — Each of the three guards admits its legitimate neighbour: a tradeoff on an option the decision holds, a criterion whose text differs from its siblings, and a binding to a story within the same epic. | Story 5 | `[integration]` |  |
| 18 | NFR1 | a row already in a state that would now be refused goes on reading exactly as it does today | For each refusal this epic adds, a row written into the now-refused state before the change reads identically through every tool after it — same columns, same values, same standing in any report that mentions it. | Story 6 | `[integration]` |  |
| 19 | NFR1 | Every new refusal sits on the write path only | Each refusal is shown able to fail: the state it forbids is driven, and the test guarding it goes red on its own rather than behind a sibling assertion. | Story 6 | `[integration]` |  |
