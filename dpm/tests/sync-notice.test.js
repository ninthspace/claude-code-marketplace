/**
 * Quick 15 — a database behind the dump beside it is served without a word.
 *
 * `verdict()` could always answer this and only the pre-commit guard ever asked, so the detection
 * lived on a surface reached deliberately at the end of a piece of work. A session opened a database
 * three weeks behind the repository, answered every read from it, and reported that a spec's seven
 * epics did not exist. Nothing failed: the reads succeeded and agreed with each other, which is what
 * makes this class of defect invisible from inside the run that has it.
 *
 * **The quiet case is tested by making the database unusable**, which is the only way to assert that
 * something was not consulted. A spy counting calls asserts that *this* implementation did not dump;
 * a `null` connection asserts that no implementation could have, and it keeps holding when someone
 * reaches the database by a route this test has never seen. Its control is the noisy case driven the
 * same way, which must throw — without that, a `syncState` that returned `null` unconditionally
 * would pass the cheapness criterion perfectly.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { IMPORT_COMMAND, MERGE_COMMAND, PUBLISH_COMMAND, guard } from '../src/guard/index.js';
import { report } from '../src/rebuild/index.js';
import { syncState } from '../src/server/sync-check.js';
import { markerBeside, readMarker } from '../src/sync/marker.js';
import { behind, syncNotice } from '../src/sync/notice.js';
import { VERDICT } from '../src/sync/verdict.js';
import { BIN, HELLO, call, wire } from './support/session.js';
import { publishedRepository, pull } from './support/published.js';
import { runNode } from './support/run-node.js';

/** A settled, published repository — dump, database and marker all in agreement. */
const repository = (t) => publishedRepository(t, 'dpm-sync-notice-');

// --- Criterion 1: a database behind the dump beside it is reported -------------------------------

test('a database the dump has moved past is reported, naming the import [unit]', (t) => {
  const repo = repository(t);

  // **The premise, established from the guard rather than assumed.** If this is not the state a
  // pull leaves, whatever the check then says is not the thing the criterion is about.
  pull(repo.root);

  assert.equal(guard(repo.db, { root: repo.root }).verdict, VERDICT.dumpMoved,
    'the fixture is not the pulled state, so the notice below is about something else');

  const notice = syncState(repo.db, repo.location);

  assert.ok(notice, 'a database behind the dump beside it was reported as nothing at all');

  // The command has to be the resolved path the guard names, and it has to be on disk: a
  // diagnostic naming a file that is not there looks like help and sends the reader nowhere.
  assert.ok(notice.includes(IMPORT_COMMAND), `the notice does not name the import:\n${notice}`);
  assert.ok(notice.includes('.dpm'), `the notice does not name the dump:\n${notice}`);
});

// --- Criterion 2: a settled repository stays silent ----------------------------------------------

test('a database that agrees with the dump beside it says nothing [unit]', (t) => {
  const repo = repository(t);

  assert.equal(syncState(repo.db, repo.location), null,
    'a settled repository was told something about its sync state at open');

  // **Local unpublished work is silent too, and it is the case most easily got wrong.** It is the
  // ordinary middle of a session, the pre-commit guard already stands between it and a commit, and
  // a check that spoke here would speak on nearly every open — which is how a diagnostic stops
  // being read.
  repo.call.create_spec({ slug: 'written-since-the-last-publish', title: 'Written since' });

  assert.equal(guard(repo.db, { root: repo.root }).verdict, VERDICT.databaseMoved,
    'the fixture is not the locally-edited state');
  assert.equal(syncState(repo.db, repo.location), null,
    'unpublished local work was reported as the database being behind');
});

// --- Criterion 3: the quiet case does not dump the database --------------------------------------

test('a settled repository is answered without the database being read [unit]', (t) => {
  const repo = repository(t);

  // `null` cannot be dumped, prepared against or closed. Answering at all proves the database was
  // never reached — for this implementation and for any other.
  assert.equal(syncState(null, repo.location), null,
    'the quiet case reached the database, which it cannot do cheaply');

  // **The control.** Without it the assertion above is satisfied by a check that consults nothing
  // ever and returns `null` to everybody, which would pass criterion 3 and fail the reason it
  // exists. The expensive branch must genuinely need what the cheap one declined to take.
  pull(repo.root);

  assert.throws(() => syncState(null, repo.location),
    'the divergent case answered without the database, so the cheap path proves nothing');
});

// --- The dump is the file beside the database, and absence is not this check's business ----------

test('a database with no dump beside it is not reported on [unit]', (t) => {
  const repo = repository(t);
  const dump = join(repo.root, '.dpm', 'dpm.sql');
  const held = readFileSync(dump, 'utf8');

  writeFileSync(dump, '', 'utf8');

  // An empty file is a dump that differs, so this reaches the expensive branch and says something.
  assert.ok(syncState(repo.db, repo.location), 'a dump emptied under the database said nothing');

  writeFileSync(dump, held, 'utf8');

  // Absent is different: `from-dump.js` owns that case, there is nothing to attribute, and a server
  // whose diagnostic cannot be computed has no business saying anything about the database.
  assert.equal(syncState(repo.db, repo.location, { read: () => { throw new Error('gone'); } }), null,
    'an unreadable dump produced a report about the database');
});

