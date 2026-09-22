/**
 * Epic 05-07 Story 5 — this change set adds no schema migration (NFR5).
 *
 * **Not a box to tick.** A migration serves this project's own database read-only to the installed
 * server until the plugin is reinstalled: DPM reads work and every write is refused, by design and
 * reported exactly as designed. So a difference here is a decision to raise, and NFR5 says as much
 * — *"where a requirement turns out to need one, it is raised rather than absorbed"*.
 *
 * The comparison is between the schema this tree targets and the schema the committed corpus
 * records, both measured rather than asserted. Six epics in this spec have each broken a different
 * number of things than predicted; this one asks what the number is.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readdirSync } from 'node:fs';
import { targetVersion } from '../src/schema/migrate.js';

const PACKAGE = new URL('../', import.meta.url).pathname;
const SCHEMA = new URL('../src/schema/', import.meta.url).pathname;

/** The last commit before this change set. */
const BEFORE = 'c0e3814';

/** A `git` read against the repository this package sits in. */
const git = (...args) => execFileSync('git', args, {
  cwd: PACKAGE,
  maxBuffer: 32 * 1024 * 1024,
}).toString();

/** The numbered migration files a tree carries, by their own names. */
const migrations = (names) => names.filter((name) => /^\d{3}-.*\.sql$/.test(name)).sort();

// --- The criterion: the number did not move -------------------------------------------------------

test('the schema this tree targets is the one the corpus before it recorded [integration]', () => {
  // **The version the code will migrate a database to**, read from the module rather than from a
  // constant restated here — a second copy would agree with itself after the first one moved.
  const target = targetVersion();

  // The highest version the committed corpus records as applied. That dump was written before this
  // change set, so it is what the previous release left behind.
  const recorded = Math.max(...[...git('show', `${BEFORE}:.dpm/dpm.sql`)
    .matchAll(/INSERT INTO "schema_version" \("version", "applied_at"\) VALUES \((\d+),/g)]
    .map(([, version]) => Number(version)));

  assert.ok(Number.isFinite(recorded) && recorded > 0,
    'no schema_version rows were read from the committed dump');

  assert.equal(target, recorded,
    `this tree targets schema ${target} and the corpus before it recorded ${recorded} — `
    + 'a migration serves this project read-only to the installed server until it is reinstalled, '
    + 'so this is a decision to raise rather than a difference to absorb');
});

test('no migration file was added, removed or renamed by this change set [integration]', () => {
  const now = migrations(readdirSync(SCHEMA));
  const before = migrations(git('ls-tree', '--name-only', BEFORE, 'src/schema/')
    .split('\n')
    .map((path) => path.split('/').pop()));

  // **Named rather than counted**, because a count is satisfied by one file arriving as another
  // leaves — which is exactly what a renumbered migration looks like.
  assert.deepEqual(now, before);

  // The bound on the reading: both sides found migrations, so an equality between two empty lists
  // is not what passed.
  assert.ok(now.length >= 20, `only ${now.length} migration files were read from the tree`);
});

test('the schema files this change set touched are none [integration]', () => {
  // **The strongest form of the claim, and the cheapest**: a migration is a file, so if no file
  // under `src/schema/` changed then no migration was added however the versions happen to read.
  const touched = git('diff', '--name-only', BEFORE, '--', 'src/schema/')
    .split('\n')
    .filter(Boolean);

  assert.deepEqual(touched, []);

  // The control on the diff: it does see this change set, so an empty answer above is about
  // `src/schema/` rather than about a range that resolves to nothing.
  const elsewhere = git('diff', '--name-only', BEFORE, '--', 'src/')
    .split('\n')
    .filter(Boolean);

  assert.ok(elsewhere.length >= 5,
    `the diff against ${BEFORE} reports only ${elsewhere.length} changed files under src/`);
});
