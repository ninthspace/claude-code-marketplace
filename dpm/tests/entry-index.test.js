/**
 * Story 4 — the child-row index, and the triple that has to be complete on every table.
 *
 * `document_fts` had one indexed table, so "are the triggers right" was a question about one
 * answer. `entry_fts` has five, and the failure mode changes shape with the number: a table with
 * an insert trigger and no delete trigger indexes correctly on the day it is written and drifts
 * from the first deletion, while every search keeps answering. Nothing about the *search* looks
 * wrong; the index simply holds rows the table does not.
 *
 * **So the first criterion is structural and the second is behavioural, and neither substitutes
 * for the other.** The structural one enumerates the indexed tables out of `sqlite_schema` — from
 * the triggers that reference `entry_fts`, not from a list here — and asserts three of the right
 * kind on each. It catches the sixth table someone indexes with two triggers, which no
 * behavioural sweep written today can see. The behavioural one drives update and delete on every
 * one of the five and compares `MATCH` against a `LIKE` scan, which is what catches a trigger
 * that exists and is wrong.
 *
 * **The tag column is what makes one index serve five tables.** `entity` is indexed, so FTS5's
 * own column syntax does the scoping: `entity:requirement AND helpers` narrows to requirements,
 * and a query with no `entity:` term spans everything.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';

function surface(t) {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);

  return { db, call: Object.fromEntries(tools.map((tool) => [tool.name, tool.handler])) };
}

/**
 * The tables `entry_fts` indexes, read out of the triggers that maintain it.
 *
 * `tbl_name` is the table a trigger fires on, and the `sql LIKE` finds the triggers that touch
 * the index — so a table indexed by a trigger named anything at all is still found, and a table
 * that acquires an index without acquiring all three triggers is *still enumerated here* and then
 * fails the count. Enumerating from a list in this file would have the opposite property: the
 * table nobody remembered to add would be the table nobody remembered to check.
 */
function indexedTables(db) {
  const triggers = db
    .prepare(`SELECT name, tbl_name, sql FROM sqlite_schema
               WHERE type = 'trigger' AND sql LIKE '%entry_fts%' ORDER BY name`)
    .all();

  const byTable = new Map();

  for (const trigger of triggers) {
    if (!byTable.has(trigger.tbl_name)) byTable.set(trigger.tbl_name, []);
    byTable.get(trigger.tbl_name).push(trigger);
  }

  return byTable;
}

/** Which event a trigger fires on, taken from its own SQL. */
const eventOf = (sql) => sql.match(/AFTER\s+(INSERT|UPDATE|DELETE)/i)[1].toUpperCase();

/** The entity/id pairs the index returns for `term`. */
const matched = (db, term) => db
  .prepare('SELECT entity, entity_id FROM entry_fts WHERE entry_fts MATCH ? '
    + 'ORDER BY entity, entity_id')
  .all(term)
  .map((row) => `${row.entity}:${row.entity_id}`);

/**
 * The same set, found without the index.
 *
 * The expression per table is the trigger's own — `observation` concatenates two columns, so a
 * scan of `text` alone would agree with an index that had stopped tracking `synthesis`.
 */
const SCANS = [
  ['requirement', 'requirement', 'text'],
  ['acceptance_criterion', 'acceptance_criterion', 'text'],
  ['story_criterion', 'story_criterion', 'text'],
  ['observation', 'observation', "text || ' ' || coalesce(synthesis, '')"],
  ['finding', 'finding', 'summary'],
];

const scanned = (db, term) => SCANS
  .flatMap(([entity, table, expression]) => db
    .prepare(`SELECT id FROM ${table} WHERE lower(${expression}) LIKE '%' || ? || '%'`)
    .all(term)
    .map((row) => `${entity}:${row.id}`))
  .sort();

/** Every term the sweep below writes, so each comparison covers what the others left behind. */
const TERMS = [
  'quartzite', 'hornbeam', 'sarsaparilla', 'wolframite', 'cinnabar', 'malachite', 'siltstone',
];

