/**
 * One statement, for every tool that returns more than one row.
 *
 * `crud.js` holds the three statements a single artefact is built from; this holds the fourth.
 * Kept apart from them because it is the only one that answers to FR13, and because a paged read
 * has two properties neither of the others needs: a deterministic order, and a way for the caller
 * to know there is more.
 *
 * **`more` is a row, not a count.** The obvious shape is a second `SELECT COUNT(*)` beside the
 * page, and it is the wrong trade — a count scans the whole matching set to answer a question the
 * caller asked in order to avoid scanning the whole matching set, and on the largest tables (where
 * the bound actually earns its keep) it is the expensive half of the call. Asking for one row more
 * than the limit and reporting whether it arrived costs nothing and answers what a caller does
 * with the number anyway. What it does not give is a total, deliberately.
 */

import { DEFAULT_LIMIT } from './convention.js';

/**
 * Read one bounded page of a table.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} query
 * @param {string} query.table
 * @param {Record<string, unknown>} query.filters Columns to match. An `undefined` or `null` value
 *   is not a filter matching NULL — it is the caller declining to scope, so the column is dropped.
 * @param {{column: string, value: unknown}} [query.before] A strict `<` bound, dropped when the
 *   value is absent. The one comparison any tool needs: FR11's staleness is an age, and an age is
 *   `updated_at < ?` rather than an equality. Deliberately not a general operator parameter —
 *   there is one caller, and a filter language would be a query builder in a file that exists to
 *   avoid having one.
 * @param {string[]} query.order Columns, in precedence order.
 * @param {string} query.where The tool name, for messages.
 * @param {object} args Already validated: `limit` and `offset` may be absent, never malformed.
 * @returns {{items: object[], limit: number, offset: number, returned: number, more: boolean}}
 */
export function selectPage(db, { table, filters = {}, before, order, where }, args) {
  if (!Array.isArray(order) || order.length === 0) {
    throw new Error(`${where}: a page with no order is a page that can repeat and skip rows`);
  }

  const limit = args.limit ?? DEFAULT_LIMIT;
  const offset = args.offset ?? 0;

  const matched = Object.entries(filters)
    .filter(([, value]) => value !== undefined && value !== null)
    .map(([column, value]) => [`${column} = ?`, value]);

  if (before && before.value !== undefined && before.value !== null) {
    matched.push([`${before.column} < ?`, before.value]);
  }

  const sql = `SELECT * FROM ${table}`
    + (matched.length > 0 ? ` WHERE ${matched.map(([clause]) => clause).join(' AND ')}` : '')
    + ` ORDER BY ${order.join(', ')} LIMIT ? OFFSET ?`;

  // One row past the bound, so `more` is answered by whether it arrived.
  const rows = db.prepare(sql).all(...matched.map(([, value]) => value), limit + 1, offset);
  const more = rows.length > limit;
  const items = more ? rows.slice(0, limit) : rows;

  return { items, limit, offset, returned: items.length, more };
}
