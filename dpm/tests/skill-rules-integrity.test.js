/**
 * Epic 05-06 Story 5 — the integrity check at the breakdown's confirm step (FR15).
 *
 * The gap check `epics` already ran reads what the rows **say**: which requirement has no binding,
 * which criterion is accounted for by nothing. The integrity register reads whether they **hold**:
 * a fragment quoting text its requirement does not contain, an edge whose ends are kinds its kind
 * does not admit, a criterion counted under two stories. A breakdown can be complete by the first
 * reading and broken by the second, and the confirm step is the last place either is cheap.
 *
 * One consumer — `epics` is the breakdown skill — so by ADR 05-05 the rule goes in that body.
 *
 * **The advisory distinction is the part worth testing rather than the instruction.** The register
 * marks one entry advisory and the rule says the register decides; a run working it out for itself
 * would be a second answer to a question the register already holds. So the test reads the register
 * rather than a list here, and asserts the rule defers to it.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { conventions, skillSource } from './support/skills.js';
import { REGISTER } from '../src/integrity/register.js';

const SKILLS = new URL('../skills/', import.meta.url).pathname;

const CORPUS = readdirSync(SKILLS, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

/** The breakdown skill's body, hard wrapping collapsed. */
const breakdown = () => skillSource('epics').replace(/\s+/g, ' ');

// --- Criterion 1: the confirm step runs the check and treats violations as gaps -------------------

test('the confirm step runs the integrity check and treats a violation as a gap [unit]', () => {
  const rule = breakdown();

  assert.match(rule, /run `mcp__plugin_dpm_dpm__check_integrity`/,
    'the confirm step does not run the integrity check');
  assert.match(rule, /treat every violation it reports as a gap/);

  // **Unless the entry says it is advisory**, which is the register's call and not the run's.
  assert.match(rule, /unless the entry says it is advisory/);
  assert.match(rule, /the register says which/);

  // **Reported with the rows it names, not the count.** A report saying "three violations" sends
  // the reader back to a call they cannot make.
  assert.match(rule, /with \*\*the rows it names\*\*, not the count/);

  // And it says why it is a second reading rather than a repetition of the gap check, so a run
  // that meets a clean gap check does not skip it.
  assert.match(rule, /reads what the rows \*say\*; integrity reads whether they \*hold\*/);
});

// --- The advisory flag is the register's, and there is one -----------------------------------------

test('the register carries the advisory flag the rule defers to [unit]', () => {
  // **Read from the register rather than restated here.** The rule tells a run to ask the register
  // which entries are advisory; a test carrying its own list would be the second answer the rule
  // exists to prevent, and would go stale the first time an entry was added.
  const advisory = REGISTER.filter((entry) => entry.advisory);

  assert.ok(REGISTER.length > 5, `the register holds only ${REGISTER.length} entries`);
  assert.equal(advisory.length >= 1, true,
    'no entry is advisory, so the rule draws a distinction the register does not carry');

  // Every entry is either advisory or not, and the flag is a property of the entry — so a run can
  // answer the question for any violation it is handed.
  for (const entry of REGISTER) {
    assert.equal(typeof entry.entry, 'number');
    assert.ok(entry.advisory === undefined || entry.advisory === true);
  }
});

// --- Placement: one consumer, so one body ---------------------------------------------------------

test('the rule is in the breakdown skill and in no shared section [unit]', () => {
  const carriers = CORPUS.filter((skill) => /treat every violation it reports as a gap/
    .test(skillSource(skill).replace(/\s+/g, ' ')));

  assert.deepEqual(carriers, ['epics'], 'a rule with one consumer is in more than one body');

  assert.doesNotMatch(conventions().replace(/\s+/g, ' '),
    /treat every violation it reports as a gap/,
    'a single-consumer rule reached the shared conventions');
});

test('the rule claims no enforcement the harness does not have [unit]', () => {
  const rule = breakdown();

  // ENV6. The temptation here is to say the check blocks the gate, and nothing makes it do so —
  // the run reports and resolves, and a rule promising otherwise teaches a lean on nothing.
  assert.doesNotMatch(rule, /the host (refuses|rejects|enforces|blocks)/i);
  assert.doesNotMatch(rule, /`check_integrity` (blocks|prevents|refuses) /i);
});
