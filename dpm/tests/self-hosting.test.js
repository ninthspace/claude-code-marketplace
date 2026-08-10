/**
 * Epic 47-09 Story 6 — a planning corpus dpm can hold (FR10, FR14, NFR6).
 *
 * - "A handcrafted planning corpus loads through create tools, and the projection regenerates every
 *   document in it. Its completeness is derived rather than listed" [feature]
 * - "The loaded corpus passes `PRAGMA foreign_key_check` and every entry in the invariant register"
 *   [integration]
 * - "Every entry in the self-hosting register is closed, or explicitly waived with a recorded
 *   reason; no entry remains OPEN" [integration]
 * - "must NOT — a corpus artefact loads with content dropped because no column held it, and the
 *   load reports success" [integration]
 *
 * **This is the build's standing acceptance check, and it has a history.** Asking whether dpm could
 * hold a real planning corpus is what produced all five self-hosting register entries, every one of
 * which needed a *spec* change and none of which was found by reading the schema. What the corpus
 * exercises here is the shape of each of those five, so a regression in any of them fails a test
 * rather than being noticed the next time somebody tries to load something.
 *
 * **Every claim below is derived from the live schema rather than listed.** A hand-kept "the corpus
 * contains…" is the failure this spec removes everywhere else, and it is the failure the register
 * already recorded once: an earlier enumeration omitted the artifact, so `artifact` and
 * `artifact_document` went unexercised by the check that gates the whole build, and nothing
 * reported it. The three readings are `tool.writes` across the create surface, `document_kind`, and
 * `document_kind_parent` — a table, kind or parentage pair added later fails this file until the
 * corpus covers it.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { openPlanningDatabase, handlers } from './support/planning-database.js';
import { selfHostingCorpus } from './support/self-hosting.js';
import { spineTools } from '../src/tools/index.js';
import { project, renderDocument } from '../src/projection/index.js';
import { identifiers } from '../src/projection/naming.js';
import { resolve } from '../src/projection/markers.js';

const EPICS = join(import.meta.dirname, '..', '..', 'docs', 'epics');

/** Open a database, load the corpus, and hand back everything a test here needs. */
function loaded(t) {
  const db = openPlanningDatabase(t);
  const tools = spineTools(db);
  const call = handlers(tools);

  return { db, tools, call, corpus: selfHostingCorpus(call) };
}

// --- Criterion 1: the corpus loads and every document renders ------------------------------------

test('the corpus covers the write surface, every kind and every parentage pair', (t) => {
  const { db, tools } = loaded(t);

  // **`tool.writes` and not a list of table names.** Each create tool declares the tables it
  // writes, so the union is the write surface as the surface itself reports it. A table reachable
  // only by a tool added tomorrow is in this set the day that tool lands.
  const tables = [...new Set(tools
    .filter((tool) => tool.name.startsWith('create_'))
    .flatMap((tool) => tool.writes ?? []))].sort();

  assert.ok(tables.length >= 30, `only ${tables.length} tables have a create tool — the derivation `
    + 'is reading something other than the write surface');

  const empty = tables.filter((table) =>
    db.prepare(`SELECT count(*) AS rows FROM ${table}`).get().rows === 0);

  assert.deepEqual(empty, [],
    'a table a create tool writes carries no row, so the corpus never exercised it');

  // Every seeded kind has a document. A kind with a template and no document in the corpus is a
  // template nothing here renders.
  const kinds = db.prepare('SELECT kind FROM document_kind ORDER BY kind').all().map((r) => r.kind);
  const present = new Set(db.prepare('SELECT DISTINCT kind FROM document').all().map((r) => r.kind));

  assert.deepEqual(kinds.filter((kind) => !present.has(kind)), [],
    'a seeded document kind has no document in the corpus');

  // And every parentage pair. **This is the half that catches a vocabulary half-exercised**: the
  // first cut of this corpus reached six of the twelve pairs and looked complete, because every
  // kind was present and every table was written. `adr` under a spec and `adr` under a discussion
  // are different rows through different templates, and only this reading tells them apart.
  const pairs = db.prepare('SELECT kind, parent_kind FROM document_kind_parent ORDER BY kind')
    .all().map((row) => `${row.kind} under ${row.parent_kind}`);
  const exercised = new Set(db
    .prepare('SELECT DISTINCT kind, parent_kind FROM document WHERE parent_id IS NOT NULL').all()
    .map((row) => `${row.kind} under ${row.parent_kind}`));

  assert.deepEqual(pairs.filter((pair) => !exercised.has(pair)), [],
    'a seeded parentage pair is never exercised by the corpus');
});

