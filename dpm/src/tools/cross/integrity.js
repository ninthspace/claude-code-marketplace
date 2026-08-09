/**
 * `dpm_check_integrity` — FR14's sweep, callable without SQL.
 *
 * The checks are Epic 47-01's: `checkIntegrity` runs the thirteen register entries and the orphan
 * sweep, and this is a boundary over it. What FR14 adds beyond having the checks is that a
 * corrupted state must be *diagnosable* by someone who cannot open a database, and a check nobody
 * can call satisfies neither half of that.
 *
 * **The criterion is "reports every register entry it checks", and the underlying module does
 * not.** `checkIntegrity` returns `violations` filtered to the entries that produced rows, plus
 * `checked` as a count — so an entry that passed appears nowhere, and a caller reading the result
 * cannot tell a register of thirteen entries from one of three that happened to be quiet. The
 * count says how many ran; it does not say which. So the tool adds the roll: every entry by
 * number and invariant, each marked with whether it held. The count is then derivable from the
 * list rather than asserted beside it.
 *
 * That shape is the tool's, not `checkIntegrity`'s — 47-01's module and its tests are untouched.
 *
 * **This response is deliberately unbounded**, and Story 4's `limit` must not be swept onto it. A
 * truncated integrity report is precisely the false pass NFR6 forbids: the rows that fell off the
 * end are indistinguishable from rows that were never there, and the one report whose job is to
 * be trusted becomes the one that can lie by omission.
 */

import { checkIntegrity } from '../../integrity/check.js';
import { REGISTER } from '../../integrity/register.js';
import { defineTool } from '../convention.js';

/**
 * @param {object} context
 * @param {import('node:sqlite').DatabaseSync} context.db
 * @returns {object[]}
 */
export function integrityTools({ db }) {
  return [
    defineTool({
      name: 'dpm_check_integrity',
      // NFR5's rule — every part after the verb is a table name, a column name or a seeded
      // `document_kind.kind` — has no word for a tool that spans tables, and `integrity` is not
      // one. Named for what it does rather than bent to the regex; Story 5 decides whether to
      // widen the rule or rename, and the epic's Notes carry the reasoning.
      table: 'sqlite_schema',
      description:
        'Report orphaned rows and every cross-row invariant in the register, with the rows that '
        + 'locate each violation. Deliberately unbounded.',
      reads: ['sqlite_schema'],
      mutates: false,
      inputSchema: { type: 'object', additionalProperties: false, properties: {} },
      handler: () => {
        const report = checkIntegrity(db);
        const failed = new Map(report.violations.map((violation) => [violation.entry, violation]));

        // Every entry, not only the ones that failed. Derived from `REGISTER` so an entry added
        // to the register appears here without this file being edited — which is the same
        // property the parity test in 47-01 asserts, arriving at the tool boundary for free.
        const entries = REGISTER.map(({ entry, invariant }) => ({
          entry,
          invariant,
          held: !failed.has(entry),
          rows: failed.get(entry)?.rows ?? [],
        }));

        return {
          ok: report.ok,
          // Kept from `checkIntegrity` rather than recomputed, so the two cannot drift about what
          // counts as a check. The orphan sweep is the one that is not a register entry, which is
          // why this is one greater than the list below.
          checked: report.checked,
          entries,
          orphans: report.orphans,
        };
      },
    }),
  ];
}
