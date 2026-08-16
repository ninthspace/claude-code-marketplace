# Version skew detection

**Number**: 01  
**Status**: complete — Approved 2026-08-16. Sequenced so the neighbour check ships before the database stamp — the stamp alone would not have caught the incident that prompted the work.  

## Problem recap

An MCP server is pinned to a version directory for the life of the session. The plugin root is resolved once at launch; installing a new plugin version writes a new version directory and repoints the installation registry, and reaches into nothing already running. Only sessions open *across* an upgrade are affected, and nothing tells them.

On 2026-08-16 this repository's own session ran dpm 0.3.0 for several hours after 0.4.0 was installed. All twenty-one tools answered normally. The four `disposition` taxonomy terms 0.4.0 seeds were never inserted, because the server doing the seeding did not know they existed. Nothing failed, nothing logged, and it surfaced only because a taxonomy listing was read for an unrelated reason.

**The harm is one-way.** An older server under-seeds and under-reports; it does not corrupt. The opposite direction — a database migrated beyond what the server understands — is already handled: `migrate()` reports `ahead`, the server logs `aheadMessage` and degrades to a read-only tool set. The backward case has no detection at all, and this spec is about the backward case.

**There are two backward skews, and neither subsumes the other.**

The first is *the server is older than the plugin installed beside it*. That is the failure observed, and it is detectable from the filesystem alone: the running server's own version directory has a newer sibling.

The second is *the server is older than the plugin that last wrote to this database*. That is the shared-repository case — a colleague publishes from a newer plugin, and the next person pulls and opens the result on an older one. It requires the database to carry a stamp, and no such stamp exists.

The redirection that produced this spec is that the second detector is blind to the first. In the observed failure nothing newer had ever written to the database, so a stamp recording who last wrote would have read clean while the server sat four terms short of the vocabulary it was supposed to seed. A design that shipped only the stamp would have been a correct implementation of a check that could not have caught the incident that motivated it.

## In scope

The neighbour check, taking the plugin root as an argument rather than reading it from the environment, evaluated each time it is reported.

The database stamp: a migration, a one-row table, and a write that happens only when the running version exceeds the version already recorded.

Detection of both backward skews — the server older than the plugin installed beside it, and the server older than the plugin that last wrote to the database.

Reporting through two channels: a new top-level field on `check_integrity`'s response, which is the one a session actually reads, and a stderr line at database open in the manner of the existing ahead-message.

A read-only launch reporting both skews, despite reaching neither detector today.

The maintenance record covering the coupling to the host's plugin cache layout.

## Out of scope

The three excluded requirements carry their reasoning on their own rows: refusing or degrading tool calls on a backward skew, self-repairing by loading from a newer sibling directory, and restarting the server into the newer version.

Anything over the network, which is foreclosed by ENVX4 rather than merely unplanned.

Two further exclusions are not requirements at all, and are written down so that nobody reopens them part-way through an epic.

**The existing forward-skew behaviour is not touched.** A database migrated beyond what the server understands continues to produce `ahead`, the ahead-message and a read-only tool set, exactly as it does now. This spec adds a second, opposite detector; it does not revisit the first.

**No session hook is added.** dpm ships none, deliberately — a skill names the shared conventions file and reads it, rather than a hook injecting anything into every session. A warning delivered by hook would also be useless for the failure that motivated this work, since a hook belonging to a stale plugin is as stale as the server it ships beside.

## Deferred

**Consulting the host's installation registry** (FR8), which would still detect a skew once the older sibling directories have been swept. Deferred rather than excluded: the decision records it as the route this takes when the sibling scan proves insufficient.

**Reporting a skew from the `publish` path.** This is the gap worth stating plainly, because it is the one where a stale server does the most damage. `publish` regenerates every projected document using its own release's renderers, and it opens the database rather than starting it — so it reaches neither detector, and produces a tree of subtly outdated markdown that the pre-commit guard then passes, because the guard compares that projection against a regeneration from the same stale code. Four missing vocabulary terms are a smaller problem than that.

