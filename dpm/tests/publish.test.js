/**
 * Epic 47-10 Story 1 — writing the two generated artefacts (FR6, FR7, AD11).
 *
 * **Every test here names what the wrong answer would return before it asserts anything**, because
 * this module's failures are symmetric and a bare "no error" assertion passes for both halves of
 * each pair. A publish that wrote everything and one that wrote nothing both leave a run with no
 * exception; a second publish that correctly skipped every file and one that silently did nothing
 * both report no writes; a refusal that left the tree alone and one that left it half-written both
 * throw. Retro 39's testing-gap lesson stated the rule this file is built on: the fix for each of
 * those is to make the wrong answer *return something different*, not to add another assertion.
 *
 * File-backed only in the sense that matters — the database is in memory, because publish never
 * looks at where it lives, while `docs/` and `.dpm/dpm.sql` are real files in a temp directory,
 * because they are the entire subject.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync, symlinkSync,
  utimesSync, writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { openPlanningDatabase, handlers } from './support/planning-database.js';
import { fullCorpus } from './support/corpus.js';
import { spineTools } from '../src/tools/index.js';
import { publish } from '../src/publish/index.js';
import { project } from '../src/projection/index.js';
import { ProjectionError } from '../src/projection/naming.js';
import { dump } from '../src/dump/index.js';
import { DIVERGENCE, DUMP_PATH, guard } from '../src/guard/index.js';

/** A database holding the full corpus, and an empty directory to publish it into. */
function repository(t) {
  const db = openPlanningDatabase(t);
  const call = handlers(spineTools(db));
  const documents = fullCorpus(db, call);
  const root = mkdtempSync(join(tmpdir(), 'dpm-publish-'));

  t.after(() => rmSync(root, { recursive: true, force: true }));

  return { db, call, documents, root };
}

/** Every file under `root`, relative path to contents. The tree as a comparable value. */
function snapshot(root, at = '', into = new Map()) {
  for (const entry of readdirSync(join(root, at), { withFileTypes: true })) {
    const path = at === '' ? entry.name : `${at}/${entry.name}`;

    if (entry.isDirectory()) snapshot(root, path, into);
    else into.set(path, readFileSync(join(root, path), 'utf8'));
  }

  return into;
}

/** What the guard currently calls orphaned — the rule publish must be deleting by, not a copy. */
function orphaned(db, root) {
  return guard(db, { root }).diverged
    .filter((file) => file.reason === DIVERGENCE.orphaned)
    .map((file) => file.path)
    .sort();
}

const PAST = new Date('2020-01-01T00:00:00Z');

// --- Criterion 1: an empty tree receives everything the database produces ------------------------

test('publishing into an empty tree writes every artefact and names what it wrote', (t) => {
  const { db, root } = repository(t);

  // The wrong answer this guards against: a publish that wrote nothing returns an empty `written`
  // over an empty tree, and every assertion of the form "no failures" holds. So the expectation is
  // derived from the renderer and compared against the disk, and the count is asserted non-zero
  // rather than merely equal — an empty corpus would satisfy the comparison on its own.
  const expected = new Map(project(db, { write: false }).written.map((f) => [f.path, f.text]));

  expected.set(DUMP_PATH, dump(db).sql);
  assert.ok(expected.size > 1, 'the corpus produced no files, so this test asserts nothing');

  const record = publish(db, { root });

  assert.deepEqual(record.written.sort(), [...expected.keys()].sort());
  assert.deepEqual(record.unchanged, [], 'a file was called unchanged in a tree that was empty');
  assert.deepEqual(record.removed, [], 'something was removed from an empty tree');

  for (const [path, text] of expected) {
    assert.equal(readFileSync(join(root, path), 'utf8'), text, `${path} does not hold what the `
      + 'database produces — publish writes the projection back, it does not render');
  }

  // `inline` survives the widening: a document that renders inside its parent produces no file, and
  // has to stay distinguishable from one the renderer skipped.
  assert.ok(record.inline.length > 0, 'the corpus has an inline document and the record lost it');
});

// --- Criterion 2: a second publish changes nothing, and can say so ------------------------------

