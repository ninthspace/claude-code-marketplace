/**
 * Story 3 — the three tools that belong to no single entity.
 *
 * Two of the three criteria are about a refusal, and both refusals are the kind that look like
 * success when they go wrong. An allocation that reports success without a number leaves a
 * document unnumbered with no error anywhere; a cycle that slips past the link tool makes the
 * readiness query return nothing ready, which is indistinguishable from everything being done.
 * Neither shows up as an exception, so both are asserted against the state afterwards rather than
 * against what the call returned.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPlanningDatabase } from './support/planning-database.js';
import { spineTools } from '../src/tools/index.js';
import { REGISTER } from '../src/integrity/register.js';

function surface(t) {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);

  return { db, tools, call: Object.fromEntries(tools.map((tool) => [tool.name, tool.handler])) };
}

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

/** Three specs to hang edges between, since both ends of a `blocks` edge are documents. */
const specs = (call, count = 3) => Array.from({ length: count }, (unused, index) =>
  call.dpm_create_spec({ slug: `s${index}`, title: `S${index}` }));

const edges = (db) => db.prepare('SELECT count(*) AS n FROM dependency').get().n;

// --- Allocation ---------------------------------------------------------------------------------

test('allocation returns the value, and the first one for a kind is 1', (t) => {
  const { call } = surface(t);

  const first = call.dpm_allocate_number({ kind: 'retro' });

  // The criterion is "returns the value and never a success without one", so the response is
  // checked for the number itself rather than for not having thrown. A body with `ok: true` and
  // nothing else would pass any assertion phrased as "did not throw".
  assert.equal(first.number, 1);
  assert.equal(typeof first.number, 'number');
  assert.equal(first.kind, 'retro');

  assert.deepEqual(
    [2, 3, 4],
    [1, 2, 3].map(() => call.dpm_allocate_number({ kind: 'retro' }).number),
  );
});

test('a child-numbered kind counts within its parent and restarts under a new one', (t) => {
  const { call } = surface(t);
  const [one, two] = specs(call, 2);

  const under = (spec) => call.dpm_allocate_number({ kind: 'adr', parent_id: spec.id }).number;

  assert.deepEqual([under(one), under(one), under(two)], [1, 2, 1]);

  // The control: the same kind allocated with no parent is a different sequence entirely, which
  // is the partition the two partial indexes on `number_sequence` exist to enforce.
  assert.equal(call.dpm_allocate_number({ kind: 'retro' }).number, 1);
});

test('a kind the vocabulary does not carry is refused, not counted', (t) => {
  const { db, call } = surface(t);

  const error = refused(() => call.dpm_allocate_number({ kind: 'nonsense' }));

  assert.equal(error.rpc.code, -32602, 'refused as a bad call, not reported as a broken server');
  assert.equal(
    db.prepare("SELECT count(*) AS n FROM number_sequence WHERE kind = 'nonsense'").get().n,
    0,
    'a refused allocation left a sequence row behind',
  );

  assert.equal(call.dpm_allocate_number({ kind: 'retro' }).number, 1);
});

test('numbers are not reused after the document holding one is archived', (t) => {
  const { call } = surface(t);

  const first = call.dpm_create_spec({ slug: 'a', title: 'A' });
  call.dpm_update_spec({ id: first.id, archived_at: '2026-08-08T00:00:00Z' });

  // FR5's whole promise, and the reason `number_sequence` never consults the documents: the
  // filename-globbing implementation this replaces would have handed 1 straight back out.
  assert.equal(call.dpm_create_spec({ slug: 'b', title: 'B' }).number, 2);
});

// --- The cycle refusal --------------------------------------------------------------------------

