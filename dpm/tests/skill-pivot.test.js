/**
 * Epic 47-09 Story 1 — the converted `pivot`, and the four claims made about it.
 *
 * - "A pivot run amends artefacts through update tools, and cascades to downstream documents by
 *   traversing foreign keys rather than by discovering chains from back-reference prose" [feature]
 * - "Coverage verification is cleared by FR21's triggers when a criterion's text changes, so the
 *   skill no longer edits `| ✓ |` to `| |` and no longer needs to derive a matrix path from an
 *   epic path" [integration]
 * - "The facilitation survives: every downstream change is still gated individually rather than
 *   applied as a batch, and a status change still edits the token while leaving the human note tail
 *   intact" [feature]
 * - "must NOT — the skill recovers an entity by reading a generated markdown file rather than by
 *   calling a read tool" [unit]
 *
 * **The first criterion is about reach, so the fixture is built to punish the wrong reach.** A
 * second spec carries an epic and an ADR of its own, and the assertion is not that the run found
 * the right documents but that it found *only* them — with the unscoped list run alongside as the
 * control, so "the decoys were not reached" is a fact about the scope rather than about a project
 * that happened to hold one spec.
 *
 * **The second is a claim about a trigger, and a trigger that fired is indistinguishable from one
 * that fires on every write.** So the same run is driven twice: once amending a criterion's text,
 * once passing the text back unchanged. Only the first may clear the mark. Without the second half
 * the test passes against a decay that eats a verification on any update at all, which is the
 * false pass FR21's `WHEN OLD.text <> NEW.text` guard exists to prevent.
 *
 * **The third is driven, not read off the file.** Gating is only observable as a difference between
 * what was approved and what was not, so the run takes a predicate over the proposals and the test
 * approves one of two — a batch would land both.
 *
 * **The binding to the file is the three directions every conversion uses.** See
 * `support/skills.js`.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import {
  skillSource, toolNames, prose, instructions, recorder, recoveries, sweep, bindings, reachable,
  seedStartup, driveStartup, SQL, CONSTRUCTIONS,
} from './support/skills.js';

const SKILL = 'pivot';
const source = skillSource(SKILL);

/** Above what any of these fixtures holds. */
const BOUND = 200;

