/**
 * The `audit` template (FR10, FR24).
 *
 * `audit_finding` carries a location — file, optional line, optional symbol — which is the one
 * thing an audit has that a review's finding does not, and the reason the two are separate tables
 * rather than a `finding` with a nullable `file`.
 *
 * The location renders as `path:line` where a line is set, because that form is clickable in the
 * terminal a reader is most likely holding this open in.
 */

import { resolve } from '../markers.js';
import { collection, taxonomyLabel } from '../load.js';
import { heading, table } from '../text.js';
import { document, sections } from './common.js';

/** `src/projection/load.js:42` — the symbol is a separate column and gets its own cell. */
const location = (finding) =>
  (finding.line === null ? finding.file : `${finding.file}:${finding.line}`);

/**
 * Render one audit to markdown.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} tree From `loadDocument`.
 * @param {Map<string, string>} identifiers
 * @param {string} where
 * @returns {string}
 */
export function renderAudit(db, tree, identifiers, where) {
  const ref = (text) => resolve(text, identifiers, where);
  const findings = collection(db, 'auditFindings', tree.document.id);

  return document(tree, ref, identifiers, [
    ...sections(tree.sections, ref),

    ...(findings.length > 0 ? [
      heading(2, 'Findings'),
      table(['#', 'Dimension', 'Severity', 'Location', 'Symbol'],
        findings.map((finding, index) => [
          index + 1,
          taxonomyLabel(db, finding.dimension_id),
          taxonomyLabel(db, finding.severity_id),
          location(finding),
          finding.symbol ?? '',
        ])),
    ] : []),
  ]);
}
