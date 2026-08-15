#!/usr/bin/env node
/**
 * The executable that rebuilds the database from the committed dump (FR8).
 *
 * Same shape as `dpm-publish.js`, `dpm-guard.js`, `dpm-merge.js` and `dpm-mcp.js`, and for the same
 * reason: **nothing that touches `node:sqlite` may be imported statically here.** ES module imports
 * are hoisted, so an entry point that imported the import at the top and checked the Node version
 * below would already have crashed with `ERR_UNKNOWN_BUILTIN_MODULE` on any Node under 22.5 — and
 * this is one of the two commands the guard sends a user to when it refuses a commit, so an
 * unexplained failure here leaves them with a refusal and no way through it.
 *
 * The report goes to stdout when the import succeeded and to stderr when it did not, so a shell can
 * tell them apart without reading the exit code.
 */

import { assertNodeFloor } from '../src/server/node-floor.js';
import { filterWarnings } from '../src/server/warnings.js';

try {
  assertNodeFloor();
} catch (error) {
  process.stderr.write(`${error.message}\n`);
  process.exit(2);
}

filterWarnings();

const { run } = await import('../src/import/main.js');

process.exit(run({ root: process.argv[2] ?? process.cwd() }));
