/**
 * Epic 05-02 Story 6 — the seam no member of the set can see from inside itself.
 *
 * Each of the five implementation stories proved its own refusal. What none of them observes is the
 * property that binds them, which is the only reason they are one epic: **no stored row changes how
 * it reads.** That is NFR1, and it is checkable only across the whole set — a story asserting it for
 * its own rule proves nothing about the other six, and seven separate assertions of it would each be
 * about a different database.
 *
 * So this builds one database holding *every* state the epic now refuses, writes each past the tools
 * through the fixture seam — which is how a restore brings them in, and after this epic the only way
 * they arise at all — and then reads everything back.
 *
 * **The second criterion is about the suite rather than the database**, and the honest form of it is
 * narrow: every forbidden state is driven here and every one is refused, so each rule is live and
 * each names its own subject. That each goes red *alone* was established by running the mutations
 * per story, one rule at a time, and is recorded there rather than asserted here — a test cannot
 * edit the source it runs against.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { create } from './fixtures/tool-surface.js';
import { coverageReport } from '../src/coverage/report.js';
import { checkIntegrity } from '../src/integrity/check.js';

/**
 * A spec carrying one instance of every state this epic refuses, each written past the tools.
 *
 * The rows are legal SQL and illegal calls, which is exactly the shape a dump replay produces.
 */
function forbidden(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'legacy', title: 'Written before the refusals' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'work', title: 'The work' });
  const other = call.create_epic({ parent_id: spec.id, slug: 'elsewhere', title: 'Elsewhere' });

  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'A story', position: 0 });
  const far = call.create_story({ epic_id: other.id, number: 1, title: 'Far', position: 0 });

  const requirement = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', moscow: 'must', position: 0,
    text: 'A requirement whose text a fragment is supposed to quote.',
  });

  // FR6's state: ruled out, recording nothing that rules it out.
  const excluded = create(db, 'requirement', {
    spec_id: spec.id, label: 'FR2', class: 'functional', moscow: 'wont', position: 1,
    text: 'Ruled out before the refusal existed.',
  });

  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'It is delivered', polarity: 'must', position: 0,
  });

  // FR13's state: a second live criterion saying what its sibling says.
  const twin = create(db, 'story_criterion', {
    story_id: story.id, text: 'It is delivered', polarity: 'must', position: 1,
  });

  // FR2's state: a fragment that occurs nowhere in the requirement it names.
  const unquoted = create(db, 'coverage', {
    requirement_id: requirement.id, story_criterion_id: criterion.id,
    spec_fragment: 'a clause this requirement has never contained', position: 0,
  });

  // FR14's state: a story from another epic delivering this epic's binding.
  create(db, 'coverage_story', { coverage_id: unquoted.id, story_id: far.id });

  // FR3 and FR4's states, on one story: finished with a task outstanding beneath it, and over an
  // unverified binding, with nothing said about either.
  // The task itself is an ordinary row — a pending task is not a forbidden state. What FR3 forbids
  // is the story above it being finished, and that is the only part written by statement.
  call.create_task({ story_id: story.id, number: 1, title: 'Never finished', position: 0 });
  db.prepare("UPDATE story SET status = 'complete' WHERE id = ?").run(story.id);

  return { db, call, spec, epic, story, requirement, excluded, criterion, twin, unquoted, far };
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

// --- Criterion 1 (NFR1): every stored row reads exactly as it did --------------------------------

test('a row in every now-refused state reads unchanged through every tool [integration]', (t) => {
  const { db, call, spec, epic, story, excluded, criterion, twin, unquoted } = forbidden(t);

  // **Read through the tools rather than from the table**, because the promise is about how a row
  // *reads* — a guard leaking onto a read path would still leave the table right.
  const storedRequirement = call.read_requirement({ id: excluded.id, include_body: true });

  assert.equal(storedRequirement.moscow, 'wont');
  assert.equal(storedRequirement.exclusion, null);
  assert.equal(storedRequirement.text, 'Ruled out before the refusal existed.');

  const storedBinding = call.read_coverage({ id: unquoted.id, include_body: true });

  assert.equal(storedBinding.spec_fragment, 'a clause this requirement has never contained');
  assert.equal(storedBinding.requirement_label, 'FR1');

  assert.equal(call.read_story({ id: story.id }).status, 'complete',
    'a story stored as finished stopped reading as finished');

  // Both criteria, including the twin FR13 now refuses — same text, both live, both returned.
  const criteria = call.list_story_criterion({ story_id: story.id, include_body: true }).items;

  assert.deepEqual(criteria.map((row) => row.id).sort(), [criterion.id, twin.id].sort());
  assert.deepEqual([...new Set(criteria.map((row) => row.text))], ['It is delivered']);

  // The delivery across epics is still listed as what it is.
  assert.equal(
    call.list_coverage_story({ coverage_id: unquoted.id }).items.length, 1,
    'a cross-epic delivery stopped being readable',
  );

  // **And the same standing in a report that mentions it**, which is the half a read-by-read check
  // misses: the coverage report reaches these rows by a different route and must say the same
  // things about them.
  const report = coverageReport(db, { specId: spec.id, epicId: epic.id });
  const standing = report.requirements.find((row) => row.label === 'FR2');

  assert.equal(standing.moscow, 'wont');
  assert.equal(standing.exclusion, null);
  assert.equal(report.epic.counts.bindings, 1, 'the unquoted binding fell out of the roll-up');

  // The integrity register still names the broken binding, which is what it is for — the write path
  // refusing the state does not excuse the register from reporting one that arrived anyway.
  const named = checkIntegrity(db).violations
    .filter((violation) => violation.entry === 9)
    .flatMap((violation) => violation.rows.map((row) => row.id));

  assert.deepEqual(named, [unquoted.id],
    'entry 9 stopped naming a fragment its requirement does not contain');
});

