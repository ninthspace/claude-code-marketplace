/**
 * Epic 05-04 Story 2 — a list refuses a scope id that names no row (FR8).
 *
 * `list_task({ story_id: <an epic id> })` returned `{ items: [], returned: 0 }` — the same answer
 * as a story with no tasks. The incident behind the requirement is a run that read that page as a
 * failed write and re-wrote ten tags.
 *
 * **The control is the whole story and it is not decoration.** A scope naming a real parent that
 * holds nothing must go on returning an empty page: that is the state a list exists to report, and
 * a refusal derived from an empty *result* would fire on it while satisfying every assertion about
 * the rejection. So the rejection and the control are driven on the same fixture, one line apart.
 *
 * **Criterion 4 is restated, and the restatement is the point.** It asks that every scope declare
 * the table it points at and that a disagreement with the schema be caught by a test. Measured,
 * thirty-nine of the forty-two scope arguments are plain foreign keys, so declaring them would
 * restate the schema and the pin would compare a copy with the original — the hazard
 * `support/conformance.js` exists to warn about. Chris's call was to derive and declare nothing, so
 * the test below asserts the property the criterion was protecting: every scope either resolves to
 * a parent table or is one of three named non-references, and the named set is exactly those three.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning, handlers } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { scopeParents } from '../src/tools/scope.js';

/**
 * The three scope arguments that are not references, named here so the sweep below is a statement
 * about a closed set rather than a list of whatever it happened to find.
 *
 * `taxonomy.domain` is the one worth being explicit about: a domain naming no taxonomy row and a
 * domain that is genuinely empty are the same state, so the distinction this story draws has
 * nothing to draw there. `session.skill` is free text; `session.updated_before` is a bound.
 */
const NOT_REFERENCES = [
  'list_session.skill',
  'list_session.updated_before',
  'list_taxonomy.domain',
];

/** The arguments a list takes that are scopes rather than paging or flags. */
const PAGING = new Set(['limit', 'offset', 'include_body', 'ready',
  'include_retired', 'include_archived', 'include_superseded']);

const scopeArguments = (tool) => Object.keys(tool.inputSchema.properties)
  .filter((name) => !PAGING.has(name));

