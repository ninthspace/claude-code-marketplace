/**
 * `spec` and `epic` — two kinds, one table, one factory.
 *
 * They differ in three things and share everything else: a spec is root-numbered and takes no
 * parent, an epic is child-numbered under its spec, and the tool names say which is which. That
 * is a parameter, not a second module — and it matters beyond tidiness, because `document` is
 * where the composite `(id, kind)` parent key lives, and a second hand-written copy of these
 * statements is a second place for the `numbering`/`number`/`sequence` `CHECK` to be got wrong.
 *
 * **Neither create tool takes a number.** FR5 promises numbers are allocated monotonically and
 * never reused; a tool that accepted one would let a caller hand back a number already issued,
 * and no constraint in the schema would notice — `document_root_number` is unique per kind, but
 * an archived row's number is free again as far as that index is concerned, which is the exact
 * case FR5 names. Allocating from `number_sequence` makes the promise hold by construction
 * rather than by a rule the caller has to know.
 */

import { allocateNumber } from '../../numbering/allocate.js';
import { defineTool, SUPPLIED } from '../convention.js';
import { insert, readById, update } from '../crud.js';

/** `document.status`'s `CHECK` set, copied by hand from `001-identity.sql`. AD10, Story 7. */
const STATUS = ['pending', 'complete'];

/** Columns a caller may change after creation. Identity, kind and numbering are not among them. */
const MUTABLE = {
  title: { type: 'string', minLength: 1 },
  slug: { type: 'string', minLength: 1 },
  status: { type: 'string', enum: STATUS },
  status_note: { type: 'string', description: 'The free-text qualifier a real epic appends' },
  archived_at: { type: 'string', description: 'ISO 8601; orthogonal to status' },
  commit_sha: { type: 'string' },
};

/**
 * Build create, read and update for one document kind.
 *
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @param {() => string} context.now ISO 8601, injected so a test can pin it.
 * @param {() => string} context.newId
 * @param {object} options
 * @param {string} options.kind A seeded `document_kind.kind` — NFR5 reads tool names against it.
 * @param {boolean} options.child Whether the kind is child-numbered, and so takes a parent.
 * @returns {object[]}
 */
export function documentTools({ db, now, newId }, { kind, child }) {
  const create = `dpm_create_${kind}`;
  const read = `dpm_read_${kind}`;
  const modify = `dpm_update_${kind}`;

  const createProperties = {
    slug: { type: 'string', minLength: 1 },
    title: { type: 'string', minLength: 1 },
    status: { type: 'string', enum: STATUS, default: 'pending' },
    status_note: { type: 'string' },
  };

  if (child) {
    createProperties.parent_id = {
      type: 'string',
      minLength: 1,
      description: `the document this ${kind} hangs off`,
    };
  }

  return [
    defineTool({
      name: create,
      table: 'document',
      description: `Create a ${kind}. Its number is allocated, not supplied.`,
      reads: ['document'],
      mutates: true,
      serverSupplied: {
        id: SUPPLIED.ulid,
        kind: SUPPLIED.derived('the tool'),
        numbering: SUPPLIED.derived('document_kind'),
        [child ? 'sequence' : 'number']: SUPPLIED.allocated,
        // A child derives its parent's kind from the parent it names; a root has no parent at
        // all, and both columns are written NULL by this handler. Declared either way, because
        // Story 7 asks every foreign key to be accounted for and "the tool fixes it at NULL" is
        // an account — the alternative is a column nothing in the registry admits to filling.
        ...(child
          ? { parent_kind: SUPPLIED.derived('parent_id') }
          : {
            parent_id: SUPPLIED.derived(`the tool — a ${kind} has no parent`),
            parent_kind: SUPPLIED.derived(`the tool — a ${kind} has no parent`),
          }),
        created_at: SUPPLIED.clock,
        updated_at: SUPPLIED.clock,
      },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: createProperties,
        required: child ? ['parent_id', 'slug', 'title'] : ['slug', 'title'],
      },
      handler: (args) => {
        // Read live rather than held as a constant: `numbering` is denormalised onto `document`
        // and pinned by a composite foreign key to `document_kind`, so the value has to be the
        // one that table holds now, not the one that was true when this was written.
        const numbering = db
          .prepare('SELECT numbering FROM document_kind WHERE kind = ?')
          .get(kind)?.numbering;

        if (!numbering) throw new Error(`${create}: '${kind}' is not a seeded document kind`);

        // Likewise derived, not accepted. `parent_kind` exists so a child cannot claim a parent
        // of the wrong sort; taking it as an argument would let the caller assert the very thing
        // the column was added to check.
        const parentKind = child ? readById(db, 'document', args.parent_id, create).kind : null;
        const stamp = now();

        return insert(db, 'document', {
          id: newId(),
          kind,
          numbering,
          number: child ? null : allocateNumber(db, kind),
          sequence: child ? allocateNumber(db, kind, args.parent_id) : null,
          slug: args.slug,
          title: args.title,
          status: args.status ?? 'pending',
          status_note: args.status_note ?? null,
          parent_id: child ? args.parent_id : null,
          parent_kind: parentKind,
          created_at: stamp,
          updated_at: stamp,
        }, create);
      },
    }),

    defineTool({
      name: read,
      table: 'document',
      description: `Read one ${kind} by id.`,
      reads: ['document'],
      mutates: false,
      // Declared empty rather than omitted: `document` holds a title, a slug and a status note,
      // and none of them is a body. A tool with nothing to withhold says so.
      body: [],
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 } },
        required: ['id'],
      },
      handler: (args) => {
        const row = readById(db, 'document', args.id, read);

        // A read tool named for a kind must not answer for another one, or `dpm_read_spec` would
        // return an epic quite happily and the type in the name would mean nothing.
        if (row.kind !== kind) {
          throw new Error(`${read}: '${args.id}' is a ${row.kind}, not a ${kind}`);
        }

        return row;
      },
    }),

    defineTool({
      name: modify,
      table: 'document',
      description: `Update a ${kind}'s title, slug, status, archival or commit.`,
      reads: ['document'],
      mutates: true,
      serverSupplied: { updated_at: SUPPLIED.clock },
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: { id: { type: 'string', minLength: 1 }, ...MUTABLE },
        required: ['id'],
      },
      handler: ({ id, ...changes }) => update(db, 'document', id, {
        ...changes,
        updated_at: now(),
      }, modify),
    }),
  ];
}
