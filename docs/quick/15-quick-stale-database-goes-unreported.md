# A database behind the dump beside it is served without a word

**Number**: 15  
**Status**: complete — Closed 2026-09-21 with all seven criteria met. Released as 0.7.8. The plugin-stamp interaction with the sync marker is recorded here and deliberately not fixed — it needs a decision about when the stamp is written or what the marker covers, and both are accepted decisions.  

**Closed**: 2026-09-21T17:05:00Z  

## What went wrong, and what it cost

`/dpm:do` was invoked, read the local database, and reported that every epic of every spec was complete — so there was no work to pick up. The database it read held four specs. The dump beside it, and `docs/`, held five: specification 05 and its seven epics, 32 stories and 77 tasks were missing entirely, along with two discussions, a library document, five quick records and a retro.

Nothing in that run failed. Every read succeeded and returned a smaller corpus than the one the repository holds, and the answer produced from them was internally consistent. The divergence was found only because the run was then asked to look at the branch.

`.dpm/dpm.db.synced` recorded the dump at commit `265ec67`, 30 August. Everything after that arrived by `git pull`, which rewrites `.dpm/dpm.sql` and leaves the database alone; the database had taken no write of its own in three weeks. Every document id in it was present in the dump, so nothing local was at risk and the repair was a plain rebuild — but nothing said so until the guard was run by hand.

The branch this surfaced on was authored on another machine. That is the ordinary way for the dump to move: it is the committed form, it travels, and the database does not.

## The change

**A server reports a database that no longer matches the dump beside it.** `open()` already logs the stamp skew at the moment the database is opened, and that is where this joins it. `src/sync/verdict.js` is used exactly as it stands — it is already a pure function over three hashes returning six states, and until now only the guard called it. A composer beside it holds the prose, the way `skew.js` holds prose for the two detectors that share it.

The check stays cheap in the case that is almost always the one: hash the dump file and compare it against the marker. Only when those differ is the database's own dump needed, to tell `dump-moved` from `both-moved` from `unknown`. So a settled repository pays one file hash at open and nothing else.

Only the verdicts that mean *the database is behind* speak. `clean`, `adopt` and `database-moved` are silent, following the rule already written into `open()` for the stamp: a clean session is silent, which is what makes a line that does appear worth reading. Local unpublished work is the ordinary mid-session state and the pre-commit guard already covers it.

**The restart warning gets a control that can fire.** The line was already written, guarded by the existence of `.dpm/dpm.db-wal`. Nothing in dpm sets WAL journal mode, so that file is never created and the warning had never fired — including on the rebuild in this very incident, where a server was holding the old database open. Both callers of the rebuild rename a new file into place and a live server always keeps the old inode, so the line becomes unconditional rather than acquiring a second proxy that might also turn out never to be true.

## The stamp moves the database off its own marker, and this does not fix it

The sync marker exists to say *which side moved*, and a plugin upgrade defeats it.

`plugin_stamp` held `0.7.0` in the dump the marker hashes; it holds `0.7.7` now. The stamp is written on a strict version increase, so the upgrade between those two releases wrote a row into the local database that no user asked for and no skill called for. That write moved the database off the sync point.

The consequence is a worse diagnosis, not a worse database. In this incident the true state was `dump-moved`, whose remedy is one word — import. What the guard actually reported was `both-moved`: *neither side matches the sync point, reconcile deliberately*, which is the one verdict that names no single fix. A user reading it has been told to be careful about a situation that was not delicate.

It is reachable by any repository that upgrades the plugin and then pulls, which is the normal course of events rather than an edge. The stamp module's own reasoning anticipates the tension — it rejects writing on every start precisely because that would diverge the committed dump every session — and solves it for repeated starts at one version. An upgrade is the case the condition lets through, and it only has to happen once for the marker to stop being able to attribute anything.

Fixing it means changing when the stamp is written, or what the marker covers. Both are accepted decisions with their own reasoning, and revising one of them is not something to do on the way past while fixing something else. Recorded here with its evidence so the next reader has it.

## This was recorded before, and nothing was built from it

Retro 09, *A read that succeeds is not a read that is right*, carries an observation from 2 September describing the post-import half of this in full: that a running server keeps serving the file the rebuild replaced, that the reads are the dangerous half because they succeed, that the writes come back as a bare `Internal error` which reads as a broken server rather than a stale handle, and that the import's closing line could as usefully say the server must be restarted.

Every one of those was observed again today, in the same order.

The same retro carries a second observation, of a database found rolled back to a mid-August state with the cause never established, caught only by the pre-commit guard refusing 39 files. It is the reason the criteria here cover detection at server start and not only the import's own exit: that incident had no import to hang a message on, and a check that only fires on the repair path would have missed it.