/** The recoveries this file in particular would reach for, on top of the shared sweep. */
const PARSES = [
  { pattern: /`{3}markdown/, why: 'a document template, which is the projection’s to own' },
  {
    pattern: /\*\*Source spec\*\*|\*\*Brief\*\*:/,
    why: 'a back-reference field, which is what `parent_id` replaced',
  },
  {
    pattern: /slug match|match(?:ing)? by slug/i,
    why: 'slug matching, which is a guess where an edge is already stored',
  },
  { pattern: /partial chain/i, why: 'a chain assembled where none could be read' },
  { pattern: /\|\s*✓\s*\|/, why: 'a verification cell edited in a rendered table' },
];

const NOTE = 'held open while the store lands; do not break down yet';
const CRITERION = 'The schema applies cleanly to an empty database.';
const REQUIREMENT = 'The system shall persist planning state.';

const AMENDED = {
  title: 'Persistence, scoped to one project',
  body: 'One database per project, and no second copy of the graph.',
  requirement: 'The system shall persist planning state in one database per project.',
  criterion: 'The schema applies cleanly to an empty database and to a populated one.',
};

const VERIFIED = '2026-08-01T00:00:00.000Z';
const REVIEW_BODY = 'The store is untested at the boundary.';

/**
 * What a project holds when someone runs `pivot`: a spec with a section, a requirement and its
 * criterion; an ADR under it; an epic with two stories, a verified coverage row, and the three
 * documents that hang off an epic — plus a **second** spec with an epic and an ADR of its own.
 *
 * The decoys are the point. Every downstream call the run makes has an unscoped form that returns
 * them too, and a cascade that filtered parents in the run rather than in the query would reach
 * both specs' documents and look identical from the inside.
 */
function workspace(tools) {
  const seed = handlers(tools);

  const spec = seed.create_spec({ slug: 'persistence', title: 'Persistence', status_note: NOTE });
  const specSection = seed.create_document_section({
    document_id: spec.id, heading: 'Scope', body: 'One database per project.', position: 0,
  });
  const requirement = seed.create_requirement({
    spec_id: spec.id, label: 'FR1', text: REQUIREMENT,
    class: 'functional', moscow: 'must', position: 0,
  });
  seed.create_acceptance_criterion({
    requirement_id: requirement.id, text: 'A restart loses nothing.', position: 0,
  });

  const adr = seed.create_adr({
    parent_id: spec.id, slug: 'store', title: 'One database per project',
    decision: 'Planning state lives in one SQLite file.',
  });

  const epic = seed.create_epic({ parent_id: spec.id, slug: 'spine', title: 'Spine' });
  const stories = ['Substrate', 'Tools'].map((title, position) => seed.create_story({
    epic_id: epic.id, number: position + 1, title, position,
  }));
  seed.create_task({
    story_id: stories[0].id, number: 1, title: 'Write the schema', description: 'The tables.',
    position: 0,
  });
  const criterion = seed.create_story_criterion({
    story_id: stories[0].id, text: CRITERION, position: 0,
  });

  // Verified at creation, because `verified_at` and `binding_hash` are set together and the hash is
  // computed from the bound texts — which is what makes the decay observable at all.
  const coverage = seed.create_coverage({
    requirement_id: requirement.id, story_criterion_id: criterion.id, position: 0,
    spec_fragment: 'shall persist planning state', verified_at: VERIFIED,
  });

  const matrix = seed.create_coverage_matrix({
    parent_id: epic.id, slug: 'spine', title: 'Coverage: spine',
  });
  const review = seed.create_review({ parent_id: epic.id, slug: 'spine', title: 'Review: spine' });
  const reviewSection = seed.create_document_section({
    document_id: review.id, heading: 'Findings', body: REVIEW_BODY, position: 0,
  });
  const epicRetro = seed.create_retro({ parent_id: epic.id, slug: 'spine', title: 'Retro: spine' });

  // The decoys, under a parent the run never amends.
  const otherSpec = seed.create_spec({ slug: 'search', title: 'Search' });
  const otherEpic = seed.create_epic({ parent_id: otherSpec.id, slug: 'index', title: 'Index' });
  const otherAdr = seed.create_adr({
    parent_id: otherSpec.id, slug: 'engine', title: 'FTS5', decision: 'Search runs on FTS5.',
  });
  const otherStory = seed.create_story({
    epic_id: otherEpic.id, number: 1, title: 'Indexer', position: 0,
  });
  seed.create_story_criterion({
    story_id: otherStory.id, text: 'The index rebuilds from the rows.', position: 0,
  });

  const startup = seedStartup(seed, {
    scope: 'pivot',
    skill: 'dpm:pivot',
    phase: 'Phase 3',
    live: ['A downstream document went stale because nothing said it depended on the spec.'],
  });

  // `startup` is spread last and carries a `retro` and an `other` of its own, so this fixture's own
  // keys are named apart from them. A collision here reads as a cascade reaching the wrong document.
  return {
    spec, specSection, requirement, adr, epic, stories, criterion, coverage, matrix, review,
    reviewSection, epicRetro, otherSpec, otherEpic, otherAdr, ...startup,
  };
}

/**
 * The run the SKILL.md prescribes: startup, selection, amendment, cascade, task report.
 *
 * `criterionText` and `requirementText` are the two texts a coverage row's verification hangs off —
 * passing either back unchanged drives the byte-identical control through the same function rather
 * than through a second one. **Both are parameters and not just the criterion**, because the
 * amendment changes the requirement as well: a control that held only the criterion still decayed
 * the mark from the other end, and passed for the wrong reason. `approve` decides each proposal on
 * its own, which is the only way the difference between gating and batching shows up in the rows.
 */
function run(call, fixture, {
  attempt = 1, criterionText = AMENDED.criterion, requirementText = AMENDED.requirement,
  approve = () => true,
} = {}) {
  driveStartup(call, fixture, { scope: 'pivot', skill: 'dpm:pivot', attempt, roster: false });

  // Phase 1: the amendable kinds, each bounded above what the project holds. The chosen row carries
  // its own `kind`, which is what the cascade traverses from.
  const offered = [
    ...call.list_problem_brief({ limit: BOUND }).items,
    ...call.list_product_brief({ limit: BOUND }).items,
    ...call.list_spec({ limit: BOUND }).items,
    ...call.list_epic({ limit: BOUND }).items,
    ...call.list_adr({ limit: BOUND }).items,
    ...call.list_discussion({ limit: BOUND }).items,
    ...call.list_quick({ limit: BOUND }).items,
  ];
  const chosen = offered.find((row) => row.id === fixture.spec.id);

  // Phase 2: read the prose before amending it, then amend through the update tool of each thing.
  const sections = call.list_document_section({ document_id: chosen.id }).items
    .map((row) => call.read_document_section({ id: row.id, include_body: true }));
  const requirements = call.list_requirement({ spec_id: chosen.id, include_body: true }).items;

  call.update_spec({ id: chosen.id, title: AMENDED.title, status: 'complete' });
  call.update_document_section({ id: sections[0].id, body: AMENDED.body });
  call.update_requirement({ id: requirements[0].id, text: requirementText });

  // Phase 3: where the cascade reaches, read from the edge table rather than carried in prose.
  const reached = [];
  const walk = (document) => {
    for (const child of call.read_document_kind({ kind: document.kind }).children) {
      for (const row of call[`list_${child}`]({ parent_id: document.id, limit: BOUND }).items) {
        reached.push(row);
        walk(row);
      }
    }
  };
  walk(chosen);

  // A spec reaches further than its own row: the criteria written against an amended requirement.
  const bound = requirements.map((requirement) => ({
    requirement,
    criteria: call.list_coverage({ requirement_id: requirement.id, limit: BOUND }).items
      .map((row) => call.read_story_criterion({ id: row.story_criterion_id, include_body: true })),
  }));

  // And an epic reaches its stories and their criteria.
  const stories = reached.filter((row) => row.kind === 'epic')
    .flatMap((epic) => call.list_story({ epic_id: epic.id, limit: BOUND }).items
      .map((story) => ({
        story,
        criteria: call.list_story_criterion({
          story_id: story.id, include_body: true, limit: BOUND,
        }).items,
      })));

  // The walk, gated one change at a time.
  const proposals = [
    () => call.update_story_criterion({ id: fixture.criterion.id, text: criterionText }),
    () => call.update_document_section({
      id: fixture.reviewSection.id, body: 'The store is tested at the boundary.',
    }),
  ];
  const applied = proposals.filter((_, index) => approve(index)).map((apply) => apply());

  call.update_session({
    id: `session-run-${attempt}`, state: JSON.stringify({ applied: applied.length }),
  });

  // Phase 4: the tasks now in doubt, reported and never changed.
  const tasks = stories.flatMap((entry) => call.list_task({
    story_id: entry.story.id, limit: BOUND,
  }).items);

  return { offered, chosen, sections, reached, bound, stories, applied, tasks };
}

// --- Criterion 1: amendment through update tools, cascade by foreign key -------------------------

test('a pivot run amends through update tools and reaches exactly what hangs off the artefact', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call, used, passed } = recorder(tools);

  const fixture = workspace(tools);
  const result = run(call, fixture);
  const raw = handlers(tools);

  // The amendment landed in the rows, through the tool of each thing amended.
  assert.equal(raw.read_spec({ id: fixture.spec.id }).title, AMENDED.title);
  assert.equal(
    raw.read_document_section({ id: fixture.specSection.id, include_body: true }).body,
    AMENDED.body,
  );
  assert.equal(
    raw.read_requirement({ id: fixture.requirement.id, include_body: true }).text,
    AMENDED.requirement,
  );

  // **The edge list is the table's, in both directions.** A root kind's `parents` is empty and a
  // leaf's `children` is empty, and both are real answers rather than absences.
  const kind = raw.read_document_kind({ kind: 'spec' });
  assert.deepEqual(kind.parents, []);
  assert.deepEqual(kind.children, ['adr', 'epic', 'retro', 'review']);
  assert.deepEqual(raw.read_document_kind({ kind: 'epic' }).children,
    ['coverage_matrix', 'retro', 'review']);
  assert.deepEqual(raw.read_document_kind({ kind: 'adr' }).children, []);
  assert.deepEqual(raw.read_document_kind({ kind: 'epic' }).parents, ['spec']);

  // The traversal visited exactly the documents hanging off the amended spec, transitively.
  assert.deepEqual(
    new Set(result.reached.map((row) => row.id)),
    new Set([fixture.adr.id, fixture.epic.id, fixture.matrix.id, fixture.epicRetro.id,
      fixture.review.id]),
  );
  assert.deepEqual([...new Set(result.reached.map((row) => row.kind))].sort(),
    ['adr', 'coverage_matrix', 'epic', 'retro', 'review']);

  // **The control, and the reason the line above means anything.** Both decoys are returned by the
  // unscoped form of a call the cascade makes, so a run that listed and then matched parents itself
  // would have reached them. Without this, "the decoys were not reached" is a statement about a
  // project that holds one spec.
  assert.equal(raw.list_epic({ limit: BOUND }).items.length, 2);
  assert.equal(raw.list_adr({ limit: BOUND }).items.length, 2);
  assert.ok(!result.reached.some((row) => row.id === fixture.otherEpic.id
    || row.id === fixture.otherAdr.id), 'the cascade reached a document under a different spec');

  // The requirement-to-criterion join, which is the reach a cascade comparing prose never had.
  assert.deepEqual(result.bound[0].criteria.map((row) => row.id), [fixture.criterion.id]);

  // Nothing was recovered by name: the second spec shares no slug with the first, and the run holds
  // the chosen row's own `kind` rather than inferring one.
  assert.equal(result.chosen.kind, 'spec');

  // **The substrate half is asserted here because no run can speak for it.** A `read_document_kind`
  // that dropped `children`, or that stopped declaring the table it reads, leaves the traversal
  // above unable to move and every prose assertion intact.
  const descriptor = tools.find((tool) => tool.name === 'read_document_kind');
  assert.ok(descriptor.reads.includes('document_kind_parent'),
    'read_document_kind no longer declares the edge table it reads');
  assert.match(descriptor.description, /`children` names the kinds that may hang off it/);
  assert.match(descriptor.description, /`parents` names the kinds this one may hang off/);

  // And the file says the chain is read rather than assembled — the claim the rows cannot make,
  // because a run traverses whatever the test told it to.
  assert.match(source, /The chain is stored, not rediscovered/);
  assert.match(source, /pinned by a composite foreign key/);
  assert.match(source, /nothing pairs one artefact with another by matching their names/);

  const cascade = prose(source, 'Where the cascade reaches');
  assert.match(cascade, /`children` names the kinds that may hang off this one/);
  assert.match(cascade, /Scope every one of those calls by `parent_id`/);
  assert.match(cascade, /a kind nothing hangs off comes back with `children` empty/);

  assert.deepEqual(bindings(source, tools, { used, passed }), []);
});

// --- Criterion 2: the verification mark decays on its own ----------------------------------------

test('an amended criterion loses its verification, and a byte-identical amendment does not', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call, used } = recorder(tools);

  const fixture = workspace(tools);
  const raw = handlers(tools);

  const before = raw.read_coverage({ id: fixture.coverage.id });
  assert.equal(before.verified_at, VERIFIED);
  assert.notEqual(before.binding_hash, null);

  run(call, fixture, { criterionText: AMENDED.criterion });

  const after = raw.read_coverage({ id: fixture.coverage.id });
  assert.equal(after.verified_at, null, 'a changed criterion still reads as verified');
  assert.equal(after.binding_hash, null, 'the binding hash outlived the text it was taken over');

  // **And the run did not do it.** The whole of criterion 2 is that clearing the mark is the write's
  // consequence rather than a step, so a run that touched `coverage` at all would be re-asserting an
  // answer the database already gave.
  assert.ok(!used.has('update_coverage'), 'the run cleared the verification mark itself');

  // **The control, in the same run against a fresh project.** Passing both bound texts back
  // unchanged must leave the mark standing — without this the test passes against a decay that
  // fires on every write, which clears verifications nobody invalidated. Both, because either end
  // decays the row on its own: a control that held the criterion and went on amending the
  // requirement cleared the mark anyway and would have read as the trigger being correct.
  const control = openPlanningDatabase(t);
  const controlTools = spineTools(control);
  const recorded = recorder(controlTools);
  const unchanged = workspace(controlTools);

  run(recorded.call, unchanged, { criterionText: CRITERION, requirementText: REQUIREMENT });

  // And it is not vacuous: the control drove both writes, it just wrote the same bytes back.
  assert.ok(recorded.used.has('update_story_criterion'));
  assert.ok(recorded.used.has('update_requirement'));

  const stood = handlers(controlTools).read_coverage({ id: unchanged.coverage.id });
  assert.equal(stood.verified_at, VERIFIED, 'a byte-identical amendment cleared a verification');
  assert.notEqual(stood.binding_hash, null);

  // The file states the rule, and states it as a prohibition on both directions.
  const verification = prose(source, 'Verification looks after itself');
  assert.match(verification, /Never write `verified_at`, and never clear one/);
  assert.match(verification, /as a consequence of that write/);
  assert.match(verification, /an edit that changes no bytes leaves the mark standing/);
  assert.match(verification, /nothing to derive, nothing to locate, and no cell to edit/);
  assert.match(verification, /asserting a verification nobody performed/);

  // The tool that would let a run do it by hand is never named — the invalidation procedure is gone
  // rather than reworded.
  assert.ok(!toolNames(reachable(source)).includes('update_coverage'));
});

// --- Criterion 3: the facilitation survives -------------------------------------------------------

test('a status change leaves the note, and each downstream change is gated on its own', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const { call, passed } = recorder(tools);

  const fixture = workspace(tools);
  const raw = handlers(tools);

  run(call, fixture, { approve: (index) => index === 0 });

  // The token moved and the note the author wrote is still where they put it.
  const stored = raw.read_spec({ id: fixture.spec.id });
  assert.equal(stored.status, 'complete');
  assert.equal(stored.status_note, NOTE, 'a status change overwrote the human note');
  assert.ok(!passed.get('update_spec').has('status_note'),
    'the run carried a note it was not asked to change');

  // One of two proposals approved: the approved one landed, the refused one did not. A batch behind
  // a single gate lands both, and looks the same in the file.
  assert.equal(
    raw.read_story_criterion({ id: fixture.criterion.id, include_body: true }).text,
    AMENDED.criterion,
  );
  assert.equal(
    raw.read_document_section({ id: fixture.reviewSection.id, include_body: true }).body,
    REVIEW_BODY,
    'a refused change was applied anyway',
  );

  // And what Phase 2 applied before the gate is still applied — an abandoned cascade keeps its work.
  assert.equal(raw.read_spec({ id: fixture.spec.id }).title, AMENDED.title);

  // **The gating rule is asserted on the numbered step, not on the section.** The paragraph around
  // it can go on forbidding a batch while the step a run follows stops saying so.
  const walk = instructions(source, 'The walk');
  assert.match(walk, /Gate each change on its own/);
  assert.match(walk, /one decision per change/);
  assert.match(walk, /never carry an approval forward/);
  assert.match(walk, /⚠️ editing it changes the record of/);

  const amend = prose(source, 'Phase 2: Amend');
  assert.match(amend, /A status change carries `status` and nothing else/);
  assert.match(amend, /`status_note` is the sentence whoever set it wrote/);
  assert.match(amend, /Passing `status` alone leaves that note exactly where its author put it/);
  assert.match(amend, /Name no status value in this file/);

  // **And it names none.** The set is enforced in the database, so a project that widens it reaches
  // this skill with no edit — a file listing the values would be a second copy going quietly short.
  assert.doesNotMatch(source, /`(pending|complete|in progress|in_progress|blocked)`/);

  // The completion branch still asks before it walks, and counts completion from the rows.
  const gate = prose(source, 'Before the walk');
  assert.match(gate, /counted from `mcp__plugin_dpm_dpm__list_story`'s `status`, not from anything written in a document/);
  assert.match(gate, /Pivot forward/);
  assert.match(gate, /Raise a new spec/);
  assert.match(gate, /The second and third skip the walk entirely/);

  // Tasks are reported and never touched.
  const affected = prose(source, 'Phase 4: Tasks affected');
  assert.match(affected, /\*\*Change nothing\.\*\*/);
  assert.ok(!toolNames(reachable(source)).includes('retire_task'));
});

// --- Criterion 4 (must NOT): no recovery by reading what was written -------------------------------

test('the skill recovers nothing by reading a generated file', (t) => {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);

  assert.deepEqual(recoveries(source, PARSES), []);
  assert.deepEqual(sweep(source, SQL), []);
  assert.deepEqual(sweep(source, CONSTRUCTIONS), []);

  const known = new Set(tools.map((tool) => tool.name));
  const named = toolNames(reachable(source));

  for (const required of ['list_problem_brief', 'list_product_brief', 'list_spec', 'list_epic',
    'list_adr', 'list_discussion', 'list_quick', 'list_document_section', 'read_document_section',
    'list_requirement', 'read_document_kind', 'list_coverage_matrix', 'list_retro', 'list_review',
    'list_coverage', 'read_story_criterion', 'list_story', 'list_story_criterion', 'list_task',
    'update_spec', 'update_epic', 'update_adr', 'update_document_section', 'update_requirement',
    'update_acceptance_criterion', 'update_story', 'update_story_criterion', 'update_task']) {
    assert.ok(named.includes(required), `the skill never names ${required}`);
    assert.ok(known.has(required), `${required} is not a tool`);
  }

  // The control: the same reading applied to the procedure this conversion deletes finds every part
  // of it. Without it a pattern that stopped matching reports a clean file indistinguishably.
  const regressed = `${source}\n\nGlob docs/epics/[0-9]*-epic-*.md, read **Source spec**: and `
    + '**Status**: out of each file’s front matter, fall back to slug matching, present partial '
    + 'chains for what does not resolve, then clear the `| ✓ |` cells in the companion matrix at '
    + 'docs/epics/15-coverage-spine.md.';

  assert.ok(recoveries(regressed, PARSES).length >= 8,
    'the sweep passed a file that globs, parses two fields, matches slugs, builds partial chains '
    + 'and edits a verification cell in a companion file');
});
