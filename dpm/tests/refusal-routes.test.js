/**
 * Epic 05-04 Story 5 — every refusal this spec adds names a way out (NFR4).
 *
 * The four stories before this each proved their own message. What none of them can see is the
 * property that makes them one spec: **a refusal that reports a fault without a route out is the
 * prose rule it replaced, moved one layer down.** That is checkable only across the set — an
 * assertion per story proves nothing about the other twelve, and thirteen separate assertions of it
 * would each be about a different message.
 *
 * **What "names a way out" is, mechanically.** The criterion lists what counts: a requirement, a
 * table, a list, an option or an argument. All five are names the *project* holds — schema tables
 * and columns, registered tool names, requirement labels, the values an enum admits. So the sweep
 * asks whether a refusal, with the caller's own supplied values removed, still names something from
 * that vocabulary. A message that echoes the bad value back and stops names nothing the caller did
 * not already have, which is precisely the failure.
 *
 * **Removing the supplied values is what makes it discriminate**, and it is the part a looser
 * reading would drop. `unknown argument 'labell'` contains a quoted token and looks specific; with
 * `labell` taken out there is nothing left. The message that passes is the one still standing after
 * the caller's own words are gone.
 *
 * The control plants exactly that: a real refusal reduced to its fault, run through the same
 * predicate, which must fail. A contract test that cannot fail is the most confident kind of
 * nothing.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { create } from './fixtures/tool-surface.js';

/**
 * Every name this project holds — the vocabulary a refusal may point a caller at.
 *
 * Read from the live schema and the built registry rather than listed, so a table or tool added
 * later is in scope without anything here being edited.
 */
function vocabulary(db, tools) {
  const words = new Set(tools.map((tool) => tool.name));

  for (const { name } of db.prepare("SELECT name FROM sqlite_schema WHERE type = 'table'").all()) {
    words.add(name);

    for (const column of db.prepare(`PRAGMA table_info(${name})`).all()) words.add(column.name);
  }

  // The values an enum admits, which is what a refusal offering "deferred or out_of_scope" is
  // naming. Parsed from the same `CHECK` text `support/conformance.js` reads.
  for (const { sql } of db.prepare("SELECT sql FROM sqlite_schema WHERE type = 'table'").all()) {
    for (const [, , list] of (sql ?? '').matchAll(/CHECK\s*\(\s*(\w+)\s+IN\s*\(([^)]*)\)\s*\)/g)) {
      for (const value of list.split(',')) words.add(value.trim().replace(/^'|'$/g, ''));
    }
  }

  return words;
}

/**
 * Whether a refusal points at something the caller did not already hold.
 *
 * @param {string} message
 * @param {Set<string>} words The project's vocabulary.
 * @param {unknown[]} supplied Everything the refused call carried.
 * @returns {boolean}
 */
function namesARouteOut(message, words, supplied) {
  const given = new Set(supplied.filter((value) => typeof value === 'string'));

  // The message minus the tool's own name, which every refusal carries as its prefix and which
  // tells the caller only where they already were.
  const body = message.slice(message.indexOf(':') + 1);

  return [...body.matchAll(/[A-Za-z_][A-Za-z0-9_:-]*/g)]
    .map(([token]) => token)
    .some((token) => !given.has(token) && words.has(token));
}

