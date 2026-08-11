/**
 * Epic 47-06 Story 3 — the converted `do`, and the five claims made about it.
 *
 * - "A do run updates story and task status through update tools, and records verification by
 *   writing `coverage.verified_at`, so FR21's triggers govern it rather than the skill's own
 *   prose rule" [feature]
 * - "Story readiness comes from the dependency query, not from reading `**Blocked by**` lines"
 *   [integration]
 * - "A do run reads whether to enter plan mode from the story's `plan` column, not from a marker
 *   in its title" [feature]
 * - "The facilitation survives: the retro-consumption gate still requires a disposition per
 *   observation rather than one blanket acknowledgement, and a story's verification gate still
 *   fires only once every implementation task under it is complete" [feature]
 * - "must NOT — the skill recovers an entity by reading a generated markdown file rather than by
 *   calling a read tool" [unit]
 *
 * **The fixture is what `epics` leaves behind**, for the reason `skill-epics.test.js` seeds a
 * spec: Story 3's subject is the second half of the same handoff. A fixture that seeded stories
 * without their blocking edges, their coverage rows or their retro observations would let three of
 * the five claims pass over nothing.
 *
 * **The binding to the file is the same three directions the other conversions use** — every tool
 * the file names is real, every tool the run drove is named, and every fixed-vocabulary argument
 * the run supplied is named. See `support/skills.js`.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import {
  skillSource, toolNames, reachable, section, recorder, recoveries, bindings,
  seedStartup, driveStartup,
} from './support/skills.js';

const SKILL = 'do';
const source = skillSource(SKILL);

/**
 * The two recoveries this file in particular would reach for, on top of the shared sweep.
 *
 * Hoisted so the control at the end reads the source with the same patterns the assertion does —
 * a control run over a narrower list proves the narrower list works.
 */
const PARSES = [
  { pattern: /read the (epic|coverage) (doc|matrix)/i, why: 'a read of a projected document' },
  { pattern: /\bTaskCreate\b|\bTaskUpdate\b/, why: 'harness task state standing in for a row' },
];

/**
 * A spec broken down the way `epics` breaks one down: two epics with a gating edge between them,
 * two stories under the first with a gating edge between them, tasks, criteria with their approach
 * tags, and coverage rows bound and unverified.
 *
 * Written with the raw handlers — none of it is this skill's work, and a fixture write counted as
 * a run write would demand the file name `create_story`.
 */
function project(tools) {
  const seed = handlers(tools);

  const spec = seed.create_spec({ slug: 'sessions', title: 'Sessions' });

  const requirement = seed.create_requirement({
    spec_id: spec.id,
    label: 'FR1',
    class: 'functional',
    moscow: 'must',
    text: 'A user creates a session by submitting valid credentials, and reaches the dashboard.',
    position: 0,
  });

  const lifecycle = seed.create_epic({ parent_id: spec.id, slug: 'lifecycle', title: 'Lifecycle' });
  const durability = seed.create_epic({ parent_id: spec.id, slug: 'durability', title: 'Durability' });

  // The second epic waits on the first. `list_epic` with `ready` is the only thing that knows.
  seed.create_dependency({
    kind: 'blocks',
    source_document_id: lifecycle.id,
    target_document_id: durability.id,
  });

  // **`plan` is a column and the titles carry no marker**, which is half of the third claim; the
  // other half is that the run reads the column. Both stories are titled plainly on purpose.
  const first = seed.create_story({
    epic_id: lifecycle.id, number: 1, title: 'Issue a session on valid credentials', position: 0,
    plan: 1,
  });
  const second = seed.create_story({
    epic_id: lifecycle.id, number: 2, title: 'Reach the dashboard from a live session', position: 1,
  });

  seed.create_dependency({ kind: 'blocks', source_story_id: first.id, target_story_id: second.id });

  // A non-gating edge into the *first* story, which nothing should treat as a blocker. Without it
  // a readiness query hardcoded to "any edge" would pass every assertion below.
  seed.create_dependency({
    kind: 'builds_on', source_document_id: durability.id, target_story_id: first.id,
  });

  const tasks = [
    { story: first, number: 1, title: 'Add the session route' },
    { story: first, number: 2, title: 'Write tests for issuing a session' },
    { story: second, number: 1, title: 'Render the dashboard' },
  ].map(({ story, ...fields }, position) =>
    seed.create_task({ story_id: story.id, description: 'work', position, ...fields }));

  const criteria = [
    { story: first, text: 'A valid credential pair returns a session token', tag: 'integration' },
    { story: first, text: 'a credential reaches a log line', polarity: 'must_not', tag: 'unit' },
    { story: second, text: 'A live session renders the dashboard', tag: 'feature' },
  ].map(({ story, tag, ...fields }, position) => {
    const criterion = seed.create_story_criterion({ story_id: story.id, position, ...fields });
    seed.create_story_criterion_approach({ story_criterion_id: criterion.id, tag });
    return criterion;
  });

  const coverage = criteria.map((criterion, position) => seed.create_coverage({
    requirement_id: requirement.id,
    spec_fragment: position === 2 ? 'reaches the dashboard' : 'submitting valid credentials',
    story_criterion_id: criterion.id,
    position,
  }));

  const matrix = seed.create_coverage_matrix({
    parent_id: lifecycle.id, slug: 'lifecycle-coverage', title: 'Coverage Matrix: Lifecycle',
  });

  // **Two live observations, not one.** The gate has to dispose of each on its own, which is what
  // the fourth claim is about, and a single-observation fixture cannot tell that apart from one
  // blanket acknowledgement. The retired third is left out by its row.
  const startup = seedStartup(seed, {
    scope: 'do',
    skill: 'dpm:do',
    phase: 'Story 1 Task 1',
    live: [
      'The token store had an index nobody expected.',
      'A story spanning four components ran to twice its estimate.',
    ],
  });

  return {
    spec, requirement, lifecycle, durability, first, second, tasks, criteria, coverage, matrix,
    ...startup,
  };
}

