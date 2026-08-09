/**
 * Epic 47-06 Story 1 — the converted `spec`, and the three claims made about it.
 *
 * - "A spec run writes the document, its requirements with `class` and MoSCoW band, and its
 *   acceptance-criteria coverage rows, all through create tools" [feature]
 * - "The facilitation survives: the run still gates on scope, still produces a testing strategy,
 *   and still refuses an untestable criterion" [feature]
 * - "must NOT — the skill recovers an entity by reading a generated markdown file rather than by
 *   calling a read tool" [unit]
 *
 * **"Acceptance-criteria coverage rows" are `acceptance_criterion` plus `criterion_approach`,
 * not `coverage`.** The name comes from the section CPM's `spec` writes — *Acceptance Criteria
 * Coverage*, whose columns are requirement, criterion and tag. The `coverage` table is a
 * different thing with a colliding name: it binds a requirement to a **story** criterion, so
 * `dpm_create_coverage` requires a `story_criterion_id` that does not exist until `epics` has
 * run. Reading the criterion the other way would make it unsatisfiable by the skill it is
 * written about, so the run below writes the pair and Story 2 owns the binding.
 *
 * **The first test is bound to the file in both directions** — see `support/skills.js` for why
 * that is the load-bearing part rather than the assertions on the graph.
 *
 * **What this leaves to the review at the end of the story.** The retention test asserts the
 * three named behaviours are present in the steps that own them. It cannot assess whether they
 * are *well* facilitated; the spec's Testing Strategy says as much, and puts thinness under
 * `[manual]`. CPM's own `SKILL.md` is not consulted here in either direction — it is a name
 * oracle for the corpus and nothing more.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { skillSource, frontMatter, toolNames, section, recorder, valuedArguments } from './support/skills.js';

const SKILL = 'spec';
const source = skillSource(SKILL);

/**
 * The project a spec run starts in: a brief chain, a scoped library document, a prior decision
 * and a retro with an observation. Written with the raw handlers rather than the recorded ones,
 * because none of it is the skill's own work — a fixture write counted as a run write would put
 * `dpm_create_problem_brief` in the used set and demand the skill name a tool it never calls.
 */
function project(tools) {
  const seed = Object.fromEntries(tools.map((tool) => [tool.name, tool.handler]));

  const problem = seed.dpm_create_problem_brief({ slug: 'planning-drift', title: 'Planning drift' });
  seed.dpm_create_document_section({
    document_id: problem.id,
    heading: 'Constraints',
    body: 'The store has to survive a machine with no package manager.',
    position: 0,
  });

  const product = seed.dpm_create_product_brief({ slug: 'dpm', title: 'dpm' });

  const library = seed.dpm_create_library({
    slug: 'coding-standards',
    title: 'Coding standards',
    doc_type: 'reference',
  });
  seed.dpm_create_library_scope({ document_id: library.id, scope: 'spec' });
  seed.dpm_create_document_section({
    document_id: library.id,
    heading: 'Style',
    body: 'Two spaces, and no abbreviations in exported names.',
    position: 0,
  });

  const retro = seed.dpm_create_retro({ slug: 'round-one', title: 'Round one' });
  seed.dpm_create_observation({
    retro_id: retro.id,
    position: 0,
    text: 'A criterion tagged manual was automatable all along.',
  });
  seed.dpm_create_observation({
    retro_id: retro.id,
    position: 1,
    text: 'A lesson that has since been spent.',
    retired_at: '2026-01-01T00:00:00.000Z',
    retired_reason: 'the module it warned about is gone',
  });

  const earlier = seed.dpm_create_session({
    id: 'session-before',
    skill: 'dpm:spec',
    phase: 'Section 2',
    state: '{"requirements":2}',
  });

  return { problem, product, library, retro, earlier };
}

/**
 * The run the SKILL.md prescribes, start to finish, through the recorded dispatcher.
 *
 * The startup discoveries are here rather than assumed because they are the half of the
 * conversion that FR25 is about: each one was a glob, and a run that skipped them would leave
 * the tools that replaced them unexercised and unnamed.
 */