It is deferred because closing it means deciding whether a stale publish warns or refuses, and refusing reopens the requirement this spec excluded. The plumbing is cheap once the neighbour check exists as a function taking a root; the policy is what needs its own conversation.

## Integration boundaries

Five seams, drawn from the decisions rather than invented.

**The neighbour check and the filesystem.** The reader is a parameter; the contract is a root in, sibling names out. This is where NFR1's read-counting and ENVX2's prohibition on reaching the home directory are both enforced, and having it as a seam at all is what makes either of them enforceable.

**The detectors and the verdict.** Two detectors producing one verdict shape, carrying the state, the running version, the version found and the message. FR4's must-not against composing the sentence in more than one place lives here; it is the only point that keeps one sentence from becoming four as the second channel is added.

**The verdict and the integrity response.** A new top-level field beside `entries` and `orphans`, leaving both `ok` and the register derivation untouched.

**`start()` and the stamp.** The documented contract is three steps in a fixed order, and this makes it four. The ordering constraint is the one already stated: the table has to exist before anything writes to it, so the stamp follows migration for the same reason vocabulary does.

**The read-only bring-up and the detectors.** The read-only branch is deliberately one call where the ordinary one is five, and the four it omits are the requirement rather than an optimisation. FR7 adds reading to it and must add nothing else. This is the seam most likely to be got wrong, because the obvious way to give a read-only launch the detectors is to let it call `start()` — which would reintroduce every write the branch exists to avoid.

## Functional Requirements

### FR1 (must)

The server reports when a newer version of the plugin is installed alongside the version it is running from.

- Given a root holding the running version and a higher-numbered sibling, the check reports a skew naming the higher version. `[unit]`
- Given a root whose siblings are all lower than or equal to the running version, the check reports no skew. `[unit]`
- must NOT — The check reports a skew for a sibling lower than the running version. A reversed comparison satisfies the first criterion on any machine with more than one version installed, so the first criterion alone does not pin the direction. `[unit]`

### FR1a (must)

The neighbour check is evaluated at the moment it is reported, never cached from server start. The observed failure arrived twenty hours into a running session, when a check evaluated at start had already found nothing and been right to.

- Two consecutive reports against a root that gained a higher sibling between them return different verdicts. `[integration]`
- control — With the check deliberately memoised, the two-consecutive-reports criterion fails, and the failure has been observed and read rather than assumed. This requirement exists because a start-time check would have been silently wrong for twenty hours; a test unable to distinguish a cached verdict from a fresh one reproduces the defect it was written to catch. `[integration]`

### FR1b (must)

The neighbour check completes without error when the plugin root is not a version directory, reporting could-not-check rather than failing and rather than claiming no skew. A plugin loaded from a working tree is the ordinary case for anyone developing dpm, and it produces the same "found nothing" as a genuinely current install — only one of which is honestly a no-skew answer.

- Given a root whose name does not parse as a version, the check reports could-not-check. `[unit]`
- Given a root with no sibling directories at all, the check reports could-not-check rather than no skew. `[unit]`
- must NOT — The check throws for an unreadable or unparseable root. `[unit]`

### FR2 (must)

The database records the version of the plugin that last wrote to it. The record is made by a server that writes, and never by one that only observes — a read-only launch leaves it as it found it.

- A database started by a server at version X carries X as its recorded plugin version. `[integration]`
- A database migrated from before the stamp existed acquires the running version on the next start. `[integration]`
- must NOT — A read-only launch writes the stamp. The read-only path exists so a board can observe every registered project without touching any of them; a stamp written on observation would diverge every one of those projects from its committed dump, and the owner would find the guard refusing a commit in a repository they had not opened. `[integration]`

### FR2a (must)

The recorded version is written only when the writing server's version is greater than the version already recorded, so an unchanged project produces an unchanged dump.

