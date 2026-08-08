/**
 * Story 6 — the invariants SQLite cannot hold, and the tool that reports them.
 *
 * Every test here is the same shape: a database the tool passes, one deliberate violation, and
 * the tool failing *on that entry* while naming rows. Both halves matter and the story's
 * must-NOT says why — "reports a violation it cannot locate, **or** passes a database holding
 * one". A check that reported everything would satisfy the second half and be worthless, so
 * every injection is preceded by the same database passing clean.
 *
 * The parity test holds its **own** enumeration of the thirteen, transcribed from the Data
 * Model rather than read from `REGISTER`. A test comparing the register against itself asserts
 * that a list equals itself; the point of the criterion is that a check and a documented
 * invariant can disagree, and this is what notices.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase as planning } from './support/planning-database.js';
import { checkIntegrity, orphans } from '../src/integrity/check.js';
import { REGISTER } from '../src/integrity/register.js';
import { create } from './fixtures/index.js';
import { childDocument, rootDocument } from './fixtures/planning.js';
import { ulid } from '../src/id/ulid.js';

/**
 * The thirteen, by number, transcribed from the Data Model's register table.
 *
 * Kept as short phrases rather than the register's full sentences: what the parity criterion
 * is about is that thirteen numbered invariants exist and each has a check, and copying the
 * prose verbatim would make this fail on a reworded sentence, which is not a parity failure.
 */
const REGISTER_ENTRIES = new Map([
  [1, 'gates_work cycle'],
  [2, 'superseded ADR implies a supersedes edge'],
  [3, 'coverage requirement and criterion share a spec'],
  [4, 'coverage_story story is in the coverage row\'s epic'],
  [5, 'number_sequence.next_value exceeds every allocation'],
  [6, 'dependency ends are kinds that edge admits'],
  [7, 'review scope_story is inside the epic reviewed'],
  [8, 'accepted ADR has exactly one chosen option'],
  [9, 'spec_fragment is a substring of the requirement text'],
  [10, 'no row references an already-retired vocabulary row'],
  [11, 'session.superseded_by forms no cycle'],
  [12, 'document_milestone document and milestone share a spec'],
  [13, '{{ref:}} markers resolve to live documents'],
]);

/** A spec with epics and stories — the shape most of these invariants span. */
function corpus(db) {
  const spec = rootDocument(db, 'spec', { number: 47, slug: 'substrate' });
  const epic = childDocument(db, 'epic', spec, { sequence: 1, slug: 'epic-1', title: 'Epic 1' });
  const story = create(db, 'story', { epic_id: epic.id, number: 1 });

  return { spec, epic, story };
}

/** The violations the tool found for one register entry, or `undefined` when it found none. */
const forEntry = (report, entry) => report.violations.find((violation) => violation.entry === entry);

/**
 * Assert that `inject` turns a clean database into one failing exactly `entry`, with rows.
 *
 * Bundling the three assertions is what keeps the thirteen readable, and each is load-bearing:
 * the clean pass first, so the injection is what changed; the entry, so a check that fires on
 * everything cannot stand in for the right one; and the rows, because a located violation is
 * the difference between a report and an alarm.
 */
function reportsOnly(t, entry, inject) {
  const db = planning(t);
  const context = corpus(db);

  assert.equal(
    checkIntegrity(db).ok,
    true,
    `entry ${entry}: the database passes before the violation is injected`,
  );

  inject(db, context);

  const report = checkIntegrity(db);
  const found = forEntry(report, entry);

  assert.equal(report.ok, false, `entry ${entry}: the tool does not pass a database holding it`);
  assert.ok(found, `entry ${entry}: reported under its own number, not merely reported`);
  assert.ok(found.rows.length > 0, `entry ${entry}: names the rows — a located violation, not an alarm`);
  assert.deepEqual(
    report.violations.map((violation) => violation.entry),
    [entry],
    `entry ${entry}: and nothing else fires, so the injection is what this check saw`,
  );

  return { db, report, rows: found.rows };
}

test('the register and the checks name each other, in both directions', () => {
  assert.deepEqual(
    REGISTER.map((entry) => entry.entry),
    [...REGISTER_ENTRIES.keys()],
    'an entry with no check, or a check with no entry, is the same failure read from either end',
  );
  assert.equal(REGISTER.length, 13, 'and thirteen is the count the Data Model derives');

  const uncallable = REGISTER.filter((entry) => typeof entry.check !== 'function');
  assert.deepEqual(uncallable, [], 'an entry whose check is not callable is an entry with no check');

  // Numbers are the join key between a table in a document and a function in a file, so a gap
  // or a repeat breaks the parity claim even when the counts agree.
  assert.equal(new Set(REGISTER.map((entry) => entry.entry)).size, 13);
});

