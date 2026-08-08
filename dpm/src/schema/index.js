/**
 * Schema application.
 *
 * The DDL lives in numbered `.sql` files next to this module rather than in template literals,
 * so it stays greppable and its diffs read as SQL. Story 5's migrations take the same form,
 * which is what lets a later story compare a migrated `sqlite_schema` against a freshly
 * created one and have the comparison mean something.
 *
 * Ordering is the filename prefix. Nothing here resolves dependencies between files: SQLite
 * resolves a foreign key at write time rather than at `CREATE`, so a forward reference to a
 * table a later file creates is legal — it simply cannot take rows until that file has run.
 *
 * One exception to "the DDL lives in the files": the retirement guards are generated from the
 * finished schema by `retirement.js`, because they are one trigger per referencing column and
 * a hand-written set is a set someone eventually forgets to extend. Story 5's migration path
 * must call the same generator for its `sqlite_schema` comparison to mean anything.
 */

import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createRetirementGuards } from './retirement.js';

const SCHEMA_DIR = import.meta.dirname;

/** `001-identity.sql` — a three-digit order prefix and a lower-case slug. */
const SCHEMA_FILE = /^\d{3}-[a-z0-9-]+\.sql$/;

/**
 * The DDL files, in application order.
 *
 * Throws rather than returning nothing: an `applySchema` that silently applied no DDL leaves
 * an empty database that every subsequent read reports as merely having no rows (NFR6).
 *
 * @returns {string[]} Filenames, sorted by their order prefix.
 */
export function schemaFiles() {
  const files = readdirSync(SCHEMA_DIR).filter((name) => SCHEMA_FILE.test(name)).sort();

  if (files.length === 0) {
    throw new Error(`no schema files found in ${SCHEMA_DIR}`);
  }

  return files;
}

/**
 * Create the schema on `db`, in one transaction.
 *
 * SQLite's DDL is transactional, so a file that fails part-way leaves an empty database
 * rather than a partial schema — a state in which some constraints hold and others are
 * merely absent, which is the hardest kind to notice.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {import('node:sqlite').DatabaseSync} The same connection, for chaining.
 */
export function applySchema(db) {
  db.exec('BEGIN');

  try {
    for (const name of schemaFiles()) {
      db.exec(readFileSync(join(SCHEMA_DIR, name), 'utf8'));
    }

    // Derived DDL, and the one part of the schema not in a `.sql` file. It runs last because
    // it reads the schema the files just created — see `retirement.js` for why the guards are
    // generated rather than written.
    createRetirementGuards(db);
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }

  db.exec('COMMIT');
  return db;
}