- A server at the recorded version leaves the row untouched. `[integration]`
- A server below the recorded version leaves the row untouched — the stamp never moves backwards. `[integration]`
- A server above the recorded version replaces it. `[integration]`
- must NOT — The row carries a value that differs between two runs of the same version. This is NFR3 stated where it can be checked: a timestamp column would satisfy every other criterion here and still diverge the dump on every start, which is the exact failure the requirement exists to prevent — while looking like good practice. `[integration]`
- control — With the write made unconditional, the criterion that a server at the recorded version leaves the row untouched fails, and that failure has been observed and read rather than assumed. `[integration]`

### FR3 (must)

The server reports when the plugin version recorded in the database is newer than its own.

- A database stamped above the running version produces a skew naming both versions. `[integration]`
- A database stamped at or below the running version produces no skew. `[integration]`
- A database whose stamp table is absent produces could-not-check rather than no skew. This is the read-only launch against a project the release has never opened: the table will not be there, and no-skew would be a lie told confidently. `[integration]`

### FR4 (must)

A reported skew names the version running, the newer version found, and what to do about it, and the sentence saying so is composed in one place rather than assembled separately by each caller. Naming the remedy is the existing convention: the dump-staleness message names publish, which is both true and the fix. One composer is what keeps the tool response and the stderr line from drifting into two accounts of the same skew.

- A reported skew contains the running version, the newer version found, and a remedy naming a session restart. `[unit]`
- must NOT — The skew sentence is composed in more than one place. This extends the rule the ahead-message already holds — one sentence serving both bring-ups, so a reader parsing the line matches one wording rather than two that are one edit from disagreeing. Two detectors reporting through two channels is four opportunities to write that sentence four times. `[unit]`

### FR5 (must)

The report distinguishes checked-and-found-no-skew from could-not-check. A check that silently did not run is the defect `checkIntegrity` already guards against by counting what it checked rather than reporting only what failed.

- The skew field is present in the response when no skew was found. `[unit]`
- The three states — skew found, no skew, could not check — are distinguishable without parsing message text. `[unit]`
- must NOT — A check that could not run renders as no skew. `[unit]`
- control — With could-not-check collapsed into no-skew, FR1b's criteria fail, and that failure has been observed and read rather than assumed. `[integration]`

### FR6 (must)

A skew known at database open is written to stderr, in the manner of the existing ahead-message. In practice this carries the database-stamp skew; the neighbour skew is usually absent at open and arrives later.

- A database stamped above the running version writes a line to stderr when opened. `[integration]`
- must NOT — A clean open writes anything to stderr. This continues the rule the project already holds — a clean session is silent there — which is what makes any line that does appear worth reading. `[integration]`

### FR7 (should)

A server launched read-only reports both skews. It never reaches `start()`, so as things stand it would learn of neither — and a board observing many projects is the surface where an unnoticed stale server misreports the most of them.

- A read-only launch's integrity response carries the same skew field, in the same three states, as an ordinary one. `[integration]`

### FR8 (could) — deferred

The neighbour check also consults the installation registry, catching a skew after the older sibling directories have been swept.

### FR9 (wont) — out_of_scope

Refusing or degrading tool calls on a backward skew. The forward case earns a read-only tool set because an older server can damage a newer database; the backward case cannot, and a server that refused to serve because a newer plugin exists would cost more than the under-seeding it was protecting against.

### FR10 (wont) — out_of_scope

Loading seed data or code from a newer sibling version directory in order to self-repair. It is the fix that suggests itself once the neighbour is visible, and it runs a newer release's data through an older release's guards and schema — the precise combination `migrate()` refuses in the forward direction. Recorded so the reasoning outlives the impulse.

### FR11 (wont) — out_of_scope

Restarting or reloading the server into the newer version. Which version directory a server runs from is chosen by the MCP client at launch, and a process that re-executed itself elsewhere would be overriding that choice from inside.

## Non-Functional Requirements

### NFR1 (must)

The neighbour check costs one bounded directory read per report — no recursion, no process spawn, no network call. It runs on every report rather than once per session, so its cost is paid repeatedly and has to stay negligible.

