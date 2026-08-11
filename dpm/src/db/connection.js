/**
 * Connection setup (FR2).
 *
 * `PRAGMA foreign_keys` is **per-connection**, not a property of the file, so a schema full
 * of foreign keys constrains nothing on a connection that opened without it. That is entry
 * #7 in the false-pass register — every foreign key in the schema becomes advisory, silently
 * — and it is closed here rather than at the tool layer, because a rule the caller has to
 * remember on each connect is one that will eventually be forgotten on one.
 *
 * Three things are done where one would appear to be enough, and each covers a different way
 * of being wrong:
 *
 * 1. The constructor option, because it is the only setting that applies to the connection
 *    from the moment it exists.
 * 2. The explicit `PRAGMA`, because AD5 takes an experimental API and NFR2 says its
 *    behaviour may move between minors; inheriting a default is not enforcing anything.
 * 3. A read-back, because both of the above can be accepted and ignored. NFR6 is that any
 *    condition which could produce a false pass reports and blocks, and a connection that
 *    quietly failed to enable the pragma is that condition exactly.
 *
 * **The FTS5 refusal is here for the same reason, and it has to be at the open rather than at the
 * migration.** The condition was found in the field with a database an earlier runtime had already
 * migrated in full: `schema_version` recorded every migration as applied, so the migration path —
 * the only other candidate for the check — correctly did nothing and never ran. Every binary
 * reaches this function, which is what makes "at every open" a property of the code rather than of
 * four call sites someone has to keep remembering.
 */

import { DatabaseSync } from 'node:sqlite';
import { hasFts5, refusal } from './capability.js';

/**
 * Open a connection that enforces foreign keys and can maintain the schema, or fail loudly.
 *
 * `probe` is injectable so a runtime that *does* carry FTS5 can still exercise the refusal. Without
 * it the refusal is only testable on a machine that lacks the capability, which means it is tested
 * nowhere and the assertion would be distinguishing the machine rather than the probe.
 *
 * @param {string} location A file path, or `:memory:`.
 * @param {object} [options]
 * @param {(db: DatabaseSync) => boolean} [options.probe] Answers whether this connection has FTS5.
 * @returns {DatabaseSync}
 * @throws {Error} If the connection cannot enforce foreign keys, or its SQLite has no FTS5.
 */
export function openConnection(location, { probe = hasFts5 } = {}) {
  const db = new DatabaseSync(location, { enableForeignKeyConstraints: true });

  db.exec('PRAGMA foreign_keys = ON');

  if (db.prepare('PRAGMA foreign_keys').get().foreign_keys !== 1) {
    db.close();
    throw new Error(
      `foreign key enforcement could not be enabled on ${location} — refusing to hand back ` +
        'a connection on which every foreign key in the schema is advisory',
    );
  }

  if (!probe(db)) {
    db.close();
    throw new Error(refusal(location));
  }

  return db;
}
