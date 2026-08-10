#!/usr/bin/env node
/**
 * The executable that regenerates the projection and the dump (AD11).
 *
 * Same shape as `dpm-guard.js`, `dpm-merge.js` and `dpm-mcp.js`, and for the same reason: **nothing
 * that touches `node:sqlite` may be imported statically here.** ES module imports are hoisted, so
 * an entry point that imported the publish at the top and checked the Node version below would
 * already have crashed with `ERR_UNKNOWN_BUILTIN_MODULE` on any Node under 22.5 — and this is the
 * command the guard sends a user to when it refuses a commit, so an unexplained failure here leaves
 * them with a refusal and no way through it.
 *
 * Unlike the server, stdout here is a terminal rather than a transport, so the report goes to
 * stdout and every failure to stderr.
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

const { run } = await import('../src/publish/main.js');

process.exit(run({ root: process.argv[2] ?? process.cwd() }));
