/**
 * Readiness — "which epics can be worked on now", and "which stories", as a query.
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
 *
 * **A story's blockers are not all stories.** `dependency` has four end columns in two exclusive
 * pairs, and both pairings occur at the story end of a real epic: a story waits on a sibling
 * story, and a story waits on a whole epic elsewhere. So `ENDS.story` names two blocker sources
 * where `ENDS.document` names one. Reading only `source_story_id` would report a story ready while
 * an epic it names holds it up — a wrong answer in the direction that starts work, which is the
 * worse of the two.
 *
 * **Stories have no `readyDocuments` of their own**, and that is a decision rather than a gap:
 * `readyClause('story')` is what `list_story`'s `ready` argument applies, so the query is reached
 * through the tool surface an FR25 skill has. A second entry point here would be a second answer
 * with no caller — and "why is this one held" is `list_dependency` scoped to the story, which is a
 * fuller answer than a helper returning blockers could give.
 */

/**
 * The end pairings a blocker can arrive over, per blocked table. `[blocker table, source column,
 * target column]` — read source-blocks-target, as the header says.
 */
const ENDS = {
  document: [['document', 'source_document_id', 'target_document_id']],
  story: [
    ['story', 'source_story_id', 'target_story_id'],
    ['document', 'source_document_id', 'target_story_id'],
  ],
};

/**
 * "Nothing incomplete blocks this row", as a clause correlated to `table`.
 *
 * **Exported because the list tools need the same rule and must not restate it.** FR22's whole
 * claim is that readiness is a query rather than a status, and two hand-written copies of the
 * query is a status with extra steps — one of them acquires a fifth edge kind's semantics and the
 * other does not, and the disagreement surfaces as work that two tools disagree about starting.
 *
 * A retired edge kind still gates: retirement stops new rows arriving, it does not quietly
 * release the work that edges of that kind were already holding up. That is why `retired_at`
 * appears nowhere below.
 *
 * The predicate is the whole of readiness and not the blocker half alone — being incomplete, and
 * for a document not being archived, are as much a part of "can be worked on now" as having no
 * blocker. Returning the whole of it is what keeps a second consumer from adding its own idea of
 * the other conditions.
 *
 * @param {'document'|'story'} table The blocked table, and the alias the clause correlates to.
 * @returns {string} A SQL fragment, safe to splice: every part comes from `ENDS`.
 */
export function readyClause(table) {
  const blockers = ENDS[table].map(([blocker, source, target]) => `NOT EXISTS (
           SELECT 1
             FROM dependency
             JOIN dependency_kind ON dependency_kind.kind = dependency.kind
             JOIN ${blocker} AS blocker ON blocker.id = dependency.${source}
            WHERE dependency.${target} = ${table}.id
              AND dependency_kind.gates_work = 1
              AND blocker.status <> 'complete'
         )`);

  return [
    `${table}.status <> 'complete'`,
    // A story has no archive of its own; archiving the epic takes its stories with it.
    ...(table === 'document' ? [`${table}.archived_at IS NULL`] : []),
    ...blockers,
  ].join('\n     AND ');
}

const READY = `
  SELECT document.id, document.kind, document.number, document.slug, document.title,
         document.status
    FROM document
   WHERE document.kind = ?
     AND ${readyClause('document')}
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
