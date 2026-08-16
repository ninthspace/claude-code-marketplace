/**
 * The Node floor, checked before anything that would fail without it (NFR2).
 *
 * `node:sqlite` landed in 22.5.0. Below that, importing it throws
 * `ERR_UNKNOWN_BUILTIN_MODULE` — a message about a module the reader has never heard of,
 * naming neither the version they have nor the version they need. NFR2 exists to replace that
 * with a sentence someone can act on.
 *
 * **This module must not import `node:sqlite`, directly or through anything else, and that is
 * the whole reason it is a module of its own.** ES module imports are hoisted and evaluated
 * before any statement in the importing file runs, so an entry point that statically imports
 * the server and then checks the version has already crashed by the time the check would have
 * run. The check therefore lives here, is imported first, and the rest of the server is reached
 * by `await import(…)` afterwards — a dynamic import is evaluated where it is written rather
 * than at load.
 */

/** The floor, stated once. `package.json`'s `engines.node` is asserted equal to it by the tests. */
export const REQUIRED_NODE = '22.5.0';

/**
 * `'22.18.0'` → `[22, 18, 0]`.
 *
 * A prerelease or build suffix is dropped rather than compared: `23.0.0-nightly` is above the
 * floor on the part that matters, and ordering prereleases correctly is a semver problem this
 * does not have. Anything unparseable yields `NaN`, which every comparison below treats as
 * failing — an unreadable version is not evidence of a version that is high enough.
 *
 * @param {string} version
 * @returns {number[]} Three numbers, major first.
 */
export function parseVersion(version) {
  return String(version)
    .replace(/^v/, '')
    .split('-')[0]
    .split('.')
    .slice(0, 3)
    .map((part) => Number.parseInt(part, 10));
}

/**
 * Whether `current` is at or above `required`.
 *
 * Compared component by component as numbers, never as strings: `'22.9.0' < '22.10.0'` is false
 * under a lexicographic comparison, which would put the floor above a release that clears it.
 *
 * @param {string} current
 * @param {string} [required]
 * @returns {boolean}
 */
export function meetsFloor(current, required = REQUIRED_NODE) {
  const have = parseVersion(current);
  const need = parseVersion(required);

  for (const [index, needed] of need.entries()) {
    const held = have[index];

    if (!Number.isInteger(held)) return false;
    if (held > needed) return true;
    if (held < needed) return false;
  }

  return true;
}

/**
 * Whether `candidate` is strictly above `reference`, with anything unparseable answering no.
 *
 * `meetsFloor` answers *at or above*, and both callers here need to tell equal from higher: the
 * neighbour check reports a skew only for a version genuinely newer than the running one, and the
 * database stamp is written only on an increase (FR2a). Composed from `meetsFloor` in both
 * directions rather than comparing components again, so the NaN handling that makes an unreadable
 * version fail every comparison holds here for free.
 *
 * @param {string} candidate
 * @param {string} reference
 * @returns {boolean}
 */
export function isAbove(candidate, reference) {
  return meetsFloor(candidate, reference) && !meetsFloor(reference, candidate);
}

/** What the user is told. Names both versions, because either alone leaves them guessing. */
export const floorMessage = (current, required = REQUIRED_NODE) =>
  `dpm requires Node >=${required} and this is Node ${current}. ` +
  `dpm reads and writes its database with the built-in node:sqlite module, which was added ` +
  `in Node ${required}. Upgrade Node, then start the server again.`;

/**
 * Refuse to continue below the floor.
 *
 * Throws rather than calling `process.exit`, so the entry point owns the exit code and a test
 * can drive this without ending its own process.
 *
 * @param {string} [current]
 * @param {string} [required]
 */
export function assertNodeFloor(current = process.versions.node, required = REQUIRED_NODE) {
  if (!meetsFloor(current, required)) {
    throw new Error(floorMessage(current, required));
  }
}