function agree(db, where) {
  for (const term of TERMS) {
    assert.deepEqual(matched(db, term), scanned(db, term),
      `${where}: the index and the tables disagree about '${term}'`);
  }
}

/** One row of every indexed type, each carrying a term of its own. */
function corpus(call) {
  const spec = call.dpm_create_spec({ slug: 'search', title: 'Search' });
  const epic = call.dpm_create_epic({ parent_id: spec.id, slug: 'index', title: 'Index' });
  const story = call.dpm_create_story({
    epic_id: epic.id, number: 4, title: 'Index child rows', position: 0,
  });

  const requirement = call.dpm_create_requirement({
    spec_id: spec.id, label: 'FR9', class: 'functional', position: 0,
    text: 'Hand-written text on child rows is indexed, quartzite included.',
  });

  const acceptance_criterion = call.dpm_create_acceptance_criterion({
    requirement_id: requirement.id, position: 0,
    text: 'A term held only on a child row is found, hornbeam for instance.',
  });

  const story_criterion = call.dpm_create_story_criterion({
    story_id: story.id, position: 0,
    text: 'Every indexed table has three triggers, sarsaparilla notwithstanding.',
  });

  const retro = call.dpm_create_retro({ parent_id: epic.id, slug: 'index', title: 'Index retro' });
  const observation = call.dpm_create_observation({
    retro_id: retro.id, position: 0,
    text: 'The triple is the unit, wolframite.',
    synthesis: 'Enumerate the tables from the schema, malachite.',
  });

  // An observation written against a story and not yet gathered into a retro, so `synthesis` is
  // NULL. It is in the corpus rather than in a test of its own because every `agree` sweep then
  // covers it: `a || NULL` is NULL in SQLite, so a concatenation without `coalesce` indexes the
  // *empty string* for this row — the whole observation unfindable, no error, and a search that
  // reports success. That is NFR6's false pass, and it survived four tests before this row existed.
  const ungathered = call.dpm_create_observation({
    story_id: story.id, position: 1,
    text: 'Written against the story and not yet gathered, siltstone.',
  });

  const review = call.dpm_create_review({
    parent_id: spec.id, slug: 'index', title: 'Review of the index',
  });
  const finding = call.dpm_create_finding({
    review_id: review.id, position: 0,
    category_id: 'finding:testability-concerns', severity_id: 'severity:warning',
    summary: 'A missing delete trigger is invisible to search, cinnabar.',
  });

  return {
    spec, epic, story, requirement, acceptance_criterion, story_criterion, retro, observation,
    ungathered, review, finding,
  };
}

// --- Criterion 1: three triggers per indexed table, enumerated from the schema ------------------

test('every table entry_fts indexes has all three triggers, and none has fewer', (t) => {
  const { db } = surface(t);
  const byTable = indexedTables(db);

  // The control. An enumeration that found nothing would satisfy every "for each" below, which is
  // the shape this criterion takes if the `sql LIKE` ever stops matching.
  assert.deepEqual([...byTable.keys()].sort(),
    ['acceptance_criterion', 'finding', 'observation', 'requirement', 'story_criterion'],
    'the indexed tables are not the ones FR9 enumerates');

  for (const [table, triggers] of byTable) {
    assert.deepEqual(triggers.map((trigger) => eventOf(trigger.sql)).sort(),
      ['DELETE', 'INSERT', 'UPDATE'],
      `${table} is indexed by ${triggers.length} trigger(s), not by the full triple`);
  }
});

