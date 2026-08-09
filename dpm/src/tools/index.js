/**
 * The spine registry — eight entity types, create, read, update and list for each.
 *
 * **Eight rather than the seven Story 2's criterion enumerates**, and the extra one is
 * deliberate. `acceptance_criterion` is named by the story's third criterion, it is the spec-side
 * twin of `story_criterion` with the same `polarity` column, and `coverage` — which *is* one of
 * the seven — cannot bind anything without both sides existing. Tooling one criterion table and
 * not the other would have left the join reachable from one end only.
 *
 * `document` carries two of the eight, `spec` and `epic`, because they are one table
 * distinguished by `kind`. That is why the count of tools is not the count of tables, and why
 * anything asserting either derives it from this list rather than restating a number.
 *
 * The remaining tables — the sixteen without tools here — are Epic 47-05's. Story 5's
 * reachability assertion reads each tool's `reads`, so what is covered and what is not is a
 * property of this registry rather than of a list kept beside it.
 */

import { ulid } from '../id/ulid.js';
import { ToolError } from './convention.js';
import { dependencyTools } from './cross/dependency.js';
import { integrityTools } from './cross/integrity.js';
import { numberingTools } from './cross/numbering.js';
import { listTools } from './list.js';
import { sessionTools } from './session.js';
import { coverageTools } from './spine/coverage.js';
import { criterionTools } from './spine/criterion.js';
import { deliveryTools } from './spine/delivery.js';
import { documentTools } from './spine/document.js';
import { requirementTools } from './spine/requirement.js';

/**
 * Build every spine tool against one database.
 *
 * `now` and `newId` are injected rather than reached for, so a test can pin a timestamp and read
 * back exactly what it wrote. The dump work in Epic 47-02 needed a normalisation rule for one
 * machine-local timestamp it could not pin; there is no reason to create more of them here.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} [options]
 * @param {() => string} [options.now] ISO 8601.
 * @param {() => string} [options.newId]
 * @returns {object[]} Every tool, in a stable order.
 */
/**
 * The same registry with every write refused, for a database this server is too old for.
 *
 * **The write tools stay listed rather than being dropped.** Withholding them would answer a
 * create call with *Method not found*, which is what a caller sees when a server is broken or a
 * tool was renamed — and would tell them nothing about the version skew that is the actual
 * reason. Listed and refusing, the refusal names both versions and the caller knows to update
 * the plugin. NFR7's clause is that a user is not locked out of their own planning history; a
 * lockout with a misleading error is the worst of the available outcomes, not a safe default.
 *
 * @param {object[]} tools
 * @param {{found: number, supported: number}} version
 * @returns {object[]}
 */
export function readOnlyTools(tools, { found, supported }) {
  return tools.map((tool) => (tool.mutates
    ? Object.freeze({
      ...tool,
      handler: () => {
        throw new ToolError(
          `${tool.name}: this database is at schema version ${found} and this server understands `
          + `up to ${supported}. Reads are answered; writes are refused until the plugin is `
          + 'updated, so an older release cannot write rows a newer schema constrains.',
        );
      },
    })
    : tool));
}

export function spineTools(db, { now = () => new Date().toISOString(), newId = ulid } = {}) {
  const context = { db, now, newId };

  const spine = [
    ...documentTools(context, { kind: 'spec', child: false }),
    ...documentTools(context, { kind: 'epic', child: true }),
    ...requirementTools(context),
    ...criterionTools(context, {
      table: 'acceptance_criterion', parent: 'requirement_id', owner: 'requirement',
    }),
    ...criterionTools(context, {
      table: 'story_criterion', parent: 'story_id', owner: 'story',
    }),
    ...deliveryTools(context, { table: 'story', parent: 'epic_id' }),
    ...deliveryTools(context, {
      table: 'task',
      parent: 'story_id',
      extra: { description: { type: 'string' } },
    }),
    ...coverageTools(context),
  ];

  return [
    ...spine,

    // Built from the spine rather than beside it: each list tool takes its body columns from the
    // read tool of the same type, so the two cannot answer the same question differently.
    ...listTools(context, spine),

    // FR11's table. It sits here rather than in Epic 47-05 — where the parity enumeration counts
    // it — because session lifecycle is a server concern every skill needs from the first
    // conversion. The epic's Notes carry the reasoning.
    ...sessionTools(context),

    // The three that belong to no single entity: a number, an edge, and the sweep over both.
    ...numberingTools(context),
    ...dependencyTools(context),
    ...integrityTools(context),
  ];
}