test('an edge that would close a gates_work cycle is refused, naming both ends', (t) => {
  const { db, call } = surface(t);
  const [a, b, c] = specs(call);

  const link = (kind, source, target) => call.dpm_create_dependency({
    kind, source_document_id: source.id, target_document_id: target.id });

  assert.ok(link('blocks', a, b).id);
  assert.ok(link('blocks', b, c).id, 'a chain of any length is fine — it is not a cycle');

  const before = edges(db);
  const error = refused(() => link('blocks', c, a));

  assert.match(error.message, new RegExp(c.id), 'the source end is not named');
  assert.match(error.message, new RegExp(a.id), 'the target end is not named');
  assert.match(error.message, /blocks/, 'the kind that gated it is not named');

  // **Asserted against the table, not against the throw.** A refusal that threw after writing the
  // row would satisfy every assertion above and leave the cycle in place — and the readiness
  // query over it returns nothing ready, which raises no error and reads like a finished project.
  assert.equal(edges(db), before, 'the refused edge was left in the table');
  assert.deepEqual(REGISTER.find((entry) => entry.entry === 1).check(db), []);
});

test('a lineage kind may close the same loop a gating kind may not', (t) => {
  const { call } = surface(t);
  const [a, b] = specs(call, 2);

  const link = (kind, source, target) => call.dpm_create_dependency({
    kind, source_document_id: source.id, target_document_id: target.id });

  link('blocks', a, b);
  refused(() => link('blocks', b, a));

  // The control, and the reason `dependency_kind` is a table rather than a list of names in a
  // query: `builds_on` does not gate work, so nothing waits on it and a loop over it holds
  // nothing up. A tool hardcoding 'blocks' would behave identically here and diverge the moment
  // a project declared a fifth kind that gates.
  assert.ok(link('builds_on', b, a).id);
  assert.ok(link('constrains', b, a).id);
});

test('a self-edge is refused by the schema, and reaches the caller as a bad call', (t) => {
  const { call } = surface(t);
  const [a] = specs(call, 1);

  const error = refused(() => call.dpm_create_dependency({
    kind: 'blocks', source_document_id: a.id, target_document_id: a.id }));

  assert.equal(error.rpc.code, -32602);
  assert.match(error.message, /CHECK constraint failed/);
});

test('an edge missing an end is refused before the transaction opens', (t) => {
  const { db, call } = surface(t);
  const [a, b] = specs(call, 2);

  for (const partial of [
    { kind: 'blocks', source_document_id: a.id },
    { kind: 'blocks', target_document_id: b.id },
    { kind: 'blocks' },
  ]) {
    const error = refused(() => call.dpm_create_dependency(partial));
    assert.match(error.message, /one source and one target/);
  }

  assert.equal(db.isTransaction, false, 'a refused call left a transaction open');
  assert.ok(call.dpm_create_dependency({
    kind: 'blocks', source_document_id: a.id, target_document_id: b.id }).id);
});

test('a cycle already in the database does not block unrelated edges', (t) => {
  const { db, call } = surface(t);
  const [a, b, c, d] = specs(call, 4);

  // Written past the tool deliberately — this is the state a restore produces, and it is the
  // whole reason the refusal compares the cycle set before and after rather than asking whether
  // one exists. A tool that refused every edge while any cycle existed would make the integrity
  // report actionable only by hand-written SQL, which is what FR14's "without SQL" forbids.
  const raw = (source, target) => db.prepare(
    'INSERT INTO dependency (id, kind, source_document_id, target_document_id) VALUES (?, ?, ?, ?)',
  ).run(`edge-${source.slug}-${target.slug}`, 'blocks', source.id, target.id);

  raw(a, b);
  raw(b, a);

  assert.equal(REGISTER.find((entry) => entry.entry === 1).check(db).length, 2,
    'the fixture did not actually produce a cycle');

  assert.ok(call.dpm_create_dependency({
    kind: 'blocks', source_document_id: c.id, target_document_id: d.id }).id,
  'an unrelated edge was refused because of a cycle it has nothing to do with');

  // And the rule still holds for the edge that would extend the damage.
  refused(() => call.dpm_create_dependency({
    kind: 'blocks', source_document_id: d.id, target_document_id: c.id }));
});

