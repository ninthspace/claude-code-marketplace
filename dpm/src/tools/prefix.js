/**
 * A truncated id, offered back as the row it was almost certainly meant to be (FR22).
 *
 * An id copied out of a report, a log line wrapped at the wrong column, a paste that lost its last
 * characters — each arrives as a value that matches no row, and the refusal says only that nothing
 * was found. The row is right there and one character away, and nothing says so.
 *
 * **The search runs only after an exact match has already failed**, so a call that names a real
 * row never pays for it. That ordering is the whole of the cost argument: this is a `LIKE` against
 * the front of an indexed column on the refusal path, which is the path that was about to raise.
 *
 * **An ambiguous prefix offers nothing, and that is the must-NOT.** Two rows sharing a prefix is
 * the case where a guess is worst — the caller acts on a plausible suggestion and writes against
 * the wrong row, which is a mistake the original refusal could not have caused. Two rows are
 * fetched rather than one so the second's existence is the answer, in one statement.
 */

/** `%` and `_` are wildcards in `LIKE`; a ULID holds neither, but a caller's value might. */
const ESCAPED = /([\\%_])/g;

/**
 * The one row whose key begins with `value`, where there is exactly one.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table
 * @param {string} column The key column the value was compared against.
 * @param {unknown} value What the caller supplied.
 * @returns {string|null} The full key, or `null` where nothing or more than one thing matches.
 */
export function uniquePrefix(db, table, column, value) {
  if (typeof value !== 'string' || value.length === 0) return null;

  const matches = db
    .prepare(`SELECT ${column} AS key FROM ${table} WHERE ${column} LIKE ? ESCAPE '\\' LIMIT 2`)
    .all(`${value.replace(ESCAPED, '\\$1')}%`);

  // **Exactly one, never the first of several.** `LIMIT 2` is what makes that a single statement:
  // the second row is not read for its value but for the fact that it is there.
  return matches.length === 1 ? matches[0].key : null;
}

/**
 * ` — did you mean '<id>'?`, or nothing.
 *
 * A suffix rather than a message, because the refusals this joins already say what was wrong and
 * where: NFR4 asks a refusal to name a route out, and the route here is a value the caller can
 * paste. Composing the whole message would put this module in the business of phrasing two
 * different refusals, and they are not the same sentence.
 *
 * @returns {string} Empty where there is no unambiguous candidate, which is the common case.
 */
export function didYouMean(db, table, column, value) {
  const match = uniquePrefix(db, table, column, value);

  return match === null ? '' : ` — did you mean '${match}'? That is the only ${table} whose `
    + `${column} starts with what was given`;
}