/** A spec, an epic, a story with no tasks, and a story with one. */
function surface(t) {
  const db = planning(t);
  const tools = spineTools(db);
  const call = handlers(tools);

  const spec = call.create_spec({ slug: 'refusals', title: 'Refusals that name a way out' });
  const epic = call.create_epic({ parent_id: spec.id, slug: 'scopes', title: 'Scopes' });
  const bare = call.create_story({ epic_id: epic.id, number: 1, title: 'Nothing under it', position: 0 });
  const worked = call.create_story({ epic_id: epic.id, number: 2, title: 'Something under it', position: 1 });

  call.create_task({ story_id: worked.id, number: 1, title: 'A task', position: 0 });

  return { db, tools, call, spec, epic, bare, worked };
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

// --- Criterion 1 (must NOT) and criterion 2 (control), on one fixture -----------------------------

test('must NOT — a list given a scope id that matches no row returns an empty page [integration]', (t) => {
  const { call, epic } = surface(t);

  // The incident's own shape: an epic's id passed where a story's belongs.
  const error = refused(() => call.list_task({ story_id: epic.id }),
    'an epic id was accepted as a story scope and answered with an empty page');

  assert.equal(error.rpc.code, -32602, 'a bad call was reported as a broken server');

  // An id that is nothing at all is refused too — the mistyped case, which story 3 will improve by
  // offering a unique prefix rather than by changing this verdict.
  const missing = refused(() => call.list_task({ story_id: 'not-an-id' }));

  assert.match(missing.message, /matches no story/);
  assert.match(missing.message, /no other row in this project/);
});

test('control — a scope naming a real row that holds nothing still returns a page [integration]', (t) => {
  const { call, bare, worked, epic } = surface(t);

  // **The state the whole story exists to distinguish from the one above.** A refusal computed
  // from an empty result would fire here and pass every assertion in the rejection test.
  const empty = call.list_task({ story_id: bare.id });

  assert.deepEqual(empty.items, []);
  assert.equal(empty.returned, 0);
  assert.equal(empty.more, false);

  // And the scope that does hold something is unaffected, so the probe is not refusing everything.
  assert.equal(call.list_task({ story_id: worked.id }).items.length, 1);

  // An unscoped call is still legitimate — the bound is what makes it safe, not the scope being
  // compulsory, and a probe that required a scope would have changed that.
  assert.equal(call.list_task({}).items.length, 1);

  // A scope that is not a reference is never probed, which is why `domain` is exempt: a domain
  // naming no row and a domain that is empty are one state.
  assert.ok(call.list_taxonomy({ domain: 'observation' }).items.length > 0);
  assert.deepEqual(call.list_taxonomy({ domain: 'no-such-domain' }).items, []);

  // The document scopes work the same way — a real epic with no retros is an answer, not a fault.
  assert.deepEqual(call.list_retro({ parent_id: epic.id }).items, []);
});

// --- Criterion 3: the refusal names the other table and the list that takes the id ----------------

test('the refusal names the table the id belongs to and the lists that take it [integration]', (t) => {
  const { call, spec, epic, worked } = surface(t);

  const wrongWay = refused(() => call.list_task({ story_id: epic.id }));

  // The table, by way of what the row actually is — a document's kind, which is more use than
  // the word `document`.
  assert.match(wrongWay.message, /it is a epic in document|it is an epic in document/);

  // **And the lists that take it, narrowed by that kind.** Naming all twenty-one scopes that point
  // at `document` would be noise; the four that accept an epic are the answer.
  assert.match(wrongWay.message, /list_story \(epic_id\)/);
  assert.match(wrongWay.message, /list_retro \(parent_id\)/);
  assert.doesNotMatch(wrongWay.message, /list_epic \(parent_id\)/,
    'a list that takes a spec, not an epic, was offered');

  // A non-document id names its table plainly, and the one or two lists that scope by it.
  const criterion = call.create_story_criterion({
    story_id: worked.id, text: 'The refusal names the table', position: 0,
  });

  const wrongTable = refused(() => call.list_coverage({ requirement_id: criterion.id }));

  assert.match(wrongTable.message, /it is a story_criterion/);
  assert.match(wrongTable.message, /list_coverage \(story_criterion_id\)/,
    'the refusal did not name the argument that would have taken the id');

  // A spec passed where an epic's parent belongs is the same mistake one level up, and the
  // narrowing has to hold there too.
  const upward = refused(() => call.list_story({ epic_id: spec.id }));

  assert.match(upward.message, /spec/);
  assert.match(upward.message, /list_epic \(parent_id\)/);
});

// --- Criterion 4, restated: every scope resolves, or is a named non-reference ---------------------

test('every list scope resolves to a parent table, or is one of three named exceptions [unit]', (t) => {
  const { db, tools } = surface(t);
  const lists = tools.filter((tool) => tool.name.startsWith('list_'));

  assert.ok(lists.length > 30, `only ${lists.length} list tools were swept`);

  const unresolved = [];
  let resolved = 0;

  for (const tool of lists) {
    const parents = scopeParents(db, tool.table, scopeArguments(tool));

    for (const argument of scopeArguments(tool)) {
      if (parents[argument]) resolved += 1;
      else unresolved.push(`${tool.name}.${argument}`);
    }
  }

  // **The exceptions are named rather than counted.** A scope added with a typo, or one whose
  // foreign key a migration drops, appears here — silently never being probed is the failure this
  // replaces the epic's declaration-and-pin with.
  assert.deepEqual(unresolved.sort(), NOT_REFERENCES);

  // And the sweep found something to resolve, so an empty report is a clean one rather than a
  // reading that never matched.
  assert.ok(resolved > 30, `only ${resolved} scopes resolved to a parent table`);
});

test('the sweep reports a scope that names no column at all [unit]', (t) => {
  const { db } = surface(t);

  // The control for the reading above: `scopeParents` is asked about an argument that is not a
  // column of the table, and answers with nothing rather than inventing a parent for it. Without
  // this, a sweep whose lookup silently matched everything would report a clean registry.
  assert.deepEqual(scopeParents(db, 'task', ['story_id', 'storyy_id']), {
    story_id: { parent: 'story', to: 'id', pinned: [] },
  });

  // And a real composite reference resolves to the column it points at rather than to `id` by
  // assumption — `library_scope.document_id` points at `library_document`.
  assert.deepEqual(scopeParents(db, 'library_scope', ['document_id']), {
    document_id: { parent: 'library_document', to: 'document_id', pinned: [] },
  });

  // **The pinned half is what makes a document scope discriminate.** `story.epic_id` is one column
  // of `(epic_id, epic_kind) → document(id, kind)`, and the kind is fixed by the schema — without
  // it the probe finds a spec, which is a document, and waves through the mistake FR8 is about.
  assert.deepEqual(scopeParents(db, 'story', ['epic_id']), {
    epic_id: { parent: 'document', to: 'id', pinned: [{ to: 'kind', value: 'epic' }] },
  });
});
