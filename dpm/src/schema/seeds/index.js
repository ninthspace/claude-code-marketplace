/**
 * Vocabulary seeding.
 *
 * AD8 says a project starts from an empty database, and this is the one thing that is not
 * empty in it. The distinction is between *data* and *terms*: a spec, an epic and a finding
 * arrive through the tool surface, but the fact that `finding` is a legal category name and
 * `Findings` is not has to be true before the first row is written, or the constraints that
 * depend on it hold vacuously.
 *
 * Kept separate from `applySchema` rather than folded into it, because the two answer to
 * different stories: DDL is created once and migrated forward (Story 5), while a vocabulary
 * is appended to and retired from. Story 5's vocabulary migrations are insert-if-absent for
 * that reason, and this is the initial insert they build on.
 */

import { AGENTS } from './agents.js';
import { DOCUMENT_KINDS, KIND_PARENTS } from './document-kinds.js';
import { TAXONOMY } from './taxonomy.js';
import { TEST_APPROACHES } from './test-approaches.js';

/**
 * Insert `rows` into `table`, keyed off the first row's columns.
 *
 * A plain `INSERT`, not an upsert: `applySeeds` runs once against a database that has just
 * been created, so a conflict here is a duplicated term in the seed data rather than a
 * re-run, and `ON CONFLICT DO NOTHING` would swallow exactly the bug this catches.
 */
function insertRows(db, table, rows) {
  const columns = Object.keys(rows[0]);
  const statement = db.prepare(
    `INSERT INTO ${table} (${columns.join(', ')}) VALUES (${columns.map(() => '?').join(', ')})`,
  );

  for (const row of rows) {
    statement.run(...columns.map((column) => row[column]));
  }

  return rows.length;
}

/**
 * Seed every controlled vocabulary, in one transaction.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {Record<string, number>} Rows written per table — so a caller and a test can tell
 *   a seed that ran from one that found nothing to do, which are otherwise indistinguishable.
 */
export function applySeeds(db) {
  db.exec('BEGIN');

  let written;

  try {
    written = {
      document_kind: insertRows(db, 'document_kind', DOCUMENT_KINDS),
      document_kind_parent: insertRows(
        db,
        'document_kind_parent',
        KIND_PARENTS.map(([kind, parent_kind]) => ({ kind, parent_kind })),
      ),
      taxonomy: insertRows(db, 'taxonomy', TAXONOMY),
      agent: insertRows(db, 'agent', AGENTS),
      test_approach: insertRows(db, 'test_approach', TEST_APPROACHES),
    };
  } catch (error) {
    db.exec('ROLLBACK');
    throw error;
  }

  db.exec('COMMIT');
  return written;
}
