/**
 * Epic 05-05 Story 3 — removing a binding attached to the wrong story (FR11).
 *
 * `coverage_story` is the join behind "Covered by: Story 1, Story 2" — a criterion may be
 * delivered by more than the story that declares it. Attaching one to the wrong story is the
 * third mistake FR11 names, and until now it had no recovery: the row carries no id of its own,
 * so there was nothing to hand a verb even if one had existed.
 *
 * **What this removes is the extra delivery, never the binding.** The coverage row is the thing a
 * ✓ is made about and nothing may delete it — a criterion in epic 04-02 says so, and a sweep over
 * `src/` enforces it. Taking a story off the "Covered by" list says a story does not deliver this;
 * it says nothing about whether the binding holds.
 *
 * **"The count at the place that reads bindings" is asserted where a reader actually sees it.**
 * `list_coverage_story` is the direct read, and the rendered coverage matrix is the published one
 * — the row's "Covered by" cell. Both are driven, because a delete that satisfied the list and
 * left the projection unchanged would be a row that is gone and still printed.
 *
 * **The fixture attaches two extra stories, not one.** "The count falls by exactly one" and "the
 * other bindings survive" are both vacuous against a coverage row with a single extra delivery —
 * one is indistinguishable from zero, and there is no sibling to be a survivor.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { renderDocument } from '../src/projection/index.js';
import { checkIntegrity } from '../src/integrity/check.js';

/** A coverage row delivered by its own story and by two others, plus a second binding beside it. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'recovery', title: 'Repair verbs' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'undo', title: 'Undoing a mistake' });

  const story = (number, title) => call.create_story({
    epic_id: epic.id, number, title, position: number - 1,
  });

  const declaring = story(1, 'The one that declares it');
  const alsoDelivers = story(2, 'The one that also delivers it');
  const wrong = story(3, 'The one that does not');

  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR11', class: 'functional', position: 0,
    text: 'A binding attached to the wrong story can be removed, and the row it extends survives.',
  });

  const criterion = call.create_story_criterion({
    story_id: declaring.id, text: 'The extra delivery is removed', polarity: 'must', position: 0,
  });
  const sibling = call.create_story_criterion({
    story_id: declaring.id, text: 'The binding itself survives', polarity: 'must', position: 1,
  });

  const binding = call.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: 'A binding attached to the wrong story can be removed',
    story_criterion_id: criterion.id,
    position: 0,
  });

  // A second binding on the same requirement, with an extra delivery of its own — so "the other
  // bindings survive" has something to be about.
  const other = call.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: 'the row it extends survives',
    story_criterion_id: sibling.id,
    position: 1,
  });

  call.create_coverage_story({ coverage_id: binding.id, story_id: alsoDelivers.id });
  call.create_coverage_story({ coverage_id: binding.id, story_id: wrong.id });
  call.create_coverage_story({ coverage_id: other.id, story_id: wrong.id });

  const matrix = call.create_coverage_matrix({
    parent_id: epic.id, slug: 'matrix', title: 'The matrix',
  });

  return {
    db, call, epic, matrix, binding, other, declaring, alsoDelivers, wrong, requirement,
  };
}

/** Every story a coverage row's extra deliveries name, sorted. */
const deliveredBy = (call, coverage) => call
  .list_coverage_story({ coverage_id: coverage.id }).items
  .map((row) => row.story_id)
  .sort();

/**
 * The rendered matrix's "Covered by" cell for a binding, as the stories it names.
 *
 * The column is found by its heading rather than by a position, so a matrix that grows a column
 * moves this reading with it instead of silently handing back the neighbour — which is what the
 * first draft did, and it read as the declaring story having vanished.
 */
function coveredBy(db, matrix, fragment) {
  const lines = renderDocument(db, matrix.id).text.split('\n');
  const cells = (line) => line.split('|').map((cell) => cell.trim());

  const header = lines.find((line) => line.includes('Covered by'));
  const line = lines.find((row) => row.includes(fragment));

  assert.ok(header, 'the matrix has no "Covered by" column');
  assert.ok(line, `the matrix does not render the binding quoting '${fragment}'`);

  return cells(line)[cells(header).indexOf('Covered by')];
}

// --- Criterion 1 (must): the wrong delivery goes, and the count falls by exactly one --------------

