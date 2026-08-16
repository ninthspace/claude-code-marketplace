# The database stamp

**Number**: 01-02  
**Source spec**: 01  
**Status**: pending — Adds a migration, and with it the one-time read-only lockout of older servers that the storage decision accepted deliberately.  

## Story 1 — The stamp table and its migration

**Status**: pending  
**Blocked by**: Story 3, Story 4, Story 7  

### Acceptance Criteria

- After `migrate()` on an empty database, the stamp table exists. `[integration]`
- `migrate()` run twice against the same database applies the new migration once and leaves the table's contents unchanged. `[integration]`
- A database at the previous schema version gains the stamp table when migrated, and no other table's contents change. `[integration]`
- A server whose target version is below the migrated database's version returns `ahead: true` and serves the read-only tool set. This is the one-time lockout of older servers that AD2 accepted deliberately, asserted here rather than discovered in the field. `[integration]`
- must NOT — The table admits a second row. `[integration]`
- must NOT — The migration inserts a row as part of applying itself. Migration SQL is static and cannot know the running version, so a row written there would carry a placeholder — and FR2 already says the value arrives on the next start. `[integration]`

### Task 1 — Write the migration adding the one-row stamp table

**Status**: pending  

The DDL and the constraint that admits only one row. Addresses the table's existence and shape, not the write path — the migration inserts nothing.

### Task 2 — Raise the schema target version and register the migration

**Status**: pending  

Addresses the ordered migration list and the version the server reports as its target. This is the change that puts older servers into the read-only branch, which AD2 accepted.

### Task 3 — Write tests for The stamp table and its migration

**Status**: pending  

Covers the six criteria tagged integration, including the second-row rejection and the assertion that an older server degrades to read-only rather than failing.

## Story 2 — Resolve this server's own plugin version

**Status**: pending  
**Blocked by**: Story 3, Story 7  

### Acceptance Criteria

- The resolver returns the version stated in the plugin's own manifest. `[unit]`
- The resolver returns a version when the plugin is loaded from a working tree, where no version directory exists. `[unit]`
- must NOT — The resolver derives the version from the containing directory's name. That is the neighbour check's mechanism, and it yields nothing in a working tree — which is the whole reason this resolver is separate from it. `[unit]`
- must NOT — The resolver takes any value from `process.env`. `[unit]`

### Task 1 — Add a resolver reading the version from the plugin's own manifest

**Status**: pending  

Addresses the case the neighbour check cannot serve — a plugin loaded from a working tree, where no version directory exists to read a name off.

### Task 2 — Write tests for Resolve this server's own plugin version

**Status**: pending  

Covers the four criteria tagged unit, including the two rejections: no directory-name derivation and no read of process.env.

## Story 3 — Write the stamp on increase

**Status**: pending  
**Blocked by**: Story 4, Story 7  

### Acceptance Criteria

- A database started by a server at version X carries X as its recorded plugin version. `[integration]`
- A database migrated from before the stamp existed acquires the running version on the next start. `[integration]`
- A server at the recorded version leaves the row untouched. `[integration]`
- A server below the recorded version leaves the row untouched — the stamp never moves backwards. `[integration]`
- A server above the recorded version replaces it. `[integration]`
- Two consecutive starts at the same version, with no planning data changed, produce byte-identical dumps. `[integration]`
- A start that raises the recorded version does change the dump. Without this positive half, a comparison that is broken — reading the wrong file, comparing nothing to nothing — passes the byte-identical criterion perfectly. `[integration]`
- must NOT — A read-only launch writes the stamp. The read-only path exists so a board can observe every registered project without touching any of them; a stamp written on observation would diverge every one of those projects from its committed dump, and the owner would find the guard refusing a commit in a repository they had not opened. `[integration]`
- must NOT — The row carries a value that differs between two runs of the same version. This is NFR3 stated where it can be checked: a timestamp column would satisfy every other criterion here and still diverge the dump on every start, which is the exact failure the requirement exists to prevent — while looking like good practice. `[integration]`
- control — With the write made unconditional, the criterion that a server at the recorded version leaves the row untouched fails, and that failure has been observed and read rather than assumed. `[integration]`

### Task 1 — Add the stamp write as a fourth step in start()

**Status**: pending  

Addresses where the write sits in the fixed order: after migrate, because the table it writes to is created there. Scope is placement, not the increase condition.

### Task 2 — Gate the write on the running version exceeding the recorded one

**Status**: pending  

Addresses FR2a — equal and lower both leave the row untouched, so the stamp never moves backwards and an unchanged project produces an unchanged dump.

### Task 3 — Keep the write off the read-only path

**Status**: pending  

A separate path from the increase gate: a correct gate still writes when a newer server merely observes a project. Addresses the read-only rejection only.

