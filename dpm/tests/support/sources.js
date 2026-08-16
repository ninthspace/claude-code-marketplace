/**
 * Walking dpm's own sources.
 *
 * Several checks read the tree rather than the code — which fixtures exist, which files
 * import a package, which test files one command reaches. They differ in what they conclude
 * and not in how they look, so the walk lives here once.
 */

import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

/** Directories that are not dpm's own source, and would make every check report on them. */
const SKIPPED = new Set(['node_modules']);

/**
 * Every `.js` file under a directory, recursively, as absolute paths in a stable order.
 * Dot-directories are skipped, so a check cannot be thrown by editor or VCS state.
 *
 * @param {string} directory
 * @returns {string[]}
 */
export function javascriptFilesUnder(directory) {
  const found = [];

  for (const entry of readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (SKIPPED.has(entry.name) || entry.name.startsWith('.')) continue;

    const path = join(directory, entry.name);
    if (entry.isDirectory()) found.push(...javascriptFilesUnder(path));
    else if (entry.name.endsWith('.js')) found.push(path);
  }

  return found;
}

/**
 * dpm's own `package.json`, parsed.
 *
 * Five suites assert over this file — that nothing is declared to install, that the engine floor
 * matches the one the code enforces, that no build script exists — and each had written its own
 * read of it. The reads were identical and the assertions are not, which is the shape this module
 * already exists to collect: the walk lives here once and the conclusions stay with their suites.
 *
 * @returns {object}
 */
export function packageManifest() {
  return JSON.parse(readFileSync(join(import.meta.dirname, '..', '..', 'package.json'), 'utf8'));
}

/**
 * A module's text with its comments removed, for the sweeps that read code and not prose.
 *
 * **Written because a sweep that cannot tell the two apart reports the presence of a rule as a
 * breach of it.** `neighbour.js` and `plugin-version.js` each carry a doc comment saying they read
 * nothing from `process.env`, and the first run of the first of those sweeps found the explanation
 * and failed. Every caller wants the same stripping, and every caller also needs the *unstripped*
 * text to hand — the control on this function is that the string really is in the file, in the
 * comment that says why it is not in the code.
 *
 * A regex rather than a parser, and that is a limit worth stating: a comment opener written inside
 * a string literal would be stripped as though it opened a comment. Nothing in this project writes
 * one, and a sweep is a check on prose rather than a semantic analysis — if that changes, this
 * needs a parser and not a longer regex.
 *
 * @param {string} source
 * @returns {string}
 */
export function withoutComments(source) {
  return source.replaceAll(/\/\*[\s\S]*?\*\//g, '').replaceAll(/\/\/.*$/gm, '');
}

/**
 * Every file under a directory, recursively, as absolute paths in a stable order.
 *
 * The `.js` walk above answers "which of dpm's modules"; this one answers "which of these files",
 * whatever they are. A sweep over the skills tree wants the second: a reference smuggled into a
 * reference file beside a `SKILL.md` costs a reader exactly what one in the skill would, and a walk
 * filtered by extension is a walk that would not have found it.
 *
 * @param {string} directory
 * @returns {string[]}
 */
export function filesUnder(directory) {
  const found = [];

  for (const entry of readdirSync(directory, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (SKIPPED.has(entry.name) || entry.name.startsWith('.')) continue;

    const path = join(directory, entry.name);
    if (entry.isDirectory()) found.push(...filesUnder(path));
    else found.push(path);
  }

  return found;
}
