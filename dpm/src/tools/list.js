/**
 * A list tool per spine type — the subject FR13's bound was missing.
 *
 * **Why these exist in this story rather than a later one.** Story 2 and Story 3 built twenty-seven
 * tools and not one of them returns more than a single row: every read is by primary key, and
 * `dpm_check_integrity` is deliberately unbounded (a truncated integrity report is precisely the
 * false pass NFR6 forbids, and it is excluded here for that reason, not by oversight). FR13's
 * criterion — "every list-returning tool declares a `limit` with a default, and a caller that
 * raises it receives the larger result" — and its must-NOT would both have passed by having
 * nothing to check. A requirement that cannot fail is not covered.
 *
 * **The scope argument is optional on every one of them.** Listing an epic's stories is the common
 * call, but "every task in the project" is a legitimate one, and refusing it would make the bound
 * a substitute for a query rather than a default over one. Optional scope is also what gives the
 * must-NOT something to bite on: an unscoped list over a large table is exactly the unbounded row
 * set FR13 forbids, so the limit has to be doing real work rather than shadowing a `WHERE`.
 *
 * **`body` is copied off the matching read tool, never restated.** A list that withheld a
 * different set of columns from the read of the same type would be two answers to one question,
 * and the pair a caller compares most often is `dpm_list_x` then `dpm_read_x`.
 */

import { defineTool } from './convention.js';
import { selectPage } from './query.js';

/**
 * One row per list tool. `fixed` is scoping the tool applies whatever the caller says — `document`
 * holds two kinds in one table, and `dpm_list_spec` returning epics would make the type in the
 * name mean nothing, the same rule the kind-scoped read tools already hold to.
 *
 * `order` ends in `id` everywhere: `position` and `number` are unique only within a parent, so on
 * an unscoped list they tie, and a tie in an ordered page is a row that can appear twice or not at
 * all across two calls.
 */
const LISTS = [
  { type: 'spec', table: 'document', fixed: { kind: 'spec' }, order: ['number', 'id'] },
  {
    type: 'epic',
    table: 'document',
    fixed: { kind: 'epic' },
    within: 'parent_id',
    order: ['sequence', 'id'],
  },
  { type: 'requirement', table: 'requirement', within: 'spec_id', order: ['position', 'id'] },
  {
    type: 'acceptance_criterion',
    table: 'acceptance_criterion',
    within: 'requirement_id',
    order: ['position', 'id'],
  },
  {
    type: 'story_criterion',
    table: 'story_criterion',
    within: 'story_id',
    order: ['position', 'id'],
  },
  { type: 'story', table: 'story', within: 'epic_id', order: ['number', 'id'] },
  { type: 'task', table: 'task', within: 'story_id', order: ['number', 'id'] },
  { type: 'coverage', table: 'coverage', within: 'requirement_id', order: ['position', 'id'] },
];

/**
 * Build the list tools, taking each one's body columns from its own read tool.
 *
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {object[]} spine The already-built spine tools, which is where `body` comes from.
 * @returns {object[]}
 */
export function listTools({ db }, spine) {
  return LISTS.map(({ type, table, fixed = {}, within, order }) => {
    const name = `dpm_list_${type}`;
    const read = spine.find((tool) => tool.name === `dpm_read_${type}`);

    if (!read) {
      throw new Error(`${name}: there is no dpm_read_${type} to take its body columns from`);
    }

    const owner = within?.replace(/_id$/, '');

    return defineTool({
      name,
      table,
      description: `List ${type} rows${owner ? `, optionally within one ${owner}` : ''}. `
        + 'Bounded by `limit`, which has a default and no ceiling.',
      reads: [table],
      mutates: false,
      body: read.body,
      paged: true,
      // Declared on the tool as well as used by it, so a test can hold the tiebreaker to being a
      // key the table actually guarantees unique rather than to a column that looks like one.
      order,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: within
          ? { [within]: { type: 'string', minLength: 1, description: `Only rows under this ${owner}` } }
          : {},
        // Nothing is required. An unscoped call is a legitimate one, and the bound is what makes
        // it safe rather than the scope being compulsory.
        required: [],
      },
      handler: (args) => selectPage(db, {
        table,
        order,
        where: name,
        filters: { ...fixed, ...(within ? { [within]: args[within] } : {}) },
      }, args),
    });
  });
}
