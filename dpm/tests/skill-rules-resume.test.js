/**
 * Epic 05-06 Story 3 — the resume rule and the read-back rule (FR19, FR20).
 *
 * Both go in **Session Startup**, which twenty skills cite, and both are about the same seam:
 * `state` records where a run *believed* it had reached, and the rows record what it actually did.
 * They part company exactly when a run is interrupted between a write and the update that would
 * have noted it — which is the case a resume is for.
 *
 * **They are subsections rather than a new shared section, and that is the placement decision.**
 * Story 1's table put both in **Session Startup** on a count of twenty consumers; a section of
 * their own would have needed twenty citation lines edited to reach the same runs, and any skill
 * that missed one would resume without the rule while still reading the file that holds it.
 *
 * As in story 2, nothing here pins a sentence — each assertion matches the shortest clause carrying
 * the obligation, with whitespace collapsed because the file is hard-wrapped.
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

/** The whole of Session Startup, subsections included, with whitespace collapsed. */
const startup = () => prose(conventions(), 'Session Startup');

// --- Criterion 1 (FR19): a resumed step lists before it proposes ---------------------------------

test('a resumed step is told to list its rows before proposing anything [unit]', () => {
  const rule = startup();

  // **The seam, stated.** Without it the rule reads as bureaucracy; with it, a run knows why the
  // list is not optional.
  assert.match(rule, /the rows say what was written and `state` does not/);

  // The obligation: list under the parent, propose only what is missing, never re-propose a row
  // the list just returned.
  assert.match(rule, /lists the rows that step writes/);
  assert.match(rule, /under the parent it writes them to/);
  assert.match(rule, /proposes only what is missing/);
  assert.match(rule, /Never a row a list has just returned/);

  // **The per-parent half**, which is the one a production loop needs and the one `state` cannot
  // express: some parents have their rows and some do not.
  assert.match(rule, /resumes at the first parent without them/);

  // And the per-skill part is named as per-skill, which is what keeps the shared rule general —
  // only the skill knows which lists its own step produces.
  assert.match(rule, /Each skill names the ordered read for its own step/);
});

// --- Criterion 2 (FR20): read-backs batch, check by label, count from the report -------------------

test('read-backs are told to batch, check by label and count from the report [unit]', () => {
  const rule = startup();

  // One message, not one per row.
  assert.match(rule, /read back before the next unit begins/);
  assert.match(rule, /in \*\*one\*\* message/);

  // **By label, never by an id the run is holding** — the difference between checking the row and
  // checking that two calls agree.
  assert.match(rule, /checked by its label, never by an id held from an earlier call/);

  // And the count comes from the report, which is the half that catches a run that wrote fewer
  // rows than it thinks.
  assert.match(rule, /comes from the last report, not from a tally of the calls sent/);
});

// --- Both rules reach the runs they were counted for ----------------------------------------------

test('both rules sit in the section twenty skills cite, and they still cite it [unit]', () => {
  // **Subsections of Session Startup**, so they travel with a section already cited rather than
  // needing twenty citation lines edited to reach the same runs.
  assert.ok(section(conventions(), 'Resuming a step').length > 0,
    'the resume rule is not a section of the shared conventions');
  assert.ok(section(conventions(), 'Reading back what was written').length > 0);

  // Reach, over the whole corpus rather than over the skills this story edited — which is none.
  const citers = CORPUS.filter((skill) => /\*\*Session\s+Startup\*\*/.test(skillSource(skill)));

  assert.ok(citers.length >= 18, `only ${citers.length} skills cite Session Startup`);
  for (const skill of ['do', 'epics', 'spec', 'quick', 'review', 'retro']) {
    assert.ok(citers.includes(skill), `${skill} does not cite Session Startup`);
  }

  // **The control for the reading**: a skill that genuinely does not cite it is found not to.
  // `templates` opens no session, so it is the honest negative rather than a contrived one.
  assert.equal(citers.includes('templates'), false);
});

test('neither rule claims an enforcement the harness does not have [unit]', () => {
  const rule = startup();

  // ENV6, held as the rule is written. The resume rule is the one that invites it — a run would
  // like to be told the harness replays what it missed, and nothing does.
  assert.doesNotMatch(rule, /the host (refuses|rejects|enforces|replays|restores)/i);
  assert.doesNotMatch(rule, /automatically (resumes|replays|re-?runs)/i);

  // And it does not promise that `state` survives what it does not: the rule's whole point is that
  // the rows are the record precisely because `state` can be behind them.
  assert.doesNotMatch(rule, /`state` is always|state always reflects/);
});