- The check performs exactly one directory read per invocation. Counting reads means the reader is injectable — a seam falling out of the criterion rather than a preference, and the same seam ENVX2 needs. `[unit]`
- must NOT — The check recurses into subdirectories. `[unit]`
- must NOT — The check spawns a process or opens a socket. `[unit]`

### NFR2 (must)

A skew check that cannot complete degrades to could-not-check. It never fails the tool call and never stops the server. Paired with FR5: FR5 gives the report a way to say it, this gives the failure somewhere to go.

- A directory read that throws produces could-not-check and a successful tool response. `[integration]`
- must NOT — An error from the check propagates out of the tool handler. `[integration]`
- control — With the error handling removed, the criterion that a throwing read produces could-not-check fails, and that failure has been observed and read rather than assumed. `[integration]`

### NFR3 (must)

A session that neither upgrades the plugin nor changes planning data leaves the committed dump byte-identical. A stamp written on every start would diverge the dump every session, the pre-commit guard would fire on commits that changed nothing, and a guard that fires on nothing stops being read — which costs more than this feature is worth.

- Two consecutive starts at the same version, with no planning data changed, produce byte-identical dumps. `[integration]`
- A start that raises the recorded version does change the dump. Without this positive half, a comparison that is broken — reading the wrong file, comparing nothing to nothing — passes the first criterion perfectly. `[integration]`

### NFR4 (must)

The neighbour check reads only. It creates no file and no directory, and writes nothing anywhere — including under a read-only launch, whose whole guarantee is inertness.

- After a report, the filesystem beneath and beside the plugin root is unchanged. `[integration]`
- must NOT — The check creates a file or directory anywhere. `[integration]`

### NFR5 (must)

The coupling to the host's plugin cache layout is recorded in the project's maintenance record, and named from no skill file. The layout is the host's to change and not ours to rely on quietly; a pointer from a skill would be a line every invocation pays for.

- The maintenance record documents the assumed plugin cache layout and what breaks if the host changes it. Manual because whether a written record actually explains the coupling is a judgement about prose; the automatable version — asserting the file contains certain words — would pass on a heading with nothing under it, which measures the wrong thing. `[manual]`
- must NOT — Any file under the skills directory names the maintenance record's path. `[unit]`

## Environmental Requirements

### ENV1 (must)

Development: Node 22.5.0 or later, matching `engines.node`. Checkable by comparing the running `process.version` against the floor the server already states as `REQUIRED_NODE`.

- The running Node satisfies `REQUIRED_NODE`, and `engines.node` equals it. `[unit]`

### ENV2 (must)

Development: the suite runs via the built-in `node --test` runner with no install step. Checkable by running the test script on a clean checkout. This project has no CI, so the suite is run by whoever is at the keyboard — a runner needing setup is a runner that stops being run.

- The test script invokes only the built-in runner, with no binary resolved from `node_modules`. `[unit]`

### ENV3 (must)

Development: a fixture standing in for a plugin cache layout — a directory holding sibling version directories — that the neighbour check can be pointed at. Checkable by a test that constructs one and asserts the check's verdict against it.

- A constructed directory of sibling version directories exists in the suite, and the check reports a verdict against it. `[unit]`

### ENV4 (must)

Production: Node 22.5.0 or later on the machine running the MCP client. Checkable by the floor check the entry point already performs before anything reaches `node:sqlite`.

- On the host, launching below the floor produces the floor message rather than the raw unknown-builtin-module error. `[target]`

### ENV5 (must)

Production: the running plugin's own directory is derivable from the module's URL at runtime. Checkable by resolving it and asserting it names the directory the module was loaded from. This is what makes the neighbour check possible without the host handing us anything.

- Resolving from the module's own URL names the directory the module was loaded from. `[unit]`

### ENV6 (must)

Development: a temporary filesystem location the suite can create, write to and remove. Checkable by a test that creates one, writes into it and asserts it is gone afterwards. Reached from Step 6d rather than elicited: several integration criteria write and compare real files — the two dump comparisons, the filesystem-unchanged assertion, and the construction of ENV3's sibling directories — and nothing recorded said the suite could.