The retro's own synthesis names the lesson this record acts on — that a run has no cheap way to know its inputs are current, so the checks that do compare should be moved earlier or their absence treated as a known blind spot. Moving one of them earlier is what the change above does.

## What shipped, and what the suite found on the way

`sync/notice.js` decides which verdicts are worth saying out loud and composes the sentence for each; `server/sync-check.js` decides what the verdict is and is called from `open()`, one line below the stamp skew it sits beside. `sync/marker.js` gained a way to find a marker from the database rather than from a repository root, because the server knows where the database is and `DPM_DATABASE` can put it anywhere — a marker found by joining a root would be read from the default project while serving another, which is a comparison that answers rather than fails.

The restart warning in `rebuild/index.js` became unconditional, and the `root` option it needed for its unreachable probe came out of the signature and both call sites with it.

**The suite found a false alarm that the design had not.** A session that restores the database from the dump beside it has no sync marker, so the check reported *no sync point records which of them moved* on the first open of every fresh clone — telling the reader that a database built moments earlier from that very file might be behind it. `restore-on-create.test.js` failed on the second line of stderr where it expected one, which is the assertion catching it rather than anybody noticing. The check is now skipped where a restore has just answered the question.

That is worth reading beside what this record fixes. The line exists so that an unusual state is not silent, and a line printed on an ordinary one costs exactly what the silence cost: a reader who stops reading it.

Eight tests in `tests/sync-notice.test.js`, 981 in the suite, all passing. Both new checks were mutated away and both mutants were killed.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A server opened on a database whose dump differs from the `.dpm/dpm.sql` beside it says so on stderr, and the sentence names `dpm-import` as the way out. | A spawned server against a pulled repository writes the line to stderr and it carries the resolved import command; asserted in `tests/sync-notice.test.js` as an integration test through `bin/dpm-mcp.js` rather than against the function, so the wiring is covered and not only the composer. The two verdicts beyond dump-moved name their own remedy instead — merge for both-moved, and for a repository with no sync point both commands with the choice left to the reader, since nothing there says which side moved and each repair discards the other. |
| ✓ | A server opened on a database that agrees with the dump beside it says nothing about the sync state, so a settled repository stays silent at open. | Silent in all three states that are not a stale database: a settled repository, one carrying unpublished local work, and — found by the suite rather than by design — a session that has just restored the database from the dump beside it. That third one was reported as unknown on the first open of every fresh clone, telling the reader a database built moments earlier from that very file might be behind it; `restore-on-create.test.js` caught it, and the check is now skipped where the restore already answered the question. The spawned control asserts a settled repository's stderr carries nothing. |
| ✓ | The quiet case costs one hash of the dump file and does not dump the database. | The marker records the dump text at the last agreement, so comparing it against the file on disk rules out all three reportable verdicts from one file read — each of them requires the file to differ from the marker. Asserted by passing a null connection: a settled repository is answered without it, which proves the database was unreachable rather than merely unused by this implementation. Its control is the divergent case driven the same way, which throws — without that, a check returning null to everybody would pass this criterion perfectly. |
| ✓ | A rebuild's closing report names the server restart in a repository that has no `.dpm/dpm.db-wal` — the state that made the existing warning unreachable, since nothing in dpm sets WAL journal mode and that file is therefore never created. | The line is now unconditional and a test reads it back from a repository in the state that made the old guard false — which is every repository, since the journal mode is asserted not to be WAL rather than described as such. Removing the line fails that test. The `root` option on the report became unused with the proxy and was taken out of the signature and both call sites, so nothing is left documented as needed that is not. |
| ✓ | Removing either new check makes a test fail, so neither is a green over a check that is not running. | Both mutants run and both killed. Replacing the startup call with a constant null fails the spawned-server test; deleting the restart line fails the rebuild report test. The restore-silence branch has a killer too, in `restore-on-create.test.js`, which is the test that found the need for it. |
| ✓ | The record carries a section naming the plugin-stamp interaction with the sync marker, with its evidence, stated as a limitation this change deliberately does not fix. | Recorded as its own section, with the two stamp values that evidence it and the reason the fix is not taken here. |
| ✓ | The plugin version moves to 0.7.8 across every site the version consistency test pins, and that test passes. | Four sites, not three: the marketplace entry, the plugin manifest and the package manifest are the ones the consistency test pins, and the README's heading states the version too and is pinned by nothing. Found by looking rather than by a failing test, which is the gap worth noting — the suite would have stayed green on a README a release behind. |