test('every update trigger is scoped to the columns it indexes, and names all of them', (t) => {
  const { db } = surface(t);

  for (const [table, triggers] of indexedTables(db)) {
    const update = triggers.find((trigger) => eventOf(trigger.sql) === 'UPDATE');

    // `UPDATE OF` and not a bare `AFTER UPDATE`: an edit to a position or a status has no business
    // rewriting an index entry, and `updateByKey` writes only the columns a caller supplied.
    assert.match(update.sql, /AFTER\s+UPDATE\s+OF\s/i,
      `${update.name} fires on any update, so unindexed edits churn the index`);

    // And the columns it names are exactly the ones the insert trigger reads. Written this way
    // rather than against a list here, so a table that gains a prose column and indexes it in
    // `INSERT` while forgetting `UPDATE OF` is named — the drift that leaves an edit unindexed.
    const insert = triggers.find((trigger) => eventOf(trigger.sql) === 'INSERT');
    const read = new Set([...insert.sql.matchAll(/NEW\.(\w+)/g)].map((m) => m[1]));

    read.delete('id');

    const watched = new Set(update.sql.match(/AFTER\s+UPDATE\s+OF\s+([^\n]+?)\s+ON\s/i)[1]
      .split(',')
      .map((column) => column.trim()));

    assert.deepEqual([...watched].sort(), [...read].sort(),
      `${table}: the update trigger watches columns the insert trigger does not read, or misses one`);
  }
});

test('the tag column scopes a search, and an untagged query spans every table', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  // Every entity carries the same word, so the only thing separating the answers is the tag.
  for (const key of ['requirement', 'acceptance_criterion', 'story_criterion', 'finding']) {
    call[`dpm_update_${key}`]({
      id: rows[key].id,
      [key === 'finding' ? 'summary' : 'text']: `A shared word: basalt. (${key})`,
    });
  }

  call.dpm_update_observation({ id: rows.observation.id, text: 'A shared word: basalt.' });

  assert.equal(matched(db, 'basalt').length, 5, 'an untagged query did not span every table');
  assert.deepEqual(matched(db, 'entity:requirement AND basalt'),
    [`requirement:${rows.requirement.id}`]);
  assert.deepEqual(matched(db, 'entity:finding AND basalt'), [`finding:${rows.finding.id}`]);
});

// --- Criterion 2: update and delete leave the index consistent, on every indexed table ----------

test('one row of every indexed type is written, indexed, and found under its own term', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  assert.deepEqual(matched(db, 'quartzite'), [`requirement:${rows.requirement.id}`]);
  assert.deepEqual(matched(db, 'hornbeam'),
    [`acceptance_criterion:${rows.acceptance_criterion.id}`]);
  assert.deepEqual(matched(db, 'sarsaparilla'), [`story_criterion:${rows.story_criterion.id}`]);
  assert.deepEqual(matched(db, 'wolframite'), [`observation:${rows.observation.id}`]);
  assert.deepEqual(matched(db, 'cinnabar'), [`finding:${rows.finding.id}`]);

  // The observation's second indexed column, which is the one a single-column scan would miss.
  assert.deepEqual(matched(db, 'malachite'), [`observation:${rows.observation.id}`]);

  // And the row whose second column is NULL. Without `coalesce` the concatenation is NULL, this
  // observation is indexed as the empty string, and every search for its text returns nothing —
  // reporting success the whole time.
  assert.deepEqual(matched(db, 'siltstone'), [`observation:${rows.ungathered.id}`]);

  agree(db, 'after the corpus is written');
});

test('editing the indexed column of every type replaces its entry rather than adding one', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  call.dpm_update_requirement({ id: rows.requirement.id, text: 'Now mentions gypsum.' });
  call.dpm_update_acceptance_criterion({
    id: rows.acceptance_criterion.id, text: 'Now mentions gypsum.',
  });
  call.dpm_update_story_criterion({ id: rows.story_criterion.id, text: 'Now mentions gypsum.' });
  call.dpm_update_observation({ id: rows.observation.id, text: 'Now mentions gypsum.' });
  call.dpm_update_finding({ id: rows.finding.id, summary: 'Now mentions gypsum.' });

  assert.equal(matched(db, 'gypsum').length, 5);

  // The half a search for the new text cannot see. Each old term is gone from the index because
  // the update trigger deleted before it inserted; an insert-only trigger passes the line above.
  for (const gone of ['quartzite', 'hornbeam', 'sarsaparilla', 'wolframite', 'cinnabar']) {
    assert.deepEqual(matched(db, gone), [], `'${gone}' survives its own row's edit`);
  }

  agree(db, 'after editing every indexed column');
});

