#!/usr/bin/env node
/**
 * The executable a user runs during a conflicted `git merge`.
 *
 * Same shape as `dpm-guard.js` and `dpm-mcp.js`, and for the same reason: **nothing that touches
 * `node:sqlite` may be imported statically here.** ES module imports are hoisted, so an entry point
 * that imported the merge at the top and checked the Node version below would already have crashed
 * with `ERR_UNKNOWN_BUILTIN_MODULE` on any Node under 22.5 — in the middle of a merge, where a
 * user has the least appetite for an unexplained failure.
 *
 * The report goes to stdout when the merge succeeded and to stderr when it did not, so a shell can
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

const { run } = await import('../src/merge/main.js');

process.exit(run({ root: process.argv[2] ?? process.cwd() }));
