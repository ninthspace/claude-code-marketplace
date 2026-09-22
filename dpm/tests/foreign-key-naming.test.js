/**
 * Epic 05-04 Story 1 — a foreign-key failure names the column and the table (FR7).
 *
 * SQLite says `FOREIGN KEY constraint failed` and stops. No column, no table, no value. That is
 * bearable on a write carrying one id and useless on one carrying four: `create_coverage` names a
 * requirement and a criterion, `create_finding` names a review, a category, a severity and a task,
 * and a caller told only that a foreign key failed has to try them one at a time.
 *
 * **The answer is worked out after the failure, never before the write.** `missingParent` runs
 * only once a constraint has already fired, so the common path pays nothing — and, more to the
 * point, it is not a second enforcement point that has to agree with the database about what a
 * reference is. It reads `PRAGMA foreign_key_list`, which *is* the database's answer.
 *
 * **Two cases the first draft got wrong, both kept here as tests rather than as comments.** A
 * composite reference is named whole, because which half is the caller's mistake is not knowable
 * from the failure — blaming the leading column reported a review's own kind as unknown when what
 * was wrong was its parent. And a reference can be half-defaulted: `finding(category_id,
 * category_domain)` has the domain from the schema, so reading only the supplied columns made that
 * reference look unsupplied and skipped the probe on exactly the mix-up this story is for.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { missingParent } from '../src/tools/foreign-keys.js';

/** A spec with a story and a criterion beneath it, and a requirement to bind against. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'refusals', title: 'Refusals that name a way out' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'naming', title: 'Naming' });
  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'Name it', position: 0 });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The refusal names the column', polarity: 'must', position: 0,
  });
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR7', class: 'functional', position: 0,
    text: 'A write that misses a parent row names the column that missed and the table it points at.',
  });

  return { db, call, spec, epic, story, criterion, requirement };
}

/** Run something expected to be refused, and hand back the error it raised. */
function refused(run, message) {
  let caught;

  try {
    run();
  } catch (error) {
    caught = error;
  }

  assert.ok(caught, message ?? 'the call was accepted when it should have been refused');

  return caught;
}

// --- Criterion 1 (must): the column and its table, on a call carrying several ids -----------------

test('a write missing a parent names the column and the table, among several ids [integration]', (t) => {
  const { call, requirement, criterion } = surface(t);

  // **Four ids, only one of them wrong**, which is the case the criterion names and the case
  // SQLite's own message is useless for. The requirement and the criterion both exist; the story
  // does not.
  const error = refused(() => call.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: 'names the column that missed',
    story_criterion_id: 'no-such-criterion',
    position: 0,
  }), 'a binding was written against a criterion that does not exist');

  assert.match(error.message, /story_criterion_id 'no-such-criterion'/,
    'the refusal does not name the column whose value missed');
  assert.match(error.message, /\bstory_criterion\b/,
    'the refusal does not name the table that column points at');

  // **The ids that were right are not named**, which is the whole of the improvement: a refusal
  // listing every reference on the call is the bare message with extra words.
  assert.doesNotMatch(error.message, new RegExp(requirement.id));

  // It is a refusal and not a crash — the boundary code, so a caller can tell a bad call from a
  // broken server.
  assert.equal(error.rpc.code, -32602);
});

test('a composite reference is named whole, both halves and the table [integration]', (t) => {
  const { call, spec } = surface(t);
  const retro = call.create_retro({ parent_id: spec.id, slug: 'r', title: 'A retro' });

  // A review under a retro. Both halves are legal on their own — `review` is a kind and `retro` is
  // a kind — and only the pair is refused, so naming one of them would send the caller to a value
  // that is not wrong.
  const error = refused(() => call.create_review({
    parent_id: retro.id, slug: 'nope', title: 'A review of a retro',
  }));

  assert.match(error.message, /kind 'review' and parent_kind 'retro'/);
  assert.match(error.message, /document_kind_parent/);
});

test('a half-defaulted reference is probed, using what the schema supplies [integration]', (t) => {
  const { call, spec } = surface(t);
  const review = call.create_review({ parent_id: spec.id, slug: 'rev', title: 'A review' });

  // `finding(severity_id, severity_domain)` points at `taxonomy`, and the domain comes from the
  // schema rather than the call. A probe reading only the columns a caller supplied finds the pair
  // incomplete and skips it — which is how the first draft let the commonest vocabulary mix-up
  // fall through to SQLite's own words.
  const error = refused(() => call.create_finding({
    review_id: review.id,
    position: 0,
    summary: 'A term from the wrong vocabulary',
    category_id: 'finding:unclear-requirements',
    severity_id: 'finding:unclear-requirements',
  }), 'a finding category was accepted in the severity slot');

  assert.match(error.message, /severity_id 'finding:unclear-requirements'/);
  assert.match(error.message, /severity_domain 'severity'/,
    'the defaulted half of the reference is not named, so the domain mix-up is invisible');
  assert.match(error.message, /taxonomy/);
});

// --- Criterion 2 (control): a healthy write is untouched -------------------------------------------

test('control — a write whose parents all exist succeeds unchanged [integration]', (t) => {
  const { call, requirement, criterion, story } = surface(t);

  // The rejection's own call, differing in one id. Without this the assertions above are equally
  // satisfied by a handler that refused every write carrying a reference.
  const binding = call.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: 'names the column that missed',
    story_criterion_id: criterion.id,
    position: 0,
  });

  assert.equal(binding.story_criterion_id, criterion.id);
  assert.equal(binding.requirement_id, requirement.id);

  // **And an update, which reaches the same code by the other statement.** A probe wired to the
  // insert alone would pass everything above and leave every update reporting the bare message.
  assert.equal(call.update_coverage({ id: binding.id, position: 3 }).position, 3);

  const observation = call.create_observation({
    story_id: story.id, text: 'Something the story turned up.',
  });

  const moved = refused(() => call.update_observation({
    id: observation.id, retro_id: 'no-such-retro',
  }), 'an observation was gathered into a retro that does not exist');

  assert.match(moved.message, /retro_id 'no-such-retro'/);
  assert.match(moved.message, /\bdocument\b/);

  // A reference the call never made is not a reference that missed. `create_story` names an epic
  // and nothing else; the row goes in with every other reference absent.
  assert.equal(call.create_story({
    epic_id: story.epic_id, number: 2, title: 'Nothing else named', position: 1,
  }).number, 2);
});

// --- The probe itself, where the tool surface cannot reach it -------------------------------------

test('the probe answers nothing where every supplied reference resolves [unit]', (t) => {
  const { db, criterion, story } = surface(t);

  // **`null` is the honest answer when the constraint that fired was somebody else's.** A probe
  // that named a reference anyway would blame a healthy id for a UNIQUE or a CHECK failure, and
  // the caller would go and check a value that is correct.
  assert.equal(missingParent(db, 'story_criterion', { story_id: story.id, text: 't' }), null);

  // An absent or null reference is not one that missed — it is one not made, and SQLite does not
  // enforce it.
  assert.equal(missingParent(db, 'story_criterion', { story_id: story.id, warrant_adr_id: null }),
    null);

  // And the answer when there is one carries the parent table, which is what the message needs and
  // what SQLite withholds.
  assert.deepEqual(missingParent(db, 'coverage', {
    requirement_id: 'nope', spec_fragment: 'x', story_criterion_id: criterion.id,
  }), {
    parent: 'requirement',
    columns: [{ column: 'requirement_id', value: 'nope' }],
  });
});