test('a freshly seeded database passes, and the pass is a real sweep', (t) => {
  const db = planning(t);
  corpus(db);

  const report = checkIntegrity(db);

  assert.equal(report.ok, true);
  assert.deepEqual(report.violations, []);
  assert.deepEqual(report.orphans, []);
  // A register that failed to load would report `ok` with nothing checked, which is the shape
  // NFR6 exists to refuse: a pass and a no-op are otherwise the same observation.
  assert.equal(report.checked, REGISTER.length + 1, 'thirteen checks and the orphan sweep');
});

test('entry 1 — a cycle among gates_work edges', (t) => {
  const { rows } = reportsOnly(t, 1, (db, { spec }) => {
    const second = rootDocument(db, 'spec', { number: 48, slug: 'successor' });
    const a = childDocument(db, 'epic', spec, { sequence: 2, slug: 'a', title: 'A' });
    const b = childDocument(db, 'epic', second, { sequence: 1, slug: 'b', title: 'B' });

    create(db, 'dependency', { source_document_id: a.id, target_document_id: b.id });
    create(db, 'dependency', { source_document_id: b.id, target_document_id: a.id });
  });

  assert.equal(rows.length, 2, 'both ends of the cycle are named, since either is a place to break it');
});

test('entry 2 — a superseded ADR with no supersedes edge out of it', (t) => {
  reportsOnly(t, 2, (db, { spec }) => {
    const adr = childDocument(db, 'adr', spec, { sequence: 1, slug: 'adr-1', title: 'ADR 1' });
    create(db, 'adr', { document_id: adr.id, decision_status: 'superseded' });
  });
});

test('entry 3 — coverage joining one spec\'s requirement to another spec\'s criterion', (t) => {
  const { rows } = reportsOnly(t, 3, (db, { spec, story }) => {
    const other = rootDocument(db, 'spec', { number: 48, slug: 'other' });
    const requirement = create(db, 'requirement', { spec_id: other.id, text: 'A fragment lives here.' });
    const criterion = create(db, 'story_criterion', { story_id: story.id });

    create(db, 'coverage', {
      requirement_id: requirement.id, story_criterion_id: criterion.id,
      spec_fragment: 'A fragment lives here.',
    });

    assert.notEqual(other.id, spec.id);
  });

  assert.notEqual(
    rows[0].requirement_spec,
    rows[0].criterion_spec,
    'the report names both specs — the entry that renders plausibly is the one worth locating',
  );
});

test('entry 4 — a coverage_story naming a story from another epic', (t) => {
  reportsOnly(t, 4, (db, { spec, story }) => {
    const requirement = create(db, 'requirement', { spec_id: spec.id, text: 'Fragment.' });
    const criterion = create(db, 'story_criterion', { story_id: story.id });
    const coverage = create(db, 'coverage', {
      requirement_id: requirement.id, story_criterion_id: criterion.id, spec_fragment: 'Fragment.',
    });

    const elsewhere = childDocument(db, 'epic', spec, { sequence: 2, slug: 'epic-2', title: 'Epic 2' });
    const stray = create(db, 'story', { epic_id: elsewhere.id, number: 1 });

    create(db, 'coverage_story', { coverage_id: coverage.id, story_id: stray.id });
  });
});

test('entry 5 — a sequence that would reissue a number already allocated', (t) => {
  reportsOnly(t, 5, (db) => {
    // The counter is written directly rather than rewound, because the fixtures number their
    // documents explicitly and so leave no `number_sequence` row to rewind — which is the
    // state a restore produces too, and is the reason the register calls this one repairable.
    db.prepare("INSERT INTO number_sequence (kind, parent_id, next_value) VALUES ('spec', NULL, 1)").run();
  });
});

test('entry 6 — a builds_on edge between two epics', (t) => {
  reportsOnly(t, 6, (db, { spec }) => {
    const a = childDocument(db, 'epic', spec, { sequence: 2, slug: 'a', title: 'A' });
    const b = childDocument(db, 'epic', spec, { sequence: 3, slug: 'b', title: 'B' });

    create(db, 'dependency', { kind: 'builds_on', source_document_id: a.id, target_document_id: b.id });
  });
});

test('entry 7 — a review scoped to a story in an epic it does not review', (t) => {
  reportsOnly(t, 7, (db, { spec, epic }) => {
    const elsewhere = childDocument(db, 'epic', spec, { sequence: 2, slug: 'epic-2', title: 'Epic 2' });
    const stray = create(db, 'story', { epic_id: elsewhere.id, number: 1 });

    // A review is root-numbered but parented, so it is a `rootDocument` with a parent rather
    // than a `childDocument` — the numbering CHECK refuses the other combination.
    const review = rootDocument(db, 'review', {
      number: 1, slug: 'review-1', parent_id: epic.id, parent_kind: 'epic',
    });
    create(db, 'review', { document_id: review.id, scope: 'story', scope_story_id: stray.id });
  });
});

test('entry 8 — an accepted ADR with no chosen option', (t) => {
  const { rows } = reportsOnly(t, 8, (db, { spec }) => {
    const document = childDocument(db, 'adr', spec, { sequence: 1, slug: 'adr-1', title: 'ADR 1' });
    create(db, 'adr', { document_id: document.id, decision_status: 'accepted' });
    create(db, 'adr_option', { adr_id: document.id, name: 'Rejected option', chosen: 0 });
  });

  assert.equal(rows[0].chosen, 0, 'the count is reported, since "not exactly one" is two failures');
});

