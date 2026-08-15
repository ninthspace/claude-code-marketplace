/**
 * The guard as a command: open the database, check, report, decide the exit code.
 *
 * Separated from `bin/dpm-guard.js` for the reason `server/index.js` is separated from
 * `bin/dpm-mcp.js` — the entry point must reach `node:sqlite` through `await import` and nothing
 * else, so that the Node floor check runs before the module that needs the floor is evaluated.
 * Everything below this line is free to import normally.
 *
 * **The database is opened, not started.** `start()` migrates and seeds; a pre-commit hook that
 * quietly upgraded the schema would make committing a schema-writing operation, and the first
 * anyone knew of it would be an unexplained diff in `.dpm/dpm.sql` produced by the guard that was
 * supposed to be checking it. The guard reads. If the schema is behind, the answer is to start the
 * server, not to have the hook do it.
 */

import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { openConnection } from '../db/connection.js';
import { DATABASE } from '../db/location.js';
import { describe, guard } from './index.js';

/**
 * @typedef {object} Streams
 * @property {(text: string) => void} out
 * @property {(text: string) => void} err
 */

/**
 * Run the guard.
 *
 * @param {object} [options]
 * @param {string} [options.root] The repository root.
 * @param {string} [options.location] The database.
 * @param {Streams} [options.streams] Injected so a test reads the report rather than a process's
 *   stdout — and so the exit code and the text are asserted from the same call.
 * @returns {number} The exit code: 0 clean, 1 divergence, 2 the guard could not run.
 */
export function run({ root = '.', location = DATABASE, streams } = {}) {
  const out = streams?.out ?? ((text) => process.stdout.write(text));
  const err = streams?.err ?? ((text) => process.stderr.write(text));

  // **The database is found under `root`, not under the working directory.** In a pre-commit hook
  // the two are the same, which is why this went unnoticed: git runs hooks from the repository
  // root and the guard's own `root` is `git rev-parse --show-toplevel`. Run against any other
  // tree — as `dpm merge` does when it checks its own output — the docs came from `root` and the
  // database came from wherever the process happened to start, and the guard compared one
  // repository's files against another's rows. `resolve` and not `join`, so an absolute
  // `DPM_DATABASE` still points where it says.
  const database = location === ':memory:' ? location : resolve(root, location);

  // **Checked before opening, because opening creates it.** `DatabaseSync` makes an empty database
  // at a path that has none, so a guard that opened first would write a `.dpm/dpm.db` into a
  // repository as a side effect of checking one — and then fail with `no such table: document`,
  // which names a SQLite internal rather than the thing that is wrong. This module writes nothing;
  // that has to include the database.
  if (database !== ':memory:' && !existsSync(database)) {
    // **Exit 2 and not 1.** "The guard could not run" is not "the tree is clean", and it is not
    // "the tree diverged" either — a hook that reported divergence because the database was
    // missing would send a user to regenerate files against nothing.
    err(`dpm: cannot open ${database} — there is no database there. Start the dpm server to `
      + 'create one, or point DPM_DATABASE at the right path.\n');

    return 2;
  }

  let db;

  try {
    db = openConnection(database);
  } catch (error) {
    err(`dpm: cannot open ${database} — ${error.message}\n`);

    return 2;
  }

  try {
    const result = guard(db, { root });

    if (result.diverged.length === 0) {
      out(`${describe(result)}\n`);

      return 0;
    }

    err(`${describe(result)}\n`);

    return 1;
  } catch (error) {
    err(`dpm: the guard failed before it could compare ${database} — ${error.message}\n`);

    return 2;
  } finally {
    db.close();
  }
}
