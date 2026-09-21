/**
 * Epic 05-02 Story 1 — a fragment that is nowhere in its requirement is refused (FR2).
 *
 * The check itself is not new: integrity register entry 9 has asked this question in SQL since
 * Epic 04-04. What changes is when it is asked. Reported afterwards, a paraphrased or mistyped
 * quote reads as a sound binding in every roll-up until somebody runs the register — and by then it
 * has counted toward a requirement being discharged. Asked at the write, it is a refusal the run
 * meets at the step that caused it.
 *
 * **The register keeps its copy and this does not make it redundant.** `src/restore/` replays a dump
 * as raw SQL with foreign keys off and no tool in the path, so a database can still arrive holding
 * a binding that quotes nothing. After this story that is the *only* way the state arises, which is
 * why the fixtures below that need a broken row write it through the fixture seam rather than
 * through the tool.
 *
 * **The rejection is driven on its own rows**, with the control built separately rather than as a
 * second assertion after it. A rejection sharing a test with the positive it complements is only
 * verified when the mutation happens to fail the rejection's assertion first, and assertion order
 * inside one test is not evidence worth depending on.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { fragmentPlacement } from '../src/coverage/binding.js';

/** The tool surface, and a spec with two requirements whose texts are deliberately unalike. */
function surface(t) {
  const db = planning(t);
  const call = handlers(spineTools(db));

  const spec = call.create_spec({ slug: 'refusals', title: 'Write-path refusals' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'guards', title: 'Guards' });
  const story = call.create_story({ epic_id: epic.id, number: 1, title: 'Guard', position: 0 });
  const criterion = call.create_story_criterion({
    story_id: story.id, text: 'The write is refused', polarity: 'must', position: 0,
  });

  // **Two requirements sharing no wording**, so a fragment of one cannot accidentally be a slice of
  // the other. Without that, the sibling assertion below could pass on a coincidence.
  const clock = call.create_requirement({
    spec_id: spec.id, label: 'FR1', class: 'functional', position: 0,
    text: 'The server supplies the clock for a coverage verification stamp.',
  });
  const scope = call.create_requirement({
    spec_id: spec.id, label: 'FR2', class: 'functional', position: 1,
    text: 'A list refuses a scope id that matches no row.',
  });

  const bind = (requirement, fragment, position = 0) => call.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: fragment,
    story_criterion_id: criterion.id,
    position,
  });

  return { db, call, spec, criterion, clock, scope, bind };
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

// --- Criterion 2 (must NOT): the unfound fragment is not stored ----------------------------------

test('must NOT — a fragment nowhere in its requirement is stored [integration]', (t) => {
  const { db, clock, bind } = surface(t);

  // The refused thing first, on rows of its own. What is asserted is the *absence of a row*, not
  // merely that something was thrown: a guard that raised after writing would satisfy a check on
  // the exception and leave exactly the binding this refusal exists to prevent.
  refused(() => bind(clock, 'a sentence the requirement does not contain'),
    'a fragment absent from its requirement was accepted');

  assert.equal(db.prepare('SELECT count(*) AS n FROM coverage').get().n, 0,
    'the write was refused and the row is in the table anyway');

  // And the refusal says which requirement it looked in, so the caller is not left to guess which
  // of a spec's requirements rejected them.
  const error = refused(() => bind(clock, 'a sentence the requirement does not contain'));

  assert.match(error.message, /nowhere in FR1's text/);
});

// --- Criterion 1 (control): the sound binding still succeeds -------------------------------------

test('control — a fragment that does occur in its requirement is stored [integration]', (t) => {
  const { db, call, clock, bind } = surface(t);

  // **Its own rows and its own test.** This is what shows the refusal above discriminates rather
  // than the write path being broken: same tool, same requirement, a fragment that is a verbatim
  // slice rather than a paraphrase.
  const row = bind(clock, 'supplies the clock');

  assert.ok(row.id, 'a verbatim fragment was refused');
  assert.equal(db.prepare('SELECT count(*) AS n FROM coverage').get().n, 1);

  // Read back through the tool rather than trusted from the create's return, asking for the
  // withheld column explicitly — a comparison written without `include_body` compares undefined
  // against undefined and passes on a call that stored nothing.
  const stored = call.read_coverage({ id: row.id, include_body: true });

  assert.equal(stored.spec_fragment, 'supplies the clock');
  assert.equal(stored.requirement_label, 'FR1');

  // The boundary cases a substring test has to admit: the whole text, and a slice that starts
  // mid-word. Neither is a sensible fragment, and both are verbatim — the rule is occurrence, not
  // tidiness, and a guard that also judged tidiness would refuse quotes nobody can predict.
  assert.ok(bind(clock, 'The server supplies the clock for a coverage verification stamp.', 1).id);
  assert.ok(bind(clock, 'lies the clock', 2).id);
});

// --- Criterion 3: the refusal names the requirement the fragment belongs to -----------------------

test('the refusal names the sibling requirement whose text holds the fragment [integration]', (t) => {
  const { clock, scope, bind } = surface(t);

  // A fragment of FR2 offered against FR1 — the commonest real mistake, which is aiming a sound
  // quote at the wrong row rather than mistyping it.
  const error = refused(() => bind(clock, 'refuses a scope id'),
    "a fragment of another requirement's text was accepted");

  assert.match(error.message, /it belongs to FR2, so bind it to that requirement/);

  // **The control for the naming, and it is the half that makes the assertion mean something.** A
  // refusal that named a sibling unconditionally would pass the assertion above; this one has no
  // sibling to find, so it must say something else.
  const unfound = refused(() => bind(clock, 'a sentence no requirement here contains'));

  assert.doesNotMatch(unfound.message, /belongs to/,
    'a fragment no requirement holds was reported as belonging to one');
  assert.match(unfound.message, /check the quote against the text/);

  // And the sibling really is bindable — the refusal's advice is followed and succeeds, rather
  // than naming a row that would refuse for some other reason.
  assert.ok(bind(scope, 'refuses a scope id').id, 'the refusal named a requirement that refuses too');
});

// --- The write path and the register ask one question ---------------------------------------------

test('the refusal and register entry 9 agree on the same rows [integration]', (t) => {
  const { db, clock, scope } = surface(t);

  // Entry 9 reads `instr(requirement.text, coverage.spec_fragment) = 0` in SQL; the write path
  // reads `includes` in JavaScript. Two spellings of one predicate is how two answers to one
  // question start, so they are compared on the same inputs rather than assumed to agree.
  const cases = [
    ['supplies the clock', clock, true],
    ['The server supplies the clock for a coverage verification stamp.', clock, true],
    ['refuses a scope id', clock, false],
    ['a sentence no requirement here contains', clock, false],
    ['refuses a scope id', scope, true],
  ];

  for (const [fragment, requirement, expected] of cases) {
    const bySql = db
      .prepare('SELECT instr(text, ?) > 0 AS found FROM requirement WHERE id = ?')
      .get(fragment, requirement.id).found === 1;
    const byWritePath = fragmentPlacement(db, {
      requirement_id: requirement.id, spec_fragment: fragment,
    }).found;

    assert.equal(byWritePath, expected, `the write path is wrong about ${JSON.stringify(fragment)}`);
    assert.equal(bySql, expected, `the register is wrong about ${JSON.stringify(fragment)}`);
  }
});
