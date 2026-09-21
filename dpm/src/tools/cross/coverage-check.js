/**
 * `check_coverage` — FR5's report, callable without SQL and without a page read per requirement.
 *
 * A boundary over `src/coverage/report.js`, the way `check_integrity` is a boundary over
 * `checkIntegrity`. The computation is there; what this adds is a tool a skill can call.
 *
 * **A tool of its own rather than a field on `check_integrity`** (decision 05-02, accepted).
 * Integrity asks whether the rows hold and takes no scope; coverage asks what the rows say and
 * takes a spec. Folding the second into the first would put a per-spec argument on a tool half its
 * callers ask an unscoped question of, and make every integrity call pay for a coverage sweep it
 * did not want.
 *
 * **`table: 'coverage'` is a finding rather than a guess.** `naming.test.js` requires the part of a
 * tool name after the verb to be a word the live schema holds, and exempts tools whose declared
 * table is not an authored table — pinning that exemption to `check_integrity`, `publish` and
 * `search`, with a comment saying a fourth entry is a decision rather than a detail.
 * `check_integrity` is in it because *integrity* is not a word the schema has. *coverage* is one,
 * so this tool takes no exemption and the pinned list is untouched. Every name in `reads` is a live
 * table for the reachability assertion in the same file.
 *
 * **The response is unbounded, and Story 4's `limit` must not be swept onto it** — the same rule
 * `check_integrity` states and for the same reason. A truncated gap list is worse than no gap list:
 * the criteria that fell off the end read exactly like criteria that were never unaccounted for.
 */

import { coverageReport } from '../../coverage/report.js';
import { defineTool } from '../convention.js';

/**
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @returns {object[]}
 */
export function coverageCheckTools({ db }) {
  return [
    defineTool({
      name: 'check_coverage',
      table: 'coverage',
      description:
        'Report every requirement of a spec with its standing, the story criteria accounted for '
        + 'by nothing, those carrying no approach tag, those serving a must-have requirement, and '
        + 'a block of counts to quote rather than recompute. Deliberately unbounded.',
      reads: ['requirement', 'coverage', 'story_criterion', 'story', 'story_criterion_approach',
        'acceptance_criterion'],
      mutates: false,
      inputSchema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          spec_id: {
            type: 'string',
            minLength: 1,
            description: 'The spec whose requirements and epics are reported on',
          },
          epic_id: {
            type: 'string',
            minLength: 1,
            description: 'One epic under that spec; adds a roll-up of its stories and bindings, '
              + 'and narrows nothing else',
          },
        },
        required: ['spec_id'],
      },
      handler: ({ spec_id: specId, epic_id: epicId }) => coverageReport(db, { specId, epicId }),
    }),
  ];
}
