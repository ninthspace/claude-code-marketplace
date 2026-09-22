/**
 * Epic 05-04 Story 4 — a refusal names the arguments the tool does accept (FR23).
 *
 * The evidence is this spec's own planning run: its first eight writes were refused for a missing
 * field and told only that the parameters were invalid. A caller told a property is not allowed has
 * nothing to correct towards — they cannot see the schema, and the one thing they need is the list
 * they were choosing from.
 *
 * **The second criterion was already true, and is asserted rather than built.** `validate` has
 * always named the missing required argument; what it did not do is name the set. Recording it as
 * delivered-and-checked is the honest shape, and epic 05-05's story 1 took the same one.
 *
 * **Required and optional are separated because they answer different questions.** Mistyping one of
 * four required arguments is a different mistake from reaching for a capability the tool does not
 * have, and an alphabetical merge of the two serves neither.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

/** The surface, and a spec to hang writes off. */
function surface(t) {
  const db = planning(t);
  const tools = spineTools(db);
  const call = handlers(tools);
  const spec = call.create_spec({ slug: 'arguments', title: 'Arguments a tool accepts' });

  return { db, tools, call, spec };
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

// --- Criterion 1 (must): the accepted arguments are named -----------------------------------------

test('a refusal for an argument a tool does not accept names the ones it does [integration]', (t) => {
  const { call, spec } = surface(t);

  // The mistake the requirement was written from: a plausible name that is not the one.
  const error = refused(() => call.create_requirement({
    spec_id: spec.id, labell: 'FR1', class: 'functional', text: 'Something.', position: 0,
  }), 'an argument the tool does not take was accepted');

  assert.match(error.message, /unknown argument 'labell'/, 'the refusal stopped naming the fault');
  assert.equal(error.rpc.code, -32602);

  // **Every required argument, so a caller who mistyped one can see which four they were choosing
  // from.** Named individually rather than counted — a message listing three of four sends them
  // back for the fourth.
  for (const required of ['spec_id', 'label', 'class', 'text', 'position']) {
    assert.match(error.message, new RegExp(`\\b${required}\\b`), `${required} is not named`);
  }

  // **And the optional ones, separately.** The two are different instructions: one says what a
  // call must carry, the other says what it may. A caller reaching for a capability the tool does
  // not have needs the second to find out it is not there.
  assert.match(error.message, /\(required\)/);
  assert.match(error.message, /\(optional\)/);

  for (const optional of ['moscow', 'exclusion', 'parent_id']) {
    assert.match(error.message, new RegExp(`\\b${optional}\\b`), `${optional} is not named`);
  }

  // **The unknown name is not offered back as something the tool takes**, which is what a message
  // built from the call rather than from the schema would have done. Read from the accepted clause
  // alone — the whole message names it once, as the fault.
  assert.doesNotMatch(error.message.slice(error.message.indexOf('it takes')), /labell/);
});

test('a tool with no optional arguments says only what it requires [integration]', (t) => {
  const { call, spec } = surface(t);
  const epic = call.create_epic({ parent_id: spec.id, slug: 'e', title: 'E' });
  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'S', position: 0 });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'It holds', position: 0,
  });

  // **A tool whose arguments are all required must not print an empty `(optional)` clause**, which
  // is the shape a message assembled without checking would produce. `create_story_criterion_approach`
  // takes exactly two and requires both.
  const error = refused(() => call.create_story_criterion_approach({
    story_criterion_id: criterion.id, tag: 'unit', note: 'not an argument',
  }));

  assert.match(error.message, /story_criterion_id, tag \(required\)/);
  assert.doesNotMatch(error.message, /\(optional\)/, 'an empty optional clause was printed');
});

// --- Criterion 2 (must): the missing required argument is named -----------------------------------

test('a refusal for a missing required argument names which one is missing [integration]', (t) => {
  const { call, spec } = surface(t);

  // **Already true before this story, and asserted because nothing held it.** The requirement's
  // own evidence is a run refused for a missing field; this half of it was working, and a test is
  // what keeps it working.
  assert.match(
    refused(() => call.create_requirement({
      spec_id: spec.id, class: 'functional', text: 'Something.', position: 0,
    }), 'a requirement with no label was written').message,
    /'label' is required/,
  );

  // An explicit null is refused with the omission and named the same way — below, `null` means
  // *clear this column*, and a required column is one there is no legal way to clear.
  assert.match(
    refused(() => call.create_requirement({
      spec_id: spec.id, label: null, class: 'functional', text: 'Something.', position: 0,
    })).message,
    /'label' is required/,
  );

  // The first missing argument is named rather than every one of them, which is the same choice
  // the foreign-key refusal makes: a caller fixes one and calls again.
  assert.match(
    refused(() => call.create_requirement({ spec_id: spec.id })).message,
    /'(label|class|text|position)' is required/,
  );
});

// --- Criterion 3 (control): a valid call succeeds unchanged ---------------------------------------

test('control — a call carrying only arguments the tool accepts succeeds [integration]', (t) => {
  const { call, spec } = surface(t);

  // The rejection's own call with the typo corrected. Without this, both refusals above are
  // equally satisfied by a validator that refused everything.
  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', text: 'Something.', position: 0,
  });

  assert.equal(requirement.label, 'FR1');

  // And a call carrying the optional arguments as well, since the message distinguishes them and
  // a validator that had confused the two sets would refuse these.
  assert.equal(call.create_requirement({
    spec_id: spec.id,
    label: 'FR2',
    class: 'functional',
    text: 'Something else.',
    position: 1,
    moscow: 'wont',
    exclusion: 'deferred',
    parent_id: requirement.id,
  }).exclusion, 'deferred');

  // A read carrying the convention's own arguments is untouched too — `include_body` and the
  // paging pair are injected by `defineTool` rather than declared, and a message built from the
  // declared properties alone would have reported them as unknown.
  assert.equal(call.list_requirement({ spec_id: spec.id, limit: 1, include_body: true }).items.length, 1);
});
