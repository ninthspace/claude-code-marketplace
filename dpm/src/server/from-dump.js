/**
 * Restoring the committed dump into a database that does not exist yet (FR6, AD14).
 *
 * The README has said since it was written that `.dpm/dpm.sql` is what a checkout restores from,
 * and until now nothing performed it — `restore()` was reachable only from the conflicted-merge
 * path, so a fresh clone got an empty database beside a dump full of rows. Deferring the create
 * (49-01) is what makes this placeable: the first open is now a decision point rather than
 * something that already happened at launch.
 *
 * **Only when there is no database, and that asymmetry is the whole of AD14.** Restoring into
 * nothing can lose nothing, so it needs no confirmation and gets none; restoring *over* an
 * existing database can lose everything in it, so this never does it, whatever the dump says. A
 * user who wants that asks for it through the import path, which is a different thing with
 * different protections.
 *
 * **AD14 has a third case, and the paragraph above is what makes it easy to get wrong: under a
 * read-only server, never** (spec 49, FR12). The safety argument for the automatic restore rests
 * on the caller — someone who asked dpm to open their planning database and was going to use it,
 * for whom a restore is the outcome they wanted. An observer asked for none of that: spec 48's
 * board opens projects it does not own, and a restore is a write, so it is out of bounds there
 * however empty the directory is and however plainly the dump says what belongs in it. Nothing in
 * this function enforces that, deliberately — `open()` returns above the call site, so the
 * suppression is a property of where the read-only branch sits rather than a condition here that
 * a caller could forget to pass.
 *
 * **`restore()` alone — deliberately not the staging-file-and-rename sequence** `merge/main.js`
 * uses. Those protections exist to keep a live database intact while an uncertain restore runs
 * against a scratch file. Here there is no live database: the file this creates did not exist a
 * moment ago and holds nothing anyone could want. Reusing the sequence would be harmless and
 * misleading, and the next reader would take the protections as evidence something was at risk.
 *
 * **What is kept from that sequence is the failure behaviour, for a reason specific to this
 * path.** `restore()` rolls back so that a failed restore changes nothing — but opening the
 * connection has already created the file, and a file that exists is exactly what stops this
 * function running next time. Left behind, a bad dump would produce one error and then an empty
 * database, silently, forever. So a failed restore removes what it created and re-throws, and the
 * next session tries again and reports the same fault.
 */

import { existsSync, readFileSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { openConnection } from '../db/connection.js';
import { restore as restoreDump } from '../restore/index.js';

/**
 * The dump's name inside the database's directory.
 *
 * Derived from the database's own location rather than taken from `guard/index.js`'s repo-relative
 * `DUMP_PATH`, because `DPM_DATABASE` can point the database anywhere and the dump is defined by
 * AD4 as the file *beside* it. A constant here would be right for the default and wrong for every
 * override.
 */
export const DUMP_FILE = 'dpm.sql';

/**
 * Restore the dump beside `location` into it, if and only if `location` does not exist.
 *
 * Runs before `start()` rather than against the connection it returns: the dump carries its own
 * `CREATE TABLE` statements, so it needs a database with no schema, and `start()` migrates and
 * seeds. The restored file is then opened by `start()` in the ordinary way, which is what brings
 * an older dump's schema forward — a clone of a branch behind this server gets migrated on first
 * open exactly as a database committed at that version would be.
 *
 * @param {string} location A file path, or `:memory:`.
 * @param {object} [options]
 * @param {typeof restoreDump} [options.restore] Injected alongside `open()`'s other seams so the
 *   *order* of the three is observable: the story's must-NOT is a condition-and-ordering claim,
 *   and a test that read the rows afterwards would pass whether the restore ran in the right
 *   place, the wrong place, or not at all.
 * @param {typeof openConnection} [options.connect]
 * @returns {boolean} Whether a restore ran, so the caller can report the unusual case (FR10).
 */
export function restoreIfMissing(
  location, { restore = restoreDump, connect = openConnection } = {},
) {
  if (location === ':memory:' || existsSync(location)) return false;

  const dump = join(dirname(location), DUMP_FILE);

  if (!existsSync(dump)) return false;

  const db = connect(location);

  try {
    restore(db, readFileSync(dump, 'utf8'));
  } catch (error) {
    db.close();
    rmSync(location, { force: true });

    throw error;
  }

  db.close();

  return true;
}
