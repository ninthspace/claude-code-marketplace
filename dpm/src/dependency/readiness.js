/**
 * Readiness — "which epics can be worked on now" as a query.
 *
 * This is what makes blocking a relationship rather than a status. A `status = 'blocked'`
 * cannot say *what* blocks you, cannot be traversed, and cannot be invalidated when the
 * blocker completes; all three fall out of an edge table for free.
 *
 * **Readiness reads `gates_work` and never a list of kind names.** That is the whole reason
 * `dependency_kind` is a table: a project adding a fifth edge kind decides for itself whether
 * it gates, and nothing here has to be edited to agree. A query with `WHERE kind = 'blocks'`
 * in it would be the hardcoded list back again, one indirection further down.
 *
 * **An edge reads source-blocks-target**, so the epic that cannot start is the *target*. The
 * direction is worth stating because both ends are documents and nothing in the row's shape
 * distinguishes them.
 *
 * **What this deliberately does not do is detect cycles.** `A blocks B` with `B blocks A` is
 * two legal rows, and over them this query returns nothing ready — which is indistinguishable
 * from everything being done, and raises no error. Closing that needs reachability, which is
 * not row-local: the link tool refuses the edge that would close a cycle (Epic 47-03) and
 * FR14's integrity check reports the ones that predate the rule or arrive by restore (Story
 * 6). Lineage kinds are left alone, because nothing waits on them.
 */

/**
 * `blocked` is every document with at least one incomplete blocker over a gating edge kind.
 * A retired edge kind still gates: retirement stops new rows arriving, it does not quietly
 * release the work that edges of that kind were already holding up.
 */
const READY = `
  SELECT document.id, document.kind, document.number, document.slug, document.title,
         document.status
    FROM document
   WHERE document.kind = ?
     AND document.status <> 'complete'
     AND document.archived_at IS NULL
     AND NOT EXISTS (
           SELECT 1
             FROM dependency
             JOIN dependency_kind ON dependency_kind.kind = dependency.kind
             JOIN document AS blocker ON blocker.id = dependency.source_document_id
            WHERE dependency.target_document_id = document.id
              AND dependency_kind.gates_work = 1
              AND blocker.status <> 'complete'
         )
   ORDER BY document.number, document.sequence
`;

const MILESTONES = `
  SELECT milestone.label, milestone.title, milestone.position
    FROM document_milestone
    JOIN milestone ON milestone.id = document_milestone.milestone_id
   WHERE document_milestone.document_id = ?
   ORDER BY milestone.position
`;

/**
 * Documents of `kind` with nothing incomplete blocking them.
 *
 * Each result carries **every** milestone it delivers, not one. `document_milestone` is a
 * join table precisely because an epic can span two — this spec's own breakdown has one
 * delivering part of M2 and part of M4 — and a result that returned a single milestone would
 * re-impose the column FR27 removed, one layer up from the schema.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} [options]
 * @param {string} [options.kind] Document kind to consider. Defaults to `'epic'`.
 * @param {string} [options.milestone] Milestone label to filter by; results still report all.
 * @returns {{id: string, title: string, milestones: {label: string, title: string}[]}[]}
 */
export function readyDocuments(db, { kind = 'epic', milestone = null } = {}) {
  const ready = db.prepare(READY).all(kind).map((row) => ({
    ...row,
    milestones: db.prepare(MILESTONES).all(row.id).map((m) => ({ ...m })),
  }));

  if (milestone === null) return ready;

  // Filtered *after* the milestones are attached, so an epic delivering M2 and M4 appears
  // under either and reports both either way.
  return ready.filter((row) => row.milestones.some((m) => m.label === milestone));
}

/**
 * The edges holding `documentId` up, with the blocker each one names.
 *
 * Readiness answers "can this start"; this answers "why not", which a status column could
 * never do. Returns an empty array for a document nothing gates.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} documentId
 */
export function blockedBy(db, documentId) {
  return db.prepare(`
    SELECT dependency.id AS edge_id, dependency.kind,
           blocker.id AS blocker_id, blocker.title AS blocker_title, blocker.status
      FROM dependency
      JOIN dependency_kind ON dependency_kind.kind = dependency.kind
      JOIN document AS blocker ON blocker.id = dependency.source_document_id
     WHERE dependency.target_document_id = ?
       AND dependency_kind.gates_work = 1
       AND blocker.status <> 'complete'
     ORDER BY blocker.number, blocker.sequence
  `).all(documentId).map((row) => ({ ...row }));
}
