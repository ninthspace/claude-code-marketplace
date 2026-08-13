# Coverage Matrix: Import and Discoverability

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Epic**: docs/epics/49-04-epic-import-and-discoverability.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR8 | "A dump that does not survive its own restore is refused by the import and by the merge, with one message from one implementation" | "A dump that does not survive its own restore is refused by the import and by the merge, with one message from one implementation" | Story 1 | `[integration]` | |
| 2 | FR8 (must NOT) | "must NOT leave the original database replaced when a restore fails — the staging file is gone and the original still opens" | "must NOT leave the original database replaced when a restore fails — the staging file is gone and the original still opens" | Story 1 | `[integration]` | |
| 3 | FR8 (added) | "An explicit import operation exists, sharing one implementation with the merge. Import is the merge's restore → rename-into-place → verify-round-trip → publish → re-guard sequence without the three-way merge." | "`bin/dpm-import.js` rebuilds the database from `.dpm/dpm.sql` through the shared implementation, and is the command the guard's dump-moved verdict names" | Story 2 | `[integration]` | |
| 4 | AD13 (added) | "written by both publish and import" | "After an import, the marker equals the hash of the dump on disk and the following guard run reports clean" | Story 2 | `[integration]` | |
| 5 | FR11 | "The README names `dpm-merge`, says when to run it, and shares one constant with the guard's reconcile message rather than a second copy of the command string" | "The README names `dpm-merge`, says when to run it, and shares one constant with the guard's reconcile message rather than a second copy of the command string" | Story 3 | `[unit]` | |
| 6 | FR11 (added) | "`dpm-merge` becomes discoverable. It is documented nowhere today, so FR7's reconcile diagnostic would otherwise name a tool findable only by reading the source." | "The README names the import command on the same terms, sharing the constant the guard's dump-moved verdict uses" | Story 3 | `[unit]` | |
| 7 | FR8 | "Clone → first open restores → publish → commit passes the guard" | "Clone → first open restores → publish → commit passes the guard" | Story 4 | `[feature]` | |
| 8 | FR8 | "Pull → guard names import → import → commit passes the guard, and the pulled rows are present" | "Pull → guard names import → import → commit passes the guard, and the pulled rows are present" | Story 4 | `[feature]` | |

## Notes

**Row 3 is added because FR8's criteria never name the import's reachability.** Rows 1, 2, 7 and 8 all
describe behaviour the import participates in; none says a user can run one. The spec's Scope says "the
new import entry points", plural, without naming them, and this epic scopes that to a CLI binary
mirroring `bin/dpm-publish.js`. The reasoning is recorded in the epic's Notes rather than left implicit,
because the alternative — an MCP tool — is a defensible reading of the same sentence.

**Row 4 mirrors 49-03's rows 3 and 4.** AD13 says the marker is written by both publish and import, and
the spec's criteria say it for neither. Publish's half is covered at
`docs/epics/49-03-coverage-sync-marker-and-verdict.md`; this is import's. Without it an import leaves the
marker naming the pre-pull dump, and the next guard run reports *dump moved* against a database that has
just adopted it.

**Row 6 is added for the same reason FR11 exists.** FR11's own criterion names `dpm-merge` only, but
FR7's verdicts now name *two* commands a user must be able to find — reconcile names `dpm-merge`, dump-moved
names the import. Documenting one and not the other leaves the more common case pointing at nothing, and
the pull is the common case.

**Rows 5 and 6 are about a shared constant, not a matching string.** A test comparing the README's text
against the guard's message passes on two copies that happen to agree, which is precisely what FR11
forbids. The assertion is that one constant reaches both surfaces.

**Row 1's "one message from one implementation" is asserted by driving both callers.** Comparing each
against a transcribed expected string would pass on two implementations that agree today; the two
messages are compared to each other, over the same bad dump.

**Rows 7 and 8 span four epics.** Both journeys cross the lazy open (49-01), restore-on-create (49-02),
the marker and verdict (49-03) and import (49-04). They are in this matrix because neither can complete
until import exists. Row 8's final clause — *the pulled rows are present* — is the whole spec in one
assertion: today that sequence ends with them discarded.