function run(call, fixture) {
  // Startup: session, roster, library, prior decisions, constraint inheritance, retro awareness.
  call.dpm_list_session({});
  call.dpm_adopt_session({ id: 'session-now', predecessor_id: fixture.earlier.id, include_body: true });
  call.dpm_create_session({ id: 'session-run', skill: 'dpm:spec', phase: 'Section 1', state: '{}' });

  call.dpm_list_agent({});

  for (const document of call.dpm_list_library({}).items) {
    const scopes = call.dpm_list_library_scope({ document_id: document.id }).items;
    if (!scopes.some((entry) => entry.scope === 'spec' || entry.scope === 'all')) continue;

    for (const heading of call.dpm_list_document_section({ document_id: document.id }).items) {
      call.dpm_read_document_section({ id: heading.id, include_body: true });
    }
  }

  call.dpm_list_adr({});

  call.dpm_list_product_brief({});
  const briefs = call.dpm_list_problem_brief({});
  const brief = briefs.items.find((item) => item.id === fixture.problem.id);
  const constraints = call.dpm_list_document_section({ document_id: brief.id, include_body: true })
    .items.find((entry) => entry.heading === 'Constraints');

  const observations = call.dpm_list_retro({}).items
    .flatMap((retro) => call.dpm_list_observation({ retro_id: retro.id, include_body: true }).items)
    .filter((observation) => !observation.retired_at);

  // Section 1: the spec exists from here on, and its lineage is an edge.
  const spec = call.dpm_create_spec({ slug: 'dpm-persistence', title: 'dpm SQLite persistence' });
  call.dpm_create_dependency({
    kind: 'builds_on',
    source_document_id: spec.id,
    target_document_id: fixture.problem.id,
  });
  call.dpm_create_document_section({
    document_id: spec.id,
    heading: 'Problem Statement',
    body: 'Planning artefacts are markdown, so every skill parses what the last one wrote.',
    position: 0,
  });

  // Section 2 and Section 3: class is passed, never read back out of the label.
  const requirements = [
    { label: 'FR1', class: 'functional', moscow: 'must', text: 'Skills write through typed tools' },
    { label: 'FR2', class: 'functional', moscow: 'could', text: 'A dump is byte-stable' },
    { label: 'FR3', class: 'functional', moscow: 'wont', exclusion: 'deferred', text: 'A web view' },
    { label: 'NFR1', class: 'non_functional', text: 'A read answers in under a second' },
    {
      label: 'ENV1',
      class: 'environmental_requirement',
      text: 'A test runner is available with no install step',
    },
    {
      label: 'ENVX1',
      class: 'environmental_restriction',
      text: 'No dependency whose install requires compilation',
    },
  ].map((fields, position) => call.dpm_create_requirement({ spec_id: spec.id, position, ...fields }));

  // Section 6a and 6b: the vocabulary is read, then each criterion is written with its polarity
  // and its tag as arguments.
  const approaches = call.dpm_list_test_approach({}).items.map((entry) => entry.tag);

  const criteria = [
    { requirement: requirements[0], text: 'A create tool rejects a call with no class', tag: 'unit' },
    {
      requirement: requirements[0],
      text: 'a skill composes a statement rather than calling a tool',
      polarity: 'must_not',
      tag: 'unit',
    },
    { requirement: requirements[3], text: 'A read of one spec returns within a second', tag: 'integration' },
    { requirement: requirements[4], text: 'The suite runs from one command', tag: 'feature' },
    { requirement: requirements[5], text: 'The manifest declares no dependencies', tag: 'unit' },
  ].map(({ requirement, tag, ...fields }, position) => {
    const criterion = call.dpm_create_acceptance_criterion({
      requirement_id: requirement.id,
      position,
      ...fields,
    });
    call.dpm_create_criterion_approach({ criterion_id: criterion.id, tag });
    return { criterion, tag };
  });

  // Section 4: the decision, its options and the axes they were weighed on.
  const adr = call.dpm_create_adr({
    slug: 'sqlite-store',
    title: 'SQLite as the store',
    parent_id: spec.id,
    decision: 'Planning state lives in one SQLite database, rendered one way to markdown.',
    decision_status: 'accepted',
  });
  const chosen = call.dpm_create_adr_option({
    adr_id: adr.id,
    name: 'SQLite',
    chosen: true,
    rationale: 'It ships with the runtime.',
    position: 0,
  });
  call.dpm_create_adr_option({ adr_id: adr.id, name: 'Markdown', position: 1 });
  call.dpm_create_adr_option_tradeoff({
    option_id: chosen.id,
    axis: 'Install cost',
    assessment: 'None — no package to add.',
  });

  // Section 5 and Step 6c: the prose sections.
  call.dpm_create_document_section({
    document_id: spec.id,
    heading: 'Scope Boundary',
    body: 'In scope: the store and the tools. Out of scope: a web view.',
    position: 1,
  });
  call.dpm_create_document_section({
    document_id: spec.id,
    heading: 'Integration Boundaries',
    body: 'The tool schemas are the write contract.',
    position: 2,
  });

  call.dpm_update_session({ id: 'session-run', phase: 'Section 7', state: '{"sections":7}' });

  // Section 7: the review reads rows.
  const review = {
    spec: call.dpm_read_spec({ id: spec.id }),
    requirements: call.dpm_list_requirement({ spec_id: spec.id, limit: 100 }).items,
    criteria: requirements.flatMap((requirement) =>
      call.dpm_list_acceptance_criterion({ requirement_id: requirement.id, include_body: true }).items),
    decisions: call.dpm_list_adr({ parent_id: spec.id }).items,
    sections: call.dpm_list_document_section({ document_id: spec.id, include_body: true }).items,
  };

  call.dpm_update_spec({ id: spec.id, status: 'complete' });
  const approved = call.dpm_read_spec({ id: spec.id });

  // A published companion, recorded only once it has an address.
  const artifact = call.dpm_create_artifact({
    url: 'https://example.invalid/spec',
    title: 'Requirement explorer',
    published_at: '2026-08-09T00:00:00.000Z',
  });
  call.dpm_create_artifact_document({ artifact_id: artifact.id, document_id: spec.id });

  return { spec, requirements, criteria, approaches, adr, review, approved, constraints, observations };
}

