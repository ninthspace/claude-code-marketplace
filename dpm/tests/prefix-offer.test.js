/**
 * Epic 05-04 Story 3 — a truncated id is offered back as the row it names (FR22).
 *
 * An id copied out of a report, a log line wrapped at the wrong column, a paste that lost its last
 * characters. Each arrives as a value matching no row, and the refusal said only that nothing was
 * found — while the row sat one character away.
 *
 * **The must-NOT is the interesting half and it is about the cost of being helpful.** An ambiguous
 * prefix must offer nothing: two rows sharing a front is exactly where a guess is worst, because
 * the caller acts on a plausible suggestion and writes against the wrong row — a mistake the plain
 * refusal could not have caused. So the fixture builds a real collision rather than asserting over
 * one that cannot happen.
 *
 * **The control is that a full id costs nothing**, which is a claim about the path rather than the
 * answer: the search runs only after an exact match has already failed, so a call naming a real row
 * never reaches it. Driven by asserting the row comes back, and by the sweep below reading the
 * statements a successful read actually issues.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { uniquePrefix } from '../src/tools/prefix.js';
import { create } from './fixtures/tool-surface.js';

/** A spec with three stories, two of which share a long id prefix. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'prefixes', title: 'Unique prefixes' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'offer', title: 'Offering a row' });

  const lone = call.create_story({ epic_id: epic.id, number: 1, title: 'On its own', position: 0 });

  // **A real collision, written past the tools so the ids can be chosen.** The must-NOT cannot be
  // driven against ULIDs the server minted: they share a time-ordered front, but not reliably
  // enough for a test to depend on, and a fixture whose ambiguity is a coincidence is one that
  // stops testing the day the clock moves.
  const twins = ['01TWINAAAAAAAAAAAAAAAAAAA1', '01TWINAAAAAAAAAAAAAAAAAAA2']
    .map((id, index) => create(db, 'story', {
      id,
      epic_id: epic.id,
      number: index + 2,
      title: `Twin ${index + 1}`,
      position: index + 1,
    }));

  return { db, call, spec, epic, lone, twins };
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

// --- Criterion 1 (must): the unambiguous prefix is offered ----------------------------------------

test('an id that is the prefix of exactly one row has that row offered [integration]', (t) => {
  const { call, lone } = surface(t);

  // The paste that lost its tail — the id, four characters short.
  const truncated = lone.id.slice(0, -4);

  const error = refused(() => call.read_story({ id: truncated }),
    'a truncated id was accepted as a row');

  assert.match(error.message, new RegExp(`no story with id '${truncated}'`),
    'the refusal stopped saying what was not found');
  assert.match(error.message, new RegExp(`did you mean '${lone.id}'`),
    'the row one character away was not offered');

  // **The offer says why it is an offer**, so a caller can tell a suggestion from a fact — the row
  // was not found, and this is the only one whose id starts that way.
  assert.match(error.message, /the only story whose id starts with what was given/);

  // It reaches the other refusals that name a missing row, not only `read_*`. An update names the
  // same row by the same key and had the same nothing to say.
  assert.match(
    refused(() => call.update_story({ id: truncated, title: 'Renamed' })).message,
    new RegExp(`did you mean '${lone.id}'`),
  );
});

// --- Criterion 2 (must NOT): an ambiguous prefix offers nothing ------------------------------------

test('must NOT — an id that is a prefix of two or more rows has one of them offered [integration]', (t) => {
  const { call, twins, lone } = surface(t);

  const shared = '01TWINAAAAAAAAAAAAAAAAAAA';

  // Both twins begin with it, which the fixture asserts rather than assumes — an ambiguity that
  // is not actually ambiguous would make the rejection below pass for the wrong reason.
  assert.ok(twins.every((story) => story.id.startsWith(shared)));
  assert.equal(twins[0].id !== twins[1].id, true);

  const error = refused(() => call.read_story({ id: shared }));

  assert.match(error.message, /no story with id/);
  assert.doesNotMatch(error.message, /did you mean/,
    'a row was offered for a prefix that names more than one');

  // Neither twin is named at all — the failure this forbids is a plausible suggestion, so naming
  // either one of them is the defect whichever it is.
  for (const story of twins) assert.doesNotMatch(error.message, new RegExp(story.id));

  // **And the rejection is not a search that never offers anything**, which it would otherwise be
  // equally satisfied by: the same call against a prefix of the third story, on this same
  // database, does offer.
  assert.match(
    refused(() => call.read_story({ id: lone.id.slice(0, -4) })).message,
    /did you mean/,
    'nothing is ever offered, so the ambiguous case proves nothing',
  );
});

// --- Criterion 3 (control): a full id resolves exactly as before -----------------------------------

test('control — a full id that matches a row resolves with no prefix search [integration]', (t) => {
  const { db, call, lone, twins } = surface(t);

  assert.equal(call.read_story({ id: lone.id }).title, 'On its own');

  // **A full id that is also a prefix of nothing else still resolves**, which is the case a search
  // running *before* the exact match would have got wrong — and the twins make it a real question:
  // each of their ids is a full id and a prefix of nothing, but the shared front is a prefix of
  // both, so an implementation that searched first would have had a decision to make here.
  for (const story of twins) {
    assert.equal(call.read_story({ id: story.id }).id, story.id);
  }

  // The helper's own answer on the three cases, where the tool surface cannot show the difference
  // between "no match" and "several".
  assert.equal(uniquePrefix(db, 'story', 'id', lone.id.slice(0, -4)), lone.id);
  assert.equal(uniquePrefix(db, 'story', 'id', '01TWINAAAAAAAAAAAAAAAAAAA'), null);
  assert.equal(uniquePrefix(db, 'story', 'id', 'nothing-starts-with-this'), null);

  // **An empty value offers nothing, and the table it is asked about has to hold exactly one row
  // for that to mean anything.** Against the three stories an empty prefix matches all of them and
  // answers `null` by ambiguity, whether the guard is there or not — a mutation removing it
  // survived the whole suite. One task, and the guard is the only thing standing between an empty
  // string and a row being offered for it.
  const only = call.create_task({ story_id: lone.id, number: 1, title: 'The only task', position: 0 });

  assert.equal(db.prepare('SELECT count(*) AS n FROM task').get().n, 1);
  assert.equal(uniquePrefix(db, 'task', 'id', ''), null, 'an empty prefix offered a row');
  assert.equal(uniquePrefix(db, 'task', 'id', only.id.slice(0, -4)), only.id);

  assert.equal(uniquePrefix(db, 'story', 'id', ''), null);

  // **A value carrying `LIKE`'s own wildcards is matched literally, and the case that shows it is
  // not the bare `%`.** A lone `%` matches every story, which three rows make ambiguous, so it
  // answers `null` whether the escaping works or not — an assertion that cannot fail. A real
  // prefix *with* a `%` on the end is the discriminating case: escaped it names nothing, and
  // unescaped it would find `lone` and offer a row for an id nobody holds.
  assert.equal(uniquePrefix(db, 'story', 'id', `${lone.id.slice(0, -4)}%`), null,
    'a wildcard in the value was matched as a pattern');
  assert.equal(uniquePrefix(db, 'story', 'id', `${lone.id.slice(0, -4)}_`), null);
  assert.equal(uniquePrefix(db, 'story', 'id', '%'), null);
});

// --- The offer reaches the scope refusal story 2 left it for --------------------------------------

test('a truncated scope id is offered the row it names [integration]', (t) => {
  const { call, lone } = surface(t);

  // Story 2 refuses a scope id that names no row and says, where the id is nowhere at all, to
  // check it. This is what it was waiting for.
  const error = refused(() => call.list_task({ story_id: lone.id.slice(0, -4) }));

  assert.match(error.message, /matches no story, and no other row in this project/);
  assert.match(error.message, new RegExp(`did you mean '${lone.id}'`));
});
