# Coverage matrix — Coverage reporting

**Number**: 05-01  
**Source epic**: 05-01  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR5 | each requirement's standing | Given a spec, the report returns every requirement with its standing, computed from the coverage rows bound to it. | Story 1 | `[integration]` | ✓ |
| 2 | FR5 | which criteria are accounted for by nothing, which carry no approach tag, which are must-haves | It returns, each as its own list, the criteria that are accounted for by nothing, the criteria carrying no approach tag, and the must-have criteria. | Story 1 | `[integration]` | ✓ |
| 3 | FR5 | a block of counts that a skill quotes rather than computes | It returns a block of counts, and every number in that block agrees with the list it summarises. | Story 1 | `[unit]` | ✓ |
| 4 | FR5 | Given an epic it adds a roll-up of that epic's stories, bindings and verified bindings | Given a spec and an epic, the report adds a roll-up of that epic's stories, its bindings and its verified bindings. | Story 2 | `[integration]` | ✓ |
| 5 | FR5 | a block of counts that a skill quotes rather than computes | On a fixture whose bindings number thirteen, the roll-up says thirteen and agrees with the lists it summarises. | Story 2 | `[unit]` | ✓ |
| 6 | FR5 | a block of counts that a skill quotes rather than computes | The spec report and the epic roll-up return one response shape, so a skill quoting a count names one field whichever scope it asked for. | Story 5 | `[integration]` | ✓ |
| 7 | FR9 | every binding on a requirement is verified but the claim was never made | A requirement whose every binding is verified and whose claim was never made is reported as claimable. | Story 3 | `[integration]` | ✓ |
| 8 | FR9 | an in-scope requirement carries no acceptance criterion at all | An in-scope requirement that carries no acceptance criterion at all is reported, which is a state no gap computed from criteria can ever show. | Story 3 | `[integration]` | ✓ |
| 9 | FR9 | one criterion text lives under two different stories | One criterion text, whitespace-normalised, live under two different stories is reported as duplicated. | Story 3 | `[integration]` | ✓ |
| 10 | FR9 | All three are warnings and never gaps | must NOT — One of the three new findings is reported as a gap rather than as a warning. | Story 3 | `[integration]` | ✓ |
| 11 | FR9 | no epic that closes today stops closing | control — An epic that closes cleanly before the warnings exist still closes with all three present and firing, so the refusal to call them gaps is shown to hold where it matters. | Story 3 | `[integration]` | ✓ |
| 12 | FR9 | All three are warnings and never gaps | The three warnings appear alongside the standings in the same response and change no standing that response computes. | Story 5 | `[integration]` | ✓ |
| 13 | FR10 | A coverage row carries the label of the requirement it binds | A coverage row read back carries the label of the requirement it binds, so the read-back can be checked against a label rather than against an id held from an earlier call. | Story 4 | `[integration]` | ✓ |
| 14 | FR10 | A coverage row carries the label of the requirement it binds | The label is present on rows the coverage report returns as well as on rows read directly, and the skill text that quotes it names the field. | Story 4 | `[integration]` | ✓ |
| 15 | NFR3 | answered by a single call rather than by one page read per requirement | The whole report is obtained in a single call, with no per-requirement page read behind it. | Story 1 | `[integration]` | ✓ |