test('editing an observation synthesis alone still replaces the entry', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  call.dpm_update_observation({ id: rows.observation.id, synthesis: 'Replaced by feldspar.' });

  // `AFTER UPDATE OF text, synthesis` and not `OF text`: an observation gathered into a retro
  // acquires its synthesis in a second write, which is the common path rather than an edge case.
  assert.deepEqual(matched(db, 'malachite'), []);
  assert.deepEqual(matched(db, 'wolframite'), [`observation:${rows.observation.id}`],
    'the untouched half of the concatenation was dropped');

  agree(db, 'after a synthesis-only edit');
});

test('editing an unindexed column leaves the index untouched', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  const before = db.prepare('SELECT rowid, entity, text, entity_id FROM entry_fts '
    + 'ORDER BY rowid').all();

  call.dpm_update_requirement({ id: rows.requirement.id, position: 4 });
  call.dpm_update_finding({ id: rows.finding.id, status: 'accepted' });

  assert.deepEqual(
    db.prepare('SELECT rowid, entity, text, entity_id FROM entry_fts ORDER BY rowid').all(),
    before,
    'an edit to a position or a status rewrote index entries',
  );
});

test('deleting a row of every indexed type takes it out of the index', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  for (const [table, key] of [
    ['requirement', 'requirement'],
    ['acceptance_criterion', 'acceptance_criterion'],
    ['story_criterion', 'story_criterion'],
    ['observation', 'observation'],
    ['observation', 'ungathered'],
    ['finding', 'finding'],
  ]) {
    db.prepare(`DELETE FROM ${table} WHERE id = ?`).run(rows[key].id);
  }

  assert.equal(db.prepare('SELECT COUNT(*) AS rows FROM entry_fts').get().rows, 0);

  agree(db, 'after deleting one row of every type');
});

test('deleting a spec takes its requirements and their criteria out through two cascades', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  // A spec of its own, because `document.parent_id` carries **no** `ON DELETE` action — deleting
  // a document that other documents hang off is refused rather than orphaning them, so `rows.spec`
  // cannot be the subject here while its epic, review and ADR exist. That refusal is asserted
  // below rather than worked around silently.
  const alone = call.dpm_create_spec({ slug: 'alone', title: 'Alone' });
  const requirement = call.dpm_create_requirement({
    spec_id: alone.id, label: 'FR1', class: 'functional', position: 0,
    text: 'Prose that goes when its spec does, feldspar.',
  });
  const criterion = call.dpm_create_acceptance_criterion({
    requirement_id: requirement.id, position: 0,
    text: 'And so does this, gypsum.',
  });

  assert.deepEqual(matched(db, 'feldspar'), [`requirement:${requirement.id}`]);
  assert.deepEqual(matched(db, 'gypsum'), [`acceptance_criterion:${criterion.id}`]);

  // `acceptance_criterion` cascades from `requirement`, which cascades from `document` — so the
  // criterion's trigger fires on a row removed by a cascade *of a cascade*. Asserted rather than
  // assumed, for the same reason Story 3 asserts the single-level case.
  db.prepare('DELETE FROM document WHERE id = ?').run(alone.id);

  assert.deepEqual(matched(db, 'feldspar'), []);
  assert.deepEqual(matched(db, 'gypsum'), [], 'the second cascade left its index entry behind');

  // The control, and the reason the corpus is still here: the index emptying would satisfy the
  // two lines above for the wrong reason. Everything the first spec wrote is untouched.
  assert.deepEqual(matched(db, 'quartzite'), [`requirement:${rows.requirement.id}`]);
  assert.deepEqual(matched(db, 'cinnabar'), [`finding:${rows.finding.id}`]);

  agree(db, 'after a two-level cascade');
});

test('a document other documents hang off refuses to be deleted rather than orphaning them', (t) => {
  const { db, call } = surface(t);
  const rows = corpus(call);

  // The premise the test above had to work around, stated where it can fail. If this ever starts
  // succeeding, that test stops exercising a two-level cascade and starts exercising a one-level
  // one without saying so.
  assert.throws(() => db.prepare('DELETE FROM document WHERE id = ?').run(rows.spec.id),
    /FOREIGN KEY constraint failed/);
});