/** A spec with enough under it to drive every refusal the spec adds. */
function corpus(t) {
  const db = planning(t);
  const tools = spineTools(db);
  const call = handlers(tools);

  const spec = call.create_spec({ slug: 'routes', title: 'Refusals that name a way out' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'here', title: 'This epic' });
  const elsewhere = call.create_epic({ parent_id: spec.id, slug: 'elsewhere', title: 'Another' });

  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'A story', position: 0 });
  const open = call.create_story({ epic_id: epic.id, number: 2, title: 'Still open', position: 1 });
  const far = call.create_story({ epic_id: elsewhere.id, number: 1, title: 'Far', position: 0 });

  const clock = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', position: 0,
    text: 'The server supplies the clock for a coverage verification stamp.',
  });
  const scope = call.create_requirement({
    spec_id: spec.id, label: 'FR2', class: 'functional', position: 1,
    text: 'A list refuses a scope id that matches no row.',
  });

  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The refusal names a route', polarity: 'must', position: 0,
  });
  const second = call.create_story_criterion({
    story_id: open.id, text: 'The other refusal does too', polarity: 'must', position: 0,
  });

  const binding = call.create_coverage({
    requirement_id: clock.id,
    spec_fragment: 'supplies the clock',
    story_criterion_id: criterion.id,
    position: 0,
  });

  call.create_coverage({
    requirement_id: scope.id,
    spec_fragment: 'matches no row',
    story_criterion_id: second.id,
    position: 1,
  });

  call.create_task({ story_id: open.id, number: 1, title: 'Not finished', position: 0 });

  const decision = call.create_adr({
    parent_id: spec.id, slug: 'ours', title: 'Ours', decision: 'This way.',
  });
  const other = call.create_adr({
    parent_id: spec.id, slug: 'theirs', title: 'Theirs', decision: 'That way.',
  });

  call.create_adr_option({ adr_id: decision.id, name: 'Take the seam', position: 0 });

  const foreign = call.create_adr_option({ adr_id: other.id, name: 'Elsewhere', position: 0 });

  // A story with nothing outstanding, so the unverified-binding refusal is reachable past the
  // outstanding-task one.
  const closing = call.create_story({ epic_id: epic.id, number: 3, title: 'Ready to close', position: 2 });
  const closingCriterion = call.create_story_criterion({
    story_id: closing.id, text: 'Nothing outstanding', polarity: 'must', position: 0,
  });

  call.create_coverage({
    requirement_id: scope.id,
    spec_fragment: 'refuses a scope id',
    story_criterion_id: closingCriterion.id,
    position: 2,
  });

  return {
    db, tools, call, spec, epic, elsewhere, story, open, far, clock, scope,
    criterion, binding, decision, foreign, closing,
  };
}

/** Run something expected to be refused, and hand back the message it raised. */
function refusalOf(run, label) {
  let caught;

  try {
    run();
  } catch (error) {
    caught = error;
  }

  assert.ok(caught, `${label} was accepted when it should have been refused`);

  return caught.message;
}

// --- Criterion 1: every refusal the spec adds names a route out -----------------------------------

test('every refusal this spec adds names something the caller did not supply [integration]', (t) => {
  const fixture = corpus(t);
  const {
    db, tools, call, spec, epic, story, open, far, clock, scope, criterion, decision, foreign,
    closing,
  } = fixture;

  const words = vocabulary(db, tools);

  /** Each refusal, with everything its call carried — so the echo can be discounted. */
  const driven = [
    ['a fragment its requirement does not contain', ['nowhere in this requirement'],
      () => call.create_coverage({
        requirement_id: clock.id, spec_fragment: 'nowhere in this requirement',
        story_criterion_id: criterion.id, position: 9,
      })],
    ['a story closed over an outstanding task', [open.id],
      () => call.update_story({ id: open.id, status: 'complete' })],
    ['a story closed silently over an unverified binding', [closing.id],
      () => call.update_story({ id: closing.id, status: 'complete' })],
    ['a requirement ruled out with no exclusion', ['FR9', 'Ruled out.'],
      () => call.create_requirement({
        spec_id: spec.id, label: 'FR9', class: 'functional', moscow: 'wont', position: 9,
        text: 'Ruled out.',
      })],
    ['a tradeoff on an option its decision does not hold', [decision.id, foreign.id, 'cost'],
      () => call.create_adr_option_tradeoff({
        adr_id: decision.id, option_id: foreign.id, axis: 'cost', assessment: 'Low.',
      })],
    ['a second live criterion repeating its sibling', [story.id, 'The refusal names a route'],
      () => call.create_story_criterion({
        story_id: story.id, text: 'The refusal names a route', position: 1,
      })],
    ['a story from another epic delivering this binding', [fixture.binding.id, far.id],
      () => call.create_coverage_story({ coverage_id: fixture.binding.id, story_id: far.id })],
    ['a write that misses a parent row', ['no-such-story', 'orphaned'],
      () => call.create_story_criterion({
        story_id: 'no-such-story', text: 'orphaned', position: 0,
      })],
    ['a scope id belonging to another table', [epic.id],
      () => call.list_task({ story_id: epic.id })],
    ['a scope id that is a truncated row', [story.id.slice(0, -4)],
      () => call.list_task({ story_id: story.id.slice(0, -4) })],
    ['an argument the tool does not accept', ['labell', spec.id, 'Something.'],
      () => call.create_requirement({
        spec_id: spec.id, labell: 'FR8', class: 'functional', text: 'Something.', position: 8,
      })],
    ['a required argument left out', [spec.id, 'Something.'],
      () => call.create_requirement({
        spec_id: spec.id, class: 'functional', text: 'Something.', position: 8,
      })],
    ['a truncated id on a read', [scope.id.slice(0, -4)],
      () => call.read_requirement({ id: scope.id.slice(0, -4) })],
    ['a dependency edge that is not there', ['no-such-edge'],
      () => call.delete_dependency({ id: 'no-such-edge' })],
    ['a delivery that is not there', [fixture.binding.id, far.id],
      () => call.delete_coverage_story({ coverage_id: fixture.binding.id, story_id: far.id })],
  ];

  // **Thirteen at least, because the claim is about a set.** A sweep over three refusals is three
  // assertions wearing a sweep's clothes, and the spec adds far more than three.
  assert.ok(driven.length >= 13, `only ${driven.length} refusals are driven`);

  const silent = [];

  for (const [what, supplied, run] of driven) {
    const message = refusalOf(run, what);

    if (!namesARouteOut(message, words, supplied)) silent.push(`${what}: ${message}`);
  }

  // Reported together rather than asserted one at a time, so a run that broke two messages sees
  // both — the same reason `bindings` in `support/skills.js` returns problems.
  assert.deepEqual(silent, []);
});

