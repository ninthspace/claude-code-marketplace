/**
 * Asking, at open, whether this database is still the one the repository committed.
 *
 * The check the pre-commit guard has always run, moved to the one place every session passes
 * through. `sync/notice.js` decides what to say about a verdict; this decides what the verdict is,
 * and the split is the one `skew.js` keeps from its detectors — a composer that could also detect
 * is one a caller can get an answer from without running the check that produces it.
 *
 * **The quiet case does not dump the database, and that is the whole design.** Hashing a dump means
 * generating one, which for a real corpus is the most expensive thing a server could do at startup;
 * a check that cost that on every open would be a check somebody turned off. But the marker records
 * *the dump text* at the last agreement, so comparing it against the file on disk answers "has the
 * dump moved since we last agreed" from one file read — and when it has not, neither `dump-moved`
 * nor `both-moved` nor `unknown` is reachable, because all three require the file to differ from the
 * marker. The database is dumped only once something is already known to be wrong.
 *
 * **A missing dump is not this check's business.** `from-dump.js` runs before `start()` and restores
 * a database that has no dump-shaped history; with no file on disk there is nothing to attribute and
 * nothing to compare, which is the same reading the guard takes of the same absence.
 */

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { DUMP_FILE } from './from-dump.js';
import { dump } from '../dump/index.js';
import { hashDump, markerBeside, readMarker } from '../sync/marker.js';
import { behind, syncNotice } from '../sync/notice.js';
import { verdict } from '../sync/verdict.js';

/**
 * Whether the database at `location` is behind the dump beside it, as a sentence or as nothing.
 *
 * @param {import('node:sqlite').DatabaseSync} db The connection already open on `location`, so this
 *   costs no second handle — and so the expensive branch dumps the database the server is actually
 *   serving rather than one it opened again and might find in a different state.
 * @param {string} location The database's path. The dump is the file beside it (AD4) and the marker
 *   is the same path suffixed, so both are derived from this rather than from a repository root the
 *   server does not otherwise need to know.
 * @param {object} [options]
 * @param {(path: string, encoding: string) => string} [options.read] Injected so a test drives the
 *   absent-dump and unreadable-dump paths without a filesystem in that state.
 * @returns {string|null} The line to log, or `null` when there is nothing to say.
 */
export function syncState(db, location, { read = readFileSync } = {}) {
  const path = join(dirname(location), DUMP_FILE);

  let onDisk;

  try {
    onDisk = read(path, 'utf8');
  } catch {
    // Absent, unreadable, a directory — all the same answer. The server's job is to serve, and a
    // diagnostic that cannot be computed is not a reason to say something about the database.
    return null;
  }

  const marker = readMarker({ path: markerBeside(location) });
  const file = hashDump(onDisk);

  // The cheap exit, and it is exact rather than a heuristic: every verdict this check reports
  // requires `file` to differ from `marker`, so agreement here rules all three out without the
  // database being touched. What remains is `clean` or `database-moved`, both of which are silent.
  if (marker === file) return null;

  const state = verdict({ marker, file, database: hashDump(dump(db).sql) });

  return behind(state) ? syncNotice(state, path) : null;
}