/**
 * The run the SKILL.md prescribes: startup, the retro gate, one story worked to completion, then
 * the story its completion releases.
 *
 * Returns the readiness answers at each point rather than only the final state, because the claim
 * is about *when* a story became workable and a final snapshot cannot distinguish that from a
 * story that was never blocked.
 */
function run(call, fixture) {
  // --- Startup -----------------------------------------------------------------------------
  // Session, library and retro awareness. No roster — this skill runs no Perspectives step.
  const startup = driveStartup(call, fixture, { scope: 'do', skill: 'dpm:do', roster: false });
  const observations = startup.observations;

  // Input: which epics can be worked on now, as a query.
  const readyEpics = call.list_epic({ ready: true }).items;

  // The retro consumption gate: every live observation gets its own disposition row.
  const dispositions = observations.map(({ retro, observation }, index) =>
    call.create_retro_application({
      retro_id: retro.id,
      applied_to_id: fixture.lifecycle.id,
      theme: observation.text.slice(0, 30),
      disposition: index === 0 ? 'applied' : 'deferred',
      note: index === 0 ? 'informs the exploration of task 1' : 'no re-scoping in this run',
    }));

  call.list_test_approach({});

  // --- Story selection ---------------------------------------------------------------------
  const readiness = [];

  /** One pass of the selection rule: what is ready now, and why the rest is not. */
  const select = () => {
    const ready = call.list_story({ epic_id: fixture.lifecycle.id, ready: true }).items;
    const held = call.list_story({ epic_id: fixture.lifecycle.id }).items
      .filter((story) => !ready.some((entry) => entry.id === story.id))
      .filter((story) => story.status !== 'complete')
      .map((story) => ({
        story,
        blockers: call.list_dependency({ target_story_id: story.id }).items
          .filter((edge) => call.list_dependency_kind({}).items
            .find((kind) => kind.kind === edge.kind)?.gates_work === 1),
      }));

    readiness.push({ ready: ready.map((story) => story.number), held: held.map((entry) => entry.story.number) });
    return { ready, held };
  };

  const worked = [];

  for (let pass = 0; pass < 2; pass += 1) {
    const { ready } = select();
    if (ready.length === 0) break;

    const next = ready[0];
    const story = call.read_story({ id: next.id });
    const tasks = call.list_task({ story_id: story.id }).items;
    const criteria = call.list_story_criterion({ story_id: story.id, include_body: true }).items
      .map((criterion) => ({
        criterion,
        tags: call.list_story_criterion_approach({ story_criterion_id: criterion.id }).items
          .map((row) => row.tag),
      }));

    // Step 3: plan mode is decided by the column, never by the title.
    const planned = story.plan === 1;

    // Steps 4 and 6: each task worked, then marked complete through the update tool.
    for (const task of tasks) {
      call.read_task({ id: task.id });
      call.update_session({
        id: startup.session, phase: `Story ${story.number} Task ${task.number}`, state: '{}',
      });
      call.update_task({ id: task.id, status: 'complete' });
    }

    // Step 5: the verification gate, which fires only once every task under the story is done.
    const remaining = call.list_task({ story_id: story.id }).items
      .filter((task) => task.status !== 'complete');

    assert.deepEqual(remaining, [], 'the gate ran with implementation tasks still open');

    const verified = criteria.flatMap(({ criterion }) =>
      call.list_coverage({ story_criterion_id: criterion.id }).items
        .map((row) => call.update_coverage({ id: row.id, verified_at: '2026-08-09T00:00:00.000Z' })));

    call.update_story({
      id: story.id,
      status: 'complete',
      status_note: planned ? 'planned in full before execution' : '',
    });

    worked.push({ story, tasks, criteria, planned, verified });
  }

  select();

  // Step 8: the roll-up, and the completeness claim that is a judgement rather than a sum.
  const requirements = call.list_requirement({ spec_id: fixture.spec.id }).items;
  const rollUp = requirements.map((requirement) => ({
    requirement,
    rows: call.list_coverage({ requirement_id: requirement.id }).items,
  }));

  for (const { requirement, rows } of rollUp) {
    if (rows.every((row) => row.verified_at !== null)) {
      call.update_requirement({ id: requirement.id, coverage_claimed_at: '2026-08-09T00:00:00.000Z' });
    }
  }

  const nextEpic = call.list_epic({ ready: true }).items;

  return { readyEpics, observations, dispositions, readiness, worked, rollUp, nextEpic };
}

