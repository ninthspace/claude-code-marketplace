/**
 * Epic 05-06 Story 2 — the gate rule and the two criterion-writing rules (FR16, FR17, FR18).
 *
 * Story 1 settled where each of these lands. This one writes them, and the whole of what these
 * tests check is **reach**: the rule is where its consumers look, and each consumer looks there.
 *
 * - FR16 goes in **Gate Presentation**, which twenty skills cite.
 * - FR17 goes in **Writing a Criterion**, a new section cited by the three skills that write
 *   criteria — `epics`, `quick`, `spec` — and by nobody else, since nobody else needs it.
 * - FR18 goes in `epics`' own body, because `epics` alone writes coverage bindings.
 *
 * **Nothing here pins a sentence.** A test asserting a rule's wording fires the day somebody
 * improves it, and whoever repairs the test learns that the test was about the string — after
 * which the rule is checked by nothing. So each assertion is over what the rule *requires*: the
 * obligation is stated in the section its consumers read, and the shortest clause carrying it is
 * what gets matched.
 *
 * **The reach assertions run against the whole corpus** rather than the three files this story
 * edits, which is the reading that cannot tell a rule reaching everyone from one reaching what was
 * in front of it — the failure the epic exists to remove.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync } from 'node:fs';
import { conventions, prose, section, skillSource } from './support/skills.js';

const SKILLS = new URL('../skills/', import.meta.url).pathname;

const CORPUS = readdirSync(SKILLS, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

/** Whether a skill names a shared section anywhere in its body, line wraps and all. */
const names = (skill, heading) => new RegExp(`\\*\\*${heading.replace(/ /g, '\\s+')}\\*\\*`)
  .test(skillSource(skill));

/** The skills that write criteria — the consumers **Writing a Criterion** was counted for. */
const CRITERION_WRITERS = ['epics', 'quick', 'spec'];

// --- Criterion 1 (FR16): the gate rule, where every gate-presenting skill reads ------------------

test('the gate rule is in the section its consumers cite, and they cite it [unit]', () => {
  // Read with whitespace collapsed, because the file is hard-wrapped and every phrase
  // worth matching straddles a line about half the time — story 1's sweep learned the same thing.
  const gate = prose(conventions(), 'Gate Presentation');

  assert.ok(gate.length > 0, 'Gate Presentation is not a section of the shared conventions');

  // **Two steps, performed as two.** Matched on the obligation rather than the sentence: the draft
  // is in the message that asks, and the reasoning the user cannot see is not where it lives.
  assert.match(gate, /two steps/);
  assert.match(gate, /same message/);
  assert.match(gate, /reasoning nobody can see|reasoning the user cannot see/);

  // And the second half, which is the one a run breaks by being helpful.
  assert.match(gate, /Nothing a gate decides is written before it is answered/);

  // **Reach.** Twenty of the twenty-three cite it, which is what put the rule here rather than in
  // any one body — asserted over the corpus so a citation dropped later shows up.
  const citers = CORPUS.filter((skill) => names(skill, 'Gate Presentation'));

  assert.ok(citers.length >= 18, `only ${citers.length} skills cite Gate Presentation`);
  for (const skill of ['do', 'epics', 'spec', 'quick', 'review']) {
    assert.ok(citers.includes(skill), `${skill} does not cite Gate Presentation`);
  }

  // **ENV6, held here rather than waiting for story 6**: the rule may not claim an enforcement the
  // harness does not have. A run told a badly-formed gate is refused leans on a net that is not
  // there, which is worse than the rule's absence.
  assert.doesNotMatch(gate, /the host (refuses|rejects|enforces)/i);
});

// --- Criterion 2 (FR17): the rejected outcome, at the three skills that write criteria ------------

test('the criterion-wording rule is shared, and the three writers cite it [unit]', () => {
  const rule = prose(conventions(), 'Writing a Criterion');

  assert.ok(rule.length > 0, 'Writing a Criterion is not a section of the shared conventions');

  // The obligation: name the outcome as though it happened, because the document negates it.
  assert.match(rule, /as though it had happened/);
  assert.match(rule, /double negative/);

  // **And the clause that only restates the denial is dropped, not inverted** — the half that
  // matters, because inverting one reverses what the spec says.
  assert.match(rule, /dropped, never inverted|dropped rather than inverted/);

  // **Reach, in both directions.** The three counted consumers cite it; nobody else does, because
  // a section cited by skills that never write a criterion is noise in twenty bodies.
  const citers = CORPUS.filter((skill) => names(skill, 'Writing a Criterion'));

  assert.deepEqual(citers, CRITERION_WRITERS);
});

// --- Criterion 3 (FR18): the binding rule, in the one body that writes bindings -------------------

test('the binding rule is in the breakdown skill and not in the shared conventions [unit]', () => {
  const shared = conventions();
  const epics = skillSource('epics').replace(/\s+/g, ' ');

  // **One consumer, so one body.** `epics` alone calls `create_coverage`; a shared section would
  // be a rule twenty-two skills carry and none of them can act on.
  const writers = CORPUS.filter((skill) => /create_coverage\b/.test(skillSource(skill)));

  assert.deepEqual(writers, ['epics'], 'more than one skill writes bindings, so the count moved');
  assert.equal(section(shared, 'Binding a Criterion'), '',
    'a single-consumer rule was put into the shared conventions');

  // The three obligations FR18 carries, each matched on what it requires.
  assert.match(epics, /not the nearest one that would pass|nearest verbatim/,
    'the rule does not say the clause is the one this criterion tests');
  assert.match(epics, /quotes the clause whose outcome it rejects/,
    'the must_not half of the rule is missing');
  assert.match(epics, /covered as far as its criteria go/,
    'the rule does not bound coverage by what the criteria measure');
});

// --- The rules reach a run, which is a property of the file rather than of any one rule ----------

test('every skill this story touched still reads the shared conventions [unit]', () => {
  // The channel the three shared rules travel by. A skill that stopped naming the file would take
  // none of them, and every assertion above would go on passing.
  for (const skill of [...CRITERION_WRITERS, 'do']) {
    assert.match(skillSource(skill), /dpm\/shared\/skill-conventions\.md/,
      `${skill} no longer reads the shared conventions`);
  }

  // **The control for the reach assertions**: the reading finds a section a skill does not cite,
  // so an empty answer above is the corpus's rather than the search's.
  assert.equal(names('templates', 'Writing a Criterion'), false);
  assert.equal(names('epics', 'Writing a Criterion'), true);
});