test('a spec run writes the document, its classed requirements and its tagged criteria through create tools', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call, used, passed } = recorder(tools);

  const fixture = project(tools);
  const result = { ...run(call, fixture), passed };

  // The startup discoveries found what a glob used to find.
  assert.equal(result.constraints.heading, 'Constraints');
  assert.match(result.constraints.body, /no package manager/,
    'the problem brief\'s constraints reached the run, so Step 3a starts from what was captured');
  assert.equal(result.observations.length, 1,
    'the retired observation was left out by its own row, with nothing parsed to find out');

  // Class and band are values on the row, and survive a label that says nothing about either.
  const byLabel = Object.fromEntries(result.review.requirements.map((row) => [row.label, row]));
  assert.equal(byLabel.FR1.class, 'functional');
  assert.equal(byLabel.FR1.moscow, 'must');
  assert.equal(byLabel.NFR1.class, 'non_functional');
  assert.equal(byLabel.ENV1.class, 'environmental_requirement');
  assert.equal(byLabel.ENVX1.class, 'environmental_restriction');
  assert.equal(byLabel.FR3.moscow, 'wont');
  assert.equal(byLabel.FR3.exclusion, 'deferred',
    'a deferred requirement is recognisable as one, rather than counting as an outstanding gap');

  // A rejected behaviour is a polarity, not the words "must NOT" at the front of the text.
  const rejected = result.review.criteria.filter((row) => row.polarity === 'must_not');
  assert.equal(rejected.length, 1);
  assert.doesNotMatch(rejected[0].text, /must\s*NOT/i,
    'the rejection is carried by the column, so the text does not have to state it');

  // Every criterion carries a tag drawn from the project's own vocabulary.
  const tags = db.prepare('SELECT criterion_id, tag FROM criterion_approach').all();
  assert.equal(tags.length, result.criteria.length);
  for (const { tag } of tags) {
    assert.ok(result.approaches.includes(tag), `${tag} is a term dpm_list_test_approach offered`);
  }

  // The graph reads back whole through the read tools. The review sees `pending` because the
  // status is what the gate decides — approval is the write, not a formality after one.
  assert.equal(result.review.spec.status, 'pending');
  assert.equal(result.approved.status, 'complete');
  assert.equal(result.review.requirements.length, 6);
  assert.equal(result.review.criteria.length, 5);
  assert.equal(result.review.decisions.length, 1);
  assert.deepEqual(result.review.sections.map((row) => row.heading),
    ['Problem Statement', 'Scope Boundary', 'Integration Boundaries']);

  // Both directions of the binding to the file.
  const named = toolNames(source);
  const known = new Set(tools.map((tool) => tool.name));

  for (const name of named) {
    assert.ok(known.has(name), `${SKILL} instructs a run to call ${name}, which is not a tool`);
  }
  for (const name of [...used].sort()) {
    assert.ok(named.includes(name),
      `this test drove ${name} and the skill never names it — one of the two has drifted`);
  }

  // And the same binding one level down: every fixed-vocabulary argument this run supplied is
  // named in the file, so a value cannot quietly go back to being a heading.
  for (const tool of tools.filter((entry) => used.has(entry.name))) {
    for (const argument of valuedArguments(tool)) {
      if (!result.passed.get(tool.name)?.has(argument)) continue;

      // Matched inside a code span but not to its end, because a skill names an argument both
      // bare (`class`) and with the value it should carry (`polarity: 'must_not'`).
      assert.match(source, new RegExp(`\`${argument}\\b`),
        `the run passes ${argument} to ${tool.name} and the skill never names it — a value that `
          + 'nothing instructs the run to supply is a value the next reader infers');
    }
  }
});

