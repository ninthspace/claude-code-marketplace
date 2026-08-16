# Coverage — The database stamp

**Number**: 01-02  
**Source epic**: 01-02  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR2 | The database records the version | After `migrate()` on an empty database, the stamp table exists. | Story 1 | `[integration]` |  |
| 2 | FR2 | The database records the version of the plugin that last wrote to it | A database at the previous schema version gains the stamp table when migrated, and no other table's contents change. | Story 1 | `[integration]` |  |
| 3 | FR2 | the version of the plugin that last wrote to it | must NOT — The table admits a second row. | Story 1 | `[integration]` |  |
| 4 | FR2 | the plugin that last wrote to it | must NOT — The migration inserts a row as part of applying itself. Migration SQL is static and cannot know the running version, so a row written there would carry a placeholder — and FR2 already says the value arrives on the next start. | Story 1 | `[integration]` |  |
| 5 | FR2 | the version of the plugin that last wrote to it | The resolver returns the version stated in the plugin's own manifest. | Story 2 | `[unit]` |  |
| 6 | FR2 | The database records the version of the plugin that last wrote to it | The resolver returns a version when the plugin is loaded from a working tree, where no version directory exists. | Story 2 | `[unit]` |  |
| 7 | FR2 | The database records the version | must NOT — The resolver derives the version from the containing directory's name. That is the neighbour check's mechanism, and it yields nothing in a working tree — which is the whole reason this resolver is separate from it. | Story 2 | `[unit]` |  |
| 8 | FR2 | The database records the version of the plugin that last wrote to it | A database started by a server at version X carries X as its recorded plugin version. | Story 3 | `[integration]` |  |
| 9 | FR2 | The database records the version | A database migrated from before the stamp existed acquires the running version on the next start. | Story 3 | `[integration]` |  |
| 10 | FR2 | never by one that only observes — a read-only launch leaves it as it found it | must NOT — A read-only launch writes the stamp. The read-only path exists so a board can observe every registered project without touching any of them; a stamp written on observation would diverge every one of those projects from its committed dump, and the owner would find the guard refusing a commit in a repository they had not opened. | Story 3 | `[integration]` |  |
| 11 | FR2a | written only when the writing server's version is greater than the version already recorded | A server at the recorded version leaves the row untouched. | Story 3 | `[integration]` |  |
| 12 | FR2a | written only when the writing server's version is greater than the version already recorded | A server below the recorded version leaves the row untouched — the stamp never moves backwards. | Story 3 | `[integration]` |  |
| 13 | FR2a | The recorded version is written only when the writing server's version is greater than the version already recorded | A server above the recorded version replaces it. | Story 3 | `[integration]` |  |
| 14 | FR2a | so an unchanged project produces an unchanged dump | A start that raises the recorded version does change the dump. Without this positive half, a comparison that is broken — reading the wrong file, comparing nothing to nothing — passes the byte-identical criterion perfectly. | Story 3 | `[integration]` |  |
| 15 | FR2a | written only when the writing server's version is greater than the version already recorded | control — With the write made unconditional, the criterion that a server at the recorded version leaves the row untouched fails, and that failure has been observed and read rather than assumed. | Story 3 | `[integration]` |  |
| 16 | FR3 | The server reports when the plugin version recorded in the database is newer than its own. | A database stamped above the running version produces a skew naming both versions. | Story 4 | `[integration]` |  |
| 17 | FR3 | when the plugin version recorded in the database is newer than its own | A database stamped at or below the running version produces no skew. | Story 4 | `[integration]` |  |
| 18 | FR3 | The server reports when the plugin version recorded in the database is newer than its own. | The stamp skew reaches `check_integrity` through the same top-level field the neighbour skew uses. | Story 5 | `[integration]` |  |
| 19 | FR3 | The server reports when the plugin version recorded in the database is newer than its own. | A database stamped by a newer server and then opened by an older one produces a skew on `check_integrity` naming both versions, and a line on stderr, in a single run exercising the table, the write, the comparison and the report. | Story 7 | `[integration]` |  |
| 20 | FR4 | names the version running, the newer version found, and what to do about it | The stamp skew's sentence names the version running, the version recorded, and the remedy. | Story 5 | `[integration]` |  |
| 21 | FR5 | The report distinguishes checked-and-found-no-skew from could-not-check | A database whose stamp table is absent produces could-not-check rather than no skew. This is the read-only launch against a project the release has never opened: the table will not be there, and no-skew would be a lie told confidently. | Story 4 | `[integration]` |  |
| 22 | FR5 | distinguishes checked-and-found-no-skew from could-not-check | must NOT — An absent or unreadable stamp renders as checked-and-found-no-skew. | Story 4 | `[integration]` |  |
| 23 | FR6 | A skew known at database open is written to stderr, in the manner of the existing ahead-message. | A database stamped above the running version writes a line to stderr when opened. | Story 5 | `[integration]` |  |
| 24 | FR6 | A skew known at database open is written to stderr | must NOT — A clean open writes anything to stderr. This continues the rule the project already holds — a clean session is silent there — which is what makes any line that does appear worth reading. | Story 5 | `[integration]` |  |
| 25 | FR7 | A server launched read-only reports both skews. | A read-only launch's integrity response carries the same skew field, in the same three states, as an ordinary one. | Story 6 | `[integration]` |  |
| 26 | FR7 | reports both skews | A read-only launch reports a neighbour skew as well as a stamp skew. It never reaches `start()`, so both detectors have to be reachable from the read-only open for either to arrive. | Story 6 | `[integration]` |  |
| 27 | NFR2 | A skew check that cannot complete degrades to could-not-check | A stamp comparison that throws yields could-not-check and the call it was made from succeeds. | Story 4 | `[integration]` |  |
| 28 | NFR3 | leaves the committed dump byte-identical | `migrate()` run twice against the same database applies the new migration once and leaves the table's contents unchanged. | Story 1 | `[integration]` |  |
| 29 | NFR3 | A session that neither upgrades the plugin nor changes planning data leaves the committed dump byte-identical | Two consecutive starts at the same version, with no planning data changed, produce byte-identical dumps. | Story 3 | `[integration]` |  |
| 30 | NFR3 | leaves the committed dump byte-identical | must NOT — The row carries a value that differs between two runs of the same version. This is NFR3 stated where it can be checked: a timestamp column would satisfy every other criterion here and still diverge the dump on every start, which is the exact failure the requirement exists to prevent — while looking like good practice. | Story 3 | `[integration]` |  |
| 31 | NFR3 | A session that neither upgrades the plugin nor changes planning data leaves the committed dump byte-identical | Two consecutive full starts at the same version, with the neighbour check running as well, leave the committed dump byte-identical. This is not story 3's comparison repeated: it adds the other epic's detector to the run, which is where the two meet. | Story 7 | `[integration]` |  |
| 32 | NFR4 | including under a read-only launch, whose whole guarantee is inertness | must NOT — A read-only launch writes to the database or to the filesystem while reporting a skew. | Story 6 | `[integration]` |  |
| 33 | ENVX3 | an environment variable naming the plugin root must not be required | must NOT — The resolver takes any value from `process.env`. | Story 2 | `[unit]` |  |
