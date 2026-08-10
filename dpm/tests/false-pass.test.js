/**
 * NFR6's register, and what makes it a criterion rather than a sentiment.
 *
 * "Every condition capable of producing a false pass blocks rather than warns" has no set to
 * check against, so a suite with one such test passes as readily as a suite with ten. The
 * spec enumerates twenty-three conditions for that reason, and NFR6's criterion is checked against
 * the table rather than against a reading of the code.
 *
 * This file is that check. Each condition is listed with **one** of two dispositions:
 *
 * - `test` — the name of a test in this suite that asserts the condition is refused. The name
 *   is verified to exist, so a renamed or deleted test fails here rather than quietly leaving
 *   a condition uncovered. That is the entire mechanism: a citation nobody resolves is how a
 *   register goes stale without anyone noticing.
 * - `closedIn` — the epic that closes it, for the conditions whose blocking mechanism this
 *   epic does not build. Six of the first twenty were like that, and pretending otherwise would
 *   have made this file the thing it exists to prevent.
 *
 * **As of Epic 47-05 Story 6 the second disposition is unused, and that is the register being
 * satisfied rather than the mechanism being retired.** The six deferrals named four epics —
 * 47-02's dump path, 47-03's tool boundary, 47-04's projection guard, and this epic's search
 * index — and this story is the first point in the build order at which all four are complete.
 * The `closedIn` branch stays because the register outlives this epic: a later condition whose
 * mechanism nobody has built yet needs somewhere honest to sit, and the assertion below now
 * passes over an empty set precisely because nothing is deferred, not because nothing checks.
 * Three such conditions have arrived since — #21 with FR29, and #22 and #23 with the amendments
 * of 2026-08-10 — and each landed with its mechanism built, so the branch is still unused.
 *
 * **A citation resolves a name and cannot read what the test asserts.** That gap is entry #18's
 * own shape turned on the register — a claim outliving what makes it true — and no assertion in
 * this file can close it. Each of the six conversions was therefore mutation-checked at its
 * source: the guard the condition names was broken, the cited test was confirmed to fail, and the
 * source reverted. The record is in Epic 47-05's Notes.
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
 * The twenty-three conditions, transcribed from the spec's false-pass register.
 *
 * `condition` is a short phrase rather than the register's full sentence: the criterion is
 * that every numbered condition has a disposition, and copying the prose verbatim would make
 * this fail on a rewording, which is not what it is watching for.
 *
 * **A new condition is appended and its number is never reused**, which the spec's table now says
 * in as many words. The amendments of 2026-08-10 first inserted #22 and #23 after #14, giving them
 * numbers two conditions already had — and since the number is the join key this file resolves
 * against, an entry list transcribed from that table would have carried two collisions the
 * contiguity assertion below could not have expressed.
 */