- A test creates a temporary location, writes into it, and asserts it is gone afterwards. `[unit]`

## Environmental Restrictions

### ENVX1 (must)

Development: no runtime or development dependency may be required. Checkable by asserting `dependencies` and `devDependencies` are both empty in `package.json`. A semver comparison is the obvious place a package would creep in, and the parser this needs already exists in `node-floor.js`.

- `dependencies` and `devDependencies` are both empty. `[unit]`

### ENVX2 (must)

Development: the suite must not require the real plugin cache or the user's home directory. Checkable by the neighbour check taking its root as an argument, and by a test asserting it reads only the path it was given. Without this the obvious implementation passes on the author's machine for reasons unrelated to the code being correct.

- The check reads only the path it was given. `[unit]`
- must NOT — Any path a test resolves runs through the user's home directory. `[unit]`

### ENVX3 (must)

Production: an environment variable naming the plugin root must not be required. Checkable by the resolver taking no value from `process.env`. The host expands its plugin-root placeholder into the launch arguments, and nothing guarantees it in the process environment.

- The resolver reads no value from `process.env`. `[unit]`

### ENVX4 (must)

Production: network access must not be required. Checkable by asserting no path this spec adds makes an outbound call. This forecloses the tempting implementation of FR8 — asking the marketplace what the current version is — which would make a local diagnostic depend on being online.

- No path this spec adds makes an outbound call. `[unit]`

## Architecture Decisions

### 01-01 — Where a version skew appears in the integrity report

**Decision status**: accepted  

A skew is reported in a new top-level field of `check_integrity`'s response, separate from `entries` and `orphans` and carrying its own verdict and could-not-check state, leaving `ok` a statement about the data alone.

#### A new top-level field — chosen

The skew sits beside `entries` and `orphans` rather than inside either, with its own verdict and its own could-not-check state. `ok` continues to mean the database is internally consistent, which it is — the rows are sound and the reader is stale. The field is present whether or not a skew was found, because an absent field and a field reporting nothing found read identically to someone who was not already looking for it.

| Axis | Assessment |
| --- | --- |
| complexity | Low, but it introduces a second notion of "something is wrong" alongside `ok`. Anyone reading the report now has two places to look, and the field has to be self-describing enough that the second place is obvious. |
| cost | One added field on one response. Nothing existing changes shape, so no caller of `check_integrity` has to be touched. |
| reversibility | High. An added field can be renamed or moved while `ok` and `entries` keep their meanings, because nothing downstream has been asked to reinterpret what it already reads. |

#### A register entry

Rejected. `entries` is built by mapping over the register so that an entry added there appears in the report without the tool being edited, and a parity test holds that derivation. A version skew names no rows and is not a cross-row invariant, so it would have to arrive either as a fake register entry or by breaking the mapping — and the second would cost the property the parity test exists to protect.

#### Setting `ok` to false

Rejected. It would guarantee the warning is noticed, at the price of the report saying the database is broken when nothing is wrong with it. Every caller branching on `ok` would begin treating an environment warning as corruption, and the one report whose job is to be trusted would start crying wolf.

| Axis | Assessment |
| --- | --- |
| reversibility | Low, and that is the reason to refuse it rather than try it. Once `ok` has meant "no skew either" for one release, every caller written against it encodes that meaning, and narrowing it back is a silent behaviour change in the direction of missing things. |

### 01-02 — Where the database records the plugin that wrote it

**Decision status**: accepted  

The plugin version is recorded in a new one-row table introduced by a migration, accepting the one-time consequence that servers older than that release degrade to read-only against any project the new release has opened.

#### A new one-row table — chosen

A named table holding a named column, arriving through the migration path everything else in the schema arrives through, and appearing in the dump like every other row. It costs a schema bump, and therefore costs older servers their write tools against any project this release has opened. That is accepted: read-only is already the policy for a database a server does not fully understand, so this extends an existing rule by one release rather than inventing a lockout. The cost is also one-time and bounded — the stamp records the plugin version rather than the schema version, so every release after it moves the stamp without moving the schema.

