/**
 * Epic 47-11 Story 1 — a runtime whose SQLite cannot maintain the schema is refused at the open.
 *
 * - "A runtime whose SQLite lacks FTS5 is refused at every database open — by all four binaries,
 *   and against a database already carrying every migration — with a message naming the capability
 *   and `process.execPath`" [integration]
 * - "must NOT — the capability is inferred from the Node version rather than probed on the
 *   connection" [unit]
 * - "The refusal is exercised with the capability forced false on a runtime that does have FTS5, so
 *   the test distinguishes the probe from the version rather than from the machine it happens to
 *   run on" [unit]
 * - "The probe answers for the connection it is handed, and answers true on the Node running the
 *   suite" [unit]
 *
 * **The already-migrated fixture is the whole of the integration criterion, not a detail of it.**
 * The field failure was a `.dpm/dpm.db` that an earlier runtime had migrated in full: every
 * migration recorded as applied, so the migration path did nothing and never ran. A test whose
 * fixture starts from an empty database would exercise the one path that was not taken.
 *
 * **And the refusal is forced rather than found.** Every machine this suite runs on has FTS5, so an
 * assertion that only fired on a machine without it would fire nowhere and report a pass. The
 * `--import` shim in `support/no-fts5.mjs` makes the capability false in the spawned process
 * without adding an override the production probe reads.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, mkdirSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { openConnection } from '../src/db/connection.js';
import { hasFts5, refusal, FTS5 } from '../src/db/capability.js';
import { openPlanningDatabase } from './support/planning-database.js';
import { runNode } from './support/run-node.js';
import { gitRepository, twoBranches } from './support/git.js';
import { start } from '../src/start.js';
import { targetVersion } from '../src/schema/migrate.js';

const ROOT = join(import.meta.dirname, '..');
const SHIM = `file://${join(ROOT, 'tests', 'support', 'no-fts5.mjs')}`;

/** The spawned runtime, with the capability forced false and nothing else changed. */
const WITHOUT = { NODE_OPTIONS: `--import=${SHIM}` };

/** A repository whose database carries every migration, as the field failure's did. */
function migrated(t) {
  const root = mkdtempSync(join(tmpdir(), 'dpm-capability-'));

  t.after(() => rmSync(root, { recursive: true, force: true }));

  const location = join(root, '.dpm', 'dpm.db');

  mkdirSync(dirname(location), { recursive: true });

  const { db } = start(location);

  // The premise, asserted rather than assumed: if `start()` left anything to apply, the migration
  // path would run on the next open and the test would be exercising a case that is not the one.
  const applied = db.prepare('SELECT max(version) AS at FROM schema_version').get().at;

  assert.equal(applied, targetVersion(), 'the fixture database is not fully migrated');

  db.close();

  return { root, location };
}

// --- Criterion 4: the probe answers for its connection ------------------------------------------

test('the probe answers for the connection it is handed, and answers true on this runtime', (t) => {
  const db = openPlanningDatabase(t);

  assert.equal(hasFts5(db), true, 'the Node running this suite reports no FTS5');

  // **It answers for the connection, not for the process.** A stub whose `exec` refuses the
  // create is a connection without the capability, and the probe says so on the same runtime that
  // just answered true — which is the distinction the must-NOT below is about.
  assert.equal(hasFts5({ exec: () => { throw new Error('no such module: fts5'); } }), false);

  // **And it leaves nothing behind, in both of the ways that matters.** It writes nothing to the
  // main schema, because it runs at every open including opens that were never going to write —
  // and it is repeatable on one connection, because `openConnection` probes and then hands the
  // connection on, so a probe that left its table in place would answer false the second time it
  // was asked and report a capable runtime as incapable.
  const before = db.prepare('SELECT count(*) AS n FROM sqlite_schema').get().n;

  assert.equal(hasFts5(db), true, 'the probe is not repeatable on a connection it already answered for');
  assert.equal(db.prepare('SELECT count(*) AS n FROM sqlite_schema').get().n, before);

  // A read-only connection answers too, because some opens are read-only and all of them probe.
  const file = migrated(t);
  const readOnly = new DatabaseSync(file.location, { readOnly: true });

  t.after(() => readOnly.close());

  assert.equal(hasFts5(readOnly), true, 'the probe cannot answer on a read-only connection');
});

