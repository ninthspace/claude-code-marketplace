# Coverage — Retiring a binding

**Number**: 04-02  
**Source epic**: 04-02  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR1 | A coverage binding can be retired, carrying the reason it was retired | retire_coverage sets retired_at and retired_reason together on a live binding, and read_coverage on that id returns both. | Story 1 | `[integration]` |  |
| 2 | FR1 | what changes is that the binding is no longer offered as live | list_coverage omits a retired binding by default and returns it when include_retired is passed. | Story 1 | `[integration]` |  |
| 3 | FR1 | A coverage binding can be retired, carrying the reason it was retired | must NOT — update_coverage does not set retired_at or retired_reason. Retirement is its own tool, as it is for every other retirable thing in the surface. | Story 1 | `[unit]` |  |
| 4 | FR1 | Retirement is not deletion: the row is not removed | must NOT — No tool in the registered surface deletes a coverage row. | Story 1 | `[unit]` |  |
| 5 | FR1 | a retired binding stays readable as the record that the binding once existed | control — update_coverage still sets position and verified_at on the same row, so the refusal above is specific to the retirement columns rather than a tool that updates nothing. | Story 1 | `[unit]` |  |
| 6 | FR3 | a claim standing over that set at the moment of retirement is withdrawn | Retiring one of three bindings on a claimed requirement clears coverage_claimed_at and coverage_claim_hash together. | Story 3 | `[integration]` | ✓ |
| 7 | FR3 | A requirement whose bindings have changed shape is one whose claim has to be made again over what remains | A claim made after the retirement hashes over the remaining bindings only, and claimState reports that claim current. | Story 3 | `[integration]` | ✓ |
| 8 | FR3 | A retired binding leaves the set that a completeness claim accounts for | must NOT — A retired binding does not count toward the bound total claimState reports. | Story 3 | `[integration]` | ✓ |
| 9 | FR3 | A retired binding leaves the set that a completeness claim accounts for | control — A live binding on the same requirement still counts toward the bound total, so the exclusion above is the retirement rather than a count that returns zero. | Story 3 | `[integration]` | ✓ |
| 10 | FR3 | a claim standing over that set at the moment of retirement is withdrawn | control — Retiring a binding on one requirement leaves another requirement's standing claim intact, so the withdrawal is scoped rather than a trigger that unclaims everything. | Story 3 | `[integration]` | ✓ |
| 11 | FR4 | A retirement without a stated reason is refused | retire_coverage called with no reason is refused, and the row is unchanged afterwards. | Story 2 | `[integration]` | ✓ |
| 12 | FR4 | A retirement without a stated reason is refused | That refusal is a boundary rejection naming the missing argument, rather than an internal error surfacing from the schema. | Story 2 | `[unit]` | ✓ |
| 13 | FR4 | A retirement without a stated reason is refused | must NOT — A row must not exist with retired_at set and retired_reason null, whatever writes it. The tool is one path to that state and a direct write is another. | Story 2 | `[integration]` | ✓ |
| 14 | FR4 | a binding leaving the matrix is a decision on the record rather than a tidy-up | control — retire_coverage with a reason succeeds on the same binding, so the refusals above are the missing reason rather than a tool that refuses everything. | Story 2 | `[integration]` | ✓ |
| 15 | NFR2 | A cost taken deliberately and written down is a different thing from the same cost met by surprise. | must NOT — No project is required to re-make a claim it had already made, as a consequence of this change. | Story 3 | `[integration]` | ✓ |
| 16 | NFR2 | Where the change alters what a completeness claim is computed over | control — A requirement with a retired binding is unclaimed, so claims surviving a migration is the migration leaving them alone rather than claims never being cleared at all. | Story 3 | `[integration]` | ✓ |
| 17 | NFR3 | nothing may leave a project unable to re-create a binding it retired by accident | After retiring a binding, create_coverage with the same requirement, fragment and criterion succeeds and yields a live row. | Story 4 | `[integration]` | ✓ |
| 18 | NFR3 | A retired row still occupies its triple | The retired row and its live replacement coexist, and only the live one counts toward the bound total. | Story 4 | `[integration]` | ✓ |
| 19 | NFR3 | A retired row still occupies its triple | must NOT — Two live bindings on the same triple must not exist: creating a second while the first is live is still refused. | Story 4 | `[integration]` | ✓ |
| 20 | NFR3 | A binding retired in error can be put right without destroying its requirement or its criterion | must NOT — Recovering from a mistaken retirement must not require destroying the requirement or the criterion the binding hangs between. | Story 4 | `[integration]` | ✓ |
| 21 | NFR3 | the natural key must not make a mistaken retirement permanent | control — Two retired bindings on the same triple can exist — retire, re-create, retire again — so the index constrains live rows rather than the table. | Story 4 | `[integration]` | ✓ |
