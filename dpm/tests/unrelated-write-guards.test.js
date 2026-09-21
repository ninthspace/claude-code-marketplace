/**
 * Epic 05-02 Story 5 — three guards with nothing in common but their shape (FR12, FR13, FR14).
 *
 * A tradeoff assessing an option its decision does not hold, a second live criterion saying what a
 * sibling already says, and a story from another epic delivering this epic's binding. Three
 * unrelated tables; one failure mode — a write that is legal today, errors nowhere, and records
 * something nobody decided.
 *
 * **Three rejections, three tests, and that is the point rather than the layout.** Written as one
 * test with three assertions, only the first to fail would ever be evidence: a mutation breaking
 * the third would stop at the first's assertion and never reach it, and the third would read as
 * verified on the strength of a neighbour. Each here drives its own rows and can go red alone.
 *
 * Each control is the *legitimate neighbour* of its rejection — the call differing in one thing —
 * because a guard that refuses the neighbour too is a guard nobody can work with, and no assertion
 * about the refusal alone would notice.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

/** A spec with two epics, so a cross-epic mistake is expressible. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'guards', title: 'Three guards' });
  const here = call.create_epic({ parent_id: spec.id, slug: 'here', title: 'This epic' });
  const elsewhere = call.create_epic({ parent_id: spec.id, slug: 'elsewhere', title: 'Another' });

  return { db, call, spec, here, elsewhere };
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

// --- FR12: a tradeoff on an option the decision does not hold -------------------------------------

test('must NOT — a tradeoff assesses an option its decision does not hold [integration]', (t) => {
  const { db, call, spec } = surface(t);

  const decision = call.create_adr({
    parent_id: spec.id, slug: 'ours', title: 'Ours', decision: 'This way.',
  });
  const other = call.create_adr({
    parent_id: spec.id, slug: 'theirs', title: 'Theirs', decision: 'That way.',
  });

  call.create_adr_option({ adr_id: decision.id, name: 'Take the seam', position: 0 });
  call.create_adr_option({ adr_id: decision.id, name: 'Write it twice', position: 1 });

  const foreign = call.create_adr_option({
    adr_id: other.id, name: 'An option of a different decision', position: 0,
  });

  // **The option exists, so no foreign key fires.** This is the row that is accepted today and
  // quietly assesses somebody else's option — the failure a constraint cannot reach, and the reason
  // the call names its decision.
  const error = refused(() => call.create_adr_option_tradeoff({
    adr_id: decision.id, option_id: foreign.id, axis: 'cost', assessment: 'Low.',
  }), "a tradeoff assessed another decision's option");

  assert.equal(db.prepare('SELECT count(*) AS n FROM adr_option_tradeoff').get().n, 0);

  // **The real set, not a verdict on the value given.** FR12's second criterion: the caller is
  // handed the options the decision holds, so they can pick the one they meant.
  assert.match(error.message, /Take the seam/);
  assert.match(error.message, /Write it twice/);

  // An invented id reaches the same refusal by the same route, which is the case the requirement
  // names — a plausible value written where a read one belongs.
  assert.match(
    refused(() => call.create_adr_option_tradeoff({
      adr_id: decision.id, option_id: 'not-an-option', axis: 'risk', assessment: 'Low.',
    })).message,
    /does not hold the option/,
  );
});

test('control — a tradeoff on an option the decision does hold is written [integration]', (t) => {
  const { call, spec } = surface(t);

  const decision = call.create_adr({
    parent_id: spec.id, slug: 'ours', title: 'Ours', decision: 'This way.',
  });
  const option = call.create_adr_option({
    adr_id: decision.id, name: 'Take the seam', position: 0,
  });

  const row = call.create_adr_option_tradeoff({
    adr_id: decision.id, option_id: option.id, axis: 'cost', assessment: 'Low.',
  });

  assert.equal(row.option_id, option.id);

  // **`adr_id` is checked and not stored**, which is what keeps the decision one fact in one place:
  // the option already names its ADR, and a copy here would be the second place to disagree.
  assert.equal('adr_id' in row, false, 'the decision was written onto the tradeoff row');
});

// --- FR13: a second live criterion with the same text under one story ----------------------------

test('must NOT — a second live criterion repeats a sibling under one story [integration]', (t) => {
  const { db, call, here } = surface(t);
  const story = call.create_story({
    epic_id: here.id, number: 1, title: 'A story', position: 0,
  });

  call.create_story_criterion({ story_id: story.id, text: 'The write is refused', position: 0 });

  const error = refused(() => call.create_story_criterion({
    story_id: story.id, text: 'The write is refused', position: 1,
  }), 'one story took the same obligation twice');

  assert.equal(db.prepare('SELECT count(*) AS n FROM story_criterion').get().n, 1);

  // The twin's position, because that is what the caller goes and looks at.
  assert.match(error.message, /at position 0/);
});

test('control — the same text under another story, and a superseded twin, are written [integration]', (t) => {
  const { call, here } = surface(t);
  const first = call.create_story({ epic_id: here.id, number: 1, title: 'One', position: 0 });
  const second = call.create_story({ epic_id: here.id, number: 2, title: 'Two', position: 1 });

  call.create_story_criterion({ story_id: first.id, text: 'The write is refused', position: 0 });

  // **Two stories may owe the same obligation**, which the coverage report *warns* about and this
  // rule does not touch — a refusal here would make the state the warning reports unreachable, and
  // the warning would then be a check about nothing.
  assert.ok(call.create_story_criterion({
    story_id: second.id, text: 'The write is refused', position: 0,
  }).id);

  // **And a superseded criterion keeps its text**, so restating one an amendment overtook is the
  // ordinary way of correcting a criterion. Counting those would make that impossible.
  const overtaken = call.create_story_criterion({
    story_id: first.id, text: 'An earlier wording', position: 1,
  });

  call.update_story_criterion({
    id: overtaken.id,
    superseded_at: '2026-09-21T00:00:00Z',
    superseded_reason: 'the requirement it read was amended',
  });

  assert.ok(call.create_story_criterion({
    story_id: first.id, text: 'An earlier wording', position: 2,
  }).id, 'a criterion could not restate the text of one an amendment had overtaken');
});

// --- FR14: a binding delivered by a story in another epic -----------------------------------------

test('must NOT — a story from another epic delivers this epic\'s binding [integration]', (t) => {
  const { db, call, spec, here, elsewhere } = surface(t);

  const story = call.create_story({ epic_id: here.id, number: 1, title: 'Mine', position: 0 });
  const far = call.create_story({ epic_id: elsewhere.id, number: 1, title: 'Theirs', position: 0 });
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', position: 0,
    text: 'A story delivers a binding within its own epic.',
  });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The delivery is refused', position: 0,
  });
  const binding = call.create_coverage({
    requirement_id: requirement.id, spec_fragment: 'within its own epic',
    story_criterion_id: criterion.id, position: 0,
  });

  const error = refused(() => call.create_coverage_story({
    coverage_id: binding.id, story_id: far.id,
  }), "a story in another epic was recorded as delivering this epic's binding");

  assert.equal(db.prepare('SELECT count(*) AS n FROM coverage_story').get().n, 0);

  // **Both epics, because the caller cannot see which of the two they got wrong.** The binding may
  // be right and the story mistyped, or the other way about.
  assert.match(error.message, /'here'/);
  assert.match(error.message, /'elsewhere'/);
});

test('control — a second story in the same epic delivers the binding [integration]', (t) => {
  const { call, spec, here } = surface(t);

  const story = call.create_story({ epic_id: here.id, number: 1, title: 'Mine', position: 0 });
  const sibling = call.create_story({ epic_id: here.id, number: 2, title: 'Also mine', position: 1 });
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', position: 0,
    text: 'A story delivers a binding within its own epic.',
  });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The delivery is refused', position: 0,
  });
  const binding = call.create_coverage({
    requirement_id: requirement.id, spec_fragment: 'within its own epic',
    story_criterion_id: criterion.id, position: 0,
  });

  // The whole reason `coverage_story` exists — "Covered by: Story 1, Story 2". A guard that refused
  // this would have closed the table rather than guarded it.
  assert.ok(call.create_coverage_story({ coverage_id: binding.id, story_id: sibling.id }));
});