const FALSE_PASSES = [
  { entry: 1, condition: 'A binding stored twice',
    test: 'coverage identity is the fragment, and position is no part of it' },
  { entry: 2, condition: 'A ✓ outliving the text it verified',
    test: 'editing a story criterion clears the ✓ on every coverage row bound to it' },
  { entry: 3, condition: 'Search index behind the data',
    test: 'a row written in the same call sequence is searchable immediately' },
  { entry: 4, condition: 'A hand-edit to a generated file',
    test: 'a hand-edited generated file fails the guard, naming the file' },
  { entry: 5, condition: 'Number allocation matching no row',
    test: 'an allocation never reports success without a number' },
  { entry: 6, condition: 'A cycle among gates_work edges',
    test: 'entry 1 — a cycle among gates_work edges' },
  { entry: 7, condition: 'foreign_keys defaulting off on a connection',
    test: 'a connection dpm opens enforces foreign keys, whatever the default was' },
  { entry: 8, condition: 'A wrong-domain taxonomy reference',
    test: 'a term from the wrong domain is rejected in every slot that draws from taxonomy' },
  // **Not `dumping the same state twice from independent databases is byte-stable`**, which is
  // the obvious citation and is the *claim* rather than the guard. Dropping the `ORDER BY` from
  // the row select leaves it green — two databases built by the same statements in the same order
  // hand back the same unordered scan — while the ordering test below fails at once. Determinism
  // is only observable where the inputs differ, so the citation has to be the test that varies
  // them. Found by driving the mutation; nothing about the two names says which is which.
  { entry: 9, condition: 'A non-deterministic dump',
    test: 'rows are emitted in primary-key order regardless of the order they were written' },
  { entry: 10, condition: 'A class inferred from a label',
    test: 'a label of any shape is stored against the class it was given, never one read off it' },
  { entry: 11, condition: "Coverage joining one spec's requirement to another spec's criterion",
    test: "entry 3 — coverage joining one spec's requirement to another spec's criterion" },
  { entry: 12, condition: 'A document referenced as the wrong kind of document',
    test: 'every foreign key into document is kind-pinned, except the ones the Data Model names' },
  { entry: 13, condition: 'A ✓ surviving an edit to coverage.spec_fragment',
    test: 'editing the coverage fragment clears the ✓ on that row' },
  { entry: 14, condition: 'A row referencing a retired vocabulary item',
    test: 'retiring a term leaves the rows that reference it intact and stops new ones arriving' },
  { entry: 15, condition: 'A search covering document_section only',
    test: 'a search covering sections alone misses five of the six, and says nothing about it' },
  { entry: 16, condition: 'An FTS trigger absent for one indexed table',
    test: 'every table entry_fts indexes has all three triggers, and none has fewer' },
  { entry: 17, condition: 'A requirement with one of five obligations bound',
    test: 'a claimed requirement is distinguishable by query from an identically bound unclaimed one' },
  { entry: 18, condition: 'A completeness claim outliving its binding set',
    test: 'a completeness claim is cleared when a bound fragment or the requirement text is edited' },
  { entry: 19, condition: 'A {{ref:}} marker naming a deleted document',
    test: 'entry 13 — a {{ref:}} marker naming a document that is not there' },
  { entry: 20, condition: 'A document_milestone row pairing across specs',
    test: 'entry 12 — a document assigned to a milestone belonging to another spec' },
  { entry: 21, condition: 'A server nothing declares',
    test: 'the plugin manifest declares a server whose entry point exists' },
  { entry: 22, condition: 'An update that clears a field and changes nothing',
    test: 'an update clears a nullable column when told to, and leaves it alone when not' },
  { entry: 23, condition: 'A superseded or withdrawn blocker read as satisfied',
    test: 'a retired blocker goes on blocking, where the same blocker completed does not' },
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

test('the false-pass register is twenty-three conditions, each with a disposition', () => {
  assert.equal(FALSE_PASSES.length, 23, 'the count the spec states, so a twenty-fourth fails here');
  assert.deepEqual(
    FALSE_PASSES.map((condition) => condition.entry),
    Array.from({ length: 23 }, (unused, index) => index + 1),
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

test('nothing is deferred any longer — every condition is closed by a test', () => {
  const deferred = FALSE_PASSES.filter((condition) => condition.closedIn);

  // Six of twenty were deferred when Epic 47-01 wrote this file: #9 to the dump path, #10 to the
  // tool boundary, #4 to the projection guard, and #3, #15 and #16 to the search index. Four more
  // had been deferred to that epic's own Story 7 and became citations at its gate. The claim
  // "every condition capable of producing a false pass blocks rather than warns" is now made over
  // the whole register rather than over fourteen twentieths of it. The three conditions added
  // since — #21, #22 and #23 — each arrived with a test rather than with an epic to name.
  assert.deepEqual(deferred.map((condition) => condition.entry), [],
    'a condition is back to naming an epic instead of a test');

  assert.equal(FALSE_PASSES.filter((condition) => condition.test).length, FALSE_PASSES.length,
    'NFR6\'s criterion is over the register entire, so anything short of all of it fails');

  // The rule the empty set above is measured against, kept for the register's next entry rather
  // than deleted with its last user: a deferral is a disposition only while it names where it
  // closes. This passes vacuously today and would not the moment a condition arrives with
  // `closedIn: ''` — which is the shape "we'll get to it" takes when it is written down.
  assert.ok(
    deferred.every((condition) => condition.closedIn.length > 0),
    'every deferral names where, since "later" is not a disposition',
  );
});
