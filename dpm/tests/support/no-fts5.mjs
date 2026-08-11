/**
 * A runtime that reports no FTS5, for driving the refusal through a spawned binary.
 *
 * Passed as `--import` so it runs before the entry point's own imports resolve. It rewrites
 * `hasFts5` at load time to return false, which is the one thing a test on this machine cannot
 * otherwise arrange: the criterion asks for the refusal to be exercised on a runtime that *does*
 * have the capability, so that the assertion distinguishes the probe from the machine it happens
 * to run on.
 *
 * **A module hook rather than an environment variable the probe reads.** An env override would be
 * a production surface — a way to talk a real server out of its own safety check — added for the
 * convenience of a test. This reaches the same place and ships nothing.
 */

import { registerHooks } from 'node:module';

registerHooks({
  load(url, context, nextLoad) {
    const loaded = nextLoad(url, context);

    if (!url.endsWith('/dpm/src/db/capability.js')) return loaded;

    const patched = loaded.source.toString()
      .replace('export function hasFts5(db) {', 'export function hasFts5(db) { return false;');

    if (patched === loaded.source.toString()) {
      throw new Error('no-fts5.mjs could not patch hasFts5 — its signature moved and this shim '
        + 'would otherwise leave the capability true and report the run as a pass');
    }

    return { ...loaded, source: patched };
  },
});
