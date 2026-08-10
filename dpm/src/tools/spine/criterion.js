/**
 * `acceptance_criterion` and `story_criterion` — the two criterion sets, one factory.
 *
 * They are separate tables for a reason `004-delivery.sql` sets out: a spec states its criteria
 * in `## Testing Strategy`, an epic states different ones per story, and `coverage` is the join
 * between them. Modelling only one side leaves that join with nothing on its right-hand side. But
 * their *shape* is identical — a parent, a text, a polarity, a position — so the tools are one
 * factory taking the parent column's name, and the two are told apart by the tool name.
 *
 * **`polarity` is the sleeper this pair exists to fix.** In the markdown corpus a negative
 * criterion is written `must NOT — …` and recognised by that prefix; a control case by the word
 * `control`. Both are types carried in prose, in the artefact whose entire purpose is deciding
 * whether the work is done. Here they are a column with a `CHECK`, and the create tool offers
 * exactly the three values that `CHECK` admits — which is FR4's "type is a column, not a
 * spelling" applied to the criterion tables rather than only to `requirement`.
 */

import { defineTool, SUPPLIED } from '../convention.js';
import { insert, readById, update } from '../crud.js';

/** Copied by hand from `004-delivery.sql`, where both tables declare the same set. */
const POLARITY = ['must', 'must_not', 'control'];

/**
 * Build create, read and update for one criterion table.
 *
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.newId
 * @param {object} options
 * @param {string} options.table `acceptance_criterion` or `story_criterion`.
 * @param {string} options.parent The column naming its owner — `requirement_id` or `story_id`.
 * @param {string} options.owner What that owner is, for the descriptions.
 * @returns {object[]}
 */
export function criterionTools({ db, newId }, { table, parent, owner }) {
  const fields = {
    text: { type: 'string', minLength: 1 },
    polarity: {
      type: 'string',
      enum: POLARITY,
      default: 'must',
      description: "'must_not' is a type here, not the words 'must NOT' at the front of the text",
    },
    position: { type: 'integer', minimum: 0 },
  };

  return [
    defineTool({
      name: `create_${table}`,
      table,
      description: `Create a criterion under its ${owner}. Polarity is a value, not a prefix.`,
      reads: [table],
      mutates: true,
      serverSupplied: { id: SUPPLIED.ulid },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { [parent]: { type: 'string', minLength: 1 }, ...fields },
        required: [parent, 'text', 'position'],
      },
      handler: (args) => insert(db, table, {
        id: newId(),
        [parent]: args[parent],
        text: args.text,
        polarity: args.polarity ?? 'must',
        position: args.position,
      }, `create_${table}`),
    }),

    defineTool({
      name: `read_${table}`,
      table,
      description: `Read one criterion by id, with its polarity as a column.`,
      reads: [table],
      mutates: false,
      body: ['text'],
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 } },
        required: ['id'],
      },
      handler: (args) => readById(db, table, args.id, `read_${table}`),
    }),

    defineTool({
      name: `update_${table}`,
      table,
      description: `Update a criterion's text, polarity or position.`,
      reads: [table],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...fields },
        required: ['id'],
      },
      handler: ({ id, ...changes }) => update(db, table, id, changes, `update_${table}`),
    }),
  ];
}
