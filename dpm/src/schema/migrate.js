/**
 * Forward-only migration (FR12).
 *
 * **The numbered `.sql` files are the migrations.** There is no second set: a fresh database
 * is one whose recorded version is 0, so creating a schema and upgrading one are the same
 * loop over the same files, and the only difference is where it starts. Story 8 asks that
 * migrations and DDL produce an identical `sqlite_schema`; the cheapest way to be sure of
 * that is for there to be one path rather than two that have to agree.
 *
 * What that buys is narrow and worth naming: it makes divergence between the two paths
 * impossible, and it does **not** make forward-only safe on its own. Editing an already-
 * released file in place still produces two different schemas — a fresh database gets the new
 * text, an existing one keeps what it applied and never revisits it — and no comparison run
 * inside one process can see that, because both sides read the same working tree. A schema
 * change is a new file with the next number. That rule is the whole of forward-only, and it
 * is enforced by review rather than by code.
 *
 * Each migration runs in its own transaction with its `schema_version` row, so a set that
 * fails at step 9 leaves a database at version 8 rather than at some state between the two.
 * SQLite's DDL is transactional, which is what makes that available.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createRetirementGuards } from './retirement.js';
import { schemaDirectory, schemaFiles } from './files.js';

/** `007-artifacts-session.sql` → 7. */
export function versionOf(filename) {
  return Number.parseInt(filename.slice(0, 3), 10);
}

/** The bootstrap: the one file applied unconditionally, because it holds the version. */
const BOOTSTRAP = 0;

/**
 * How far this database has been migrated. 0 for one that has never been.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {number}
 */
export function currentVersion(db) {
  const present = db
    .prepare("SELECT 1 FROM sqlite_schema WHERE type = 'table' AND name = 'schema_version'")
    .get();

  if (!present) return 0;

  // `max()` over no rows is NULL, which is the freshly bootstrapped database.
  return db.prepare('SELECT max(version) AS version FROM schema_version').get().version ?? 0;
}

/** The version the plugin's files represent — what `currentVersion` becomes after a migration. */
export function targetVersion() {
  return Math.max(...schemaFiles().map(versionOf));
}

function readMigration(filename) {
  return readFileSync(join(schemaDirectory(), filename), 'utf8');
}

/**
 * Apply every migration this database has not seen, in order.
 *
 * Runs on server start with no user action, which is the requirement — so it is safe to call
 * against a database that is already current, where it applies nothing and reports as much.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {{now?: string}} [options] Timestamp recorded against each migration; injected so a
 *   test can assert what was written rather than that something was.
 * @returns {{from: number, to: number, applied: number[]}}
 */
export function migrate(db, { now = new Date().toISOString() } = {}) {
  const files = schemaFiles();

  // Unconditional and idempotent — see `000-version.sql` for why this one cannot be versioned.
  db.exec(readMigration(files.find((name) => versionOf(name) === BOOTSTRAP)));

  const from = currentVersion(db);
  const target = targetVersion();

  // **A database from a newer plugin is left exactly as it is.** Forward-only migration says
  // nothing about the backward case, and the tempting reading — there is nothing pending, so
  // carry on — is the damaging one: `createRetirementGuards` below regenerates triggers *derived
  // from the schema*, so an older server would rewrite a newer database's guards to match an
  // understanding of it that is missing tables. Seeding is the same hazard one table over. NFR7
  // asks that the user still reach their planning history, and reaching it read-only is what
  // makes that possible without an older release quietly editing a newer one.
  if (from > target) return { from, to: from, target, applied: [], guards: [], ahead: true };

  const pending = files.filter((name) => versionOf(name) > from);
  const applied = [];

  for (const name of pending) {
    const version = versionOf(name);

    db.exec('BEGIN');

    try {
      db.exec(readMigration(name));
      db.prepare('INSERT INTO schema_version (version, applied_at) VALUES (?, ?)').run(version, now);
    } catch (error) {
      db.exec('ROLLBACK');
      throw new Error(`migration ${name} failed and was rolled back: ${error.message}`, { cause: error });
    }

    db.exec('COMMIT');
    applied.push(version);
  }

  // After the DDL and outside the per-migration transactions, because the guards are derived
  // from the *finished* schema: a migration that adds a referencing column needs a guard that
  // did not exist when its own transaction opened. Regenerating the whole set rather than
  // appending to it is what makes a second run legal and what removes a guard whose reference
  // a migration dropped.
  const guards = createRetirementGuards(db);

  return { from, to: currentVersion(db), target, applied, guards, ahead: false };
}