test('a second publish writes nothing, reports the files as unchanged, and leaves them alone', (t) => {
  const { db, root } = repository(t);

  const first = publish(db, { root });

  // **The wrong answer is a publish that skipped everything**, which also reports no writes — so
  // "written is empty" cannot carry this on its own. Two more things are asserted: the files are
  // named as *unchanged* rather than merely absent from `written`, and they are physically not
  // rewritten. The mtimes are stamped into the past first, so the check does not depend on the
  // clock's resolution — two writes inside the same millisecond would otherwise read as no write.
  for (const path of first.written) utimesSync(join(root, path), PAST, PAST);

  const stamped = first.written.map((path) => statSync(join(root, path)).mtimeMs);

  const second = publish(db, { root });

  assert.deepEqual(second.written, [], 'the second publish rewrote files nothing had changed');
  assert.deepEqual(second.unchanged.sort(), [...first.written].sort());
  assert.deepEqual(second.removed, []);
  assert.deepEqual(first.written.map((path) => statSync(join(root, path)).mtimeMs), stamped,
    'a file was rewritten with identical bytes, which is a write the record did not report');

  // And the tree is still correct, not merely still. A publish that deleted everything would also
  // leave every remaining mtime untouched.
  assert.deepEqual(guard(db, { root }).diverged, []);
});

// --- Criterion 3: what no document produces any more is removed, and reported apart -------------

test('a renumbered document\'s old files are removed, and the removal is reported apart from the writes', (t) => {
  const { db, documents, root } = repository(t);

  publish(db, { root });

  // A real renumber, not a hand-placed stray file. A stray reaches the same code path and proves a
  // weaker thing: that publish deletes files it does not produce. What the criterion is about is
  // the file a *rename* leaves behind, and the spec is the case that matters because its number is
  // the identifier its children are named from — so one renumber orphans the spec, its epic, its
  // coverage matrix and its ADR at once.
  const before = new Set(project(db, { write: false }).written.map((file) => file.path));

  db.prepare('UPDATE document SET number = 77 WHERE id = ?').run(documents.spec.id);

  const after = new Set(project(db, { write: false }).written.map((file) => file.path));
  const vanished = [...before].filter((path) => !after.has(path)).sort();

  assert.ok(vanished.length > 1, 'the renumber moved fewer files than the cascade it is here for');

  // The guard's answer, read before publish runs, is the set publish has to match. This is the
  // must-NOT driven rather than swept: it does not ask whether publish re-implements the rule, it
  // asks whether the two agree on a case where a second implementation would have to be right by
  // coincidence.
  const reported = orphaned(db, root);
  const record = publish(db, { root });

  assert.deepEqual(record.removed.sort(), reported);
  assert.deepEqual(record.removed.sort(), vanished);

  // Reported *and* gone. A record naming a removal it did not perform is the failure this pair
  // exists for, and it is invisible to the two comparisons above — both read the record.
  for (const path of record.removed) {
    assert.equal(existsSync(join(root, path)), false, `${path} is named as removed and is on disk`);
  }

  for (const path of after) {
    assert.equal(existsSync(join(root, path)), true, `${path} is produced and was not written`);
  }
});

test('removals are named apart from writes, and the two sets never overlap', (t) => {
  const { db, documents, root } = repository(t);

  publish(db, { root });
  db.prepare('UPDATE document SET number = 77 WHERE id = ?').run(documents.spec.id);

  const record = publish(db, { root });
  const overlap = record.removed.filter((path) => record.written.includes(path));

  assert.deepEqual(overlap, [], 'a path was reported as both written and removed');
  assert.ok(record.written.length > 0, 'the renumber wrote no new file, so the pairing is vacuous');
  assert.deepEqual(readdirSync(join(root, 'docs', 'specifications')).sort(),
    ['77-spec-persistence.md'], 'the old file survived the renumber');
  assert.deepEqual(guard(db, { root }).diverged, []);
});

// --- Criterion 4: one call, both artefacts -----------------------------------------------------

test('one call leaves both artefacts current, and a write to the database leaves both stale', (t) => {
  const { db, call, root } = repository(t);

  publish(db, { root });
  assert.deepEqual(guard(db, { root }).diverged, [], 'a single publish did not satisfy the guard');

  // The control, and the reason this criterion is not a restatement of the first: a write to the
  // database has to leave *both* artefacts behind, and the dump is the half that passes every check
  // aimed at the markdown. A publish that wrote only the projection would satisfy a guard that only
  // walked files, and the commit would carry a readable diff over a database nobody reviewed.
  call.create_spec({ slug: 'second', title: 'A second spec' });

  const stale = guard(db, { root }).diverged.map((file) => file.path);

  assert.ok(stale.includes(DUMP_PATH), 'the dump did not go stale when the database moved');
  assert.ok(stale.some((path) => path.startsWith('docs/')), 'the projection did not go stale');

  publish(db, { root });
  assert.deepEqual(guard(db, { root }).diverged, []);
});

// --- Criterion 5 (must NOT): a refusal leaves the tree exactly as it was ------------------------

