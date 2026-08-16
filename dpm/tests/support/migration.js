/**
 * Databases from before the current release.
 *
 * Every vocabulary-evolution criterion in Story 5 is about what an *upgrade* does, and an
 * upgrade needs a database that predates it. A test that builds the new state directly and
 * then checks the new state asserts nothing about the path between them — so the shape here
 * is always: build an old database, close it, start it again with a release description that
 * differs, and read what changed.
 *
 * It lives in `support/` because it opens databases and applies DDL, which is the harness's
 * job rather than a fixture's.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { openDatabaseFile } from './database.js';
import { schemaDirectory, schemaFiles } from '../../src/schema/files.js';
import { versionOf } from '../../src/schema/migrate.js';
import { createRetirementGuards } from '../../src/schema/retirement.js';

/**
 * The highest schema version below the one this server migrates to.
 *
 * Derived from the files rather than written down, for the same reason `targetVersion` is: a test
 * pinning "the previous version" to a number goes stale on the next migration while continuing to
 * pass, having quietly become a test about some particular older release.
 *
 * @returns {number}
 */
export function previousVersion() {
  return schemaFiles().map(versionOf).sort((a, b) => a - b).at(-2);
}

/**
 * A temp-file database carrying the schema as of `version`, and nothing later.
 *
 * The DDL is applied and recorded by hand rather than by calling `migrate`, which is the
 * point: `migrate` always brings a database to the current version, so a test that used it to
 * build its starting state would have no earlier state to upgrade from. The guards are
 * derived at the old version too, so the count they reach afterwards is a real change.
 *
 * @param {import('node:test').TestContext} t
 * @param {number} version
 * @returns {{path: string, connect: () => import('node:sqlite').DatabaseSync}}
 */
export function databaseAtVersion(t, version) {
  const file = openDatabaseFile(t);
  const db = file.connect();

  for (const name of schemaFiles().filter((filename) => versionOf(filename) <= version)) {
    db.exec(readFileSync(join(schemaDirectory(), name), 'utf8'));

    if (versionOf(name) > 0) {
      db.prepare('INSERT INTO schema_version (version, applied_at) VALUES (?, ?)')
        .run(versionOf(name), '2026-01-01T00:00:00Z');
    }
  }

  createRetirementGuards(db);
  db.close();

  return file;
}

/**
 * The shipped vocabulary with one table's rows replaced — a stand-in for the next release.
 *
 * Takes the real `VOCABULARIES` and substitutes, rather than letting a test hand-write a list:
 * a test whose "release" carried only the table it cares about would upgrade a database into a
 * state where every other vocabulary had been dropped from the release, and would then be
 * asserting against a release that could never ship.
 *
 * @param {{table: string, rows: object[]}[]} vocabularies
 * @param {string} table
 * @param {(rows: object[]) => object[]} change
 */
export function release(vocabularies, table, change) {
  return vocabularies.map((vocabulary) =>
    vocabulary.table === table ? { table, rows: change(vocabulary.rows) } : vocabulary);
}
