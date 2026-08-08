/**
 * Walking dpm's own sources.
 *
 * Several checks read the tree rather than the code — which fixtures exist, which files
 * import a package, which test files one command reaches. They differ in what they conclude
 * and not in how they look, so the walk lives here once.
 */

import { readdirSync } from 'node:fs';
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
