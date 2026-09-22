/**
 * Epic 05-05 Story 1 — withdrawing an observation written twice (FR11).
 *
 * **This story ships no code, and that is its finding.** FR11 asks that three mistakes a run makes
 * be undoable, and names an observation written twice among them — but the surface already answers
 * this one: `update_observation` takes `retired_at` and `retired_reason`, the table's `CHECK` pairs
 * them so a date with no reason is refused, and `list_observation` omits retired rows unless
 * `include_retired` asks for them. A `retire_observation` verb would have been a second way to do
 * one thing, and taking the columns off the update to avoid that would break `/dpm:retro learn`,
 * which writes the promotion link and the retirement in one call on purpose.
 *
 * So what was missing was not the capability but the evidence. Nothing asserted the recovery
 * *as a recovery* — the existing coverage of these columns is about the `CHECK` and about what a
 * skill's prose says, neither of which would notice `list_observation` starting to return retired
 * rows. This file is that assertion.
 *
 * **Every fixture below holds two of whatever is being withdrawn**, because both criteria are of
 * the shape that goes vacuous on a corpus of one: "the withdrawn row stops appearing" cannot be
 * told from "the list returns nothing" against a retro with a single observation, and the control
 * that a sibling survives has nothing to be a sibling of.
 *
 * Two gaps this does *not* close, recorded rather than absorbed: retiring twice silently restamps
 * the date, losing when the decision was made; and `retired_at` is a caller-supplied timestamp,
 * which is what epic 05-03 removed from every other stamp in the project.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

const WITHDRAWN = '2026-09-21T18:00:00.000Z';

/**
 * A retro holding two observations, one of them the duplicate, plus a third under a story.
 *
 * Two under the retro because that is the corpus the criteria need; the third is under a *story*
 * so the story-scoped list — the other list that gathers observations — is exercised by a row of
 * its own rather than by the same row read a second way.
 */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'recovery', title: 'Repair verbs' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'undo', title: 'Undoing a mistake' });
  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'Withdraw', position: 0 });
  const retro = call.create_retro({ parent_id: epic.id, slug: 'first', title: 'The first retro' });

  const text = 'The sweep read the suite\'s own planted controls as findings.';

  // **The mistake, as it actually happens**: the same lesson written twice under one retro, the
  // second time because the run had lost track of the first. Same text, different positions —
  // which nothing refuses, and should not, since two runs may genuinely observe the same thing.
  const first = call.create_observation({ retro_id: retro.id, text, position: 0 });
  const duplicate = call.create_observation({ retro_id: retro.id, text, position: 1 });
  const sibling = call.create_observation({
    retro_id: retro.id, text: 'A different lesson entirely.', position: 2,
  });
  const fromStory = call.create_observation({
    story_id: story.id, text: 'Written against the story rather than the retro.',
  });

  const withdraw = (id, reason) => call.update_observation({
    id, retired_at: WITHDRAWN, retired_reason: reason,
  });

  return { db, call, retro, story, first, duplicate, sibling, fromStory, withdraw };
}

/** The ids a list returns, which is what both criteria are actually about. */
const idsOf = (page) => page.items.map((row) => row.id).sort();

// --- Criterion 1 (must): the duplicate is withdrawn and leaves the gathering lists ---------------

test('an observation written twice is withdrawn and stops being gathered [integration]', (t) => {
  const { call, retro, first, duplicate, sibling, withdraw } = surface(t);

  assert.deepEqual(
    idsOf(call.list_observation({ retro_id: retro.id })),
    [first.id, duplicate.id, sibling.id].sort(),
    'the fixture did not write the duplicate this story is about',
  );

  const withdrawn = withdraw(duplicate.id, 'written twice — the first row says the same thing');

  assert.equal(withdrawn.retired_at, WITHDRAWN);
  assert.equal(withdrawn.retired_reason, 'written twice — the first row says the same thing');

  // **The list a retro is gathered from, which is the place the miscount happened.** Two rows
  // saying one thing is a miscount at the only place that reads them, and this is that place.
  assert.deepEqual(
    idsOf(call.list_observation({ retro_id: retro.id })),
    [first.id, sibling.id].sort(),
    'the withdrawn duplicate is still gathered into its retro',
  );

  // **And the row is still there**, which is the whole difference between withdrawing and
  // deleting — the historical question, what did this retro hear, is one somebody asks.
  const audited = call.list_observation({ retro_id: retro.id, include_retired: true, include_body: true });

  assert.deepEqual(idsOf(audited), [first.id, duplicate.id, sibling.id].sort());
  assert.equal(
    audited.items.find((row) => row.id === duplicate.id).retired_reason,
    'written twice — the first row says the same thing',
    'the withdrawal kept no record of why it was made',
  );
});

test('a withdrawal leaves the story-scoped list as well as the retro one [integration]', (t) => {
  const { call, story, fromStory, withdraw } = surface(t);

  // The other list that gathers observations, on a row of its own. `/dpm:retro` reads both — the
  // retro scope when it is grouping, the story scope when it is collecting — so a withdrawal that
  // held in one and not the other would be a row that is gone and still counted.
  assert.deepEqual(idsOf(call.list_observation({ story_id: story.id })), [fromStory.id]);

  withdraw(fromStory.id, 'the observation it duplicated was written against the epic');

  assert.deepEqual(idsOf(call.list_observation({ story_id: story.id })), []);
  assert.deepEqual(
    idsOf(call.list_observation({ story_id: story.id, include_retired: true })),
    [fromStory.id],
    'the row was deleted rather than withdrawn',
  );
});

// --- Criterion 2 (control): the live sibling is untouched -----------------------------------------

test('control — a live observation under the same retro goes on being returned [integration]', (t) => {
  const { call, retro, first, duplicate, sibling, withdraw } = surface(t);

  withdraw(duplicate.id, 'written twice');

  // **Named rather than counted.** A count of two after the withdrawal is satisfied by a list that
  // returned the wrong two; the criterion is that *these* rows survive, so it names them.
  const live = call.list_observation({ retro_id: retro.id, include_body: true });

  assert.deepEqual(idsOf(live), [first.id, sibling.id].sort(),
    'the withdrawal reached a row it was not aimed at');

  // The surviving twin still says what it said — the withdrawal took the duplicate and not the
  // text they shared, which is the failure a retirement keyed on text rather than id would produce.
  const survivor = live.items.find((row) => row.id === first.id);

  assert.equal(survivor.retired_at, null);
  assert.match(survivor.text, /planted controls/);
  assert.equal(live.items.find((row) => row.id === sibling.id).retired_at, null);
});

// --- What the pair costs, and what it does not -----------------------------------------------------

test('a withdrawal records its reason or does not happen [integration]', (t) => {
  const { call, duplicate } = surface(t);

  // **The reason is not optional, and it is the database that says so.** A withdrawal with a date
  // and no reason is a decision with no record of why it was made — which is the state FR11's
  // "two rows saying one thing" is the visible half of.
  assert.throws(
    () => call.update_observation({ id: duplicate.id, retired_at: WITHDRAWN }),
    /CHECK constraint/,
    'an observation was withdrawn without a reason',
  );

  assert.equal(call.read_observation({ id: duplicate.id }).retired_at, null,
    'the refusal left the row half-withdrawn');
});
