# The database stamp

**Number**: 01-02  
**Source spec**: 01  
**Status**: complete — Adds a migration, and with it the one-time read-only lockout of older servers that the storage decision accepted deliberately.  

## Story 1 — The stamp table and its migration

**Status**: complete  
**Blocked by**: Story 3, Story 4, Story 7  

### Acceptance Criteria

- After `migrate()` on an empty database, the stamp table exists. `[integration]`
- `migrate()` run twice against the same database applies the new migration once and leaves the table's contents unchanged. `[integration]`
- A database at the previous schema version gains the stamp table when migrated, and no other table's contents change. `[integration]`
- A server whose target version is below the migrated database's version returns `ahead: true` and serves the read-only tool set. This is the one-time lockout of older servers that AD2 accepted deliberately, asserted here rather than discovered in the field. `[integration]`
- must NOT — The table admits a second row. `[integration]`
- must NOT — The migration inserts a row as part of applying itself. Migration SQL is static and cannot know the running version, so a row written there would carry a placeholder — and FR2 already says the value arrives on the next start. `[integration]`

### Task 1 — Write the migration adding the one-row stamp table

**Status**: complete  

The DDL and the constraint that admits only one row. Addresses the table's existence and shape, not the write path — the migration inserts nothing.

### Task 2 — Raise the schema target version and register the migration

**Status**: complete  

Addresses the ordered migration list and the version the server reports as its target. This is the change that puts older servers into the read-only branch, which AD2 accepted.

### Task 3 — Write tests for The stamp table and its migration

**Status**: complete  

Covers the six criteria tagged integration, including the second-row rejection and the assertion that an older server degrades to read-only rather than failing.

### Retro

