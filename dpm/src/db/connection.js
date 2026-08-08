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
 */

import { DatabaseSync } from 'node:sqlite';

/**
 * Open a connection that enforces foreign keys, or fail loudly.
 *
 * @param {string} location A file path, or `:memory:`.
 * @returns {DatabaseSync}
 * @throws {Error} If the connection cannot be made to enforce foreign keys.
 */
export function openConnection(location) {
  const db = new DatabaseSync(location, { enableForeignKeyConstraints: true });

  db.exec('PRAGMA foreign_keys = ON');

  if (db.prepare('PRAGMA foreign_keys').get().foreign_keys !== 1) {
    db.close();
    throw new Error(
      `foreign key enforcement could not be enabled on ${location} — refusing to hand back ` +
        'a connection on which every foreign key in the schema is advisory',
    );
  }

  return db;
}
