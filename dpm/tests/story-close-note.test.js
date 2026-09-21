/**
 * Epic 05-02 Story 3 — closing over an unverified binding needs a reason (FR4).
 *
 * **What is refused is the silence, not the binding.** A story can legitimately finish over work
 * somebody else verifies — a criterion checked on a machine nobody here has, a binding another
 * epic's run will mark. FR4 does not forbid that; it forbids doing it without saying so, because an
 * unverified binding under a `complete` story is indistinguishable from one nobody noticed.
 *
 * That distinction is the whole design, and it is why the control here carries the *same* unverified
 * binding as the rejection and differs only in the note. Without that, the rejection would be
 * equally satisfied by a rule that refused every close over an unverified row — a stricter rule
 * that FR4 explicitly does not want and that no assertion about the refusal alone would catch.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

/** A story bound to a requirement, with the binding left unverified. */
function surface(t, { note } = {}) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'notes', title: 'Closing notes' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'guards', title: 'Guards' });
  const story = call.create_story({
    epic_id: epic.id, number: 4, title: 'Deliver it', position: 0, ...(note ? { status_note: note } : {}),
  });
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR4', class: 'functional', position: 0,
    text: 'A story finishing over an unverified binding must carry a status note explaining why.',
  });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The close is refused', polarity: 'must', position: 0,
  });
  const binding = call.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: 'must carry a status note explaining why',
    story_criterion_id: criterion.id,
    position: 0,
  });

  const close = (extra = {}) => call.update_story({ id: story.id, status: 'complete', ...extra });

  return { db, call, story, requirement, criterion, binding, close };
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

// --- Criterion 1 (must NOT): the silent close ----------------------------------------------------

test('must NOT — a story with an unverified binding and no note is set finished [integration]', (t) => {
  const { call, story, close } = surface(t);

  const error = refused(close, 'a story closed silently over a binding nobody had verified');

  // The stored status, because a guard refusing after the write would leave the state this removes.
  assert.equal(call.read_story({ id: story.id }).status, 'pending');

  // The refusal names the requirement by label rather than by an id, so the run reading it can
  // check the claim against the spec rather than against an id it held from an earlier call.
  assert.match(error.message, /FR4/);

  // **And it says the binding is not what was refused.** A refusal that read as "you may not close
  // over unverified work" would send a run to verify something it has no way to verify, which is
  // the opposite of what FR4 permits.
  assert.match(error.message, /which is allowed/);
});

// --- Criterion 2 (control): the same story, with a note -------------------------------------------

test('control — the same story with a note is finished, binding still unverified [integration]', (t) => {
  const { call, story, binding, close } = surface(t);

  assert.equal(close({ status_note: 'the board verifies this one against a real panel' }).status,
    'complete');

  // **The binding is still unverified afterwards**, which is what says the note was the condition
  // and the verification was not. A rule that quietly accepted the close because something had
  // changed about the binding would pass the assertion above and fail this one.
  assert.equal(call.read_coverage({ id: binding.id, include_body: true }).verified_at, null);
  assert.equal(call.read_story({ id: story.id }).status, 'complete');
});

// --- Criterion 3: a stored note counts, and whitespace does not -----------------------------------

test('a note already on the row satisfies the condition, unrestated [integration]', (t) => {
  // The note is set when the story is created; the closing call carries only `status`. This is the
  // resolved-row half of story 2's seam — a hook judging the call's arguments would find no note
  // and refuse a story that already says why.
  const { call, story, close } = surface(t, { note: 'verified downstream by the release run' });

  assert.equal(close().status, 'complete', 'a stored note was not read, only a restated one');
  assert.equal(call.read_story({ id: story.id }).status_note,
    'verified downstream by the release run', 'the stored note was overwritten by the close');
});

test('a note of whitespace alone does not satisfy the condition [integration]', (t) => {
  const { close } = surface(t);

  // **An empty note that looks like a full one is the one way to pass this rule while saying
  // nothing**, so it is refused. Three shapes, because a guard checking only `''` admits the other
  // two and would read as working.
  for (const blank of ['   ', '\n', '\t \n ']) {
    refused(() => close({ status_note: blank }),
      `a status note of ${JSON.stringify(blank)} was accepted as a reason`);
  }

  // The control, on the same rows: one non-blank character is a reason, badly given but given.
  assert.equal(close({ status_note: '.' }).status, 'complete');
});

// --- The condition reads live bindings only -------------------------------------------------------

test('a retired binding is not something to close over [integration]', (t) => {
  const { call, story, binding, close } = surface(t);

  // A withdrawal carries its own reason, so the decision has already been made and recorded. Left
  // in the condition, a retired binding would demand a second reason for the same thing.
  call.retire_coverage({ id: binding.id, reason: 'the criterion it quoted was superseded' });

  assert.equal(close().status, 'complete',
    'a binding somebody withdrew was still counted as unverified work');
  assert.equal(call.read_story({ id: story.id }).status, 'complete');
});
