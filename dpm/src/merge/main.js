/**
 * The merge as a command: read git's three stages, merge, and leave the tree consistent.
 *
 * Separated from `bin/dpm-merge.js` for the reason `guard/main.js` is separated from
 * `bin/dpm-guard.js` — the entry point must reach `node:sqlite` through `await import` and nothing
 * else, so the Node floor check runs before the module that needs the floor is evaluated.
 *
 * **Nothing is staged.** The tool writes files and stops; `git add` is the user's, exactly as it is
 * with the guard. A merge tool that staged its own output would make the resolution of a conflict
 * something that happened without a review.
 */

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, renameSync, rmSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { openConnection } from '../db/connection.js';
import { dump } from '../dump/index.js';
import { describe as describeGuard, guard, DUMP_PATH } from '../guard/index.js';
import { publish } from '../publish/index.js';
import { restore } from '../restore/index.js';
import { describe, merge } from './index.js';
import { MergeError } from './rows.js';

/** Where the database lives. Same default and same override as the server's and the guard's. */
export const DATABASE = process.env.DPM_DATABASE ?? '.dpm/dpm.db';

/** git's numbering of the three sides of a conflict. */
const SIDES = { 1: 'base', 2: 'ours', 3: 'theirs' };

/**
 * The three sides of the conflict on `path`, read out of the index.
 *
 * Read by blob sha from `git ls-files -u` rather than by `git show :N:path`, because the pathspec
 * form has to be quoted the way git expects and the sha form does not — and because the same
 * command establishes whether there is a conflict at all. An empty listing is not an error here;
 * it is the answer to "is this a conflicted merge", and the caller turns it into one.
 *
 * @param {string} root
 * @param {string} path
 * @returns {Record<string, string>} `base`, `ours` and `theirs`, for whichever stages exist.
 */
export function stages(root, path) {
  const listed = execFileSync('git', ['ls-files', '-u', '--', path], {
    cwd: root,
    encoding: 'utf8',
  });

  const found = {};

  for (const line of listed.split('\n')) {
    if (line.trim() === '') continue;

    // `<mode> <sha> <stage>\t<path>`
    const [meta] = line.split('\t');
    const [, sha, stage] = meta.split(/\s+/);
    const side = SIDES[stage];

    if (!side) continue;

    found[side] = execFileSync('git', ['cat-file', 'blob', sha], {
      cwd: root,
      encoding: 'utf8',
      maxBuffer: 512 * 1024 * 1024,
    });
  }

  return found;
}

/**
 * @typedef {object} Streams
 * @property {(text: string) => void} out
 * @property {(text: string) => void} err
 */

/**
 * Run the merge.
 *
 * @param {object} [options]
 * @param {string} [options.root] The repository root.
 * @param {string} [options.location] The database to rebuild from the merged dump.
 * @param {Streams} [options.streams] Injected so a test reads the report rather than a process's
 *   stdout — and so the exit code and the text are asserted from the same call.
 * @returns {number} 0 merged, 1 refused, 2 the merge could not run.
 */
export function run({ root = '.', location = DATABASE, streams } = {}) {
  const out = streams?.out ?? ((text) => process.stdout.write(text));
  const err = streams?.err ?? ((text) => process.stderr.write(text));

  let sides;

  try {
    sides = stages(root, DUMP_PATH);
  } catch (error) {
    err(`dpm: cannot read the merge from git — ${error.message}\n`);

    return 2;
  }

  if (!sides.ours || !sides.theirs) {
    err(
      `dpm: ${DUMP_PATH} is not in a conflicted merge — there is nothing here to resolve. Run this `
      + 'during a `git merge` that left it conflicted.\n',
    );

    return 2;
  }

  if (!sides.base) {
    // Stage 1 is absent when both sides added the file with no common ancestor. Every row then
    // looks new to both sides, and the merge would keep two copies of a shared history rather than
    // one. Saying so is the whole of the fix; guessing an empty ancestor is not.
    err(
      `dpm: ${DUMP_PATH} has no common ancestor in this merge — the two branches added it `
      + 'independently. There is no base to merge against, so the two databases have to be '
      + 'reconciled deliberately.\n',
    );

    return 2;
  }

  let result;

  try {
    result = merge(sides);
  } catch (error) {
    if (!(error instanceof MergeError)) throw error;

    err(`dpm: ${error.message}\n`);

    return 2;
  }

  if (result.conflicts.length > 0) {
    err(`${describe(result)}\n`);

    return 1;
  }

  // **The database is rebuilt beside the real one and moved into place.** A restore straight over
  // `.dpm/dpm.db` that failed part-way would leave the user without the database *and* without the
  // merge, which is a worse position than the conflict they started with.
  // Under `root` and not under the working directory, and `resolve` rather than `join` so an
  // absolute `DPM_DATABASE` still points where it says — the same rule the guard follows.
  const target = resolve(root, location);
  const staging = `${target}.merging`;

  try {
    mkdirSync(dirname(target), { recursive: true });
    rmSync(staging, { force: true });

    const fresh = openConnection(staging);

    try {
      restore(fresh, result.sql);
    } finally {
      fresh.close();
    }

    renameSync(staging, target);
  } catch (error) {
    rmSync(staging, { force: true });
    err(`dpm: the merged dump did not restore into ${location} — ${error.message}\n`);

    return 2;
  }

  const db = openConnection(target);
  let removed = [];

  try {
    // **The merged dump has to survive its own restore, and this is where that was checked.** The
    // merge used to write `result.sql` here and then let the guard compare `dump(db)` against it,
    // so a merged file that restored into a database dumping differently failed. `publish` writes
    // what the database dumps, which would make that comparison trivially true — so the check is
    // stated rather than left to emerge from the order of two writes.
    if (dump(db).sql !== result.sql) {
      err(
        'dpm: the merged dump did not survive its own restore — the database it produced dumps '
        + 'differently, so committing it would commit a state nobody merged.\n',
      );

      return 2;
    }

    // **Both artefacts, one call, and the orphan rule is not restated here.** A renumbered
    // document's old file is on disk and no document produces it, which is what the guard already
    // knows how to recognise; `publish` removes exactly what the guard would report, so the two
    // cannot disagree the first time naming changes. The dump still lands after the restore for
    // the reason it always did — it is the committed artefact, and a run that wrote it and then
    // failed would leave a broken database in the commit and a tree that looked resolved — but
    // that ordering is now a property of `publish` rather than of this call site.
    ({ removed } = publish(db, { root }));

    const after = guard(db, { root });

    if (after.diverged.length > 0) {
      err(`dpm: the merge left the tree inconsistent, which is a bug:\n${describeGuard(after)}\n`);

      return 2;
    }
  } finally {
    db.close();
  }

  const lines = [describe(result)];

  if (removed.length > 0) {
    lines.push('', 'Removed, because no document produces them any more:',
      ...removed.map((path) => `  ${path}`));
  }

  lines.push('', `Review the changes and stage them: git add ${DUMP_PATH} docs`);

  if (existsSync(join(root, '.dpm', 'dpm.db-wal'))) {
    lines.push('A dpm server may be holding the old database open — restart it before using it.');
  }

  out(`${lines.join('\n')}\n`);

  return 0;
}