test('entry 9 — a spec_fragment that appears nowhere in its requirement', (t) => {
  reportsOnly(t, 9, (db, { spec, story }) => {
    const requirement = create(db, 'requirement', { spec_id: spec.id, text: 'The system shall persist.' });
    const criterion = create(db, 'story_criterion', { story_id: story.id });

    create(db, 'coverage', {
      requirement_id: requirement.id, story_criterion_id: criterion.id,
      spec_fragment: 'a sentence the requirement does not contain',
    });
  });
});

test('entry 10 — a vocabulary reference no guard covers', (t) => {
  const { rows } = reportsOnly(t, 10, (db) => {
    db.exec('DROP TRIGGER finding_category_id_category_domain_not_retired_on_insert');
  });

  assert.deepEqual(
    rows.map((row) => row.missing),
    ['finding_category_id_category_domain_not_retired_on_insert'],
    'the guard is named, because "some reference is unguarded" is not something anyone can fix',
  );
});

test('entry 11 — a cycle in session.superseded_by', (t) => {
  reportsOnly(t, 11, (db) => {
    const first = create(db, 'session', {});
    const second = create(db, 'session', { superseded_by: first.id });

    db.prepare('UPDATE session SET superseded_by = ? WHERE id = ?').run(second.id, first.id);
  });
});

test('entry 12 — a document assigned to a milestone belonging to another spec', (t) => {
  reportsOnly(t, 12, (db, { epic }) => {
    const other = rootDocument(db, 'spec', { number: 48, slug: 'other' });
    const milestone = create(db, 'milestone', { spec_id: other.id, label: 'M1', title: 'Elsewhere' });

    create(db, 'document_milestone', { document_id: epic.id, milestone_id: milestone.id });
  });
});

test('entry 13 — a {{ref:}} marker naming a document that is not there', (t) => {
  const missing = ulid();

  const { rows } = reportsOnly(t, 13, (db, { epic }) => {
    create(db, 'document_section', {
      document_id: epic.id, heading: 'Context', position: 1,
      body: `As decided in {{ref:${missing}}}, the substrate lands first.`,
    });
  });

  assert.deepEqual(
    { table: rows[0].table, column: rows[0].column, reference: rows[0].reference },
    { table: 'document_section', column: 'body', reference: missing },
    'the column is named as well as the row — a marker sweep that could not say where is unactionable',
  );
});

test('a marker in a column nobody would call prose is still swept', (t) => {
  const db = planning(t);
  const { epic } = corpus(db);
  const missing = ulid();

  // The sweep derives its columns from `PRAGMA table_info` rather than from a list of the
  // prose ones, so this is not a special case — it is the property that makes a column added
  // later impossible to forget. A declared list is what entry 13 exists to avoid needing.
  db.prepare('UPDATE document SET title = ? WHERE id = ?').run(`Epic {{ref:${missing}}}`, epic.id);

  const found = forEntry(checkIntegrity(db), 13);
  assert.deepEqual(
    { table: found.rows[0].table, column: found.rows[0].column },
    { table: 'document', column: 'title' },
  );
});

test('a resolvable marker is not a violation', (t) => {
  const db = planning(t);
  const { spec, epic } = corpus(db);

  create(db, 'document_section', {
    document_id: epic.id, heading: 'Context', position: 1,
    body: `Derived from {{ref:${spec.id}}}, and from {{ref:${epic.id}}} itself.`,
  });

  // The control. A sweep that reported every marker would satisfy the test above and be
  // useless, and the failure would look exactly like a corpus full of broken references.
  assert.equal(checkIntegrity(db).ok, true, 'two markers, both resolving, and nothing reported');
});

test('an orphaned row is reported, and located', (t) => {
  const db = planning(t);
  const { epic } = corpus(db);

  assert.deepEqual(orphans(db), [], 'nothing is orphaned while foreign keys are enforced');

  // The one path this state arrives by: a restore, which opens with `foreign_keys=OFF` because
  // no dump sorted by natural key is in topological order. Reproduced here rather than
  // described, since a check for a state no test can create is a check nothing exercises.
  db.exec('PRAGMA foreign_keys = OFF');
  db.prepare('DELETE FROM document WHERE id = ?').run(epic.id);
  db.exec('PRAGMA foreign_keys = ON');

  const report = checkIntegrity(db);
  const found = report.orphans.find((row) => row.table === 'story');

  assert.equal(report.ok, false, 'a database holding an orphan does not pass');
  assert.ok(found, 'the story left behind by the deleted epic is reported');
  assert.equal(
    found.columns,
    'epic_id, epic_kind',
    'named by column rather than by foreign-key index, and a composite key named whole',
  );
  assert.equal(found.parent, 'document', 'and by the table its reference failed to reach');
});
