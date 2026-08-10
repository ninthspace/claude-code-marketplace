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
 * enforces and this tool does not duplicate. What these tools do add is that the pair can only be
 * set *correctly*: `verified_at` is the caller's, `binding_hash` is computed from the row's own two
 * texts by `src/coverage/binding.js` and is not an argument at all. A hash chosen by the party
 * making the claim attests to nothing, and the `CHECK` would have accepted any string — so a
 * skill writing a ✓ says when, and the server says over what.
 */

import { defineTool, SUPPLIED } from '../convention.js';
import { bindingHash } from '../../coverage/binding.js';
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
  verified_at: {
    type: 'string',
    description: 'ISO 8601. Records the ✓; the server computes the binding hash that accompanies it',
  },
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
      name: 'create_coverage',
      table: 'coverage',
      description: 'Bind a requirement fragment to a story criterion. One matrix row.',
      reads: ['coverage'],
      mutates: true,
      serverSupplied: { id: SUPPLIED.ulid, binding_hash: SUPPLIED.derived('the bound texts') },
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
        // Computed from the arguments rather than read back, because the row is not there yet —
        // and the criterion is, which is the half that has to be looked up either way. Nullish,
        // so a row created explicitly unverified gets no hash: a `binding_hash` beside a NULL
        // `verified_at` is a binding recorded for a verification that was never made, which is
        // the state FR21's decay triggers exist to prevent arising the other way round.
        binding_hash: args.verified_at == null ? null : bindingHash(db, args),
      }, 'create_coverage'),
    }),

    defineTool({
      name: 'read_coverage',
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
      handler: (args) => readById(db, 'coverage', args.id, 'read_coverage'),
    }),

    defineTool({
      name: 'update_coverage',
      table: 'coverage',
      description: "Update a coverage row's position, or record its verification.",
      reads: ['coverage'],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...STATE },
        required: ['id'],
      },
      // The mark and its binding move together, in all three of the states a caller can now
      // express. Omitting `verified_at` leaves both alone. Supplying one hashes off the **stored**
      // row rather than off anything the caller holds: a verification is a statement about the
      // texts as they are now, and a caller working from a copy read earlier would otherwise stamp
      // a hash over text that has since moved. Clearing it clears the hash with it — a binding
      // left behind by an unverification is the stale mark of a verification nobody made.
      handler: ({ id, ...changes }) => {
        if (changes.verified_at === undefined) {
          return update(db, 'coverage', id, changes, 'update_coverage');
        }

        const binding = changes.verified_at === null
          ? null
          : bindingHash(db, readById(db, 'coverage', id, 'update_coverage'));

        return update(db, 'coverage', id, { ...changes, binding_hash: binding }, 'update_coverage');
      },
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
