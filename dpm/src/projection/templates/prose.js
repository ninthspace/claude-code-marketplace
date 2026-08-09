/**
 * The four kinds whose whole structure is narrative sections (FR10).
 *
 * `problem_brief`, `product_brief`, `discussion` and `runbook` have no detail table and no child
 * table of their own. AD7's rule is that structure earns a table by being queried, and nothing
 * queries a brief's sections by anything but their order — so `document_section` is the entire
 * shape, and a template that invented headings for them would be projecting a structure the
 * database does not hold.
 *
 * **Four registry entries, one function, and that is not the fallback FR10 forbids.** The must-NOT
 * is about reachability: a kind with no entry must fail, not land somewhere generic. Each of these
 * four names this function explicitly, so a fourteenth kind seeded tomorrow reaches nothing. What
 * makes the difference checkable rather than a claim is that the registry is enumerated against
 * `document_kind` — an unlisted kind has no entry to share.
 *
 * Three of the four may parent an ADR; `runbook` may not. `adrSection` is called for all four
 * anyway, because it renders what `children` holds and the parentage allow-list is what decides
 * whether that is ever non-empty. A template asking a second time would be a second place for the
 * two to disagree.
 */

import { resolve } from '../markers.js';
import { adrSection } from './adr.js';
import { document, sections } from './common.js';

/**
 * Render a section-only document to markdown.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} tree From `loadDocument`.
 * @param {Map<string, string>} identifiers
 * @param {string} where
 * @returns {string}
 */
export function renderProse(db, tree, identifiers, where) {
  const ref = (text) => resolve(text, identifiers, where);

  return document(tree, ref, identifiers, [
    ...sections(tree.sections, ref),
    ...adrSection(db, tree, ref),
  ]);
}