test('the projection regenerates every document in the corpus', (t) => {
  const { db } = loaded(t);

  const { written, inline } = project(db, { write: false });
  const documents = db.prepare('SELECT id, kind FROM document').all();

  // `written` and `inline` are separate for exactly this reason: a document that silently produced
  // nothing is indistinguishable from one the renderer skipped, so both are counted and the total
  // has to be the corpus. The artifact register is the one written path that is not a document.
  assert.equal(written.length + inline.length, documents.length + 1,
    `${documents.length} documents produced ${written.length} files and ${inline.length} inline `
    + 'renders — something rendered to neither');

  // The inline set is exactly the kinds whose `dir` is NULL, read off the vocabulary rather than
  // named here, so a kind made inline later moves between the two sets without an edit.
  const inlineKinds = new Set(db.prepare('SELECT kind FROM document_kind WHERE dir IS NULL').all()
    .map((row) => row.kind));

  assert.deepEqual([...new Set(inline.map((entry) => entry.split(':')[0]))].sort(),
    [...inlineKinds].sort(), 'a document rendered inline whose kind has a directory, or the reverse');

  // Every file is distinct. Two documents rendering to one path is a silent overwrite, and it is
  // the failure the kind-in-the-filename rule exists to prevent.
  const paths = written.map((entry) => entry.path);
  assert.equal(new Set(paths).size, paths.length, 'two documents render to the same path');

  // **A coverage matrix carries its epic's identifier, and this needs two epics to say anything.**
  // `document_child_number` allocates per parent, so every matrix is `sequence` 1 under its own
  // epic; a rule taking the document's own sequence names every matrix `{spec}-01` and looks
  // correct against any fixture holding one epic. Two matrices then differ only by slug — which is
  // enough for the uniqueness check above to pass while the numbers are wrong.
  const names = identifiers(db);
  const matrices = db.prepare("SELECT id, parent_id FROM document WHERE kind = 'coverage_matrix'")
    .all();

  assert.ok(matrices.length >= 2,
    `the corpus holds ${matrices.length} coverage matrices — with fewer than two, a matrix taking `
    + 'its own sequence and one taking its epic\'s are indistinguishable');

  for (const matrix of matrices) {
    assert.equal(names.get(matrix.id), names.get(matrix.parent_id),
      'a coverage matrix does not share its epic\'s identifier');
  }

  // The inline kind still renders. Its bytes are computed whether or not a parent spliced it in,
  // which is what render-checks an ADR whose parent's template dropped it.
  for (const { id, kind } of documents.filter((row) => inlineKinds.has(row.kind))) {
    const { path, text } = renderDocument(db, id, names);

    assert.equal(path, null, `${kind} produced a path and its kind has no directory`);
    assert.ok(text.length > 0, `${kind} rendered nothing`);
  }
});

