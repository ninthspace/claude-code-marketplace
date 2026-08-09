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
 * `order` ends in the table's own primary key everywhere — `id` on the spine types, the term itself
 * on a vocabulary: `position` and `number` are unique only within a parent, so on an unscoped list
 * they tie, and a tie in an ordered page is a row that can appear twice or not at all across two
 * calls. The key is what the table guarantees unique, which is not always the column named `id`.
 *
 * `live` marks the four vocabularies, whose lists are the roster a skill offers a choice from. It
 * is the difference between a term being retired and a term being gone: the row stays readable by
 * key and stops being offered.
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

  // The vocabularies. A term is reachable by key without these, and a *roster* is not — FR24's
  // "extensible per project" is only observable if something can enumerate what the project now
  // has, and the party, review and consult rosters are that enumeration.
  {
    type: 'taxonomy',
    table: 'taxonomy',
    within: 'domain',
    live: 'retired_at',
    order: ['position', 'id'],
  },
  { type: 'agent', table: 'agent', live: 'retired_at', order: ['position', 'name'] },
  { type: 'test_approach', table: 'test_approach', live: 'retired_at', order: ['position', 'tag'] },
  {
    type: 'dependency_kind',
    table: 'dependency_kind',
    live: 'retired_at',
    order: ['position', 'kind'],
  },
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
  return LISTS.map(({ type, table, fixed = {}, within, live, order }) => {
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
        + 'Bounded by `limit`, which has a default and no ceiling.'
        + (live ? ' Retired terms are left out unless `include_retired` asks for them.' : ''),
      reads: [table],
      mutates: false,
      body: read.body,
      paged: true,
      // Declared on the tool as well as used by it, so a test can hold the tiebreaker to being a
      // key the table actually guarantees unique rather than to a column that looks like one, and
      // can count what a list should reach without restating which tools hide retired rows.
      order,
      live,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          ...(within
            ? { [within]: { type: 'string', minLength: 1, description: `Only rows under this ${owner}` } }
            : {}),
          ...(live
            ? {
              include_retired: {
                type: 'boolean',
                default: false,
                description: 'Include terms that have been retired. They stay readable and stay '
                  + 'referenced by existing rows; what retirement stops is new rows arriving.',
              },
            }
            : {}),
        },
        // Nothing is required. An unscoped call is a legitimate one, and the bound is what makes
        // it safe rather than the scope being compulsory.
        required: [],
      },
      handler: (args) => selectPage(db, {
        table,
        order,
        live,
        where: name,
        filters: { ...fixed, ...(within ? { [within]: args[within] } : {}) },
      }, args),
    });
  });
}