test('the facilitation survives: scope gates, the testing strategy is produced, and an untestable criterion is refused', () => {
  const front = frontMatter(source);
  assert.equal(front.name, SKILL);
  assert.match(front.description, /\/dpm:spec/, 'the skill still triggers on its own command');

  const scope = section(source, 'Scope boundary');
  assert.match(scope, /in scope[\s\S]*out of scope[\s\S]*deferred/i,
    'the three-way boundary is still what the section produces');
  assert.match(scope, /\bgate\b/i, 'and it is still gated before anything is recorded');

  const strategy = section(source, 'Testing strategy');
  assert.notEqual(strategy, '', 'Section 6 is still a section');
  for (const step of ['Step 6a', 'Step 6b', 'Step 6c', 'Step 6d']) {
    assert.notEqual(section(source, step), '', `${step} still exists`);
  }
  assert.match(section(source, 'Step 6a'), /dpm_list_test_approach/,
    'the vocabulary is still confirmed with the user before tags are assigned');
  assert.match(section(source, 'Step 6b'), /dpm_create_criterion_approach/,
    'and every criterion still gets a tag written as a row');

  // The refusal is asserted in the two steps that own one, because a refusal stated once in a
  // guideline and absent from the step is a refusal the run reaches and does not make.
  for (const step of ['Step 6b', 'Step 3a']) {
    assert.match(section(source, step), /\brefuse\b/i,
      `${step} still refuses rather than recording something nobody can check`);
  }
  assert.match(section(source, 'Step 6b'), /vague|cannot be checked/i,
    'and the refusal is about a criterion that cannot be checked, not about some other failure');
  assert.match(section(source, 'Step 3a'), /blocks this step/i,
    'Step 3a still fails closed rather than proceeding');
});

test('must NOT — the skill recovers an entity by reading a generated markdown file', () => {
  const forbidden = [
    { pattern: /docs\//, why: 'a path into the rendered tree — the projection owns those' },
    { pattern: /\bglob\b/i, why: 'a glob, which is how every recovery this conversion removes began' },
    { pattern: /\*\.md\b|\[0-9\]\*/, why: 'a filename pattern' },
    { pattern: /\{nn\}|\{slug\}|\{session_id\}/, why: 'a filename template' },
    { pattern: /front\s*matter/i, why: 'a front-matter read, which is a parse of a generated file' },
    { pattern: /\bRead tool\b|\bGrep tool\b|\bGlob tool\b/, why: 'a file-reading tool' },
    { pattern: /\*\*Status\*\*:|\*\*Blocked by\*\*:|\*\*Source\*\*:/, why: 'a metadata field parsed out of prose' },
    { pattern: /progress file/i, why: 'a progress-file lifecycle — session state is a row' },
  ];

  // **A markdown table in the file is not on that list, and should not be.** The obvious check —
  // a `|---|---|` divider — fires on Step 3a's requirement/restriction grid, which is a table the
  // skill *shows the user* while facilitating. The criterion forbids recovering an entity by
  // reading a generated file; a table the skill draws is neither generated nor read. A check that
  // cannot tell those apart fails a correct file and would be silenced by deleting a facilitation
  // aid, which is the wrong repair.

  // The one path the skill is allowed to name is its own shared conventions, which is not a
  // generated artefact and is not recovered from — it is read, once, for prose.
  const body = source.replace(/`dpm\/shared\/skill-conventions\.md`/g, '');

  for (const { pattern, why } of forbidden) {
    const hit = body.match(pattern);
    assert.ok(!hit, hit && `${SKILL} names ${why} — ${JSON.stringify(context(body, hit.index))}`);
  }

  // The positive half: every discovery the skill does make goes through a list or read tool.
  for (const step of ['Prior decisions', 'Constraint inheritance', 'Retro awareness', 'Library']) {
    assert.match(section(source, step), /dpm_(list|read)_[a-z_]+/,
      `${step} recovers what it needs by calling a tool`);
  }
});

/** The line a match sits on, so a failure names the sentence rather than an offset. */
function context(text, index) {
  const start = text.lastIndexOf('\n', index) + 1;
  const end = text.indexOf('\n', index);
  return text.slice(start, end === -1 ? undefined : end).trim();
}