test('the shapes the self-hosting register was opened for all survive the round trip', (t) => {
  const { db, call, corpus } = loaded(t);
  const names = identifiers(db);
  const render = (id) => renderDocument(db, id, names).text;

  // Entry 3 — an inline AD keeps `decision_status`, its options and their tradeoff axes, and the
  // spec that holds it renders all of them. An AD degraded to prose keeps the words and loses the
  // four columns; the assertion is on the columns.
  const adr = call.read_adr({ id: corpus.adr.id });
  assert.equal(adr.decision_status, 'accepted');

  const options = call.list_adr_option({ adr_id: corpus.adr.id, include_body: true }).items;
  assert.equal(options.filter((option) => option.chosen).length, 1);
  assert.ok(options.every((option) =>
    call.list_adr_option_tradeoff({ option_id: option.id, include_body: true }).items.length === 2));

  const inSpec = render(corpus.spec.id);
  for (const option of options) assert.ok(inSpec.includes(option.name), `${option.name} is not in its spec`);

  // Entry 4 — the retro's parent is the spec, not an epic. Seeded parentage allows all three, and
  // the corpus exercises all three; this is the one the entry was opened for.
  assert.equal(call.read_retro({ id: corpus.retro.id }).parent_kind, 'spec');

  // Entry 2 — one epic in two milestones. `document_milestone` is many-to-many precisely for this,
  // and an epic in exactly one exercises the table without exercising the reason.
  const spanning = call.list_document_milestone({ document_id: corpus.epics[1].id }).items;
  assert.equal(spanning.length, 2, 'the spanning epic delivers one milestone, so nothing spans');

  // Entry 1 — partial coverage beside full. Both requirements carry bound fragments; only one
  // carries the claim, so "covered" and "claimed complete" are distinguishable observations.
  const claimed = call.read_requirement({ id: corpus.requirements[0].id });
  const unclaimed = call.read_requirement({ id: corpus.requirements[1].id });

  assert.ok(claimed.coverage_claimed_at, 'the claimed requirement carries no claim');
  assert.equal(unclaimed.coverage_claimed_at, null, 'both requirements are claimed, so neither is partial');
  assert.ok(call.list_coverage({ requirement_id: unclaimed.id }).items.length > 0,
    'the unclaimed requirement has no coverage either, so the pair is covered/uncovered and not partial/full');

  // Entry 5 — a marker in body prose renders as its target's current identifier, in a section body
  // *and* in an observation. The second is the case that killed `document_reference`: an
  // observation is a child row, so a section-scoped table could never have reached it.
  const specText = render(corpus.spec.id);
  const retroText = render(corpus.retro.id);

  assert.ok(specText.includes(`brief ${names.get(corpus.product.id)}`),
    'the section marker did not resolve to its target\'s identifier');
  assert.ok(retroText.includes(`spec ${names.get(corpus.spec.id)}`),
    'the observation marker did not resolve — the child-row column is unreached');

  for (const text of [specText, retroText]) {
    assert.doesNotMatch(text, /\{\{ref:/, 'a marker survived into the projection unresolved');
  }
});

// --- Criterion 2: foreign_key_check and every register entry -------------------------------------

test('the loaded corpus passes foreign_key_check and every invariant register entry', (t) => {
  const { db, call } = loaded(t);

  assert.deepEqual(db.prepare('PRAGMA foreign_key_check').all(), [],
    'the corpus carries a foreign-key violation');

  const report = call.check_integrity({});

  assert.deepEqual(report.entries.filter((entry) => !entry.held), [],
    'the corpus violates an entry in the cross-row invariant register');
  assert.deepEqual(report.orphans, [], 'the corpus carries an orphaned row');
  assert.equal(report.ok, true);

  // **The count is asserted because a report of zero problems over zero checks is the false pass
  // this whole register exists to refuse.** Both sides are derived — `checked` from the register's
  // own length and `entries` from `REGISTER` — so an entry added later moves them together rather
  // than failing here. The one they differ by is the orphan sweep, which is a check and not a
  // register entry.
  assert.equal(report.checked, report.entries.length + 1);
  assert.ok(report.entries.length >= 13, `only ${report.entries.length} register entries ran`);

  // The register's per-entry tests use minimal fixtures, one violation at a time. What is new here
  // is every entry run against one large connected graph, where a check can be wrong by matching
  // rows it was never meant to reach — invisible against a fixture holding only its own subject.
  assert.ok(db.prepare('SELECT count(*) AS rows FROM document').get().rows >= 15,
    'the graph is too small for this to be a different test from the per-entry ones');
});

// --- Criterion 3: the self-hosting register has no OPEN entry ------------------------------------

/**
 * Every `### Self-hosting register` section across the epics, as raw text keyed by file.
 *
 * Scanned rather than listed, so an entry raised by an epic written later is picked up. The
 * register's home is Epic 47-01's Notes; the other epics carry sections of the same name scoping
 * which entries bear on them, and an entry can be reopened in any of them.
 */
function registerSections() {
  const sections = new Map();

  for (const file of readdirSync(EPICS).filter((name) => /-epic-.*\.md$/.test(name))) {
    const lines = readFileSync(join(EPICS, file), 'utf8').split('\n');
    const start = lines.findIndex((line) => /^#{2,4} Self-hosting register/.test(line));
    if (start === -1) continue;

    const rest = lines.slice(start + 1);
    const end = rest.findIndex((line) => /^#{1,4} /.test(line));

    sections.set(file, (end === -1 ? rest : rest.slice(0, end)).join('\n'));
  }

  return sections;
}

/**
 * The numbered entries in a register section, each as `{ number, subject, status }`.
 *
 * **The status column and not the word.** A first cut swept the section text for the word `OPEN`
 * and failed on 47-09, whose notes narrate *"it held five OPEN entries when this epic was
 * written"* — a sentence about the register's history, in a section whose own table has no status
 * to give. Reading the column distinguishes an entry's state from prose that mentions a state,
 * and a section tabulating something other than entry status contributes nothing rather than
 * everything.
 */
function registerEntries(text) {
  const rows = text.split('\n').filter((line) => line.trim().startsWith('|'));
  const heading = rows.findIndex((line) => /\|\s*Status\s*\|/.test(line));
  if (heading === -1) return [];

  const columns = rows[heading].split('|').map((cell) => cell.trim());
  const status = columns.indexOf('Status');

  return rows.slice(heading + 1)
    .map((line) => line.split('|').map((cell) => cell.trim()))
    .filter((cells) => cells.length === columns.length && /^\d+$/.test(cells[1]))
    .map((cells) => ({ number: cells[1], subject: cells[2], status: cells[status] }));
}

test('no entry in the self-hosting register remains OPEN', () => {
  const sections = registerSections();

  assert.ok(sections.size > 0, 'no epic carries a self-hosting register section');

  const entries = [...sections].flatMap(([file, text]) =>
    registerEntries(text).map((entry) => ({ file, ...entry })));

  // **The sweep having something to read is half the claim.** A register whose rows were deleted
  // has no OPEN entry either, and it passes the negative check in exactly the shape a closed
  // register does — so the count is asserted before the states are.
  assert.ok(entries.length >= 5,
    `the register sweep found ${entries.length} entries across ${sections.size} sections — it had five`);

  assert.deepEqual(
    entries.filter((entry) => !/^(CLOSED|WAIVED)\b/.test(entry.status))
      .map((entry) => `${entry.file} #${entry.number}: ${entry.subject} is ${entry.status}`),
    [], 'a self-hosting register entry is neither closed nor explicitly waived');

  // And the control: the same reading over a section written the way a reopened entry would be,
  // in a table shaped like the register's own.
  const planted = registerEntries([
    '| # | Entry | Status | Closed by |',
    '|---|---|---|---|',
    '| 6 | Something the corpus needs | OPEN | — |',
  ].join('\n'));

  assert.deepEqual(planted, [{ number: '6', subject: 'Something the corpus needs', status: 'OPEN' }],
    'the reading does not recognise an OPEN entry');
});

// --- Criterion 4 (must NOT): content dropped, and the load reporting success ----------------------

/**
 * Which of the bodies the corpus wrote are absent from the projection that should carry them.
 *
 * A function returning problems rather than a run of assertions, so the same reading can be driven
 * against an expectation that is wrong on purpose — which is how the comparison itself is checked.
 * **Markers are resolved on the expected side with the renderer's own resolver**, because a body
 * written with `{{ref:<id>}}` is *meant* to come out as an identifier: comparing the raw text would
 * report every marker as a drop, and comparing after stripping them would stop seeing whether they
 * resolved at all.
 */
function dropped(db, expectations, names = identifiers(db)) {
  const rendered = new Map(db.prepare('SELECT id FROM document').all()
    .map(({ id }) => [id, renderDocument(db, id, names).text]));

  return expectations
    .map(({ documentId, text }) => ({ documentId, text: resolve(text, names, 'expected') }))
    .filter(({ documentId, text }) => !rendered.get(documentId)?.includes(text))
    .map(({ documentId, text }) => `${documentId} does not carry ${JSON.stringify(text)}`);
}

/**
 * Which narrative column values in the database appear nowhere in the projection.
 *
 * **The columns are derived from the read surface, not listed.** A read tool's `body` array is the
 * columns it withholds until `include_body` — which is the surface's own statement of what counts
 * as narrative — and its `table` says where they live. So a narrative column added to any entity is
 * swept the day it is declared, and none of that is written down here.
 *
 * This is the complement to the per-document walk, and it exists because that walk missed
 * something: it compares only the bodies the corpus deliberately recorded, so a column the corpus
 * writes *without* recording is invisible to it. Dropping `adr_option.rationale` from its template
 * survived the recorded walk untouched. It does not survive this one.
 *
 * `except` names the values whose absence is a decision rather than a loss. `swept` is returned
 * beside `missing` because a sweep that read nothing reports nothing missing, and the two are
 * indistinguishable from the assertion's side.
 */
function unprojectedNarrative(db, tools, except = new Set()) {
  const columns = new Map();

  for (const tool of tools.filter((t) => Array.isArray(t.body) && t.body.length > 0)) {
    const declared = columns.get(tool.table) ?? new Set();
    for (const column of tool.body) declared.add(column);
    columns.set(tool.table, declared);
  }

  const names = identifiers(db);
  const projection = db.prepare('SELECT id FROM document').all()
    .map(({ id }) => renderDocument(db, id, names).text).join('\n');
  const missing = [];
  let swept = 0;

  for (const [table, declared] of columns) {
    for (const column of declared) {
      if (except.has(`${table}.${column}`)) continue;

      const rows = db.prepare(`SELECT ${column} AS value FROM ${table} WHERE ${column} IS NOT NULL`)
        .all();

      for (const { value } of rows) {
        if (typeof value !== 'string' || value.length === 0) continue;
        swept += 1;
        if (!projection.includes(resolve(value, names, `${table}.${column}`))) {
          missing.push(`${table}.${column}: ${JSON.stringify(value.slice(0, 60))}`);
        }
      }
    }
  }

  return { missing: missing.sort(), swept };
}

/**
 * Narrative columns whose absence from the projection is deliberate.
 *
 * Named rather than filtered out of the corpus, because a corpus that never writes them makes the
 * check pass by shrinking its own input. Each of these is written, and each is expected not to
 * come back — which is a claim a reader can disagree with, and that is the point.
 */
const UNPROJECTED = new Map([
  // FR11 removed the progress file; projecting the state it held would put it straight back.
  ['session.state', 'the session blob FR11 took off disk'],
  // Roster rows are vocabulary, not documents. They reach a run through `list_agent`, and a
  // projection that rendered them would be publishing the personas rather than the plan.
  ['agent.personality', 'roster vocabulary, which no document renders'],
  ['agent.communication_style', 'roster vocabulary, which no document renders'],
]);

test('must NOT — a body the corpus wrote is missing from the projection and nothing says so', (t) => {
  const { db, tools, corpus } = loaded(t);

  assert.ok(corpus.prose.length >= 20,
    `only ${corpus.prose.length} bodies were recorded — the comparison covers too little to mean much`);

  assert.deepEqual(dropped(db, corpus.prose), [],
    'a body a create tool accepted does not appear in the projection of the document that holds it');

  // And the same claim swept over every narrative column the read surface declares, which reaches
  // the ones the corpus writes without recording.
  const sweep = unprojectedNarrative(db, tools, new Set(UNPROJECTED.keys()));

  assert.deepEqual(sweep.missing, [],
    'a narrative column holds text that reaches no projection, and no template says it should not');
  assert.ok(sweep.swept > corpus.prose.length,
    `the sweep read ${sweep.swept} values against ${corpus.prose.length} recorded bodies — it is `
    + 'covering less than the walk it exists to widen');

  // **The control.** Without it a comparison that had stopped reading — a rendered map keyed
  // wrongly, an `includes` against an empty string — reports a clean corpus in the same shape as a
  // clean corpus does.
  const planted = [{ documentId: corpus.spec.id, text: 'A sentence the corpus never wrote.' }];

  assert.equal(dropped(db, planted).length, 1, 'the comparison does not read');

  // **And the one column deliberately unprojected, named rather than left out.** `session.state` is
  // written by a create tool and reaches no template, because projecting it would put back the
  // progress-file leak FR11 removed. Leaving it out of the corpus would make the check pass by
  // shrinking its own input; carrying it and asserting the absence is what makes it a decision.
  const session = db.prepare("SELECT state FROM session WHERE id = 'session-corpus'").get();

  assert.ok(session.state, 'the corpus recorded no session state, so there is nothing to exclude');
  assert.equal(dropped(db, [{ documentId: corpus.spec.id, text: session.state }]).length, 1,
    'session state reached a projection — FR11 removed the file it used to be');
});
