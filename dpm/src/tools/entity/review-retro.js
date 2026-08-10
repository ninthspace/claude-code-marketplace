/**
 * The rows a review, a retro and an audit are made of.
 *
 * **`observation` is the one with behaviour rather than columns.** `006-review-retro.sql` records
 * why its parentage is inclusive: an earlier draft had `CHECK ((retro_id IS NULL) <> (story_id IS
 * NULL))`, which makes the act of gathering a story-level observation into a retro *destroy* its
 * story link, because the only way to satisfy the constraint is to clear `story_id`. The origin
 * and the grouping are different facts and both survive. The update tool holds to that by writing
 * only the columns a call actually names — so setting `retro_id` cannot clear `story_id`, and the
 * story's second acceptance criterion is a property of how updates are built rather than a rule
 * this handler remembers.
 *
 * **The `*_kind` and `*_domain` companions are never caller arguments.** Each exists so a
 * reference cannot point at the wrong sort of thing — a severity where a category belongs, a spec
 * where a retro belongs — and taking it as an argument would let the caller assert exactly what
 * the column was added to check. Where the schema gives one a default it is left to the database;
 * where it does not, because the reference is optional, it is derived from the id beside it.
 */

import { SUPPLIED } from '../convention.js';
import { entityTools } from '../entity.js';

/** `finding.status`'s `CHECK` set, copied by hand from `006-review-retro.sql`. */
const FINDING_STATUS = ['open', 'accepted', 'rejected', 'remediated'];

/** `retro_application.disposition`'s `CHECK` set, likewise. */
const DISPOSITION = ['applied', 'not_applicable', 'deferred'];

/**
 * @param {object} context
 * @returns {object[]}
 */
export function reviewRetroTools(context) {
  return [
    ...entityTools(context, {
      table: 'finding',
      noun: 'one finding of a review',
      fields: {
        review_id: { type: 'string', minLength: 1 },
        position: { type: 'integer', minimum: 0, description: 'projection order within the review' },
        agent: { type: 'string', minLength: 1, description: 'a seeded agent.name; not every finding is attributed' },
        category_id: { type: 'string', minLength: 1, description: "a taxonomy row in the 'finding' domain" },
        severity_id: { type: 'string', minLength: 1, description: "a taxonomy row in the 'severity' domain" },
        summary: { type: 'string', minLength: 1 },
        status: { type: 'string', enum: FINDING_STATUS, default: 'open' },
        // Closes a loop CPM leaves open: which findings were actually acted on becomes a query.
        remediation_task_id: { type: 'string', minLength: 1 },
      },
      required: ['review_id', 'position', 'category_id', 'severity_id', 'summary'],
      mutable: ['position', 'agent', 'category_id', 'severity_id', 'summary', 'status',
        'remediation_task_id'],
      body: ['summary'],
    }),

    ...entityTools(context, {
      table: 'observation',
      noun: 'one retro observation',
      fields: {
        retro_id: { type: 'string', minLength: 1, description: 'the grouping; set when the retro is written' },
        story_id: { type: 'string', minLength: 1, description: 'the origin; survives promotion into a retro' },
        quick_id: { type: 'string', minLength: 1, description: 'the origin, on the quick path; survives promotion into a retro' },
        position: { type: 'integer', minimum: 0 },
        text: { type: 'string', minLength: 1 },
        synthesis: { type: 'string', description: 'written when grouped into a retro' },
        note: { type: 'string', description: 'qualifiers, caveats, scope' },
        library_doc_id: { type: 'string', minLength: 1, description: 'set on promotion' },
        retired_at: { type: 'string', description: 'ISO 8601; set with retired_reason or not at all' },
        retired_reason: { type: 'string' },
      },
      // Only `text` is required. Which of `retro_id`, `story_id` and `quick_id` must be present is
      // a `CHECK`, and restating it here would be a second copy of a rule the database already
      // holds.
      required: ['text'],
      mutable: ['retro_id', 'story_id', 'quick_id', 'position', 'text', 'synthesis', 'note',
        'library_doc_id', 'retired_at', 'retired_reason'],
      body: ['text', 'synthesis'],
      supplied: {
        retro_kind: SUPPLIED.derived('retro_id'),
        quick_kind: SUPPLIED.derived('quick_id'),
        library_doc_kind: SUPPLIED.derived('library_doc_id'),
      },
      derive: (args) => ({
        retro_kind: args.retro_id === undefined ? null : 'retro',
        quick_kind: args.quick_id === undefined ? null : 'quick',
        library_doc_kind: args.library_doc_id === undefined ? null : 'library',
      }),
    }),

    ...entityTools(context, {
      table: 'audit_finding',
      noun: 'one finding of an audit, pinned to a file',
      fields: {
        audit_id: { type: 'string', minLength: 1 },
        position: { type: 'integer', minimum: 0 },
        dimension_id: { type: 'string', minLength: 1, description: "a taxonomy row in the 'audit_dimension' domain" },
        file: { type: 'string', minLength: 1 },
        line: { type: 'integer', minimum: 1 },
        symbol: { type: 'string' },
        severity_id: { type: 'string', minLength: 1 },
        summary: { type: 'string', minLength: 1, description: 'what is wrong, in one sentence' },
        recommendation: {
          type: 'string',
          description: 'the scoped change that would fix it, where one is known',
        },
      },

      // **`summary` is required here and merely defaulted in the schema**, and the two are not in
      // conflict. `ALTER TABLE … ADD COLUMN` takes no `NOT NULL` without a default, so the column
      // could not be made unwritable-by-omission the way `finding.summary` is. Requiring it at the
      // tool is what closes that gap for every caller that goes through the surface, which is all
      // of them bar a restore.
      required: ['audit_id', 'position', 'dimension_id', 'file', 'severity_id', 'summary'],
      mutable: ['position', 'dimension_id', 'file', 'line', 'symbol', 'severity_id', 'summary',
        'recommendation'],
      body: ['summary', 'recommendation'],
    }),

    ...entityTools(context, {
      table: 'retro_application',
      noun: "the record that a retro's lesson was applied to one artefact",
      fields: {
        retro_id: { type: 'string', minLength: 1 },
        // Deliberately not kind-pinned: a lesson may be applied to a document of any kind.
        applied_to_id: { type: 'string', minLength: 1 },
        theme: { type: 'string', description: 'the observation category, where the record names one' },
        disposition: { type: 'string', enum: DISPOSITION },
        note: { type: 'string', description: 'the how, the reason or the why' },
      },
      required: ['retro_id', 'applied_to_id', 'disposition'],
      mutable: ['theme', 'disposition', 'note'],
      body: ['note'],
    }),
  ];
}