// --- Criterion 2 (control): a message reduced to its fault fails the sweep ------------------------

test('control — a refusal reduced to naming only the fault fails the sweep [unit]', (t) => {
  const { db, tools, call, epic, story } = corpus(t);
  const words = vocabulary(db, tools);

  // The real refusal, taken from the tool rather than written here, so the control is about a
  // message the project actually produces.
  const real = refusalOf(() => call.list_task({ story_id: epic.id }), 'a scope from another table');

  assert.equal(namesARouteOut(real, words, [epic.id]), true, 'the live refusal names nothing');

  // **Reduced to the fault and nothing else**, which is the prose rule NFR4 replaced: it says what
  // was wrong and leaves the caller where they started.
  assert.equal(namesARouteOut(`list_task: ${epic.id} is not valid here`, words, [epic.id]), false,
    'a message that only echoes the bad value passed the sweep');

  assert.equal(namesARouteOut('list_task: invalid params', words, [epic.id]), false);

  // **And the discounting is load-bearing.** A message naming only what the caller already gave —
  // here a real column name that was itself supplied — must not count as a route out.
  assert.equal(
    namesARouteOut(`create_story_criterion: story_id '${story.id}' is wrong`, words, ['story_id', story.id]),
    false,
    'a message echoing an argument the caller named was read as pointing somewhere',
  );

  // The other direction: naming a column the caller did *not* supply is a route out, which is what
  // the foreign-key refusal does.
  assert.equal(
    namesARouteOut(`create_story_criterion: it names no story`, words, ['no-such-story']),
    true,
  );
});

// --- The sweep reads the live messages, not a copy of them ----------------------------------------

test('the sweep is driven against the registry rather than a transcript [unit]', (t) => {
  const { db, tools } = corpus(t);
  const words = vocabulary(db, tools);

  // The vocabulary is the project's own, so a refusal naming a table or a tool that does not exist
  // reads as silence rather than as a route. Without this the sweep would accept any plausible
  // word and pass on a message pointing nowhere.
  assert.equal(words.has('story_criterion'), true);
  assert.equal(words.has('list_task'), true);
  assert.equal(words.has('deferred'), true, 'the enum values a refusal offers are not in scope');
  assert.equal(words.has('list_nothing'), false);

  assert.equal(namesARouteOut('x: try list_nothing instead', words, []), false);
  assert.ok(words.size > 200, `the vocabulary holds only ${words.size} names`);
});
