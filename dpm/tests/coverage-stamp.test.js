/**
 * Epic 05-03 Story 1 — the coverage verification stamp is the server's clock (FR1).
 *
 * The failure being removed is the one with no error in it. A run supplied `verified_at` as a
 * string it had never read off a clock, the `CHECK` accepted it, and nothing downstream could tell
 * that row from a real one — while verification time is exactly what the coverage matrix publishes
 * as proof. `retire_coverage` had already settled the shape one verb over: the caller says the
 * thing happened, the server says when.
 *
 * **The pinned clock here is an instant nothing in this file passes as an argument**, and that is
 * the whole of what makes criterion 1 assertable. "The stamp holds the server's clock" checked
 * against a pinned `now` is satisfied just as well by a handler that stored a caller's string,
 * whenever the two happen to be the same string — so the two are kept different by construction,
 * and the must-NOT below drives a time that is neither.
 *
 * **The boolean carries three states, and all three are driven.** Omitted leaves the mark alone,
 * `true` stamps it, `false` clears it with its hash. A swap that quietly dropped the clear would
 * pass every assertion about stamping and would have removed the only way to unverify a row.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

/** What the pinned server clock reads. Passed as an argument nowhere below. */
const CLOCK = '2026-09-21T16:04:11.298Z';

/** A time a caller might invent, and the one the must-NOT tries to supply. */
const SUPPLIED = '2026-01-01T00:00:00.000Z';

/** The tool surface with its clock pinned, and a requirement bound to a criterion. */
function surface(t) {
  const db = planning(t);
  const tools = spineTools(db, { now: () => CLOCK });
  const call = handlers(tools);

  const spec = call.create_spec({ slug: 'stamps', title: 'Server-supplied stamps' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'clock', title: 'The clock' });
  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'Stamp it', position: 0 });
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', position: 0,
    text: 'The server supplies the clock for a coverage verification stamp.',
  });

  const FRAGMENT = 'supplies the clock';

  // **Each binding gets a criterion of its own**, because the natural key is the fragment and the
  // criterion together — one requirement quoted twice by one criterion is the duplicate the table
  // refuses. The fragment is held constant so every hash below is over the same left half and the
  // criterion's text is the only thing that moves.
  let position = 0;
  const bind = (extra = {}) => {
    const criterion = call.create_story_criterion({
      story_id: story.id,
      text: `The server supplies the clock, ${position} times over`,
      polarity: 'must',
      position,
    });

    return {
      row: call.create_coverage({
        requirement_id: requirement.id,
        spec_fragment: FRAGMENT,
        story_criterion_id: criterion.id,
        position: position++,
        ...extra,
      }),
      criterion,
    };
  };

  /** The digest the server ought to have taken, recomputed rather than read from `binding.js`. */
  const digest = (text) => createHash('sha256')
    .update(`${FRAGMENT}\\u0000${text}\\u0000`)
    .digest('hex');

  return { db, tools, call, story, requirement, FRAGMENT, bind, digest };
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

// --- Criterion 1 (must): the stamp is the clock, and the hash comes with it -----------------------

test('a verification supplying no time is stamped with the server\'s clock [integration]', (t) => {
  const { call, bind, digest } = surface(t);

  // **Both write paths, because both accept the boolean and both reach the same pair of columns.**
  // A swap made on the update alone would pass every assertion about updating and leave a create
  // able to write a stamp the caller chose.
  const born = bind({ verified: true });

  assert.equal(born.row.verified_at, CLOCK, 'a create stamped something other than the clock');
  assert.equal(born.row.binding_hash, digest(born.criterion.text),
    'the hash is not over the fragment and the criterion text it binds');

  const second = bind();
  const later = call.update_coverage({ id: second.row.id, verified: true });

  assert.equal(later.verified_at, CLOCK, 'an update stamped something other than the clock');
  assert.equal(later.binding_hash, digest(second.criterion.text));

  // **The hash comes off the row as it stands, not off anything a caller holds**, which is the
  // half a stamp-only change would silently drop. Editing the criterion clears the pair by trigger;
  // re-verifying takes the digest over the text that is there now.
  const moved = 'The server supplies the clock, and says so';

  call.update_story_criterion({ id: born.criterion.id, text: moved });

  assert.equal(call.read_coverage({ id: born.row.id, include_body: true }).verified_at, null,
    'the mark outlived the text it was made about');

  const again = call.update_coverage({ id: born.row.id, verified: true });

  assert.equal(again.verified_at, CLOCK);
  assert.equal(again.binding_hash, digest(moved), 'the ✓ came back over text that had moved');
});

// --- Criterion 2 (must NOT): a supplied time is not accepted and not stored ------------------------

