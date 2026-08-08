/**
 * Retiring a term, for the tests that need one retired.
 *
 * This is an `UPDATE`, and the fixture seam only creates — Epic 47-03's update tools do not
 * exist yet and `create()` is deliberately not a general write path. So it lives in
 * `support/`, beside the creators, under the same rule: the code with SQL in it sits here and
 * `tests/fixtures/` stays free of it.
 *
 * It writes `retired_at` and nothing else. Retirement is not a delete and not a status change
 * — the row stays, its references stay resolvable, and the only thing that changes is whether
 * a *new* row may point at it.
 */

/** The column each vocabulary is keyed on. */
const KEY = {
  taxonomy: 'id',
  agent: 'name',
  test_approach: 'tag',
  dependency_kind: 'kind',
  observation: 'id',
};

/**
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {keyof KEY} table
 * @param {string} key
 * @param {string} [at]
 * @returns {object} The retired row, read back.
 */
export function retire(db, table, key, at = '2026-08-08T00:00:00Z') {
  const column = KEY[table];

  if (!column) {
    throw new Error(`no retirement key known for ${table} — add it to vocabulary.js`);
  }

  const changes = db
    .prepare(`UPDATE ${table} SET retired_at = ? WHERE ${column} = ?`)
    .run(at, key).changes;

  // A typo in a term name would otherwise retire nothing and leave the test asserting that a
  // live term behaves like a live term, which passes.
  if (changes !== 1) {
    throw new Error(`retiring ${table}.${column} = ${key} matched ${changes} rows, not 1`);
  }

  return db.prepare(`SELECT * FROM ${table} WHERE ${column} = ?`).get(key);
}