| Axis | Assessment |
| --- | --- |
| complexity | Low, and deliberately the most boring option available. It uses the migration path, the dump and the guard exactly as they already work, so nothing new has to be kept in step. |
| cost | A migration file, a table, and a one-time read-only lockout for anyone still on an older plugin the first time this release opens a shared project. The lockout is the real price and it is paid by people who did nothing. |
| reversibility | Low in one direction only. A schema version, once raised, cannot be lowered for databases already migrated, so the lockout cannot be taken back by a later release. What can be changed freely is what is done with the stamp — the reading, the comparison and the reporting are all ordinary code. |

#### A column on `schema_version`

Rejected. It costs the same schema bump as its own table while additionally putting two adjacent answers in one place: `schema_version` records how far the database has been migrated, one row per migration, and the plugin version is neither of those things. A table holding one fact per row and another fact on some of those rows is a table that will be read wrongly.

#### `PRAGMA user_version`

Rejected, and it is the one that tempts. It avoids the migration and the bump entirely. But it is a single unnamed 32-bit integer, so a three-part version has to be encoded into it and decoded on the way out, and the slot belongs to whoever claims it first — nothing marks it as ours, and nothing would notice if something else began writing there.

| Axis | Assessment |
| --- | --- |
| cost | Lowest of the four up front — no migration, no bump, no lockout, and no change to the dump's shape. |
| reversibility | Superficially high and actually poor. Moving off the pragma later means every database already carrying an encoded integer has to be read by something that knows the encoding, and by then the encoding is undocumented history rather than a decision. |

#### A sidecar file beside the database

Rejected. It avoids the schema bump, and it is a file rather than a row in a system whose thesis is that planning state is rows and files are a generated projection. To be useful across a team it would have to be committed, which means the pre-commit guard has to learn about it, which means a second artefact to keep in step with the database — more machinery than the migration it was avoiding.

| Axis | Assessment |
| --- | --- |
| complexity | Highest of the four, in the place it is least visible. A committed sidecar becomes a second artefact the pre-commit guard has to reconcile, which is the machinery the migration was supposedly too expensive for. |

### 01-03 — How the running plugin finds its neighbours

**Decision status**: accepted  

The running plugin's directory is derived from the module's own URL and its siblings are read from the parent directory and compared as versions with the existing `parseVersion`, with the root taken as an argument rather than from the environment.

#### Sibling directory scan — chosen

The running directory comes from the module's own URL, the parent is read, and the names are compared as versions with the parser the Node floor check already uses. It depends on one property of the host — that versions are sibling directories — rather than on a file format. The root is a parameter, which is what makes it testable against a constructed directory instead of against the author's own machine.

| Axis | Assessment |
| --- | --- |
| complexity | Low in code and non-zero in coupling: it assumes the host lays versions out as sibling directories. That assumption is the thing recorded in the maintenance record under NFR5, because it is the host's to change. |
| cost | One directory read and a comparison, reusing a parser that already exists. No dependency, no schema change, no new file. |
| reversibility | High. It writes nothing and nothing persists, so it can be replaced or removed in a release without leaving anything behind to migrate. |

#### Read the host's installation registry

Not chosen now, and the route FR8 would take. It carries strictly better information — which version is current, rather than which are present — and would still detect a skew after the older sibling directories are swept. It is rejected for the first release because it is an undocumented JSON file at a path we would have to construct, owned by a component shipping on its own schedule. A weaker signal from a stabler surface is the better first move.

| Axis | Assessment |
| --- | --- |
| reversibility | High, which is why deferring it costs nothing. It reads a file and persists no state, so adopting it under FR8 later is an addition rather than a migration away from this. |

#### Query the marketplace over the network

Rejected, and foreclosed by ENVX4. It answers a different question — what has been published, rather than what is installed — and makes a local diagnostic fail differently depending on whether the machine is online.