// --- Criterion 1: status and verification are written, not asserted ------------------------------

test('a do run writes status through update tools and records verification as a coverage row', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call, used, passed } = recorder(tools);

  const fixture = project(tools);
  const result = run(call, fixture);

  // The assertions below read through the raw handlers, never the recorded ones: a read this test
  // performs to check the run is the *test's* verification, and counting it as the run's would
  // demand the file prescribe a call nothing in the run makes.
  const raw = handlers(tools);

  assert.equal(result.worked.length, 2, 'both stories were worked, in the order readiness gave');

  // Status is a column on the row, read back from the store rather than from the run's return.
  for (const { story, tasks } of result.worked) {
    assert.equal(raw.read_story({ id: story.id }).status, 'complete');

    for (const task of tasks) {
      assert.equal(raw.read_task({ id: task.id }).status, 'complete');
    }
  }

  // The qualification lives in its own column, so there is no token-plus-tail to parse back out.
  assert.equal(raw.read_story({ id: fixture.first.id }).status_note,
    'planned in full before execution');

  // Verification is the pair on the coverage row, and the hash half is not the skill's to supply.
  const rows = raw.list_coverage({ requirement_id: fixture.requirement.id }).items;

  assert.equal(rows.length, 3);
  for (const row of rows) {
    assert.equal(row.verified_at, '2026-08-09T00:00:00.000Z');
    assert.ok(row.binding_hash, 'a ✓ with no record of what it verified');
  }

  assert.ok(!passed.get('update_coverage').has('binding_hash'),
    'the run supplied the digest that vouches for its own claim');

  // **The trigger governs the mark, not the skill.** Editing the criterion clears the pair with
  // nothing in the file having to remember to — which is why the file may not carry its own rule.
  raw.update_story_criterion({ id: fixture.criteria[0].id, text: 'A valid pair returns a token' });

  const decayed = raw.read_coverage({ id: fixture.coverage[0].id });
  assert.equal(decayed.verified_at, null);
  assert.equal(decayed.binding_hash, null);

  const step = section(source, '5. Verify');
  assert.notEqual(step, '', 'the verification step still exists');
  assert.doesNotMatch(step, /✓/, 'the step writes a mark instead of a row');
  assert.doesNotMatch(step, /\|\s*-{3}/, 'and composes no table');

  // The three directions of the binding to the file, all reported at once.
  assert.deepEqual(bindings(source, tools, { used, passed }), []);
});

// --- Criterion 2: readiness is the dependency query ----------------------------------------------

test('story readiness comes from the edges, and releases when the blocker completes', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call } = recorder(tools);

  const fixture = project(tools);
  const result = run(call, fixture);

  // Three passes of the selection rule: before any work, after the first story, and at the end.
  assert.deepEqual(result.readiness, [
    { ready: [1], held: [2] },
    { ready: [2], held: [] },
    { ready: [], held: [] },
  ], 'story 2 was workable before its blocker finished, or never became workable');

  // The non-gating edge into story 1 was ignored — and it was really there, so the assertion
  // above is not passing over an empty set.
  const into = call.list_dependency({ target_story_id: fixture.first.id }).items;
  assert.deepEqual(into.map((edge) => edge.kind), ['builds_on']);

  // `gates_work` is read from the table rather than matched against a kind name here. A project
  // that flips the flag changes the answer with nothing edited anywhere else.
  const raw = handlers(tools);
  raw.update_dependency_kind({ kind: 'builds_on', gates_work: true });

  assert.deepEqual(
    call.list_story({ epic_id: fixture.lifecycle.id, ready: true }).items.map((story) => story.number),
    [],
    'a kind that now gates released nothing — the query is matching names, not the flag',
  );

  raw.update_dependency_kind({ kind: 'builds_on', gates_work: false });

  // The same query at epic level, which is what Input resolves against: durability waits on
  // lifecycle, and lifecycle is complete only once its stories are.
  assert.deepEqual(result.readyEpics.map((epic) => epic.slug), ['lifecycle']);

  call.update_epic({ id: fixture.lifecycle.id, status: 'complete' });
  assert.deepEqual(
    call.list_epic({ ready: true }).items.map((epic) => epic.slug),
    ['durability'],
  );
});

