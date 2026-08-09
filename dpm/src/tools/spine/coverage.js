/**
 * `coverage` — one matrix row: a verbatim fragment of a requirement bound to one story criterion.
 *
 * **The natural key is `(requirement_id, spec_fragment, story_criterion_id)`, and `position` is no
 * part of it.** `004-delivery.sql` records what an earlier draft cost by keying on `position`
 * instead of `spec_fragment`: it accepted the same fragment bound to the same criterion twice at
 * two positions — two identical rows, each independently verifiable, each counting toward a
 * roll-up — while rejecting two genuinely different fragments that happened to share a position.
 * The tool inherits that. `position` is an argument because the column is `NOT NULL` with no
 * default, and it is display order; nothing here reads it to decide whether a binding exists.
 *
 * **`verified_at` and `binding_hash` are set together or not at all**, which the table's `CHECK`
 * enforces and this tool does not duplicate. A caller supplying one alone is refused by the
 * database and the refusal is surfaced as a tool error rather than an internal one — the division
 * FR3 draws is between what the tool boundary can know (a value outside an enum, a missing
 * argument) and what only a row in context can (this pair, a foreign key, a duplicate binding).
 */

import { defineTool, SUPPLIED } from '../convention.js';
import { insert, readById, update } from '../crud.js';
import { entityTools } from '../entity.js';

const BINDING = {
  requirement_id: { type: 'string', minLength: 1 },
  spec_fragment: {
    type: 'string',
    minLength: 1,
    description: 'A verbatim fragment of the requirement — part of identity, not a summary',
  },
  story_criterion_id: { type: 'string', minLength: 1 },
};

const STATE = {
  position: { type: 'integer', minimum: 0, description: 'Display order only; not identity' },
  verified_at: { type: 'string', description: 'ISO 8601; set with binding_hash or not at all' },
  binding_hash: { type: 'string', description: 'Hash of (fragment ‖ criterion text) at verification' },
};

/**
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.newId
 * @returns {object[]}
 */
export function coverageTools({ db, newId }) {
  return [
    defineTool({
      name: 'dpm_create_coverage',
      table: 'coverage',
      description: 'Bind a requirement fragment to a story criterion. One matrix row.',
      reads: ['coverage'],
      mutates: true,
      serverSupplied: { id: SUPPLIED.ulid },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { ...BINDING, ...STATE },
        required: ['requirement_id', 'spec_fragment', 'story_criterion_id', 'position'],
      },
      handler: (args) => insert(db, 'coverage', {
        id: newId(),
        requirement_id: args.requirement_id,
        spec_fragment: args.spec_fragment,
        story_criterion_id: args.story_criterion_id,
        position: args.position,
        verified_at: args.verified_at ?? null,
        binding_hash: args.binding_hash ?? null,
      }, 'dpm_create_coverage'),
    }),

    defineTool({
      name: 'dpm_read_coverage',
      table: 'coverage',
      description: 'Read one coverage row by id, with its verification state as columns.',
      reads: ['coverage'],
      mutates: false,
      body: ['spec_fragment'],
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 } },
        required: ['id'],
      },
      handler: (args) => readById(db, 'coverage', args.id, 'dpm_read_coverage'),
    }),

    defineTool({
      name: 'dpm_update_coverage',
      table: 'coverage',
      description: "Update a coverage row's position or verification state.",
      reads: ['coverage'],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...STATE },
        required: ['id'],
      },
      handler: ({ id, ...changes }) => update(db, 'coverage', id, changes, 'dpm_update_coverage'),
    }),

    // "Covered by: Story 2, Story 4" — a criterion may be delivered by more than the story that
    // declares it. Rare (three rows in a 393-artefact corpus) and real, and the reason it is a
    // join rather than a second `story_id` column on `coverage`.
    ...entityTools({ db, newId }, {
      table: 'coverage_story',
      noun: 'the record that a story also delivers a coverage row',
      key: ['coverage_id', 'story_id'],
      fields: {
        coverage_id: { type: 'string', minLength: 1 },
        story_id: { type: 'string', minLength: 1 },
      },
    }),
  ];
}
