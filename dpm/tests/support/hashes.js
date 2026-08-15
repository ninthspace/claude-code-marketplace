/**
 * Digests computed for a test, deliberately not through the code under test.
 *
 * Three suites had grown the same line — the marker suite, the publish suite and the verdict suite —
 * and each of them had it for the same stated reason: `src/sync/marker.js` exports `hashDump`, and a
 * test that checked a marker by hashing with `hashDump` would have both sides of the equality coming
 * out of one function. That holds for any digest at all, including one taken over the wrong text,
 * which is the only way a marker is ever wrong.
 *
 * Collecting them here keeps that independence rather than spending it: this is still a test-owned
 * implementation over `node:crypto`, with no import from `src/`. What it removes is the third copy.
 */

import { createHash } from 'node:crypto';

/**
 * sha256 of `text`, hex.
 *
 * @param {string} text
 * @returns {string}
 */
export function sha256(text) {
  return createHash('sha256').update(text).digest('hex');
}
