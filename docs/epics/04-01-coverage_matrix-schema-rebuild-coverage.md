# Coverage — Migration 025, the rebuilt schema, and the writes that reach it

**Number**: 04-01  
**Source epic**: 04-01  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR1 | A coverage binding can be retired, carrying the reason it was retired | retire_coverage sets retired_at and retired_reason together on a live binding, and read_coverage on that id returns both. | Story 4 | `[integration]` | ✓ |
| 2 | FR1 | what changes is that the binding is no longer offered as live | list_coverage omits a retired binding by default and returns it when include_retired is passed. | Story 4 | `[integration]` | ✓ |
| 3 | FR1 | A coverage binding can be retired, carrying the reason it was retired | must NOT — update_coverage does not set retired_at or retired_reason. Retirement is its own tool, as it is for every other retirable thing in the surface. | Story 4 | `[unit]` | ✓ |
| 4 | FR1 | Retirement is not deletion: the row is not removed | must NOT — No tool in the registered surface deletes a coverage row. | Story 4 | `[unit]` | ✓ |
| 5 | FR1 | a retired binding stays readable as the record that the binding once existed | control — update_coverage still sets position and verified_at on the same row, so the refusal above is specific to the retirement columns rather than a tool that updates nothing. | Story 4 | `[unit]` | ✓ |
| 6 | FR6 | A story criterion an amendment has overtaken can be marked superseded rather than rewritten | update_story_criterion sets superseded_at and superseded_reason together, and the criterion's own text is unchanged by that call. | Story 5 | `[integration]` | ✓ |
| 7 | FR6 | so the epic goes on recording what it actually delivered | list_story_criterion omits a superseded criterion by default and returns it when include_superseded is passed. | Story 5 | `[integration]` | ✓ |
| 8 | FR6 | A story criterion an amendment has overtaken can be marked superseded rather than rewritten | must NOT — A row must not exist with superseded_at set and superseded_reason null. | Story 5 | `[integration]` | ✓ |
| 9 | FR6 | so the epic goes on recording what it actually delivered | must NOT — Superseding a criterion must not clear the verification of bindings on other criteria of the same story. | Story 5 | `[integration]` | ✓ |
| 10 | FR6 | so the epic goes on recording what it actually delivered | control — The same call passing the criterion's text back byte-identical leaves its bindings' verification standing, so a cleared mark is the supersession rather than a trigger firing on any write. | Story 5 | `[integration]` | ✓ |
| 11 | NFR1 | Every coverage row and story criterion in an existing database migrates live and untouched | A database at the previous schema version, holding coverage rows and story criteria, migrates with every one of them live: retired_at and superseded_at are null throughout. | Story 2 | `[integration]` | ✓ |
| 12 | NFR1 | a project with no broken bindings sees no change in what is reported, counted or claimed | The claim hash over a requirement with no retired bindings returns the same digest before and after the migration, so every standing claim survives it. | Story 2 | `[integration]` | ✓ |
| 13 | NFR1 | a project with no broken bindings sees no change in what is reported, counted or claimed | must NOT — Migrating must not drop a coverage_story row, an index or a trigger. | Story 2 | `[integration]` | ✓ |
| 14 | NFR1 | a project with no broken bindings sees no change in what is reported, counted or claimed | control — A coverage_story row present before the rebuild is present after it, carrying the same pair, so the rescue put back what it took aside. | Story 2 | `[integration]` | ✓ |
| 15 | NFR2 | the resulting invalidation of every existing claim is stated in the release rather than discovered in the first project to migrate | The migration file states what the claim hash now excludes, and states that no existing claim is invalidated by it because no row is retired at migration time. | Story 1 | `[unit]` | ✓ |
| 16 | NFR4 | the retired_at and retired_reason pair as on artifact and observation | The retirement columns on coverage carry the same paired CHECK that artifact and observation carry, read from the live schema rather than transcribed into the test. | Story 1 | `[integration]` | ✓ |
| 17 | NFR4 | New columns follow the shapes this schema already carries | The supersession column on story_criterion yields an include_superseded flag and the retirement column on coverage yields an include_retired flag, both derived from the column name rather than declared. | Story 1 | `[unit]` | ✓ |
| 18 | NFR4 | rather than a third spelling of either | must NOT — No column this change adds introduces a third spelling of retirement or of supersession. | Story 1 | `[integration]` | ✓ |
| 19 | ENV1 | Node.js 22.5.0 or later is available on the development machine, providing the DatabaseSync class of node:sqlite and the node --test runner. | The suite runs to completion on Node 22.5.0 or later using node --test, with DatabaseSync imported from node:sqlite. | Story 3 | `[integration]` | ✓ |
| 20 | ENV2 | A scratch database can be created and migrated in-process from the numbered schema files | A test creates a database at the previous schema version and migrates it in-process, without opening the project's own planning database. | Story 3 | `[integration]` | ✓ |
| 21 | ENV4 | A project database at the current schema version upgrades to the next on first start after the release, in one transaction | A project database at the previous schema version reaches the new one on first start, in a single transaction, with no SQLite beyond the one built into Node. | Story 3 | `[target]` |  |
| 22 | ENVX1 | A third-party test runner, assertion library, migration tool or SQLite binary must not be required. | must NOT — The suite runs with no dependencies and no devDependencies installed, and the manifest declares none. | Story 3 | `[integration]` | ✓ |
| 23 | ENVX2 | The project's own planning database must not be required to be writable while the suite runs. | must NOT — No test in the suite opens the project's own planning database for writing. | Story 3 | `[integration]` | ✓ |
| 24 | ENVX3 | A project must not be required to run a command, edit a file, or repair its data by hand in order to migrate. | must NOT — Migrating must not require a project to run a command, edit a file or repair a row by hand. | Story 3 | `[target]` |  |