// --- Which verdicts speak, and what each of them says --------------------------------------------

test('only the verdicts meaning the database may be behind speak [unit]', () => {
  // Every one of the six, named individually rather than looped over `VERDICT`, so adding a state
  // to that object fails here instead of being silently absorbed into whichever branch it lands in.
  assert.equal(behind(VERDICT.clean), false);
  assert.equal(behind(VERDICT.adopt), false);
  assert.equal(behind(VERDICT.databaseMoved), false);
  assert.equal(behind(VERDICT.dumpMoved), true);
  assert.equal(behind(VERDICT.bothMoved), true);
  assert.equal(behind(VERDICT.unknown), true);

  assert.deepEqual(Object.values(VERDICT).length, 6,
    'a verdict was added and this test did not learn whether it speaks');

  const dump = '.dpm/dpm.sql';

  // Each speaking verdict names its own remedy. One sentence for all three would send a reader who
  // had both artefacts move to an import that discards the half only they have.
  assert.ok(syncNotice(VERDICT.dumpMoved, dump).includes(IMPORT_COMMAND));
  assert.ok(syncNotice(VERDICT.bothMoved, dump).includes(MERGE_COMMAND));

  // **`unknown` names both and chooses neither**, because with no sync point nothing says which
  // side moved and each repair discards the other. A single command here would be a guess with a
  // diagnosis's authority, which is the failure this whole check exists to remove.
  const unknown = syncNotice(VERDICT.unknown, dump);

  assert.ok(unknown.includes(IMPORT_COMMAND) && unknown.includes(PUBLISH_COMMAND),
    `the no-sync-point verdict does not name both fixes:\n${unknown}`);

  for (const silent of [VERDICT.clean, VERDICT.adopt, VERDICT.databaseMoved]) {
    assert.equal(syncNotice(silent, dump), null, `${silent} composed a sentence`);
  }
});

// --- The marker is found from the database, not from a repository root ---------------------------

test('the marker is the database path suffixed, so an override finds its own [unit]', (t) => {
  const repo = repository(t);

  assert.equal(markerBeside(repo.location), `${repo.location}.synced`);

  // Read back through the path route and the root route, which must be the same file: a server that
  // found the marker by joining a repository root would read the default project's marker while
  // serving a database `DPM_DATABASE` had pointed somewhere else entirely.
  assert.equal(readMarker({ path: markerBeside(repo.location) }), readMarker({ root: repo.root }));
  assert.ok(readMarker({ path: markerBeside(repo.location) }), 'publish wrote no marker');
});

// --- Criterion 4: the restart warning has a control that can fire --------------------------------

test('a rebuild names the server restart where the old proxy never could [unit]', (t) => {
  const repo = repository(t);

  // The state that made the warning unreachable, asserted rather than described: nothing in dpm
  // sets WAL journal mode, so this file is never created and the old `existsSync` guard was false
  // on every rebuild dpm has ever run — including one performed while a server held the database.
  assert.equal(readFileSync(repo.location).length > 0, true);
  assert.equal(
    repo.db.prepare('PRAGMA journal_mode').get().journal_mode.toLowerCase() === 'wal', false,
    'dpm now uses WAL, so the removed proxy was not unreachable after all',
  );

  const lines = report({ removed: [] }, { stage: 'git add docs' });

  assert.ok(lines.some((line) => /restart/i.test(line)),
    `a rebuild's report does not mention restarting a server:\n${lines.join('\n')}`);
});

// --- The line reaches a real session's stderr ----------------------------------------------------

test('a spawned server reports a stale database on stderr, and a settled one does not [integration]',
  async (t) => {
    const repo = repository(t);

    pull(repo.root);

    const stale = await runNode([BIN], wire([HELLO, call(2, 'list_spec')]),
      { DPM_DATABASE: repo.location });

    assert.equal(stale.code, 0, `the server exited ${stale.code}: ${stale.stderr}`);
    assert.ok(stale.stderr.includes(IMPORT_COMMAND),
      `a session against a stale database said nothing about it:\n${stale.stderr}`);

    // **The control, and it is the one that matters most.** A line printed on every open is a line
    // nobody reads, and this check's whole value is that its appearance is news.
    const settled = repository(t);
    const quiet = await runNode([BIN], wire([HELLO, call(2, 'list_spec')]),
      { DPM_DATABASE: settled.location });

    assert.equal(quiet.code, 0, `the server exited ${quiet.code}: ${quiet.stderr}`);
    assert.equal(quiet.stderr.includes(IMPORT_COMMAND), false,
      `a settled repository was told its database was behind:\n${quiet.stderr}`);
  });