test('a document that cannot render leaves the tree untouched rather than half-written', (t) => {
  const { db, root } = repository(t);

  publish(db, { root });

  const before = snapshot(root);

  // A kind seeded and never templated — the shape this failure takes in life, where a kind arrives
  // by migration and nobody writes the template.
  db.prepare("INSERT INTO document_kind (kind, dir, numbering) VALUES ('ledger', 'ledgers', 'root')")
    .run();
  db.prepare(`INSERT INTO document
      (id, kind, numbering, number, slug, title, status, created_at, updated_at)
      VALUES ('led-1', 'ledger', 'root', 9, 'costs', 'Costs', 'pending',
              '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z')`).run();

  // Something that *would* have been written, so the assertion below is not satisfied by a corpus
  // in which nothing changed anyway: the ledger is not the only pending write when publish refuses.
  db.prepare('UPDATE document SET title = ? WHERE id = ?')
    .run('Artefact persistence, revised', 'doc-quick');

  assert.throws(() => publish(db, { root }), ProjectionError);

  // **Untouched, not merely "no new file".** A publish that wrote the specs and refused the ledger
  // would leave a tree the guard then diffs clean for everything it managed — a stale projection
  // wearing a passing check, which is NFR6's false pass exactly.
  assert.deepEqual([...snapshot(root).entries()].sort(), [...before.entries()].sort());
});

// --- Criterion 6 (must NOT): one orphan rule, and it is the narrow one --------------------------

test('publish removes exactly what the guard reports, and nothing it does not', (t) => {
  const { db, documents, root } = repository(t);

  publish(db, { root });

  // Files dpm did not write, in the directories dpm writes into. The guard's rule is deliberately
  // narrow — only a name carrying a seeded kind where the projection puts it — and that narrowness
  // is the whole safety of a delete. A second implementation of "what does not belong here" is how
  // a hand-kept note becomes something a tool removes without anything having reported it.
  const kept = ['docs/epics/README.md', 'docs/specifications/notes.md'];

  for (const path of kept) writeFileSync(join(root, path), 'Written by a person.\n', 'utf8');

  db.prepare('UPDATE document SET number = 77 WHERE id = ?').run(documents.spec.id);

  const reported = orphaned(db, root);
  const record = publish(db, { root });

  assert.deepEqual(record.removed.sort(), reported, 'publish and the guard disagree about orphans');

  for (const path of kept) {
    assert.equal(readFileSync(join(root, path), 'utf8'), 'Written by a person.\n',
      `${path} was removed — publish is deleting by a wider rule than the guard reports by`);
  }

  // The control that stops the pair above passing vacuously: if the rule matched nothing at all,
  // both sets would be empty and the files would survive for the wrong reason.
  assert.ok(reported.length > 0, 'the renumber produced no orphan, so the agreement is vacuous');
});

// --- Criterion 5 (must NOT), second half: the dump never lands ahead of the projection ----------

test('a write that fails partway leaves the dump unwritten rather than ahead of the projection', (t) => {
  const { db, root } = repository(t);

  // **Once the first byte is written, "untouched" is no longer available**, and the criterion above
  // stops applying — it governs a refusal, which happens before any write. What governs a write that
  // fails halfway is the *order*, and the order is the thing this test exists for: the dump is the
  // committed form of the database, so a partial run must leave a projection ahead of the dump (the
  // guard reports the dump stale, and running again fixes it) rather than the reverse (a current
  // dump above markdown that never landed — a commit whose readable diff is missing the change its
  // database already carries, which passes every check aimed at the projection).
  //
  // It needs a fault injected because it is invisible to every run that completes: reordering the
  // two writes changes nothing a successful publish leaves behind, so no assertion over a finished
  // tree can see it. The injection is a dangling symlink rather than a permission bit, which would
  // not hold when the suite runs as root: `contents` follows it, gets ENOENT, and classifies the
  // file as needing a write; `writeFileSync` follows it to a directory that does not exist and
  // throws. Nothing here depends on who is running.
  const rendered = project(db, { write: false }).written;

  assert.ok(rendered.length > 1, 'one rendered file cannot show an ordering');

  const victim = rendered.at(-1).path;

  mkdirSync(join(root, dirname(victim)), { recursive: true });
  symlinkSync(join(root, 'nowhere', 'target.md'), join(root, victim));

  assert.throws(() => publish(db, { root }), { code: 'ENOENT' });

  // The wrong answer this pair is built against is a test that passes because nothing was written
  // at all — a refusal, not a partial write, which criterion 5 already covers and which would make
  // the assertion below true for the wrong reason. So the first assertion establishes that publish
  // really did reach its write loop and get part way through it, and only then does the second one
  // mean anything.
  assert.equal(existsSync(join(root, rendered[0].path)), true,
    'nothing was written, so this test is asserting a refusal rather than a partial write');
  assert.equal(existsSync(join(root, DUMP_PATH)), false,
    'the dump was written before the projection finished — a failed publish leaves a current dump '
    + 'over markdown that never landed, which is the half-finished state the order exists to avoid');
});
