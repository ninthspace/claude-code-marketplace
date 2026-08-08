/**
 * The edge kinds, and which of them stop work.
 *
 * `gates_work` is the whole point of the table being a table: readiness is a query over one
 * flag, so a project adding a fifth kind decides for itself whether it gates, and no query
 * anywhere carries a list of kind names to keep in step.
 *
 * `supersedes` is here rather than as a `superseded_by` column on `adr`, which an earlier
 * shape had — that would have been a second mechanism for what `dependency` already does,
 * which is the criticism this spec makes of `test_approach` applied to itself.
 */
export const DEPENDENCY_KINDS = [
  // The only one that gates. An epic blocked by epics, or a story by another story.
  { kind: 'blocks', gates_work: 1, position: 1, retired_at: null },
  // Spec-to-spec lineage. CPM has no field for it, and three real specifications carry a
  // hand-written `**Builds on**:` header anyway — a field invented independently in three
  // documents is a missing feature rather than a flourish.
  { kind: 'builds_on', gates_work: 0, position: 2, retired_at: null },
  // ADR-to-ADR, which CPM does define and which is directional and distinct from blocking.
  { kind: 'constrains', gates_work: 0, position: 3, retired_at: null },
  { kind: 'supersedes', gates_work: 0, position: 4, retired_at: null },
];
