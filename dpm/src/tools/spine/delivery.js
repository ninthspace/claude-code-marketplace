/**
 * `story` and `task` — a numbered child of something, one factory.
 *
 * Both carry a parent, a number unique within it, a title, a status with its free-text note, and
 * a position. A task adds a description. That is a parameter's worth of difference, and the same
 * argument applies as for the criterion pair: two hand-written copies of these statements are two
 * places for the status `CHECK` set to drift from `004-delivery.sql`.
 *
 * **`number` is a required argument here, and that is not an inconsistency with `document`.** A
 * spec's or an epic's number comes from `number_sequence` because FR5 promises those are never
 * reused across the whole project, including after archival — they end up in filenames and in
 * every cross-reference. A story's number is ordinal within its epic: Story 3 is the third story
 * of that epic and means nothing outside it, `UNIQUE (epic_id, number)` is the whole of the
 * guarantee, and renumbering after a story is dropped is a normal editorial act rather than the
 * broken-reference disaster FR5 exists to prevent. Allocating these would make that impossible.
 */

import { defineTool, SUPPLIED } from '../convention.js';
import { insert, readById, update } from '../crud.js';

/** Copied by hand from `020-status-lifecycle.sql`; both tables declare the same set as `document`. */
const STATUS = ['pending', 'complete', 'superseded', 'withdrawn'];

/**
 * Build create, read and update for one delivery table.
 *
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.newId
 * @param {object} options
 * @param {string} options.table `story` or `task`.
 * @param {string} options.parent The column naming its owner — `epic_id` or `story_id`.
 * @param {object} [options.extra] Columns this table has and the other does not.
 * @param {(row: object, where: string) => void} [options.closing] A condition this table puts on
 *   being finished, called before the write when a call sets `status: 'complete'` and refusing by
 *   throwing. **A table that passes none behaves exactly as it does today**, which is the contract
 *   `task` is held to — the option is a seam rather than a condition written into the factory,
 *   because both tables are built here and only one of them has anything to say about closing.
 * @returns {object[]}
 */
export function deliveryTools({ db, newId }, { table, parent, extra = {}, closing = null }) {
  const fields = {
    number: { type: 'integer', minimum: 1, description: `ordinal within its ${parent}` },
    title: { type: 'string', minLength: 1 },
    status: { type: 'string', enum: STATUS, default: 'pending' },
    status_note: { type: 'string' },
    position: { type: 'integer', minimum: 0 },
    ...extra,
  };

  const columns = Object.keys(fields);

  return [
    defineTool({
      name: `create_${table}`,
      table,
      description: `Create a ${table} under its ${parent.replace('_id', '')}.`,
      reads: [table],
      mutates: true,
      serverSupplied: { id: SUPPLIED.ulid },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { [parent]: { type: 'string', minLength: 1 }, ...fields },
        required: [parent, 'number', 'title', 'position'],
      },
      handler: (args) => insert(db, table, {
        id: newId(),
        [parent]: args[parent],
        // Every optional column written explicitly rather than omitted, so what the row holds is
        // decided here rather than by which keys happened to be present. A field declaring a
        // `default` supplies it; the rest fall to NULL. `status` used to be a line of its own and
        // is now the general case, which is what stops a second `NOT NULL` column arriving with a
        // default nothing applies — the shape of this handler is what would have written NULL.
        ...Object.fromEntries(columns.map((column) =>
          [column, args[column] ?? fields[column].default ?? null])),
      }, `create_${table}`),
    }),

    defineTool({
      name: `read_${table}`,
      table,
      description: `Read one ${table} by id.`,
      reads: [table],
      mutates: false,
      body: 'description' in extra ? ['description'] : [],
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
      description: `Update a ${table}'s number, title, status or position.`,
      reads: [table],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...fields },
        required: ['id'],
      },
      handler: ({ id, ...changes }) => {
        // **Only a call that sets `complete` is asked, and only where the table offered a
        // condition.** The other two terminal values say the work was superseded or withdrawn —
        // decisions to stop rather than claims to have finished — so refusing them would block the
        // legitimate way to retire a row with work still under it.
        if (closing && changes.status === 'complete') {
          // **The resolved row, not the arguments.** A caller setting only `status` is judged on
          // the state the edit would leave, which is what lets a condition be satisfied by a column
          // already stored rather than one restated in the closing call. Judging the arguments
          // would refuse a row for failing to repeat what it already says.
          closing({ ...readById(db, table, id, `update_${table}`), ...changes }, `update_${table}`);
        }

        return update(db, table, id, changes, `update_${table}`);
      },
    }),
  ];
}
