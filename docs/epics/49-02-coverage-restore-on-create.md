# Coverage Matrix: Restore on Create

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Epic**: docs/epics/49-02-epic-restore-on-create.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR6 | "A missing database beside a committed dump is built from it. Restore, not migrate-empty — the behaviour the README already claims." | "A directory holding `.dpm/dpm.sql` and no database answers a read tool from the dump's rows" | Story 1 | `[integration]` | |
| 2 | FR6 | "The same call with no dump present returns an empty result rather than an error — the decoy that stops \"answers from the dump\" passing by returning anything at all" | "The same call with no dump present returns an empty result rather than an error — the decoy that stops \"answers from the dump\" passing by returning anything at all" | Story 1 | `[integration]` | |
| 3 | AD14 | "a first open that finds no database and a committed dump beside it restores from that dump. A first open that finds a database never touches it, whatever the dump says." | "must NOT restore over an existing database: a database holding a distinguishable row keeps it when the dump lacks it" | Story 1 | `[integration]` | |
| 4 | FR10 | "A first open that did something unusual reports it in one line on stderr. A restore from the dump, or a database served read-only, is named. An ordinary create is not." | "A first open that restored from a dump writes exactly one line to stderr naming the restore; an ordinary create writes none" | Story 2 | `[integration]` | |
| 5 | FR10 (must NOT) | "must NOT write any of it to stdout" | "must NOT write any of it to stdout" | Story 2 | `[integration]` | |

## Notes

**Row 3 maps to AD14 rather than FR6,** although the spec files the must-NOT under FR6's criteria. FR6
states only the create case; the never-overwrite half is AD14's decision and carries AD14's reasoning —
overwriting an existing database can destroy rows created and never published, which is the class of
thing AD11 already refused to let the server do on its own initiative. Traced to the decision so that a
later change to AD14 reaches this row.

**Row 2 is a decoy the spec wrote itself.** It is quoted verbatim, label and all, because the label is
the useful part: without it a reader asked to "simplify the criteria" would delete the row as redundant
with row 1, and row 1 alone passes on a read tool that answers from anywhere.

**Row 4's two halves are one criterion on purpose.** "Writes exactly one line naming the restore" is
satisfied by a server that writes that line on every open; the ordinary-create clause is what
distinguishes them, and separating them into two rows would let one ✓ stand while the other never ran.

**FR10's read-only case is not in this matrix.** "A database served read-only" is FR5's version-ahead
path, covered at `docs/epics/49-01-coverage-deferred-creation.md` rows 18 and 20. Row 4 asserts the
restore case only, which is what FR10's own criterion names.

**No row here is added.** The spec carries the decoy and the stdout must-NOT already.
