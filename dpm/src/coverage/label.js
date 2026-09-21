/**
 * FR10 — the label of the requirement a coverage row binds, on the row.
 *
 * A coverage row names its requirement by id, and an id is not something a caller can check an
 * answer against. So a test or a skill verifying a read-back has to hold an id from an earlier call
 * and compare against that, which checks that two calls agree rather than that either is right —
 * and it is the shape that has cost this project several confident assertions over the wrong row.
 * A label is a fact about the requirement the reader already knows: `FR5` is checkable by someone
 * looking at the spec.
 *
 * **Derived on the read path, not stored.** A stored copy is a second place the label lives, and the
 * two disagree the first time a requirement is relabelled — silently, because a stale label is a
 * plausible label. Deriving it means there is one answer, computed from the row that owns it.
 *
 * **Nothing here reaches any derived sweep, and that is a known cost rather than an oversight.** The
 * suite's sweeps read the schema and the tool registry; a value computed after the read is in
 * neither, so no sweep can see this field and none will notice if it disappears. The only pressure
 * on it is the skill text that quotes it and the tests below — which is why the story that adds this
 * carries a task for naming the field in that text, and why the task is not the documentation
 * exercise it looks like.
 */

import { overRows } from '../tools/convention.js';

/** The field this puts on a coverage row. Named once, because a skill and a report both read it. */
export const LABEL_FIELD = 'requirement_label';

/**
 * The labels for these requirements, in one statement.
 *
 * One query for the page rather than one per row, for the reason `warrant.js` gives about the same
 * shape: a per-row lookup satisfies every criterion about the answer and fails the one about the
 * cost, and it is invisible in a test that lists two rows.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string[]} ids
 * @returns {Map<string, string>}
 */
function labelsFor(db, ids) {
  if (ids.length === 0) return new Map();

  const rows = db
    .prepare(`SELECT id, label FROM requirement WHERE id IN (${ids.map(() => '?').join(', ')})`)
    .all(...ids);

  return new Map(rows.map((row) => [row.id, row.label]));
}

/**
 * Put `requirement_label` on one coverage row or a page of them.
 *
 * **`null` where the requirement is not there.** A row whose requirement has gone is a broken
 * binding rather than an unlabelled one, and it is the integrity register's business — answering
 * an empty string here would hand a reader something that looks like a label and names nothing.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {unknown} value One row, or a page of them.
 * @returns {unknown}
 */
export function withRequirementLabel(db, value) {
  if (value === null || typeof value !== 'object') return value;

  const rows = Array.isArray(value.items) ? value.items : [value];
  const labels = labelsFor(
    db,
    [...new Set(rows.map((row) => row.requirement_id).filter((id) => id !== undefined))],
  );

  return overRows(value, (row) => ({
    ...row,
    [LABEL_FIELD]: labels.get(row.requirement_id) ?? null,
  }));
}