- Adding a table to this schema costs five registrations, not one, and the plan predicted one. The plan said task 2 had "almost nothing to do" because `targetVersion()` derives from the filesystem — true, and beside the point. The full suite then failed in five places, every one a derived sweep doing exactly its job: `parity.test.js`'s `NO_CREATE_TOOL` (a table with no create tool needs a stated exemption), `parity-integration.test.js`'s `UNPROJECTED` twice (once for the reason, once for the closure that holds that set equal to parity's), `prose-columns.js`'s classification (a new TEXT column needs a judgement), and `schema.test.js`'s primary-key rule.

The last one changed the design rather than the registration, and it is the finding worth carrying. The plan's DDL was `id INTEGER PRIMARY KEY CHECK (id = 1)`, which AD9 forbids — every surrogate key in this schema is a ULID stored as TEXT. What replaced it is `schema_version`'s own shape two files away: no primary key, a `singleton INTEGER NOT NULL DEFAULT 1 CHECK (singleton = 1)` column, and `UNIQUE (singleton)`. That is strictly better than what was planned, and not for the reason the sweep caught it: `INTEGER PRIMARY KEY` is an alias for the rowid, so an insert naming no id would have been handed 2 and accepted — the second-row must-NOT would have passed on the named-id form and failed on the id-less one. A test written against the planned DDL would have found it; a test written to the planned DDL's obvious shape would not.

Practical consequence for the next schema story: budget the sweep registrations into the plan, and check the new DDL against `schema.test.js`'s rules before writing it rather than after. The sweeps are cheap to satisfy and they are not discoverable from the migration file — nothing in `src/schema/` mentions them.

- Criterion 4 — the read-only lockout of older servers — carries no coverage rows, and that is correct rather than a gap. `dpm:epics` refused to bind it because no verbatim fragment of any requirement supports it: it traces to AD2, which accepted the lockout as a deliberate one-time cost, not to a requirement that states it. The same shape appeared twice in epic 1, story 5, where the two AD1-derived shape rejections had no bindable text either.

That is now three instances of one pattern: a criterion whose warrant is a decision rather than a requirement. It is worth naming at the retro because the coverage roll-up cannot distinguish it from a criterion nobody got round to binding — both read as a story criterion with no rows. What separates them is a sentence someone has to write, and there is nowhere on the row to write it.

## Story 2 — Resolve this server's own plugin version

**Status**: complete  
**Blocked by**: Story 3, Story 7  

### Acceptance Criteria

- The resolver returns the version stated in the plugin's own manifest. `[unit]`
- The resolver returns a version when the plugin is loaded from a working tree, where no version directory exists. `[unit]`
- must NOT — The resolver derives the version from the containing directory's name. That is the neighbour check's mechanism, and it yields nothing in a working tree — which is the whole reason this resolver is separate from it. `[unit]`
- must NOT — The resolver takes any value from `process.env`. `[unit]`

### Task 1 — Add a resolver reading the version from the plugin's own manifest

**Status**: complete  

Addresses the case the neighbour check cannot serve — a plugin loaded from a working tree, where no version directory exists to read a name off.

### Task 2 — Write tests for Resolve this server's own plugin version

**Status**: complete  

Covers the four criteria tagged unit, including the two rejections: no directory-name derivation and no read of process.env.

### Retro

- A must-NOT control found a hole in itself, and only because the mutation was run rather than described. Criterion 3 rejects deriving the version from the containing directory's name. The test pointed the resolver at `/cache/plugins/dpm/0.3.0` with a manifest saying `9.9.9`, and controlled it with a missing manifest — a reader that throws, against a version-named root, so a directory-name derivation would be the only thing still able to answer `0.3.0`.

The mutation put the fallback *after* the parse: `return version ?? basename(root)`. A reader that throws never reaches that line, so the control passed over it. The mutation was caught only by a neighbouring test about null-handling, several criteria away — which is a sound suite and an unsound criterion, and no green run would ever have distinguished the two.

The fix was a second control on the same criterion: a manifest that parses cleanly and states no version. There are two ways for the manifest to say nothing — unreadable, and readable-but-silent — and a fallback can be reached by either. A single control covers whichever path the author happened to imagine.

Generalising: a must-NOT control needs one arm per code path that could reach the rejected behaviour, not one arm per criterion. The question to ask when writing it is not "would this have caught the thing" but "where could the thing be written, and does this reach each of those places".

- `SERVER_INFO.version` in `src/server/mcp.js:32` is `'0.1.0'` while `package.json` says `0.4.0`. It is what the MCP `initialize` handshake answers with, so every client of every dpm release since 0.1.0 has been told the server is 0.1.0. Nothing asserts it — no test in the suite reads `SERVER_INFO.version` — which is why it went stale unnoticed.

Left as found, deliberately. This story's four criteria are about a resolver, not about the handshake, and wiring one to the other is a change to what the server advertises on the wire. Recorded here so the next person to open `mcp.js` finds the reason rather than the discrepancy.

The obvious fix is now cheap and should be proposed rather than taken: `pluginVersion()` returns exactly the string that belongs there. What makes it a decision rather than a tidy-up is that `pluginVersion()` can return `null`, and a handshake has to answer with something.

## Story 3 — Write the stamp on increase

**Status**: complete  
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

**Status**: complete  

Addresses where the write sits in the fixed order: after migrate, because the table it writes to is created there. Scope is placement, not the increase condition.

### Task 2 — Gate the write on the running version exceeding the recorded one

**Status**: complete  

Addresses FR2a — equal and lower both leave the row untouched, so the stamp never moves backwards and an unchanged project produces an unchanged dump.

### Task 3 — Keep the write off the read-only path

**Status**: complete — Required no code: `open()`'s read-only branch returns before `start()` is reached, and the connection is opened read-only, so the write is refused twice over. The task's work was the assertion and its control.  

A separate path from the increase gate: a correct gate still writes when a newer server merely observes a project. Addresses the read-only rejection only.

### Task 4 — Write tests for Write the stamp on increase

**Status**: complete  

Covers the ten criteria tagged integration, including both dump comparisons and the control that makes the write unconditional and observes the untouched-row criterion fail.

### Retro

- The dump criterion does not hold the increase gate, and the story reads as though it does. Criterion 6 — two starts at one version dump identically — is satisfied by a *broken* gate, because an upsert writing the same value produces the same dump. The control mutation (`if (false && …)`, so every start writes) left criteria 6 and 7 both green and was caught only by criterion 3, the one about `written` being false. Criterion 7's positive half is honest and necessary, and it does not rescue criterion 6: it proves the comparison discriminates *something*, not that it discriminates the gate.

That is not a defect in the criteria, but it changes what each is evidence for. NFR3's real hazard is a value that differs between runs of one version — a timestamp column — which is criterion 9, and criterion 9's structural half (the table has two columns, neither able to hold an instant) is what actually forecloses it. The gate's own justification is criteria 3 to 5: the stamp answers *what is the newest release that has written here*, and an older server passing through must not erase the evidence of the newer one it is about to be compared against.

Worth carrying into the next dump-stability criterion: "the dump is unchanged" discriminates only against a write whose *value* changes. Where the concern is a write happening at all, the criterion has to name the write, not its downstream trace.

- Task 3 — keep the write off the read-only path — required no code, and the reason is worth recording rather than the fact. `open()`'s read-only branch returns before `start()` is reached, and it opens the connection with `readOnly: true`; the stamp write is refused twice over, by a branch that never calls it and by a connection that would refuse it. That is Epic 48-01's design paying off in a story written two epics later without anyone having to know about it.

The story still had work: an assertion, and a control that removes the mode and watches the write happen to the same file on the same call. Without the control, "the read-only launch did not write" is equally true of a stamp step that never writes at all — which is exactly the shape 48-01's own tests named as the thing separating "correctly inert" from "never worked".

Smooth delivery, and the smoothness is the finding: a guarantee held by a boundary rather than by a rule each new writer has to remember is one that new code inherits for free.

## Story 4 — Compare the stamp and produce a verdict

**Status**: complete  
**Blocked by**: Story 5, Story 7  

### Acceptance Criteria

- A database stamped above the running version produces a skew naming both versions. `[integration]`
- A database stamped at or below the running version produces no skew. `[integration]`
- A database whose stamp table is absent produces could-not-check rather than no skew. This is the read-only launch against a project the release has never opened: the table will not be there, and no-skew would be a lie told confidently. `[integration]`
- A stamp comparison that throws yields could-not-check and the call it was made from succeeds. `[integration]`
- must NOT — An absent or unreadable stamp renders as checked-and-found-no-skew. `[integration]`

### Task 1 — Read the recorded stamp, tolerating an absent table

**Status**: complete  

Addresses the read and its failure mode. An absent table is the ordinary case for a project this release has never opened, so it is a value the reader returns rather than an error it raises.

### Task 2 — Compare with the running version and return the three-state verdict

**Status**: complete  

Addresses the comparison and its three outcomes, reusing parseVersion. Scope is the verdict; how it is reported belongs to story 5.

### Task 3 — Write tests for Compare the stamp and produce a verdict

**Status**: complete  

Covers the five criteria tagged integration, including the rejection that an absent or unreadable stamp must not render as no-skew.

### Retro

- A surviving mutation found an unreachable `catch`, and removing it was the right fix rather than contriving a test for it.

`stampSkew` wrapped its whole body in a try/catch documented as the NFR2 backstop for "a `db` that is not a connection, a closed one, anything a later change puts in the way". Rewriting it to rethrow broke none of the seven tests. Tracing why: the two database reads are inside `readStamp`, which guards both itself, and the only other call is `isAbove` → `parseVersion`, which coerces with `String(version)` and answers `NaN` rather than throwing. There was no path from that function's body to an exception. The clause was not untested — it was unreachable by construction, and no test could have been written for it.

The same run found that `readStamp`'s *second* guard had never been entered either: the one test driving a failure (a closed connection) fails at the `sqlite_schema` lookup in the first guard, and returns before the row read is reached. That was reachable, and got a case of its own — a `plugin_stamp` table present but with no `version` column, which is what a release far enough ahead to have renamed it would leave behind.

**The judgement worth carrying is which of the two fixes applies.** A guard no test reaches is either a gap in the tests or dead code, and the difference is decided by tracing whether any input can reach it — not by how load-bearing the comment sounds. Both comments here read as load-bearing; one was describing a defence that had never run. Untestable defence with a confident comment is worse than no defence, because it reads afterwards as verified.

## Story 5 — Report the stamp skew on check_integrity and stderr

**Status**: complete  
**Blocked by**: Story 6, Story 7  

### Acceptance Criteria

- A database stamped above the running version writes a line to stderr when opened. `[integration]`
- The stamp skew reaches `check_integrity` through the same top-level field the neighbour skew uses. `[integration]`
- The stamp skew's sentence names the version running, the version recorded, and the remedy. `[integration]`
- must NOT — A clean open writes anything to stderr. This continues the rule the project already holds — a clean session is silent there — which is what makes any line that does appear worth reading. `[integration]`
- must NOT — The stamp skew adds a second top-level field distinct from the neighbour's. AD1 gave the skew one field beside `entries` and `orphans`; two fields would make a caller check both to learn whether anything is stale. `[integration]`

### Task 1 — Extend the single skew composer to cover the stamp skew

**Status**: complete — The composer moved to a new src/server/skew.js along with the SKEW vocabulary and a new SOURCE discriminator, rather than being extended in place: neighbour.js was the right home while it was the only detector, and a module named for the plugin cache composing a sentence about the database is one nobody would look in. Both detectors now tag their verdicts with their source, and the composer selects its sentence table from that.  

Addresses the sentence, not its transport. FR4 requires one composer, so this extends what epic 1 built rather than adding a second one.

### Task 2 — Report the stamp skew through the field the neighbour skew already uses

**Status**: complete — The one field now holds both verdicts under their source names, with a rolled-up state and message above them. Epic 1's flat shape assumed one detector; keeping it would have meant a second top-level field, which is the story's own must-NOT. Six assertions in cross-tools.test.js moved from report.skew.* to report.skew.neighbour.* — a relocation, with their substance unchanged.  

Addresses the tool response. AD1 gave the skew one top-level field beside entries and orphans; this fills it from a second source rather than adding a field.

### Task 3 — Write the stderr line at database open

**Status**: complete — Only `found` writes a line. `none` is the ordinary case and would be noise on every open; `unknown` is the ordinary case for a project this release has never migrated, and a warning nobody can act on trains a reader to skip the ones they can. Both still reach check_integrity, where a caller asked for them.  

Addresses FR6 and the parity with the existing ahead-message. A clean open stays silent, which is what makes a line that does appear worth reading.

### Task 4 — Write tests for Report the stamp skew on check_integrity and stderr

**Status**: complete  

Covers the five criteria tagged integration, including the silence of a clean open and the rejection of a second top-level field.

### Retro

- Fourth criterion in this spec whose must-NOT traces to an ADR rather than to requirement text, and so carries no coverage rows.

"The stamp skew adds a second top-level field distinct from the neighbour's" cites AD1 in its own wording and has zero `coverage` rows, because there is no verbatim fragment of any requirement to bind it to — AD1 is a decision document, and the coverage graph binds only to requirements. It is tested (a whole-key-set comparison, plus a control that the stamp is present in the one field), and the verification is simply invisible to the roll-up.

The earlier three: epic 1 story 5 had two, epic 2 story 1 had one. That is now a consistent shape rather than three coincidences — a decision constrains the build exactly as a requirement does, and the traceability graph has one kind of anchor. Worth deciding at spec time whether an accepted ADR should be bindable, or whether a decision that constrains a story should also produce a requirement. Recorded rather than acted on: it is a change to the coverage model, which is nothing this run should decide.

- A shape that was right for one detector had to change when the second arrived, and both changes were forced by criteria rather than chosen.

Epic 1 put the neighbour verdict flat in `check_integrity`'s `skew` field, and the vocabulary and the sentence composer in `neighbour.js`. Both were correct for one detector. This story's criteria made both untenable at once: the stamp skew must reach the report *through the same field*, and must *not* add a second top-level one — so the flat shape had to become `{state, message, neighbour, stamp}`; and FR4's one composer meant a module named for the plugin cache would be composing a sentence about the database, which nobody would think to look for.

**The nesting reintroduced the problem the must-NOT was about, one level down, and the roll-up is what closed it.** The rejection's stated reason is that two fields "would make a caller check both to learn whether anything is stale" — and two named sub-objects with no summary cost exactly that. So `skew.state` is the worst of the two, `found` over `unknown` over `none`. Two mutations confirmed the ordering is load-bearing rather than decorative: ranking `none` above `unknown` was caught by two tests, and inverting the whole ranking by four.

**What is worth carrying is the cost of the second caller, which is not the second caller's code.** Story 5 added one module, one field key and one stderr line; the work was in the eight existing assertions that had encoded "there is one detector" without ever saying so. None of them was wrong when written. A shape asserted flat is a shape claimed to be final, and nothing marks which assertions are load-bearing and which are incidental to a shape that happened to have one member.

## Story 6 — Report both skews under a read-only launch

**Status**: complete — Delivered without production code: both detectors already reached the read-only branch through spineTools' defaults, and check_integrity's `mutates: false` keeps its handler out of the read-only replacement set. The four tests hold that open, since neither property is stated anywhere near the branch that depends on it.  
**Blocked by**: Story 7  

### Acceptance Criteria

- A read-only launch's integrity response carries the same skew field, in the same three states, as an ordinary one. `[integration]`
- A read-only launch reports a neighbour skew as well as a stamp skew. It never reaches `start()`, so both detectors have to be reachable from the read-only open for either to arrive. `[integration]`
- must NOT — A read-only launch writes to the database or to the filesystem while reporting a skew. `[integration]`

### Task 1 — Reach both detectors from the read-only branch of open()

**Status**: complete — No code was needed, and the reason is worth keeping. Both detectors are defaults on `spineTools`, which the read-only branch already calls; `check_integrity` declares `mutates: false`, so `readOnlyTools` leaves its handler alone. A read-only launch against a database stamped at 99.0.0 was verified to report `skew.stamp.state: found` with the neighbour half beside it, unchanged. Writing a second wiring here would have been a second answer to a question the tool table already answers, and the two would have disagreed the first time either moved. Story 5's `skewReport` extraction, made in anticipation of a second construction site, turns out not to be needed for that reason — it stays because it is where the shape belongs, not because two callers build it.  

Addresses the path that never calls start(). Both detectors have to be reachable without it, and neither may write anything on the way.

### Task 2 — Write tests for Report both skews under a read-only launch

**Status**: complete  

Covers the three criteria tagged integration, including the rejection that a read-only launch writes nothing while reporting a skew.

### Retro

- A whole story delivered with no production code, because two earlier decisions had already made it true — and the tests are the only thing that will keep it true.

FR3's read-only requirement was satisfied before this story started: both detectors are defaults on `spineTools`, which the read-only branch already calls, and `check_integrity` declares `mutates: false`, so `readOnlyTools` leaves its handler alone. A read-only launch against a database stamped at 99.0.0 reported `found` on the first probe, with the neighbour half beside it.

**Neither of those two properties is stated anywhere near the read-only branch, and both are one edit from being false.** A future tool that reached the skew through a handler-level guard, or a `mutates: true` set on `check_integrity` by someone reasoning about the word "check", would silently remove the report from precisely the caller with the most projects to observe. That is the case for the four tests: they hold open a behaviour that emerges from two decisions taken elsewhere for other reasons.

**A second thing worth recording: I extracted `skewReport` in story 5's refactoring pass on the stated grounds that story 6 would be the second construction site. It is not.** The extraction is still right — the shape belongs beside the vocabulary that defines it — but the reason I gave for it was a prediction, and the prediction was wrong. Anticipating a second caller is a weaker argument for extraction than it feels like at the time, and it is worth noticing when the anticipated caller does not arrive.

## Story 7 — Verify cross-story integration for The database stamp

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A database stamped by a newer server and then opened by an older one produces a skew on `check_integrity` naming both versions, and a line on stderr, in a single run exercising the table, the write, the comparison and the report. `[integration]`
- Two consecutive full starts at the same version, with the neighbour check running as well, leave the committed dump byte-identical. This is not story 3's comparison repeated: it adds the other epic's detector to the run, which is where the two meet. `[integration]`

### Task 1 — Write the cross-story integration tests for the database stamp

**Status**: complete  

Covers behaviour spanning stories 1 to 6 — the end-to-end skew and the dump left undisturbed by both detectors together. Not a repeat of the per-story suites.

### Retro

- A repeated `start()` rewrites the database file every time while leaving the dump identical, and NFR3's wording says "byte-identical" about the wrong artefact.

I wrote the cross-story dump test asserting both the dump and the database file's bytes were unchanged across two full sessions at one version. The dump assertion passed; the bytes assertion failed. Measured rather than assumed: a bare read-write SQLite open changes nothing, but three consecutive `start()` calls on one file produce three different hashes with `stamp.written` false on every one after the first. Something in seeding or guard regeneration touches pages whether or not it changes a row.

**So the byte claim is true of the projection and not of the file, and that distinction is load-bearing.** NFR3's text is "leaves the committed dump byte-identical", and the committed artefact is `.dpm/dpm.sql` — which the pre-commit guard compares, and which is stable. Nothing was wrong; my assertion claimed more than the requirement does and more than SQLite offers. Removed, with the measurement written into the test so the next person does not re-derive it.

**The general shape is worth keeping:** when an integration test fails on a claim adjacent to the one under test, the first question is whether the requirement actually makes that claim. Here the answer was no, and the fix was in the test. Had I reached for the code instead I would have gone looking for a write in a feature that was not making one — the stamp declined on every run, which the same probe showed.
