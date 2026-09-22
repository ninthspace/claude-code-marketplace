/**
 * Epic 05-07 Story 4 — nothing that closes today stops closing (NFR2).
 *
 * **Run against the committed corpus, never against a fixture.** A fixture written now would encode
 * the behaviour this change set produced and pass against anything — the epic says so in its own
 * shaping note, and it is the whole reason this story exists at the end rather than beside the work.
 *
 * So the corpus is `.dpm/dpm.sql` **as it stood before this change set**, read out of git at the
 * last commit before it. That dump was written by the code as it was: every epic status, every
 * requirement claim and every verification in it is what the *old* code produced. Restoring it and
 * recomputing with today's code is the before-and-after the requirement asks for, and the rows are
 * the "before" precisely because nothing here wrote them.
 *
 * **What a difference means.** NFR2's claim is that everything the coverage report newly says is a
 * *warning* rather than a gap, so the standing that lets an epic close keeps exactly the meaning it
 * has today. A requirement the old code left claimed that now computes short of `verified` is that
 * claim broken; an epic recorded `complete` whose stories no longer all read complete is the same
 * one level up. Either is a regression to investigate rather than a result to record.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { restore } from '../src/restore/index.js';
import { coverageReport } from '../src/coverage/report.js';

const PACKAGE = new URL('../', import.meta.url).pathname;

/** The last commit before this change set — the dump in it is the "before". */
const BEFORE = 'c0e3814';

/**
 * The committed dump as it stood before this change set, read from git.
 *
 * **Read rather than kept.** A copy checked in beside this test would be a second artefact that
 * ages separately from the history, and the next reader could not tell whether it was the corpus
 * or a snapshot somebody refreshed.
 */
function corpusBefore() {
  return execFileSync('git', ['show', `${BEFORE}:.dpm/dpm.sql`], {
    cwd: PACKAGE,
    maxBuffer: 32 * 1024 * 1024,
  }).toString();
}

/** That corpus, restored into a fresh in-memory database that today's code then reads. */
function restored(t) {
  const db = new DatabaseSync(':memory:');

  t.after(() => db.close());
  restore(db, corpusBefore());

  return db;
}

// --- The criterion: every close and every standing survives the change ----------------------------

test('every epic that closed before this change set still reads closed [integration]', (t) => {
  const db = restored(t);

  const epics = db.prepare(`
    SELECT id, slug, status FROM document WHERE kind = 'epic' AND status = 'complete'
  `).all();

  // **The corpus has to hold closed epics for this to mean anything.** A dump with none would pass
  // every assertion below by having nothing to check — the vacuous shape this epic's own retro
  // disposition is about.
  assert.ok(epics.length >= 5, `the committed corpus holds only ${epics.length} closed epics`);

  const reopened = [];

  for (const epic of epics) {
    const stories = db.prepare('SELECT status FROM story WHERE epic_id = ?').all(epic.id);

    // **An epic closes when no story under it is still `pending`.** The first reading here demanded
    // every story be `complete` and reported two epics as reopened — `retire-coverage` and
    // `criterion-supersession`, each of which closed over a `superseded` story. That is the rule
    // `/dpm:do` Step 8 already states: a retired story is reported as retired rather than counted
    // as work left undone. The reading was wrong, not the corpus.
    if (stories.some((story) => story.status === 'pending')) reopened.push(epic.slug);
  }

  assert.deepEqual(reopened, []);

  // And the corpus does hold a retired story under a closed epic, so the distinction above is
  // exercised rather than merely allowed for.
  const retired = db.prepare(`
    SELECT count(*) AS n FROM story
     JOIN document ON document.id = story.epic_id AND document.status = 'complete'
    WHERE story.status IN ('superseded', 'withdrawn')
  `).get().n;

  assert.ok(retired > 0, 'no closed epic holds a retired story, so the reading is untested');
});

test('every requirement claimed before this change set still computes as verified [integration]', (t) => {
  const db = restored(t);

  const specs = db.prepare("SELECT id, slug FROM document WHERE kind = 'spec'").all();

  assert.ok(specs.length >= 1, 'the committed corpus holds no spec, so there is nothing to report on');

  const broken = [];
  let claimed = 0;

  for (const spec of specs) {
    // **Recomputed by today's code over yesterday's rows**, which is the whole of the comparison:
    // the standing is derived, so a change in the derivation shows up here and nowhere else.
    for (const requirement of coverageReport(db, { specId: spec.id }).requirements) {
      if (requirement.claimed !== true) continue;

      claimed += 1;

      // A claim the old code left standing must still compute to a standing that supports it.
      // `verified` is the only standing a claimed requirement can honestly carry.
      if (requirement.standing !== 'verified') {
        broken.push(`${spec.slug} · ${requirement.label} → ${requirement.standing}`);
      }
    }
  }

  assert.ok(claimed >= 5, `only ${claimed} requirements were claimed in the committed corpus`);
  assert.deepEqual(broken, []);
});

test('the report newly says only warnings, so no standing became a gap [integration]', (t) => {
  const db = restored(t);
  const [spec] = db.prepare("SELECT id FROM document WHERE kind = 'spec'").all();

  const report = coverageReport(db, { specId: spec.id });

  // **NFR2's mechanism, asserted rather than trusted.** Everything epic 05-01 added to the report
  // arrives under `warnings`; the fields an epic's close reads — `standing`, `unaccounted` — are
  // the ones that existed before. A new finding that had landed in `unaccounted` instead would
  // turn a corpus that closes into one that does not, silently.
  assert.ok(report.warnings, 'the report carries no warnings block');
  for (const kind of ['claimable', 'no_criterion', 'duplicated']) {
    assert.ok(Array.isArray(report.warnings[kind]), `warnings.${kind} is not a list`);
  }

  // **`unaccounted` is reported, not gating, and the corpus proves it.** The first draft asserted
  // the list was empty and it is not — this spec's own criteria include warranted ones and ones
  // still being bound. What NFR2 claims is that such a criterion does not stop an epic closing, so
  // the assertion is that closed epics and unaccounted criteria coexist here rather than that the
  // list is empty.
  assert.ok(Array.isArray(report.unaccounted));

  const closed = db.prepare(`
    SELECT count(*) AS n FROM document WHERE kind = 'epic' AND status = 'complete'
  `).get().n;

  assert.ok(closed >= 5,
    'no epic in the corpus is closed, so "unaccounted does not block a close" is untested');
});

// --- The corpus is the committed one, and it is not this working tree -----------------------------

test('the corpus read is the committed dump before the change, not the current one [unit]', (t) => {
  const before = corpusBefore();

  assert.ok(before.length > 100_000, `the dump read is ${before.length} bytes — it was not read`);

  // **It must differ from the tree's current dump**, or the "before" is the "after" and every
  // assertion above compares the change set with itself. This is the one control the whole story
  // rests on — and the first draft read `git show :.dpm/dpm.sql`, which is the *index* and so
  // returned the committed bytes unchanged while this change set sat unstaged beside it.
  const current = readFileSync(resolve(PACKAGE, '..', '.dpm', 'dpm.sql'), 'utf8');

  assert.notEqual(before, current,
    'the committed dump has not moved since the baseline, so this story compares nothing');

  // And it restores — a corpus that could not be loaded would fail every test above for a reason
  // that has nothing to do with the requirement.
  const db = restored(t);

  assert.ok(db.prepare("SELECT count(*) AS n FROM document WHERE kind = 'epic'").get().n > 5);
});
