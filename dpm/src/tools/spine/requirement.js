/**
 * `requirement` — the table where FR4 stops being a spelling convention.
 *
 * **`class` is a required argument and `label` is never read to determine one.** That is this
 * story's must-NOT, and it is worth being precise about what it forbids, because the tempting
 * version looks helpful: a create tool that saw `NFR3` and filled in `non_functional`, or saw
 * `ENVX2` and chose `environmental_restriction`, would spare every caller an argument and would
 * be right almost always. It is the "almost" that the schema exists to remove — four shell
 * parsers in the corpus this replaces derived class, band and exclusion from label text, and the
 * whole of `003-requirements.sql` is the answer to what that cost. A tool that inferred here
 * would reintroduce the parser one layer up, where no `CHECK` can see it.
 *
 * So `label` is written verbatim, read back verbatim, and consulted for nothing. Nothing in this
 * file branches on its contents, and the test for that is not "the code has no regex" but that a
 * requirement labelled `NFR3` and classed `functional` stores and returns `functional`.
 */

import { ToolError, defineTool, SUPPLIED } from '../convention.js';
import { claimComplete } from '../../coverage/claim.js';
import { insert, readById, update } from '../crud.js';

/** Copied by hand from `003-requirements.sql`. Story 7 asserts each against `PRAGMA`. */
const CLASS = ['functional', 'non_functional',
  'environmental_requirement', 'environmental_restriction'];
const MOSCOW = ['must', 'should', 'could', 'wont'];
const EXCLUSION = ['deferred', 'out_of_scope'];

/** Everything a caller may set or change. `spec_id` is identity and is not among them. */
const FIELDS = {
  label: { type: 'string', minLength: 1, description: 'Display only: FR1, NFR3, ENVX2' },
  class: { type: 'string', enum: CLASS, description: 'Never inferred from label' },
  moscow: { type: 'string', enum: MOSCOW },
  exclusion: { type: 'string', enum: EXCLUSION },
  parent_id: { type: 'string', minLength: 1, description: "FR1a's parent is FR1" },
  text: { type: 'string', minLength: 1 },
  position: { type: 'integer', minimum: 0 },
};

/**
 * FR26's completeness claim, offered on update and not on create.
 *
 * A requirement is never born claimed — there is nothing bound to it yet — so putting this in
 * `FIELDS` would give `create_requirement` an argument whose only honest value is absent.
 *
 * `coverage_claim_hash` is not here for the reason `binding_hash` is not on the coverage tools:
 * it is computed by `claimHash` over the bound fragment set, and a digest supplied by the party
 * making the claim records nothing.
 */
const CLAIM = {
  coverage_claimed_at: {
    type: 'string',
    description: 'ISO 8601. Claims the bound coverage rows account for this requirement whole; '
      + 'the server computes the hash over the bound set that accompanies it',
  },
};

/**
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.newId
 * @returns {object[]}
 */
/**
 * Refuse a requirement ruled out of the iteration with nothing recorded to rule it out (FR6).
 *
 * **The obligation falls on `wont` alone.** A requirement at any other priority is in the iteration
 * or waiting to be, and has nothing to explain; one at `wont` is being set aside, and the exclusion
 * is the whole of what distinguishes a decision from an omission. A row saying only *not this time*
 * reads afterwards as a requirement somebody forgot.
 *
 * **Judged on the row the write would leave, which is why both callers resolve first.** An update
 * naming only the priority is judged against the exclusion already stored, so a row that records
 * its reason is not refused for failing to repeat it; an update clearing the exclusion off a `wont`
 * row is refused, because an explicit `null` is a value and it leaves exactly the state this
 * forbids. Neither reading is available from the arguments alone.
 *
 * @param {object} row The requirement as the write would leave it.
 * @param {string} where The tool name, for the message's prefix.
 * @throws {ToolError} When the row would be ruled out with no exclusion.
 */
function refuseUnexplainedExclusion(row, where) {
  if (row.moscow !== 'wont' || row.exclusion) return;

  throw new ToolError(
    `${where}: ${row.label ?? 'a requirement'} is ruled out of the iteration and records nothing `
    + `that rules it out — set exclusion to one of ${EXCLUSION.join(' or ')}, or leave the `
    + 'priority at must, should or could',
  );
}

export function requirementTools({ db, newId }) {
  return [
    defineTool({
      name: 'create_requirement',
      table: 'requirement',
      description: 'Create a requirement. `class` is required and is never inferred from `label`.',
      reads: ['requirement'],
      mutates: true,
      serverSupplied: { id: SUPPLIED.ulid },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { spec_id: { type: 'string', minLength: 1 }, ...FIELDS },
        // `class` sits here, beside `label`, and that adjacency is the whole point: a caller
        // supplying one without the other is refused rather than helped.
        required: ['spec_id', 'label', 'class', 'text', 'position'],
      },
      handler: (args) => {
        const row = {
          id: newId(),
          spec_id: args.spec_id,
          label: args.label,
          class: args.class,
          moscow: args.moscow ?? null,
          exclusion: args.exclusion ?? null,
          parent_id: args.parent_id ?? null,
          text: args.text,
          position: args.position,
        };

        // FR6, on the first of the two paths that can reach the state. The row is assembled before
        // it is judged rather than the arguments being read, so this and the update below ask the
        // same question of the same shape.
        refuseUnexplainedExclusion(row, 'create_requirement');

        return insert(db, 'requirement', row, 'create_requirement');
      },
    }),

    defineTool({
      name: 'read_requirement',
      table: 'requirement',
      description: 'Read one requirement by id, with its class, band and exclusion as columns.',
      reads: ['requirement'],
      mutates: false,
      // What Story 4's bound withholds unless asked. Declared here so that story is a filter
      // over this shape rather than a change to it.
      body: ['text'],
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 } },
        required: ['id'],
      },
      handler: (args) => readById(db, 'requirement', args.id, 'read_requirement'),
    }),

    defineTool({
      name: 'update_requirement',
      table: 'requirement',
      description: "Update a requirement's label, class, band, exclusion, text or position, "
        + 'or claim that the coverage rows bound to it account for it whole.',
      reads: ['requirement'],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...FIELDS, ...CLAIM },
        required: ['id'],
      },
      handler: ({ id, coverage_claimed_at: claimedAt, ...changes }) => {
        // FR6's second path. Resolved against the stored row, so an update naming only the priority
        // is judged on the exclusion the row already carries — and one clearing that exclusion off
        // a `wont` row is refused, since an explicit null leaves the forbidden state just as an
        // omission at create would.
        if ('moscow' in changes || 'exclusion' in changes) {
          refuseUnexplainedExclusion(
            { ...readById(db, 'requirement', id, 'update_requirement'), ...changes },
            'update_requirement',
          );
        }

        if (Object.keys(changes).length > 0) update(db, 'requirement', id, changes, 'update_requirement');
        else if (claimedAt === undefined) throw new ToolError('update_requirement: nothing to update');
        // A claim against a requirement that is not there is a boundary rejection like any other,
        // and `claimComplete` raises an internal error rather than one — so the row is reached
        // for here, where the failure has the shape FR3 asks for.
        else readById(db, 'requirement', id, 'update_requirement');

        // After the edits and never before: `requirement_unclaim_on_text_edit` would clear a claim
        // written first, and the claim is about the set as it stands when this call is finished.
        if (claimedAt !== undefined) claimComplete(db, id, claimedAt);

        return readById(db, 'requirement', id, 'update_requirement');
      },
    }),
  ];
}