test('a binding attached to the wrong story is removed [integration]', (t) => {
  const { db, call, matrix, binding, alsoDelivers, wrong } = surface(t);

  const before = deliveredBy(call, binding);

  assert.deepEqual(before, [alsoDelivers.id, wrong.id].sort(),
    'the fixture did not attach the two deliveries this story is about');

  const removed = call.delete_coverage_story({
    coverage_id: binding.id, story_id: wrong.id,
  });

  // The row as it was, because a delete is the one call with nothing left to look at.
  assert.equal(removed.coverage_id, binding.id);
  assert.equal(removed.story_id, wrong.id);

  // **A delta, not a literal.** The criterion states a count, and a count asserted against a fixed
  // number is a change detector that fires the day the fixture grows a story.
  const after = deliveredBy(call, binding);

  assert.equal(after.length, before.length - 1, 'the count did not fall by exactly one');
  assert.deepEqual(after, [alsoDelivers.id], 'the removal took a delivery it was not aimed at');

  // **And at the place a reader sees it.** The matrix's "Covered by" cell is where this count is
  // published; a delete that satisfied the list and left the projection alone would be a row that
  // is gone and still printed.
  const cell = coveredBy(db, matrix, 'A binding attached to the wrong story can be removed');

  assert.match(cell, /Story 1/, 'the declaring story stopped being named');
  assert.match(cell, /Story 2/, 'the delivery that should have survived is not rendered');
  assert.doesNotMatch(cell, /Story 3/, 'the removed delivery is still published');
});

test('removing a delivery that is not there is refused rather than reported as done [integration]', (t) => {
  const { call, binding, declaring, wrong } = surface(t);

  call.delete_coverage_story({ coverage_id: binding.id, story_id: wrong.id });

  // A caller that has lost track is told so, rather than told "deleted" about a row that was never
  // there — the same reason `deleteById` reads before it writes.
  assert.throws(
    () => call.delete_coverage_story({ coverage_id: binding.id, story_id: wrong.id }),
    /delete_coverage_story/,
  );

  // **The declaring story is not among the deliveries**, and asking to remove it is a miss rather
  // than a way to take a story off its own criterion. That relationship is `story_criterion`, not
  // this join, and a delete that quietly succeeded here would suggest otherwise.
  assert.throws(
    () => call.delete_coverage_story({ coverage_id: binding.id, story_id: declaring.id }),
    /delete_coverage_story/,
  );
});

// --- Criterion 2 (control): the coverage row and its other bindings survive ------------------------

test('control — the coverage row and its other bindings survive the removal [integration]', (t) => {
  const { db, call, binding, other, alsoDelivers, wrong, requirement } = surface(t);

  const marked = call.update_coverage({ id: binding.id, verified: true });

  assert.ok(marked.binding_hash, 'the fixture recorded no verification to be at risk');

  call.delete_coverage_story({ coverage_id: binding.id, story_id: wrong.id });

  // **The binding itself, with its mark intact.** Removing a delivery says a story does not
  // deliver this; it says nothing about whether the fragment was checked against the criterion.
  const kept = call.read_coverage({ id: binding.id, include_body: true });

  assert.equal(kept.spec_fragment, 'A binding attached to the wrong story can be removed');
  assert.equal(kept.verified_at, marked.verified_at, 'the removal cleared the verification');
  assert.equal(kept.binding_hash, marked.binding_hash);
  assert.equal(kept.retired_at, null);

  // Both coverage rows are still bound to the requirement — the delete reached the join and
  // nothing above it.
  assert.equal(call.list_coverage({ requirement_id: requirement.id }).items.length, 2);

  // **And the other binding's delivery by the very same story is untouched**, which is the half a
  // delete keyed on `story_id` alone would have got wrong. `wrong` delivers both rows here.
  assert.deepEqual(deliveredBy(call, other), [wrong.id],
    "the other binding's delivery by the same story went with it");
  assert.deepEqual(deliveredBy(call, binding), [alsoDelivers.id]);

  // Nothing the register watches was broken by the removal.
  assert.deepEqual(checkIntegrity(db).violations.filter((violation) => violation.entry === 11), []);
});

// --- The verb is named by its key, which is the only way to name it --------------------------------

test('delete_coverage_story takes the pair that identifies the row [unit]', (t) => {
  const { db, call } = surface(t);
  const tool = spineTools(db).find((entry) => entry.name === 'delete_coverage_story');

  assert.deepEqual(tool.inputSchema.required.sort(), ['coverage_id', 'story_id']);
  assert.equal('id' in tool.inputSchema.properties, false,
    'the join was given a surrogate id it does not have');

  // **Both halves are required**, because either alone names a set rather than a row — one
  // coverage row's every delivery, or one story's every delivery. Deleting a set is not what this
  // verb is, and the schema is where that is said.
  assert.throws(() => call.delete_coverage_story({ coverage_id: 'x' }), /required/);
  assert.throws(() => call.delete_coverage_story({ story_id: 'x' }), /required/);
});
