/**
 * The `coverage_matrix` template (FR10, FR21).
 *
 * The last of the parity list's nine projectable non-document types renders here: `coverage`, one
 * row per matrix row, carrying the verification record — `verified_at` and the `binding_hash` it
 * was verified against. The ✓ column is that pair rendered, and FR21's decay is what empties it.
 *
 * **The hash is not projected, and the ✓ is.** A hash in a committed file is bytes no reader can
 * check and that change on every re-verification, which is diff noise standing in for information.
 * What a reader needs is whether the row is verified *against the text beside it*, and the schema
 * guarantees that: the trigger clears `verified_at` when either side of the binding is edited, so
 * a ✓ next to a fragment means the ✓ was earned by that fragment.
 *
 * `coverageFor` explains why the rows are reached through the epic's spec rather than through the
 * matrix — there is no column joining a matrix to a coverage row, and the long way round is the
 * only one that cannot render another epic's rows.
 */

import { resolve } from '../markers.js';
import { coverageFor } from '../load.js';
import { heading, table } from '../text.js';
import { document, sections } from './common.js';
import { polarity } from './spec.js';

/**
 * Render one coverage matrix to markdown.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} tree From `loadDocument`.
 * @param {Map<string, string>} identifiers
 * @param {string} where
 * @returns {string}
 */
export function renderCoverageMatrix(db, tree, identifiers, where) {
  const ref = (text) => resolve(text, identifiers, where);
  const [epic, spec] = tree.ancestry;

  // A matrix whose ancestry is incomplete has no rows to find rather than no rows to render, and
  // those are different states. `loadDocument` supplies the chain; a matrix that reached here
  // without an epic and a spec above it would be a parentage the seed forbids.
  const rows = epic && spec ? coverageFor(db, epic, spec) : [];

  return document(tree, ref, identifiers, [
    ...sections(tree.sections, ref),

    ...(rows.length > 0 ? [
      heading(2, 'Coverage'),
      table(
        ['#', 'Requirement', 'Spec Text', 'Story Criterion', 'Covered by', 'Test Approach', 'Verified'],
        rows.map((row, index) => {
          // **A withdrawn binding renders and says so.** AD 04-01 has a binding leave the live set
          // by retirement and never by deletion, so that the record it once existed survives — and
          // a projection that dropped the row would be the deletion that decision refused, in the
          // one copy a reader actually opens. `artifacts.js` and `retro.js` make the same choice
          // for the same column, which is why `coverage` sets no `live` in `COLLECTIONS`.
          //
          // **The ✓ is replaced rather than read off `verified_at`.** Retiring a binding does not
          // clear that column — none of the `requirement_unclaim_*` triggers fires on `retired_at`,
          // as `025-coverage-retirement.sql` says outright — so a withdrawn row can still carry a
          // verification, and this is the cell a reader consults to decide whether the row counts.
          const withdrawn = row.retired_at !== null;
          const strike = (text) => (withdrawn ? `~~${text}~~` : text);

          return [
            index + 1,
            row.requirement.label,
            strike(ref(row.spec_fragment)),
            strike(`${polarity(row.criterion)}${ref(row.criterion.text)}`),
            row.stories.map((story) => `Story ${story.number}`).join(', '),
            row.criterion.approaches.map((tag) => `\`[${tag}]\``).join(' '),
            withdrawn
              ? `**Withdrawn ${row.retired_at}** — ${ref(row.retired_reason)}`
              : (row.verified_at === null ? '' : '✓'),
          ];
        }),
      ),
    ] : []),
  ]);
}