### Task 4 — Write tests for Write the stamp on increase

**Status**: pending  

Covers the ten criteria tagged integration, including both dump comparisons and the control that makes the write unconditional and observes the untouched-row criterion fail.

## Story 4 — Compare the stamp and produce a verdict

**Status**: pending  
**Blocked by**: Story 5, Story 7  

### Acceptance Criteria

- A database stamped above the running version produces a skew naming both versions. `[integration]`
- A database stamped at or below the running version produces no skew. `[integration]`
- A database whose stamp table is absent produces could-not-check rather than no skew. This is the read-only launch against a project the release has never opened: the table will not be there, and no-skew would be a lie told confidently. `[integration]`
- A stamp comparison that throws yields could-not-check and the call it was made from succeeds. `[integration]`
- must NOT — An absent or unreadable stamp renders as checked-and-found-no-skew. `[integration]`

### Task 1 — Read the recorded stamp, tolerating an absent table

**Status**: pending  

Addresses the read and its failure mode. An absent table is the ordinary case for a project this release has never opened, so it is a value the reader returns rather than an error it raises.

### Task 2 — Compare with the running version and return the three-state verdict

**Status**: pending  

Addresses the comparison and its three outcomes, reusing parseVersion. Scope is the verdict; how it is reported belongs to story 5.

### Task 3 — Write tests for Compare the stamp and produce a verdict

**Status**: pending  

Covers the five criteria tagged integration, including the rejection that an absent or unreadable stamp must not render as no-skew.

## Story 5 — Report the stamp skew on check_integrity and stderr

**Status**: pending  
**Blocked by**: Story 6, Story 7  

### Acceptance Criteria

- A database stamped above the running version writes a line to stderr when opened. `[integration]`
- The stamp skew reaches `check_integrity` through the same top-level field the neighbour skew uses. `[integration]`
- The stamp skew's sentence names the version running, the version recorded, and the remedy. `[integration]`
- must NOT — A clean open writes anything to stderr. This continues the rule the project already holds — a clean session is silent there — which is what makes any line that does appear worth reading. `[integration]`
- must NOT — The stamp skew adds a second top-level field distinct from the neighbour's. AD1 gave the skew one field beside `entries` and `orphans`; two fields would make a caller check both to learn whether anything is stale. `[integration]`

### Task 1 — Extend the single skew composer to cover the stamp skew

**Status**: pending  

Addresses the sentence, not its transport. FR4 requires one composer, so this extends what epic 1 built rather than adding a second one.

### Task 2 — Report the stamp skew through the field the neighbour skew already uses

**Status**: pending  

Addresses the tool response. AD1 gave the skew one top-level field beside entries and orphans; this fills it from a second source rather than adding a field.

### Task 3 — Write the stderr line at database open

**Status**: pending  

Addresses FR6 and the parity with the existing ahead-message. A clean open stays silent, which is what makes a line that does appear worth reading.

### Task 4 — Write tests for Report the stamp skew on check_integrity and stderr

**Status**: pending  

Covers the five criteria tagged integration, including the silence of a clean open and the rejection of a second top-level field.

## Story 6 — Report both skews under a read-only launch

**Status**: pending  
**Blocked by**: Story 7  

### Acceptance Criteria

- A read-only launch's integrity response carries the same skew field, in the same three states, as an ordinary one. `[integration]`
- A read-only launch reports a neighbour skew as well as a stamp skew. It never reaches `start()`, so both detectors have to be reachable from the read-only open for either to arrive. `[integration]`
- must NOT — A read-only launch writes to the database or to the filesystem while reporting a skew. `[integration]`

### Task 1 — Reach both detectors from the read-only branch of open()

**Status**: pending  

Addresses the path that never calls start(). Both detectors have to be reachable without it, and neither may write anything on the way.

### Task 2 — Write tests for Report both skews under a read-only launch

**Status**: pending  

Covers the three criteria tagged integration, including the rejection that a read-only launch writes nothing while reporting a skew.

## Story 7 — Verify cross-story integration for The database stamp

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- A database stamped by a newer server and then opened by an older one produces a skew on `check_integrity` naming both versions, and a line on stderr, in a single run exercising the table, the write, the comparison and the report. `[integration]`
- Two consecutive full starts at the same version, with the neighbour check running as well, leave the committed dump byte-identical. This is not story 3's comparison repeated: it adds the other epic's detector to the run, which is where the two meet. `[integration]`

### Task 1 — Write the cross-story integration tests for the database stamp

**Status**: pending  

Covers behaviour spanning stories 1 to 6 — the end-to-end skew and the dump left undisturbed by both detectors together. Not a repeat of the per-story suites.
