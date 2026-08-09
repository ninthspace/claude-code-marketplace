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

import { defineTool, SUPPLIED } from '../convention.js';
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
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.newId
 * @returns {object[]}
 */
export function requirementTools({ db, newId }) {
  return [
    defineTool({
      name: 'dpm_create_requirement',
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
      handler: (args) => insert(db, 'requirement', {
        id: newId(),
        spec_id: args.spec_id,
        label: args.label,
        class: args.class,
        moscow: args.moscow ?? null,
        exclusion: args.exclusion ?? null,
        parent_id: args.parent_id ?? null,
        text: args.text,
        position: args.position,
      }, 'dpm_create_requirement'),
    }),

    defineTool({
      name: 'dpm_read_requirement',
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
      handler: (args) => readById(db, 'requirement', args.id, 'dpm_read_requirement'),
    }),

    defineTool({
      name: 'dpm_update_requirement',
      table: 'requirement',
      description: "Update a requirement's label, class, band, exclusion, text or position.",
      reads: ['requirement'],
      mutates: true,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...FIELDS },
        required: ['id'],
      },
      handler: ({ id, ...changes }) =>
        update(db, 'requirement', id, changes, 'dpm_update_requirement'),
    }),
  ];
}
