/**
 * Epic 05-05 Story 2 — removing a dependency edge written the wrong way round (FR11).
 *
 * **The mistake this recovers from is self-sealing, which is why it needs a verb.** A run writes
 * `A blocks B` when it meant `B blocks A`. Noticing, it writes the correct edge — and
 * `create_dependency` refuses it, because together the two close a cycle over a kind that gates
 * work. The wrong edge is now the thing standing between the project and the right one, and
 * without a way to remove it the only recoveries are hand-written SQL or a third row that makes
 * the graph worse.
 *
 * **So this one deletes where story 1 retires, and the asymmetry is the epic's own reasoning.** A
 * withdrawn observation stays readable because "what did this retro hear?" is a question somebody
 * asks. A withdrawn *edge* would either go on constraining the graph — in which case the recovery
 * is still impossible — or stop being an edge, which is deletion with extra columns.
 *
 * **The fixture carries four edges, not one.** Both criteria are claims about what a removal
 * leaves behind, and an assertion that a delete left something alone is vacuous when the fixture
 * holds only the thing being deleted. The control names the survivors by id rather than counting
 * them, so a list that returned the wrong three would fail it.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { checkIntegrity } from '../src/integrity/check.js';

/** Three stories under one epic, and the edges between them. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'recovery', title: 'Repair verbs' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'undo', title: 'Undoing a mistake' });

  const story = (number, title) => call.create_story({
    epic_id: epic.id, number, title, position: number - 1,
  });

  const first = story(1, 'The scaffolding');
  const second = story(2, 'The integration');
  const third = story(3, 'Elsewhere entirely');
  const fourth = story(4, 'Further along');

  const link = (kind, source, target) => call.create_dependency({
    kind, source_story_id: source.id, target_story_id: target.id,
  });

  return { db, call, epic, first, second, third, fourth, link };
}

/** The ids a list returns, which is what the control is actually about. */
const idsOf = (page) => page.items.map((row) => row.id).sort();

// --- Criterion 1 (must): the wrong edge goes, and the right one can then be written ---------------

test('an edge written the wrong way round is removed and the correct one written [integration]', (t) => {
  const { db, call, first, second, link } = surface(t);

  // The mistake: the scaffolding recorded as blocked by the integration, which is backwards.
  const wrong = link('blocks', second, first);

  // **The refusal that makes this a trap rather than an untidiness**, driven rather than described
  // — without it, a test that deleted an edge and wrote another would pass against a graph where
  // the first was never in the way.
  assert.throws(
    () => link('blocks', first, second),
    /close a cycle/,
    'the wrong edge did not actually block the right one, so this fixture proves nothing',
  );

  const removed = call.delete_dependency({ id: wrong.id });

  // **The row as it was, because a delete is the one call with nothing left to look at.** A run
  // reporting what it undid, or putting it back, has no second chance to ask.
  assert.equal(removed.id, wrong.id);
  assert.equal(removed.source_story_id, second.id);
  assert.equal(removed.target_story_id, first.id);

  assert.throws(() => call.read_dependency({ id: wrong.id }), /dependency/);

  // And now the edge that was meant goes in, which is the whole of the recovery.
  const right = link('blocks', first, second);

  assert.equal(right.source_story_id, first.id);
  assert.equal(right.target_story_id, second.id);

  // The graph is sound afterwards — no cycle left behind by the removal, which is the state the
  // register would report and the one a recovery must not create.
  assert.deepEqual(checkIntegrity(db).violations.filter((violation) => violation.entry === 1), []);
});

test('removing a row that is not there is refused rather than reported as done [integration]', (t) => {
  const { call, first, second, link } = surface(t);
  const edge = link('blocks', first, second);

  call.delete_dependency({ id: edge.id });

  // **A second delete is a caller that has lost track**, and reporting success would tell them
  // something false about their own database — the same reason `retire_coverage` refuses a second
  // retirement rather than restamping it.
  assert.throws(() => call.delete_dependency({ id: edge.id }), /delete_dependency/);
  assert.throws(() => call.delete_dependency({ id: 'not-an-edge' }), /delete_dependency/);
});

// --- Criterion 2 (control): every other edge of that kind stays ------------------------------------

test('control — removing one edge leaves every other edge of that kind in place [integration]', (t) => {
  const { call, epic, first, second, third, fourth, link } = surface(t);

  const wrong = link('blocks', second, first);
  const sibling = link('blocks', first, third);
  const alsoGating = link('blocks', third, fourth);
  const other = link('builds_on', second, third);

  call.delete_dependency({ id: wrong.id });

  // **Named, not counted.** Three edges remaining is equally true of a delete that took the wrong
  // one, so the criterion is that *these* survive.
  assert.deepEqual(
    idsOf(call.list_dependency({ kind: 'blocks' })),
    [sibling.id, alsoGating.id].sort(),
    'the removal reached an edge it was not aimed at',
  );

  // The other kind is untouched too, which is the half a delete keyed on the pair of ends rather
  // than on the id would have got wrong — `second → third` exists under both kinds here.
  assert.deepEqual(idsOf(call.list_dependency({ kind: 'builds_on' })), [other.id]);

  // And readable, not merely present: each survivor still names both its ends.
  const survivor = call.read_dependency({ id: sibling.id });

  assert.equal(survivor.source_story_id, first.id);
  assert.equal(survivor.target_story_id, third.id);

  // Nothing else in the graph moved — the stories and the epic that hold the edges are untouched,
  // which is what says the delete reached one row rather than cascading.
  assert.equal(call.list_story({ epic_id: epic.id }).items.length, 4);
});

// --- The verb is on the surface, and it is not on the tables that retire ---------------------------

test('delete_dependency is registered, and the edge is the only thing it removes [unit]', (t) => {
  const { call } = surface(t);

  assert.equal(typeof call.delete_dependency, 'function');

  // **An edge between documents as well as between stories**, because the four end columns are two
  // pairs and a delete by id has no reason to care which pair is filled — asserted rather than
  // assumed, since every other test in this file uses the story ends.
  const spec = call.create_spec({ slug: 'across', title: 'Across documents' });
  const before = call.create_epic({ parent_id: spec.id, slug: 'one', title: 'One' });
  const after = call.create_epic({ parent_id: spec.id, slug: 'two', title: 'Two' });

  const edge = call.create_dependency({
    kind: 'blocks', source_document_id: before.id, target_document_id: after.id,
  });

  assert.equal(call.delete_dependency({ id: edge.id }).source_document_id, before.id);
  assert.deepEqual(call.list_dependency({ kind: 'blocks' }).items, []);
});
