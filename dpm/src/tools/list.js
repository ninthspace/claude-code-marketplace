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
 * One row per list tool, for the types that are not document kinds. The kinds are derived instead,
 * by `documentLists` below.
 *
 * `fixed` is scoping the tool applies whatever the caller says — `document` holds every kind in one
 * table, and `dpm_list_spec` returning epics would make the type in the name mean nothing, the same
 * rule the kind-scoped read tools already hold to.
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
 * The document kinds' lists, derived from `document_kind` rather than declared above.
 *
 * **A kind acquires its list tool by being seeded**, which is the same rule `spineTools` applies to
 * create, read and update — and it is here for a reason found rather than anticipated. Only `spec`
 * and `epic` were listed by hand, so eleven of the thirteen kinds could be read by key and not
 * enumerated at all. That is invisible to `dpm/tests/parity.test.js`, which compares tables against
 * the registry and sees a `document` table well covered; it surfaced on the first attempt to
 * convert a skill, because a skill that must find "the product briefs in this project" without
 * reading a directory has nothing to call. A hand-kept list here would have to be edited for every
 * kind seeded afterwards, and that is the drift this spec exists to remove.
 *
 * The two shapes follow `numbering`: a root-numbered kind is unique on `number` across the project,
 * and a child-numbered one only within its parent, so the second is scoped and ordered by
 * `sequence`. Both end on `id`, for the tiebreaker reason given above.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {object[]}
 */
function documentLists(db) {
  return db.prepare('SELECT kind, numbering FROM document_kind ORDER BY kind').all()
    .map(({ kind, numbering }) => ({
      type: kind,
      table: 'document',
      fixed: { kind },
      ...(numbering === 'child'
        ? { within: 'parent_id', order: ['sequence', 'id'] }
        : { order: ['number', 'id'] }),
    }));
}

/**
 * A composite-key pin rather than a scope. `milestone.spec_kind` accompanies `spec_id` to hold the
 * foreign key to one kind; it narrows nothing on its own, and a list scoped by it would offer a
 * caller an argument with one legal value.
 */
const PIN = /_(kind|domain)$/;

/**
 * Child tables whose owner cannot be derived, named here with the reason rather than guessed at.
 *
 * `dependency` is an edge with two ends and four candidate columns, and the rule below would scope
 * it on `kind` — answering "every edge that blocks" where a caller asking for a list of an entity's
 * dependencies means "the edges into this story". A tool that answers a different question from the
 * one its name asks is worse than a missing tool, because the caller has no reason to check. The
 * readiness query is Epic 47-06 Story 3's subject and is where the direction gets decided.
 */
const UNOWNED = new Set(['dependency']);

/**
 * The child and link tables' lists, derived from the schema.
 *
 * **Every read tool is by primary key, so before this existed a child row could be created and
 * never found again.** `dpm_read_observation` needs an id, and nothing answered "the observations
 * of this retro" — so a skill's only route back to a child row was the rendered markdown, which is
 * the one thing FR25 forbids. Nineteen tables were in that state. It is invisible to
 * `dpm/tests/parity.test.js`, which asks whether a table has *a* tool rather than whether its rows
 * are reachable by someone who does not already hold their ids.
 *
 * Two shapes, both read off the table rather than declared:
 *
 * - **A composite key is its own scope.** `library_scope` is keyed `(document_id, scope)`, so the
 *   first key column is the owner and the whole key is the order — already unique, no tiebreak to
 *   add.
 * - **A single `id` takes the first foreign key in column order**, skipping the pins above. That
 *   is the parent in every case here: `observation.retro_id` precedes `story_id`, and
 *   `finding.review_id` precedes the taxonomy references. A table with no foreign key at all —
 *   `artifact` — lists unscoped, which is the same shape `dpm_list_agent` already has.
 *
 * `position` leads the order where the table has one and the key follows it, for the tiebreak
 * reason `LISTS` gives: `position` is unique within a parent and ties across the table.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object[]} spine
 * @returns {object[]}
 */
function childLists(db, spine) {
  const covered = new Set(['document', ...LISTS.map((entry) => entry.table)]);

  const tables = [...new Set(spine
    .filter((tool) => tool.name.startsWith('dpm_create_'))
    .map((tool) => tool.table))]
    .filter((table) => !covered.has(table) && !UNOWNED.has(table))
    .sort();

  return tables.map((table) => {
    const columns = db.prepare(`PRAGMA table_info(${table})`).all();
    const key = columns.filter((column) => column.pk)
      .sort((a, b) => a.pk - b.pk)
      .map((column) => column.name);
    const foreign = new Set(
      db.prepare(`PRAGMA foreign_key_list(${table})`).all().map((entry) => entry.from),
    );

    const within = key.length > 1
      ? key[0]
      : columns.map((column) => column.name)
        .find((name) => foreign.has(name) && !PIN.test(name));

    return {
      type: table,
      table,
      within,
      order: [...(columns.some((column) => column.name === 'position') ? ['position'] : []), ...key],
    };
  });
}

/**
 * Build the list tools, taking each one's body columns from its own read tool.
 *
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {object[]} spine The already-built spine tools, which is where `body` comes from.
 * @returns {object[]}
 */
export function listTools({ db }, spine) {
  const all = [...documentLists(db), ...LISTS, ...childLists(db, spine)];

  return all.map(({ type, table, fixed = {}, within, live, order }) => {
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
