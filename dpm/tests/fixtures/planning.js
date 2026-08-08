/**
 * Planning-corpus fixtures, built by calling the tool surface.
 *
 * Every function here is a sequence of `create()` calls in dependency order — the same
 * sequence of tool calls a skill would have made. There is no SQL in this file and no
 * database opened; `fixtureDisciplineBypasses()` fails the suite if that ever stops being
 * true.
 *
 * These fixtures build documents; the kind vocabulary they build against is the seeded one
 * from `src/schema/seeds/`, applied by `openPlanningDatabase`. It used to be a working subset
 * declared here, which was right while Story 1 owned no seed — a test bed that keeps its own
 * vocabulary after one exists is asserting against a corpus dpm does not ship.
 */

import { create } from './tool-surface.js';

/**
 * A root-numbered document — a spec, a review, a library document.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} kind
 * @param {object} [attributes] Overrides, including deliberately illegal ones.
 */
export function rootDocument(db, kind, attributes = {}) {
  return create(db, 'document', { kind, numbering: 'root', number: 1, ...attributes });
}

/**
 * A child-numbered document — an epic under a spec, an ADR inside one.
 *
 * `parent_kind` defaults to the parent's actual kind but is overridable, because the
 * criterion about a `parent_kind` that misdescribes its parent needs to set the two
 * independently.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} kind
 * @param {{id: string, kind: string}} parent
 * @param {object} [attributes]
 */
export function childDocument(db, kind, parent, attributes = {}) {
  return create(db, 'document', {
    kind,
    numbering: 'child',
    sequence: 1,
    parent_id: parent.id,
    parent_kind: parent.kind,
    ...attributes,
  });
}

/**
 * A retro, which is root-numbered *and* parented — the combination that makes numbering and
 * lineage separate columns rather than one.
 *
 * `docs/retros/` numbers globally, so a retro is not counted within the epic it reviews; it
 * still hangs off it. `rootDocument` with an explicit parent says both, and the default
 * `number: 1` means a test that wants two retros has to say which is which.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {{id: string, kind: string}} parent
 * @param {object} [attributes]
 */
export function retroDocument(db, parent, attributes = {}) {
  return rootDocument(db, 'retro', {
    parent_id: parent.id,
    parent_kind: parent.kind,
    ...attributes,
  });
}

/**
 * A spec with one epic under it — the pairing most of these tests need before they can say
 * anything about a child row.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {{spec: object, epic: object}}
 */
export function specWithEpic(db) {
  const spec = rootDocument(db, 'spec', { number: 47, slug: 'substrate' });
  const epic = childDocument(db, 'epic', spec, { slug: 'identity' });

  return { spec, epic };
}