// --- Criterion 3: plan mode is a column ----------------------------------------------------------

test('plan mode is read from the story row, and no title carries a marker', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call } = recorder(tools);

  const fixture = project(tools);
  const result = run(call, fixture);

  assert.deepEqual(result.worked.map((entry) => entry.planned), [true, false]);

  for (const { story } of result.worked) {
    assert.doesNotMatch(story.title, /\[[a-z]+\]/,
      'a story title carries a marker, which is the inference FR4 removes');
  }

  // The column survived a run that wrote status to the same row — a status update that dropped it
  // would leave the next run planning nothing.
  assert.equal(call.read_story({ id: fixture.first.id }).plan, 1);
  assert.equal(call.read_story({ id: fixture.second.id }).plan, 0);

  // And the file decides from the column: the planning step names it and names no marker.
  const step = section(source, '3. Plan');
  assert.notEqual(step, '', 'the planning step still exists');
  assert.match(step, /`plan`/);
  assert.doesNotMatch(step, /\[plan\]|title/i,
    'the step reaches for a title to decide something a column already says');
});

// --- Criterion 4: the facilitation survives ------------------------------------------------------

test('the retro gate disposes of each observation, and the verification gate waits for every task', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call } = recorder(tools);

  const fixture = project(tools);
  const result = run(call, fixture);

  // One disposition row per live observation, not one for the set. The retired one is absent
  // because its row says so, with nothing parsed to find out.
  assert.equal(result.observations.length, 2);
  assert.equal(result.dispositions.length, 2);
  assert.deepEqual(result.dispositions.map((row) => row.disposition).sort(), ['applied', 'deferred']);

  for (const { categories } of result.observations) {
    assert.ok(categories.every(Boolean), 'an observation reached the gate without its category');
  }

  // The gate's own wording: a disposition for each one, and a blanket acknowledgement refused.
  // Matched as the construction rather than as the words: an earlier draft asserted `/each one/`,
  // which the section satisfies incidentally three lines above where the rule is stated, so
  // deleting the rule left the test passing.
  const gate = section(source, 'Retro consumption gate');
  assert.notEqual(gate, '', 'the gate still exists');
  assert.match(gate, /require a disposition for \*\*each one\*\*/i);
  assert.match(gate, /blanket acknowledgement does not satisfy/i);
  assert.match(gate, /`applied`/);
  assert.match(gate, /`deferred`/);
  assert.match(gate, /`not_applicable`/);

  // The verification gate's ordering is asserted inside `run` as each story completes; here is the
  // other half — the file says the story's status is written at the gate and not before.
  const complete = section(source, '6. Complete');
  assert.notEqual(complete, '', 'the completion step still exists');
  assert.match(complete, /mcp__plugin_dpm_dpm__update_story/);
  assert.match(complete, /verification gate/i);

  // And a control on the ordering assertion itself: the gate is checkable only because a story
  // really did have more than one task under it.
  assert.equal(result.worked[0].tasks.length, 2);
});

// --- Criterion 5 (must NOT): no recovery by reading what was written -----------------------------

test('the skill recovers nothing by reading a generated file', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);

  // The shared FR25 sweep, plus the two recoveries this file in particular would reach for: the
  // rendered epic or matrix read back to find what to mark, and the harness task list treated as
  // the record of what is done rather than as a view of the rows.
  assert.deepEqual(recoveries(source, PARSES), []);

  // The positive half, which is what makes the sweep more than an absence: every discovery the
  // startup makes goes through a tool, and the tools it names are real.
  const known = new Set(tools.map((tool) => tool.name));
  const named = toolNames(reachable(source));

  for (const required of ['list_epic', 'list_story', 'list_task', 'list_story_criterion',
    'list_coverage', 'update_coverage', 'update_story', 'update_task', 'list_dependency']) {
    assert.ok(named.includes(required), `the skill never names ${required}`);
    assert.ok(known.has(required), `${required} is not a tool`);
  }

  // The control: the sweep is not so narrow that anything passes. A file with the two patterns
  // this skill is most likely to regain is caught by the same reading.
  const regressed = `${source}\n\nRead the epic doc at docs/epics/01-epic-thing.md and parse its `
    + '**Blocked by**: fields.';

  assert.ok(recoveries(regressed, PARSES).length >= 3,
    'the sweep passed a file that names a path, parses a metadata field and reads a projection');
});
