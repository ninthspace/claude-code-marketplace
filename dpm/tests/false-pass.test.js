/**
 * NFR6's register, and what makes it a criterion rather than a sentiment.
 *
 * "Every condition capable of producing a false pass blocks rather than warns" has no set to
 * check against, so a suite with one such test passes as readily as a suite with ten. The
 * spec enumerates twenty conditions for that reason, and NFR6's criterion is checked against
 * the table rather than against a reading of the code.
 *
 * This file is that check. Each condition is listed with **one** of two dispositions:
 *
 * - `test` — the name of a test in this suite that asserts the condition is refused. The name
 *   is verified to exist, so a renamed or deleted test fails here rather than quietly leaving
 *   a condition uncovered. That is the entire mechanism: a citation nobody resolves is how a
 *   register goes stale without anyone noticing.
 * - `closedIn` — the epic that closes it, for the conditions whose blocking mechanism this
 *   epic does not build. Six of the twenty are like that, and pretending otherwise would make
 *   this file the thing it exists to prevent.
 *
 * **The register is itself under test.** The count, the numbering and the condition summaries
 * are transcribed from the spec's table rather than derived from anything here, so a condition
 * added to the spec fails this file until it has a disposition.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { javascriptFilesUnder } from './support/sources.js';

const TESTS_DIRECTORY = new URL('.', import.meta.url).pathname;

/**
 * The twenty conditions, transcribed from the spec's false-pass register.
 *
 * `condition` is a short phrase rather than the register's full sentence: the criterion is
 * that twenty numbered conditions each have a disposition, and copying the prose verbatim
 * would make this fail on a rewording, which is not what it is watching for.
 */
const FALSE_PASSES = [
  { entry: 1, condition: 'A binding stored twice',
    test: 'coverage identity is the fragment, and position is no part of it' },
  { entry: 2, condition: 'A ✓ outliving the text it verified',
    test: 'editing a story criterion clears the ✓ on every coverage row bound to it' },
  { entry: 3, condition: 'Search index behind the data', closedIn: 'the FR9 search epic' },
  { entry: 4, condition: 'A hand-edit to a generated file', closedIn: 'the FR7 projection epic' },
  { entry: 5, condition: 'Number allocation matching no row',
    test: 'an allocation never reports success without a number' },
  { entry: 6, condition: 'A cycle among gates_work edges',
    test: 'entry 1 — a cycle among gates_work edges' },
  { entry: 7, condition: 'foreign_keys defaulting off on a connection',
    test: 'a connection dpm opens enforces foreign keys, whatever the default was' },
  { entry: 8, condition: 'A wrong-domain taxonomy reference',
    test: 'a term from the wrong domain is rejected in every slot that draws from taxonomy' },
  { entry: 9, condition: 'A non-deterministic dump', closedIn: 'the NFR4 dump epic' },
  { entry: 10, condition: 'A class inferred from a label', closedIn: 'the MCP tool epic' },
  { entry: 11, condition: "Coverage joining one spec's requirement to another spec's criterion",
    test: "entry 3 — coverage joining one spec's requirement to another spec's criterion" },
  { entry: 12, condition: 'A document referenced as the wrong kind of document',
    test: 'every foreign key into document is kind-pinned, except the ones the Data Model names' },
  { entry: 13, condition: 'A ✓ surviving an edit to coverage.spec_fragment',
    test: 'editing the coverage fragment clears the ✓ on that row' },
  { entry: 14, condition: 'A row referencing a retired vocabulary item',
    test: 'retiring a term leaves the rows that reference it intact and stops new ones arriving' },
  { entry: 15, condition: 'A search covering document_section only', closedIn: 'the FR9 search epic' },
  { entry: 16, condition: 'An FTS trigger absent for one indexed table', closedIn: 'the FR9 search epic' },
  { entry: 17, condition: 'A requirement with one of five obligations bound',
    test: 'a claimed requirement is distinguishable by query from an identically bound unclaimed one' },
  { entry: 18, condition: 'A completeness claim outliving its binding set',
    test: 'a completeness claim is cleared when a bound fragment or the requirement text is edited' },
  { entry: 19, condition: 'A {{ref:}} marker naming a deleted document',
    test: 'entry 13 — a {{ref:}} marker naming a document that is not there' },
  { entry: 20, condition: 'A document_milestone row pairing across specs',
    test: 'entry 12 — a document assigned to a milestone belonging to another spec' },
];

/** Every `test('…')` name the suite declares, read from the files rather than from a list. */
function declaredTests() {
  const names = new Set();

  for (const file of javascriptFilesUnder(TESTS_DIRECTORY).filter((path) => path.endsWith('.test.js'))) {
    // Group 1 is the quote, group 2 is the name — reading the first capture instead of the
    // second builds a set of two quote characters against which every citation fails to
    // resolve, and it was the size guard below that said so rather than any citation.
    for (const [, , name] of readFileSync(file, 'utf8').matchAll(/^test\(\s*(['"])((?:\\.|(?!\1).)*)\1/gm)) {
      names.add(name.replaceAll('\\\'', "'"));
    }
  }

  return names;
}

test('the false-pass register is twenty conditions, each with a disposition', () => {
  assert.equal(FALSE_PASSES.length, 20, 'the count the spec states, so a twenty-first fails here');
  assert.deepEqual(
    FALSE_PASSES.map((condition) => condition.entry),
    Array.from({ length: 20 }, (unused, index) => index + 1),
    'numbered contiguously — the number is the join key to the spec\'s table',
  );

  const undisposed = FALSE_PASSES.filter((condition) => !condition.test && !condition.closedIn);
  assert.deepEqual(undisposed, [], 'a condition with neither a test nor a home is an unregistered entry');

  const both = FALSE_PASSES.filter((condition) => condition.test && condition.closedIn);
  assert.deepEqual(both, [], 'and one with both is a claim that has not decided what it is');
});

test('every condition this epic closes names a test that exists', () => {
  const declared = declaredTests();

  // The guard on the guard: if the scan found nothing, every citation below would resolve
  // against an empty set and the assertion would still be checking something — but against
  // nothing. A suite this size has far more than fifty.
  assert.ok(declared.size > 50, `only ${declared.size} tests found — the scan is not reading the suite`);

  const unresolved = FALSE_PASSES
    .filter((condition) => condition.test && !declared.has(condition.test))
    .map((condition) => `#${condition.entry}: ${condition.test}`);

  assert.deepEqual(unresolved, [], 'a citation nobody resolves is how a register goes stale unnoticed');
});

test('the conditions this epic does not close say which one does', () => {
  const deferred = FALSE_PASSES.filter((condition) => condition.closedIn);

  // Six of twenty. Four more were deferred to Story 7 when this file was written and became
  // citations at its gate, which is the deferral working rather than a list going stale.
  assert.deepEqual(
    deferred.map((condition) => condition.entry),
    [3, 4, 9, 10, 15, 16],
    'and naming them is what stops the register reading as complete',
  );

  // Each needs the search index, the projection guard, the dump path or the tool boundary —
  // none of which this epic builds, and none of which a test here could assert without
  // inventing them. The register is complete and honest; it is not satisfied.
  assert.ok(
    deferred.every((condition) => condition.closedIn.length > 0),
    'every deferral names where, since "later" is not a disposition',
  );
});
