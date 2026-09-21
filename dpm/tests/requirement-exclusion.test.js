/**
 * Epic 05-02 Story 4 — a requirement ruled out records what rules it out (FR6).
 *
 * `moscow: 'wont'` says this is not being built. On its own that is indistinguishable from a
 * requirement somebody forgot to prioritise, and the two want opposite things from a reader: one is
 * a decision to leave alone, the other is work missing from the plan. `exclusion` is what tells them
 * apart, and FR6 makes it compulsory at that priority and at no other.
 *
 * **Two write paths, and each gets its own arm.** A state reachable from `create` and from `update`
 * needs a control at each, not one for the criterion — a guard on the create path alone would pass
 * every assertion about creating and leave the update able to walk a requirement into exactly the
 * forbidden state. That is retro 02's rule, and the update arm here is the one that would have been
 * missed.
 *
 * **Both paths judge the row the write would leave rather than the arguments it carries.** An update
 * naming only the priority is judged against the exclusion already stored; an update clearing that
 * exclusion is refused. Neither reading is available from the call alone, and the second is the one
 * an implementation is most likely to miss.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { create } from './fixtures/tool-surface.js';

/** A spec, and a way to make requirements under it. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));
  const spec = call.create_spec({ slug: 'exclusions', title: 'Exclusions' });

  let position = 0;
  const make = (label, extra = {}) => call.create_requirement({
    spec_id: spec.id, label, class: 'functional', text: `${label} asks for something.`,
    position: position++, ...extra,
  });

  return { db, call, spec, make };
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

// --- Criterion 1 (must NOT), arm one: the create path --------------------------------------------

test('must NOT — a create leaves a requirement ruled out with no exclusion [integration]', (t) => {
  const { db, make } = surface(t);

  const error = refused(() => make('FR1', { moscow: 'wont' }),
    'a requirement was ruled out with nothing recorded to rule it out');

  // The row, not the throw. A guard refusing after the insert would satisfy an exception check and
  // leave the state behind it.
  assert.equal(db.prepare('SELECT count(*) AS n FROM requirement').get().n, 0);

  // Named so the caller can act: which field, and what it may hold.
  assert.match(error.message, /exclusion/);
  assert.match(error.message, /deferred or out_of_scope/);
});

// --- Criterion 1 (must NOT), arm two: the update path --------------------------------------------

test('must NOT — an update leaves a requirement ruled out with no exclusion [integration]', (t) => {
  const { call, make } = surface(t);
  const requirement = make('FR2', { moscow: 'should' });

  // **The arm a guard written only at create would leave open.** The row is legal when created and
  // walked into the forbidden state afterwards, which is the same end state by the other route.
  refused(() => call.update_requirement({ id: requirement.id, moscow: 'wont' }),
    'a requirement was walked into being ruled out with nothing recorded');

  assert.equal(call.read_requirement({ id: requirement.id }).moscow, 'should',
    'the update was refused and the priority moved anyway');

  // **And clearing the exclusion off a row that is already ruled out.** An explicit null is a value
  // meaning *clear this*, so it reaches the forbidden state as surely as an omission at create —
  // a third way in, on the same path.
  const excluded = make('FR3', { moscow: 'wont', exclusion: 'deferred' });

  refused(() => call.update_requirement({ id: excluded.id, exclusion: null }),
    "a ruled-out requirement's exclusion was cleared, leaving it unexplained");

  assert.equal(call.read_requirement({ id: excluded.id }).exclusion, 'deferred');
});

// --- Criterion 2 (control): the same call with an exclusion, and the other three priorities -------

test('control — the exclusion makes the same call succeed, at wont and nowhere else [integration]', (t) => {
  const { call, make } = surface(t);

  // The rejection's own call, differing in one field. Without this the refusal above is equally
  // satisfied by a rule that refuses `wont` outright.
  const ruled = make('FR1', { moscow: 'wont', exclusion: 'out_of_scope' });

  assert.equal(ruled.moscow, 'wont');
  assert.equal(ruled.exclusion, 'out_of_scope');

  // **The other three carry no such duty**, which is the half that keeps the obligation where FR6
  // puts it. A guard reading "an exclusion is required" rather than "at this priority" would refuse
  // all of these, and the rejection's assertion would not notice.
  for (const moscow of ['must', 'should', 'could']) {
    assert.equal(make(`FR-${moscow}`, { moscow }).moscow, moscow,
      `a requirement at '${moscow}' was refused for carrying no exclusion`);
  }

  // And a requirement with no priority at all, which is the ordinary state of one nobody has banded.
  assert.equal(make('FR-none').moscow, null);

  // The update path's control, on its own row: the priority and the exclusion arriving together.
  const later = make('FR9', { moscow: 'should' });

  assert.equal(
    call.update_requirement({ id: later.id, moscow: 'wont', exclusion: 'deferred' }).exclusion,
    'deferred',
  );
});

// --- Criterion 3: an update naming only the priority reads the stored exclusion -------------------

test('an update naming only the priority is judged on the stored exclusion [integration]', (t) => {
  const { call, make } = surface(t);

  // Already recording why it is out, and set to `wont` again by a call carrying nothing else. A
  // guard judging the arguments finds no exclusion among them and refuses a row that already says
  // what it was asked to say.
  const excluded = make('FR4', { moscow: 'could', exclusion: 'deferred' });

  assert.equal(call.update_requirement({ id: excluded.id, moscow: 'wont' }).moscow, 'wont');
  assert.equal(call.read_requirement({ id: excluded.id }).exclusion, 'deferred',
    'the stored exclusion was disturbed by an update that never mentioned it');

  // The same row again, with the priority restated and nothing else — idempotent, and still not
  // asked to repeat itself.
  assert.equal(call.update_requirement({ id: excluded.id, moscow: 'wont' }).moscow, 'wont');
});

// --- NFR1: a row already in the refused state goes on reading exactly as it did -------------------

test('a stored requirement ruled out with no exclusion still reads as excluded [integration]', (t) => {
  const { db, call, spec } = surface(t);

  // **Written past the tool, because the tool is now the one thing that cannot produce it.** This is
  // the state a database arrives in from a restore, or from a dump written before FR6 — and NFR1's
  // promise is that no refusal this spec adds changes how a stored row reads.
  const stored = create(db, 'requirement', {
    spec_id: spec.id, label: 'FR-legacy', class: 'functional', moscow: 'wont',
    text: 'Ruled out before the refusal existed.', position: 99,
  });

  const read = call.read_requirement({ id: stored.id, include_body: true });

  assert.equal(read.moscow, 'wont', 'a stored ruled-out row stopped reading as ruled out');
  assert.equal(read.exclusion, null);
  assert.equal(read.text, 'Ruled out before the refusal existed.');

  // And through the list, which is the read a report actually uses — a guard that had leaked onto
  // the read path would drop it here rather than at the read above.
  const listed = call.list_requirement({ spec_id: spec.id }).items
    .find((row) => row.label === 'FR-legacy');

  assert.ok(listed, 'the row vanished from the listing its spec returns');
  assert.equal(listed.moscow, 'wont');
  assert.equal(listed.exclusion, null);

  // **An unrelated edit to that row still works**, which is the narrower half of the promise: the
  // refusal sits on what a write would *leave*, so a call that touches neither column is none of
  // its business even on a row already in the state.
  assert.equal(call.update_requirement({ id: stored.id, position: 98 }).position, 98);
});
