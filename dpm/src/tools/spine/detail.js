/**
 * AD7's four structured kinds — the detail their documents carry, and the rows beneath it.
 *
 * Four of the thirteen document kinds hold structure that `document_section` would flatten into
 * prose: an ADR's decision status and its options against shared axes, a review's scope, a quick
 * record's close, a library document's machine-read `doc_type`. Each detail table's primary key
 * **is** its document's, which is what makes the one-to-one structural rather than a rule someone
 * has to maintain.
 *
 * **The detail row is created by the document's own tool, not by a second call.** `adr.decision`
 * and `library_document.doc_type` are `NOT NULL`, so a document of one of these kinds without its
 * detail row is a half-made artefact — legal by every constraint in the schema, and unreadable by
 * anything that expects the pair. `documentTools` writes both in one transaction; what these
 * descriptors supply is the arguments and the mapping. The child tables below are ordinary rows
 * with their own tools, because there may be any number of them or none.
 */

import { entityTools } from '../entity.js';

/** `adr.decision_status`'s `CHECK` set, copied by hand from `002-detail.sql`. */
const DECISION_STATUS = ['proposed', 'accepted', 'rejected', 'superseded', 'deprecated'];

/** `review.scope`'s `CHECK` set, likewise. */
const REVIEW_SCOPE = ['whole', 'story'];

/**
 * The detail each of the four kinds carries, as `documentTools` takes it.
 *
 * `row` maps validated arguments to detail columns and is the only place the defaults are
 * applied: `defineTool` advertises a `default` rather than materialising it, for the reason
 * `convention.js` sets out, so the fallback has to be written where the row is built.
 */
export const DETAIL = {
  adr: {
    table: 'adr',
    fields: {
      decision_status: { type: 'string', enum: DECISION_STATUS, default: 'proposed' },
      decision: {
        type: 'string',
        minLength: 1,
        description: 'The decision itself, in one sentence — the ADR\'s reason for existing',
      },
    },
    required: ['decision'],
    row: (args) => ({
      decision_status: args.decision_status ?? 'proposed',
      decision: args.decision,
    }),
  },

  review: {
    table: 'review',
    fields: {
      scope: { type: 'string', enum: REVIEW_SCOPE, default: 'whole' },
      scope_story_id: {
        type: 'string',
        minLength: 1,
        description: "Required when scope is 'story', and refused otherwise",
      },
    },
    required: [],
    // What was reviewed is `document.parent_id`; only the narrowing lives here. The paired `CHECK`
    // is left to the database rather than restated: a second copy of it here would be the AD10
    // hazard one layer up, and its refusal already names the column.
    row: (args) => ({
      scope: args.scope ?? 'whole',
      scope_story_id: args.scope_story_id ?? null,
    }),
  },

  quick: {
    table: 'quick',
    fields: {
      closed_at: { type: 'string', description: 'ISO 8601; NULL while the record is open' },
    },
    required: [],
    row: (args) => ({ closed_at: args.closed_at ?? null }),
  },

  library: {
    table: 'library_document',
    fields: {
      doc_type: {
        type: 'string',
        minLength: 1,
        description: "'architecture', 'coding-standards', 'domain' — what the Library Check reads",
      },
    },
    required: ['doc_type'],
    row: (args) => ({ doc_type: args.doc_type }),
  },
};

/**
 * The rows beneath the detail: an ADR's options and their tradeoffs, a review's agents, a quick
 * record's criteria, a library document's scopes.
 *
 * @param {object} context
 * @returns {object[]}
 */
export function detailChildTools(context) {
  return [
    ...entityTools(context, {
      table: 'adr_option',
      noun: 'one option an ADR considered',
      fields: {
        adr_id: { type: 'string', minLength: 1, description: 'the ADR this option belongs to' },
        name: { type: 'string', minLength: 1 },
        chosen: { type: 'boolean', default: false, description: 'exactly one option should be' },
        rationale: { type: 'string' },
        position: { type: 'integer', minimum: 0 },
      },
      required: ['adr_id', 'name', 'position'],
      mutable: ['name', 'chosen', 'rationale', 'position'],
      body: ['rationale'],
    }),

    ...entityTools(context, {
      table: 'adr_option_tradeoff',
      noun: "one option's assessment against one axis",
      // The axis is half the identity: Options Considered repeats per option against the *same*
      // axes each time, and that repetition is what makes it a table rather than a paragraph.
      key: ['option_id', 'axis'],
      fields: {
        option_id: { type: 'string', minLength: 1 },
        axis: { type: 'string', minLength: 1, description: "'cost', 'complexity', 'reversibility'" },
        assessment: { type: 'string', minLength: 1 },
      },
      required: ['assessment'],
      body: ['assessment'],
    }),

    ...entityTools(context, {
      table: 'review_agent',
      noun: 'the record that one agent took part in a review',
      key: ['document_id', 'agent'],
      fields: {
        document_id: { type: 'string', minLength: 1, description: 'the review' },
        agent: { type: 'string', minLength: 1, description: 'a seeded agent.name' },
      },
    }),

    ...entityTools(context, {
      table: 'quick_criterion',
      noun: "one of a quick record's criteria",
      fields: {
        quick_id: { type: 'string', minLength: 1 },
        text: { type: 'string', minLength: 1 },
        // Tri-state on purpose: NULL while the record is open, and a decision at close. A status
        // word would have to invent a third value for "not decided yet".
        met: { type: 'boolean', description: 'left unset while the record is open' },
        note: { type: 'string' },
        position: { type: 'integer', minimum: 0 },
      },
      required: ['quick_id', 'text', 'position'],
      mutable: ['text', 'met', 'note', 'position'],
      body: ['text'],
    }),

    ...entityTools(context, {
      table: 'library_scope',
      noun: 'the record that a library document applies to one skill',
      key: ['document_id', 'scope'],
      fields: {
        document_id: { type: 'string', minLength: 1 },
        scope: { type: 'string', minLength: 1, description: "a skill name, or 'all'" },
      },
    }),
  ];
}
