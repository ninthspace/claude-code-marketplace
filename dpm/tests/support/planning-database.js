/**
 * A database with the schema applied, the creators registered and the kind vocabulary
 * seeded — the starting point almost every Story 1 test shares.
 *
 * It sits in `support/` rather than in `fixtures/` because it opens a database, which is the
 * harness's job. What it seeds is dpm's own vocabulary, applied by the same `applyVocabulary`
 * a real project gets on every server start — so a test that passes against a term the
 * release does not carry fails here rather than in the field.
 */

import { openDatabase } from './database.js';
import { registerCreators } from './creators.js';
import { applySchema } from '../../src/schema/index.js';
import { applyVocabulary } from '../../src/schema/seeds/index.js';

/**
 * @param {import('node:test').TestContext} t
 * @returns {import('node:sqlite').DatabaseSync}
 */
export function openPlanningDatabase(t) {
  registerCreators();

  const db = applySchema(openDatabase(t));
  applyVocabulary(db);

  return db;
}
