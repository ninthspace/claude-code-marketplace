/**
 * The pre-commit divergence guard (FR7, AD8).
 *
 * Both generated artefacts are regenerated from the database and compared to what is on disk: the
 * markdown projection, and `.dpm/dpm.sql`. Divergence in either fails the commit and names what
 * diverged.
 *
 * **Regenerate and diff bytes. Never parse and compare.** AD8's must-NOT names this directly, and
 * the reason is that a parser answers a different question than the one being asked. Two files
 * that parse to the same structure are the same document and *different bytes*, and bytes are what
 * a commit carries, what a diff shows, and what the next regeneration will overwrite. A guard that
 * normalised trailing whitespace, or read a metadata block into a map, would call a hand-edit clean
 * and then destroy it on the next run — which is precisely the silent loss FR7 exists to prevent,
 * arriving through the tool built to prevent it.
 *
 * **This module reads files under `docs/`, and that is not a violation of AD3.** The one-way rule
 * is a property of the *renderer*: `src/projection/` may not read what it is about to write, or
 * regenerate-and-diff would be comparing a file with itself. The guard is the other side of that
 * arrangement — it exists to read — and it lives in its own directory so the module-list assertion
 * over `src/projection/` stays exact rather than acquiring an exemption.
 *
 * **Nothing here writes.** Not the regenerated projection, not the dump, not a fix. A guard that
 * repaired what it found would leave the user's edit gone and the commit passing, and the user
 * would learn about it from a diff they did not write.
 */

import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { dump } from '../dump/index.js';
import { project } from '../projection/index.js';

/** The committed text form of the database (AD4). Generated; `.dpm/dpm.db` is not committed. */
export const DUMP_PATH = '.dpm/dpm.sql';

/** Why a path is being reported. Three states, because they want three different fixes. */
export const DIVERGENCE = {
  differs: 'differs from what the database produces',
  missing: 'is not on disk, and the database produces it',
  orphaned: 'is on disk and no document produces it',
};

/** The file's bytes, or `null` when it is not there. Absence is a finding, not an error. */
function contents(path) {
  try {
    return readFileSync(path, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') return null;

    throw error;
  }
}

/** Every filename in `directory`, or `[]` when the directory does not exist. */
function entries(directory) {
  try {
    return readdirSync(directory, { withFileTypes: true })
      .filter((entry) => entry.isFile())
      .map((entry) => entry.name);
  } catch (error) {
    if (error.code === 'ENOENT') return [];

    throw error;
  }
}

/**
 * Generated files on disk that the projection no longer produces.
 *
 * **Deleting a document removes no file, so without this the guard reports clean on a tree that
 * still holds it.** That is the same stale-projection false pass a partial write produces, reached
 * from the other direction, and it is invisible to a comparison that only walks what was
 * generated: every file the projection produces matches, and the extra one is never looked at.
 *
 * The rule is narrow on purpose. A `docs/` tree holds files dpm did not write — a hand-kept README
 * in `docs/epics/`, a maintenance note — and reporting those would make the guard unusable. Only a
 * file whose name carries a *seeded kind* in the position the projection puts it is considered,
 * because that is a name only this renderer produces.
 */
function orphans(db, root, produced) {
  const kinds = db.prepare('SELECT kind, dir FROM document_kind WHERE dir IS NOT NULL').all();
  const directories = new Map();

  for (const { kind, dir } of kinds) {
    if (!directories.has(dir)) directories.set(dir, []);

    directories.get(dir).push(kind);
  }

  const found = [];

  for (const [dir, dirKinds] of directories) {
    for (const name of entries(join(root, 'docs', dir))) {
      const path = `docs/${dir}/${name}`;

      if (produced.has(path)) continue;
      if (!name.endsWith('.md')) continue;
      if (!dirKinds.some((kind) => name.includes(`-${kind}-`))) continue;

      found.push({ path, reason: DIVERGENCE.orphaned });
    }
  }

  return found;
}

/**
 * Check both generated artefacts against the database.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} [options]
 * @param {string} [options.root] The repository root the generated files sit under.
 * @returns {{diverged: {path: string, reason: string}[], checked: {files: number, dump: string}}}
 *   `checked` is returned so a clean result is distinguishable from a check that walked nothing —
 *   an empty `diverged` over zero files is a pass nobody earned (NFR6).
 */
export function guard(db, { root = '.' } = {}) {
  // `write: false`, so the guard regenerates into memory and leaves the tree exactly as it found
  // it whichever way the comparison goes.
  const { written } = project(db, { write: false });
  const diverged = [];

  for (const { path, text } of written) {
    const actual = contents(join(root, path));

    if (actual === null) diverged.push({ path, reason: DIVERGENCE.missing });
    else if (actual !== text) diverged.push({ path, reason: DIVERGENCE.differs });
  }

  diverged.push(...orphans(db, root, new Set(written.map((file) => file.path))));

  // **The dump is checked on the same footing as the projection, in one guard rather than two.**
  // A commit carrying a fresh projection and a stale dump is the worse of FR7's two failures and
  // the one that passes every check aimed at the markdown: the prose diff reads current and the
  // committed database is behind it, so the next person to restore gets a state nobody reviewed.
  const expected = dump(db).sql;
  const onDisk = contents(join(root, DUMP_PATH));

  if (onDisk === null) diverged.push({ path: DUMP_PATH, reason: DIVERGENCE.missing });
  else if (onDisk !== expected) diverged.push({ path: DUMP_PATH, reason: DIVERGENCE.differs });

  return { diverged, checked: { files: written.length, dump: DUMP_PATH } };
}

/**
 * The report a user reads, naming every divergence.
 *
 * Naming the files is the criterion, not the exit code. "The projection is out of date" tells a
 * user nothing they can act on in a tree of four hundred artefacts; the list tells them which file
 * they edited and which command to run.
 *
 * @param {ReturnType<typeof guard>} result
 * @returns {string}
 */
export function describe(result) {
  const { diverged, checked } = result;

  if (diverged.length === 0) {
    return `dpm: ${checked.files} projected files and ${checked.dump} match the database`;
  }

  return [
    `dpm: ${diverged.length} generated ${diverged.length === 1 ? 'file' : 'files'} `
    + `${diverged.length === 1 ? 'does' : 'do'} not match the database:`,
    ...diverged.map(({ path, reason }) => `  ${path} — ${reason}`),
    '',
    'Nothing was written. The projection is generated from the database and is not an input:',
    'an edit made here is lost at the next regeneration, so it has been left in place for you',
    'to move into the database. Regenerate both artefacts to resolve.',
  ].join('\n');
}