// --- Criterion 3 and the must-NOT: forced false, and never read off the version ------------------

test('the refusal fires on a forced-false probe, on a runtime that has the capability', (t) => {
  // The control first: this runtime *does* have FTS5, so a refusal below is attributable to the
  // probe. Without this the test could not tell a working refusal from a machine that lacks it.
  const real = openConnection(':memory:');

  t.after(() => real.close());

  assert.equal(hasFts5(real), true);

  let refused;

  try {
    openConnection(':memory:', { probe: () => false }).close();
  } catch (error) {
    refused = error;
  }

  assert.ok(refused, 'a connection was handed back on a runtime that cannot maintain the schema');
  assert.match(refused.message, new RegExp(FTS5), 'the refusal does not name the capability');
  assert.match(refused.message, new RegExp(process.execPath.replaceAll(/[.*+?^${}()|[\]\\]/g, '\\$&')),
    'the refusal does not name the interpreter, which is the hour the field diagnosis cost');

  // **must NOT — the capability is inferred from the Node version.** Asserted on the decision
  // itself: `hasFts5` reaches its answer without consulting `process` at all. `refusal()` names the
  // version and the path, which is reporting rather than deciding, and sits outside this slice.
  // The function body alone, not everything up to the next export — the comment on `refusal`
  // names `process.execPath` in prose, and a slice that reached it would fail on the explanation.
  const source = readFileSync(join(ROOT, 'src', 'db', 'capability.js'), 'utf8');
  const opens = source.indexOf('export function hasFts5');
  const decision = source.slice(opens, source.indexOf('\n}\n', opens));

  assert.ok(decision.length > 0 && decision.length < 600, 'the slice did not land on the function body');

  assert.ok(decision.includes('CREATE VIRTUAL TABLE'), 'the probe no longer creates the table');
  assert.equal(/process\./.test(decision), false,
    'the probe reads something off `process` — the version is not the connection');
  assert.match(refusal(':memory:'), /v\d+\./, 'the refusal stopped reporting the version');
});

// --- Criterion 1: all four binaries, against a fully-migrated database ---------------------------

test('all four binaries refuse to open a database on a runtime without FTS5', async (t) => {
  const file = migrated(t);
  const bin = (name) => join(ROOT, 'bin', name);
  const listTools = `${JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'tools/list' })}\n`;

  // `dpm-merge` is the one that needs more than a database: it reads the conflicted dump out of
  // git, and without a merge in progress it exits before it ever opens anything.
  const repo = gitRepository(t);
  const conflict = twoBranches(repo, {
    ours: (db, call) => call.create_spec({ slug: 'ours', title: 'Ours' }),
    theirs: (db, call) => call.create_spec({ slug: 'theirs', title: 'Theirs' }),
  });

  assert.equal(conflict.conflicted, true, 'the fixture produced no conflict, so merge would exit early');

  const runs = [
    ['dpm-guard.js', [bin('dpm-guard.js'), file.root], '', { DPM_DATABASE: file.location }],
    ['dpm-publish.js', [bin('dpm-publish.js'), file.root], '', { DPM_DATABASE: file.location }],
    ['dpm-merge.js', [bin('dpm-merge.js'), repo.root], '', {}],
    ['dpm-mcp.js', [bin('dpm-mcp.js')], listTools, { DPM_DATABASE: file.location }],
  ];

  for (const [name, args, input, env] of runs) {
    const refused = await runNode(args, input, { ...env, ...WITHOUT });
    const said = refused.stdout + refused.stderr;

    assert.notEqual(refused.code, 0, `${name} exited 0 on a runtime that cannot maintain the schema`);
    assert.match(said, new RegExp(FTS5), `${name} refused without naming the capability`);
    assert.match(said, new RegExp(process.execPath.replaceAll(/[.*+?^${}()|[\]\\]/g, '\\$&')),
      `${name} refused without naming the interpreter`);

    // **The control, per binary.** The same invocation on the unshimmed runtime must not produce
    // this refusal — otherwise the assertion above is satisfied by a binary that is simply broken.
    const allowed = await runNode(args, input, env);

    assert.equal(new RegExp(FTS5).test(allowed.stdout + allowed.stderr), false,
      `${name} names ${FTS5} even on a runtime that has it, so the refusal above proves nothing`);
  }
});