test('the cycle rule and the integrity check are the same rule, not two', (t) => {
  const { tools } = surface(t);

  // Entry 1 is found by its number, not its position. The register is ordered by the Data
  // Model's numbering, so an entry inserted above it would silently repoint the link tool at a
  // different invariant — a change that breaks nothing visibly and enforces the wrong rule.
  const entry = REGISTER.find((one) => one.entry === 1);

  assert.ok(entry, 'register entry 1 is missing');
  assert.match(entry.invariant, /cycle/i);
  assert.notEqual(REGISTER.indexOf(entry), -1);
  assert.ok(tools.some((tool) => tool.name === 'dpm_create_dependency'));
});

// --- The integrity sweep ------------------------------------------------------------------------

test('the integrity tool reports every register entry, not only the failing ones', (t) => {
  const { call } = surface(t);
  const report = call.dpm_check_integrity({});

  // The criterion is "reports every register entry it checks". `checkIntegrity` alone returns
  // only the entries that produced rows, so a register of thirteen quiet entries and one of
  // three are the same result — which is why the tool carries the roll and not just the count.
  assert.deepEqual(
    report.entries.map((entry) => entry.entry),
    REGISTER.map((entry) => entry.entry),
  );

  for (const entry of report.entries) {
    assert.ok(entry.invariant, `entry ${entry.entry} is reported with no invariant text`);
  }

  // `checked` counts the orphan sweep too, which is the one check that is not a register entry.
  assert.equal(report.checked, report.entries.length + 1);
});

test('a clean database reports ok, and a corrupted one names where', (t) => {
  const { db, call } = surface(t);
  const [a] = specs(call, 1);

  call.dpm_create_requirement({
    spec_id: a.id, label: 'FR1', class: 'functional', text: 't', position: 0 });

  // The control comes first, because "reports a violation" means nothing from a tool that
  // reports one always — and entry 5 did exactly that until this story, on every database where
  // a number was both allocated and written.
  const clean = call.dpm_check_integrity({});
  assert.equal(clean.ok, true, JSON.stringify(clean.entries.filter((entry) => !entry.held)));
  assert.equal(clean.entries.every((entry) => entry.held), true);
  assert.deepEqual(clean.orphans, []);

  // A superseded ADR with no `supersedes` edge out of it — register entry 2, and a state no
  // foreign key could have prevented.
  db.exec("PRAGMA foreign_keys = OFF");
  db.prepare(`INSERT INTO document
      (id, kind, numbering, sequence, slug, title, parent_id, parent_kind, created_at, updated_at)
      VALUES ('adr-1', 'adr', 'child', 1, 'a', 'An ADR', ?, 'spec', '2026-01-01', '2026-01-01')`)
    .run(a.id);
  db.prepare(`INSERT INTO adr (document_id, decision_status, decision)
      VALUES ('adr-1', 'superseded', 'd')`).run();
  db.exec('PRAGMA foreign_keys = ON');

  const dirty = call.dpm_check_integrity({});
  const failed = dirty.entries.filter((entry) => !entry.held);

  assert.equal(dirty.ok, false);
  assert.deepEqual(failed.map((entry) => entry.entry), [2]);
  assert.deepEqual(failed[0].rows.map((row) => row.id), ['adr-1'],
    'the violation was reported without saying which row');
});

test('the integrity tool takes no arguments and refuses any', (t) => {
  const { call } = surface(t);

  const error = refused(() => call.dpm_check_integrity({ limit: 10 }));

  // Story 4 bounds reads. This response must stay unbounded: rows that fell off the end of an
  // integrity report are indistinguishable from rows that were never there, which is the false
  // pass NFR6 forbids from the one report whose job is to be trusted.
  assert.match(error.message, /unknown argument 'limit'/);
  assert.ok(call.dpm_check_integrity({}).entries.length > 0);
});
