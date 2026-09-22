/**
 * Epic 05-07 Story 1 — the development environment, narrowed to what this spec changed (ENV1–ENV4).
 *
 * **Most of what these requirements ask is already true and already asserted**, and restating it
 * here would grow a second copy that can go stale separately from the first. So this file asserts
 * only what *this change set* narrows, and names what it is deliberately not restating so the next
 * reader does not add it back.
 *
 * Not restated here, and where each already lives:
 *
 * - **The Node floor and the FTS5 probe pass in development** — `baseline.test.js`, "the Node floor
 *   check and the FTS5 probe both pass in development".
 * - **A runtime without FTS5 is refused at the open, by name, in all four binaries** —
 *   `capability.test.js`, which forces the capability false in a spawned process because every
 *   machine this suite runs on has it and an assertion that only fired elsewhere would fire
 *   nowhere.
 * - **The dependency maps are empty and no install script runs** — `baseline.test.js`, "the suite
 *   runs from a clean checkout with no install step", which also observes that *this* checkout has
 *   no `node_modules` rather than only promising that one need not.
 *
 * What is left is the one clause those three do not reach: ENV2's *"every test this spec adds is
 * discovered and run by it"*. That is a claim about the files this spec produced, and nothing could
 * have asserted it before they existed.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const TESTS = new URL('./', import.meta.url).pathname;
const ROOT = new URL('../', import.meta.url).pathname;

/** The manifest, read rather than described. */
const manifest = () => JSON.parse(readFileSync(join(ROOT, 'package.json'), 'utf8'));

/** Every file `node --test` discovers under `tests/`, by its own naming rule. */
const discovered = () => readdirSync(TESTS)
  .filter((name) => name.endsWith('.test.js'))
  .sort();

/**
 * The suites this spec added, named rather than counted.
 *
 * **Named, because a count is satisfied by the wrong files.** Twenty-one suites arrived across
 * epics 05-01 to 05-07, and a test asserting "twenty-one new files" would pass against any
 * twenty-one — including a set from which three of these were missing and three unrelated ones
 * present. Each name here is a file a story in this spec created.
 */
const ADDED = [
  // 05-01 Coverage reporting
  'coverage-report.test.js',
  // 05-02 Write-path refusals
  'coverage-fragment-refusal.test.js',
  'requirement-exclusion.test.js',
  'story-close-note.test.js',
  'story-close-refusal.test.js',
  'unrelated-write-guards.test.js',
  'write-refusals-integration.test.js',
  // 05-03 Server-supplied stamps
  'coverage-stamp.test.js',
  'requirement-claim-stamp.test.js',
  // 05-04 Refusals that name a way out
  'argument-refusal.test.js',
  'foreign-key-naming.test.js',
  'prefix-offer.test.js',
  'refusal-routes.test.js',
  'scope-refusal.test.js',
  // 05-05 Repair verbs
  'coverage-story-deletion.test.js',
  'dependency-deletion.test.js',
  'observation-withdrawal.test.js',
  // 05-06 Skill rules and their placement
  'skill-citations.test.js',
  'skill-host-claims.test.js',
  'skill-rules-execution.test.js',
  'skill-rules-gates-criteria.test.js',
  'skill-rules-integrity.test.js',
  'skill-rules-resume.test.js',
  // 05-07 Environment and compatibility
  'spec-environment.test.js',
];

// --- ENV2: the runner discovers every suite this spec added ---------------------------------------

test('every test this spec adds is discovered by the runner the manifest names [integration]', () => {
  const found = discovered();

  // **Discovery is Node's own rule, not a list this file keeps.** `node --test` takes every
  // `*.test.js` under the directory it is pointed at, so the check is that each added file is
  // there under a name that rule matches — a suite saved as `coverage-stamp.js` would run for
  // nobody and fail nothing.
  const missing = ADDED.filter((name) => !found.includes(name));

  assert.deepEqual(missing, []);

  // The bound on the reading: the corpus is the whole directory, so a discovery that had stopped
  // matching would report every added file missing rather than a clean sweep.
  assert.ok(found.length > 100, `only ${found.length} suites were discovered`);
  assert.ok(ADDED.length >= 20, `only ${ADDED.length} added suites are named`);

  // **And each one actually declares tests**, which discovery alone does not say. A file matching
  // the pattern and exporting nothing is discovered, runs nothing, and reports success.
  for (const name of ADDED) {
    assert.match(readFileSync(join(TESTS, name), 'utf8'), /\btest\(/,
      `${name} is discovered but declares no test`);
  }
});

test('the manifest names one runner, and it is the runtime\'s own [unit]', () => {
  const scripts = manifest().scripts ?? {};

  assert.equal(scripts.test, 'node --test');

  // **No other runner is present**, which is the half of ENV2 the script line alone does not
  // carry: a second runner declared beside it would mean two answers to "how is this project
  // tested" and a suite that passes under one and is never run by the other.
  for (const [name, command] of Object.entries(scripts)) {
    assert.doesNotMatch(command, /\b(jest|mocha|vitest|ava|tap|jasmine|karma)\b/,
      `the ${name} script invokes a runner other than node --test`);
  }

  // And nothing is installed that could be one — asserted from the dependency maps rather than
  // from the absence of a config file, since a runner can be run without one.
  for (const set of ['dependencies', 'devDependencies']) {
    assert.deepEqual(manifest()[set] ?? {}, {}, `${set} is not empty after this change set`);
  }
});

// --- ENV4: the change set added no dependency -----------------------------------------------------

test('this change set added no runtime or development dependency [integration]', () => {
  // **The claim is about the change set, and the empty maps above are how it is checked** — the
  // maps were empty before and are empty now, so nothing this spec did added one. `baseline.test.js`
  // holds the standing version of this; what is asserted here is that the new suites brought
  // nothing with them.
  const imports = ADDED.flatMap((name) => [
    ...readFileSync(join(TESTS, name), 'utf8').matchAll(/^import\s[^;]*?from\s+'([^']+)'/gms),
  ].map(([, specifier]) => specifier));

  assert.ok(imports.length > 40, `only ${imports.length} imports were read across the added suites`);

  const external = imports.filter((specifier) => !specifier.startsWith('node:')
    && !specifier.startsWith('.'));

  assert.deepEqual(external, [],
    'a suite this spec added imports something that is neither a builtin nor in this tree');
});