test('must NOT — a call supplying a time for a verification is accepted [integration]', (t) => {
  const { db, call, story, requirement, FRAGMENT, bind } = surface(t);

  const spare = call.create_story_criterion({
    story_id: story.id, text: 'A criterion nothing is bound to yet', polarity: 'must', position: 9,
  });

  // **Read for the argument's name and never for the sentence.** `additionalProperties: false`
  // generates this message, and FR23 — epic 05-04 — will reword it to list the arguments the tool
  // does accept. A control pinned to the whole string would then fail for somebody else's reason.
  assert.match(
    refused(() => call.create_coverage({
      requirement_id: requirement.id,
      spec_fragment: FRAGMENT,
      story_criterion_id: spare.id,
      position: 9,
      verified_at: SUPPLIED,
    }), 'a create chose the moment its own claim was checked').message,
    /verified_at/,
  );

  // The row, not the throw: a refusal after the insert would satisfy an exception check and leave
  // the state behind it.
  assert.equal(db.prepare('SELECT count(*) AS n FROM coverage').get().n, 0);

  const { row } = bind({ verified: true });

  assert.match(
    refused(() => call.update_coverage({ id: row.id, verified_at: SUPPLIED }),
      'an update chose the moment its own claim was checked').message,
    /verified_at/,
  );

  // **And the mark it already carries is unmoved**, which is what says the refusal happened before
  // the write rather than after part of it.
  assert.equal(call.read_coverage({ id: row.id, include_body: true }).verified_at, CLOCK);

  // The column is still `verified_at` and still reads back under that name — only the argument
  // moved. Asserted here because a swap that had renamed the column would pass everything above.
  assert.equal(db.prepare('SELECT verified_at FROM coverage WHERE id = ?').get(row.id).verified_at,
    CLOCK);
});

// --- Criterion 3 (control): the same call with the time omitted succeeds ---------------------------

test('control — the same calls with `verified` in place of a time are written [integration]', (t) => {
  const { call, bind } = surface(t);

  // The rejection's own calls, differing in one argument. Without this the refusal above is
  // equally satisfied by a tool that refused every call of that shape.
  assert.equal(bind({ verified: true }).row.verified_at, CLOCK);

  const { row } = bind();

  assert.equal(row.verified_at, null, 'a row nobody verified was born carrying a mark');
  assert.equal(row.binding_hash, null, 'a binding hash beside a verification nobody made');
  assert.equal(call.update_coverage({ id: row.id, verified: true }).verified_at, CLOCK);
});

test('the boolean carries the clear and the leave-alone as well as the stamp [integration]', (t) => {
  const { call, bind } = surface(t);
  const { row } = bind({ verified: true });

  // **`false` clears both columns.** Unverifying is a decision a caller can still make; what it can
  // no longer do is date one. A swap that treated `false` as "nothing to do" would pass every
  // assertion above and would have removed the only way to withdraw a ✓.
  const cleared = call.update_coverage({ id: row.id, verified: false });

  assert.equal(cleared.verified_at, null);
  assert.equal(cleared.binding_hash, null, 'the binding outlived the verification it recorded');

  // **And omitting it leaves both alone**, which is what makes the clear a decision rather than a
  // side effect of updating the row at all.
  const restamped = call.update_coverage({ id: row.id, verified: true });
  const moved = call.update_coverage({ id: row.id, position: 7 });

  assert.equal(moved.position, 7);
  assert.equal(moved.verified_at, restamped.verified_at);
  assert.ok(moved.verified_at, 'the row was never re-verified, so this proves nothing');
  assert.ok(moved.binding_hash);

  // The same on the create path: absent and `false` mean one thing there, since a row is not
  // there to have a mark left alone.
  assert.equal(bind({ verified: false }).row.verified_at, null);
});

// --- The declaration, which is what a caller is shown ---------------------------------------------

test('both coverage tools declare the stamp as the server\'s and offer no time [unit]', (t) => {
  const { tools } = surface(t);

  for (const name of ['create_coverage', 'update_coverage']) {
    const tool = tools.find((entry) => entry.name === name);
    const properties = tool.inputSchema.properties;

    assert.equal('verified_at' in properties, false,
      `${name} still offers the caller a time to choose`);
    assert.equal(properties.verified?.type, 'boolean',
      `${name} does not take a boolean saying the check happened`);

    // **Declared, not merely absent.** AD10's rule is that a column this server fills says so, and
    // a column that is neither an argument nor declared is one nobody has classified. `verified_at`
    // stopped being an argument in this story, so this is where it says where it now comes from.
    assert.equal(tool.serverSupplied.verified_at, 'clock',
      `${name} fills verified_at without declaring that it does`);
  }
});