// --- Criterion 2: every forbidden state is driven, and every one is refused -----------------------

test('every state this epic forbids is refused, and each refusal names its own subject [integration]', (t) => {
  const { db, call, spec, epic, story, requirement, criterion, far, unquoted } = forbidden(t);

  // A second story, still open, so the two closing rules can be driven without the first story's
  // `complete` status getting in the way.
  const fresh = call.create_story({ epic_id: epic.id, number: 2, title: 'Open', position: 1 });
  const freshCriterion = call.create_story_criterion({
    story_id: fresh.id, text: 'Something else entirely', position: 0,
  });

  call.create_task({ story_id: fresh.id, number: 1, title: 'Outstanding', position: 0 });

  const decision = call.create_adr({
    parent_id: spec.id, slug: 'a-decision', title: 'A decision', decision: 'This way.',
  });
  const foreignOption = call.create_adr_option({
    adr_id: call.create_adr({
      parent_id: spec.id, slug: 'another', title: 'Another', decision: 'That way.',
    }).id,
    name: 'Belongs elsewhere',
    position: 0,
  });

  // **Each forbidden state driven once, and the refusal required to name its own subject.** A set
  // of guards that all refused with one message would pass a count and tell a caller nothing.
  const driven = [
    ['a fragment its requirement does not contain', /nowhere in FR1's text/,
      () => call.create_coverage({
        requirement_id: requirement.id, spec_fragment: 'nowhere in this text',
        story_criterion_id: criterion.id, position: 9,
      })],
    ['a story closed over an outstanding task', /still outstanding/,
      () => call.update_story({ id: fresh.id, status: 'complete' })],
    ['a requirement ruled out with no exclusion', /ruled out of the iteration/,
      () => call.create_requirement({
        spec_id: spec.id, label: 'FR9', class: 'functional', moscow: 'wont', position: 9,
        text: 'Ruled out.',
      })],
    ['a requirement walked into being ruled out', /ruled out of the iteration/,
      () => call.update_requirement({ id: requirement.id, moscow: 'wont' })],
    ['a tradeoff on an option its decision does not hold', /does not hold the option/,
      () => call.create_adr_option_tradeoff({
        adr_id: decision.id, option_id: foreignOption.id, axis: 'cost', assessment: 'Low.',
      })],
    ['a second live criterion repeating its sibling', /already has a live criterion/,
      () => call.create_story_criterion({
        story_id: fresh.id, text: 'Something else entirely', position: 1,
      })],
    ['a story from another epic delivering this binding', /belongs to epic/,
      () => call.create_coverage_story({ coverage_id: unquoted.id, story_id: far.id })],
  ];

  for (const [what, names, run] of driven) {
    assert.match(refused(run, `${what} was accepted`).message, names,
      `the refusal for ${what} does not name what it is about`);
  }

  // **The closing note rule is driven last and on its own**, because it is the one that only
  // surfaces once the outstanding tasks are gone — a story refused for its tasks never reaches it.
  call.update_task({
    id: db.prepare('SELECT id FROM task WHERE story_id = ?').get(fresh.id).id, status: 'complete',
  });
  call.create_coverage({
    requirement_id: requirement.id, spec_fragment: 'A requirement whose text',
    story_criterion_id: freshCriterion.id, position: 8,
  });

  assert.match(
    refused(() => call.update_story({ id: fresh.id, status: 'complete' }),
      'a story closed silently over an unverified binding').message,
    /nobody has verified/,
  );

  // The control for the whole list: the same story closes once it says why, so none of the seven
  // above is a guard that simply refuses everything.
  assert.equal(
    call.update_story({
      id: fresh.id, status: 'complete', status_note: 'the board verifies this one',
    }).status,
    'complete',
  );
});
