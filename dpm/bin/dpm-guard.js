#!/usr/bin/env node
/**
 * The executable a pre-commit hook runs.
 *
 * Same shape as `dpm-mcp.js` and for the same reason: **nothing that touches `node:sqlite` may be
 * imported statically here.** ES module imports are hoisted, so an entry point that imported the
 * guard at the top and checked the Node version below would already have crashed with
 * `ERR_UNKNOWN_BUILTIN_MODULE` on any Node under 22.5 — inside a git hook, where the message a
 * user actually sees is "pre-commit hook failed".
 *
 * Unlike the server, stdout here is a terminal rather than a transport, so the clean-result line
 * goes to stdout and every failure to stderr.
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

const { run } = await import('../src/guard/main.js');

process.exit(run({ root: process.argv[2] ?? process.cwd() }));
