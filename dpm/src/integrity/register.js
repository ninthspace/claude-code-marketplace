/**
 * The cross-row invariant register, as executable checks (FR14).
 *
 * The register in the Data Model lists the rules the schema **cannot** express, because each
 * spans rows the way a foreign key cannot — reachability across a graph, the existence of a
 * row conditional on a column elsewhere, or agreement between two ends of a four-table join.
 * FR14's position is that an invariant which cannot be a constraint is not thereby excused
 * from being checked: without this file each entry is enforced by nothing, is invisible, and
 * survives only as long as whoever knew it is still reading the code.
 *
 * **Every entry names its rows.** A check reporting that something is wrong without saying
 * where is a check nobody can act on, and it is also one that cannot be told apart from a
 * check that is merely broken — which is why the story's must-NOT is "reports a violation it
 * cannot locate, *or* passes a database holding one". Both halves are failures of the same
 * kind.
 *
 * **The numbers are the contract.** `entry` is the register's own number, and the parity test
 * compares this set against it in both directions: an entry with no check and a check with no
 * entry both fail. So a check is added here by adding a register row first, and the number is
 * not a label — it is the join key between a table in a document and a function in this file.
 *
 * Two entries deserve their reasoning stated where it is executed rather than only in the spec:
 *
 * - **#6 checks only the two edge kinds the register names.** `builds_on` spec→spec and
 *   `constrains` ADR→ADR are the rules stated; the rest of the matrix is deliberately unknown,
 *   because `blocks` alone spans epic→epic and story→story and inventing the remainder before
 *   dpm's own pipeline exists would fix guesses in a check. A kind with no declared rule is
 *   passed over rather than guessed at, and that is why this is a register entry and not the
 *   `dependency_kind_endpoint` table it will one day become.
 *
 * - **#10 checks the guards, not the rows.** "No row is written referencing a retired
 *   vocabulary row" is not decidable from a row after the fact: a row written *before* the
 *   retirement is legal and looks identical, and no detail table carries a timestamp to tell
 *   them apart. What is decidable, and is the state the register actually describes, is
 *   whether the guard exists at all — an unguarded reference is the condition under which the
 *   invariant silently stops holding. So the check derives the references exactly as
 *   `retirement.js` does and reports the ones no trigger covers.
 */

import { vocabularyReferences, guardName } from '../schema/retirement.js';

/** How far a reachability walk goes before giving up. A backstop, not a limit anyone reaches. */
const MAX_DEPTH = 64;

/**
 * Both ends of a `dependency` as single node ids, since an end is a document *or* a story and
 * every id is a ULID — so one column can carry either without ambiguity.
 */
const EDGE_NODES = `
  SELECT dependency.id AS edge_id, dependency.kind,
         coalesce(source_document_id, source_story_id) AS source,
         coalesce(target_document_id, target_story_id) AS target
    FROM dependency
`;

/** The spec a document belongs to, found by walking `parent_id` to the root of its tree. */
const ROOT_OF = `
  WITH RECURSIVE ancestry(id, node, parent) AS (
    SELECT id, id, parent_id FROM document
     UNION ALL
    SELECT ancestry.id, document.id, document.parent_id
      FROM ancestry JOIN document ON document.id = ancestry.parent
  )
  SELECT id, node AS root FROM ancestry WHERE parent IS NULL
`;

/** The epic a story hangs off, and the spec above that — the join #3, #4 and #7 all need. */
const CRITERION_SPEC = `
  SELECT story_criterion.id AS criterion_id, story.id AS story_id,
         story.epic_id AS epic_id, root.root AS spec_id
    FROM story_criterion
    JOIN story ON story.id = story_criterion.story_id
    JOIN (${ROOT_OF}) AS root ON root.id = story.epic_id
`;

/** A reachability walk over a directed edge set, reporting nodes reachable from themselves. */
function cycles(db, edges, parameters = []) {
  return db.prepare(`
    WITH RECURSIVE edge(source, target) AS (${edges}),
    walk(root, node, depth) AS (
      SELECT source, target, 1 FROM edge
       UNION
      SELECT walk.root, edge.target, walk.depth + 1
        FROM walk JOIN edge ON edge.source = walk.node
       WHERE walk.depth < ${MAX_DEPTH}
    )
    SELECT DISTINCT root AS id FROM walk WHERE node = root ORDER BY root
  `).all(...parameters).map((row) => ({ ...row }));
}

/**
 * The register. One entry per numbered row in the Data Model's table, in its order.
 *
 * Each `check` returns the offending rows — empty when the invariant holds. The rows are
 * whatever names the violation usefully; there is no fixed shape, because "which rows" differs
 * per entry and forcing them into one would lose the part a reader needs.
 *
 * @type {{entry: number, invariant: string, check: (db: any) => object[]}[]}
 */
export const REGISTER = [
  {
    entry: 1,
    invariant: 'No cycle among gates_work edges',
    check: (db) => cycles(db, `
      SELECT edge.source, edge.target FROM (${EDGE_NODES}) AS edge
        JOIN dependency_kind ON dependency_kind.kind = edge.kind
       WHERE dependency_kind.gates_work = 1
    `),
  },
  {
    entry: 2,
    invariant: 'A superseded ADR has a supersedes edge out of it',
    check: (db) => db.prepare(`
      SELECT adr.document_id AS id, document.title
        FROM adr JOIN document ON document.id = adr.document_id
       WHERE adr.decision_status = 'superseded'
         AND NOT EXISTS (
               SELECT 1 FROM dependency
                WHERE dependency.kind = 'supersedes'
                  AND dependency.source_document_id = adr.document_id
             )
       ORDER BY adr.document_id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 3,
    invariant: "A coverage row's requirement and its story criterion belong to the same spec",
    check: (db) => db.prepare(`
      SELECT coverage.id, requirement.spec_id AS requirement_spec, criterion.spec_id AS criterion_spec
        FROM coverage
        JOIN requirement ON requirement.id = coverage.requirement_id
        JOIN (${CRITERION_SPEC}) AS criterion ON criterion.criterion_id = coverage.story_criterion_id
       WHERE requirement.spec_id <> criterion.spec_id
       ORDER BY coverage.id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 4,
    invariant: "A coverage_story row's story is in the same epic as the coverage row it extends",
    check: (db) => db.prepare(`
      SELECT coverage_story.coverage_id, coverage_story.story_id,
             extra.epic_id AS story_epic, criterion.epic_id AS coverage_epic
        FROM coverage_story
        JOIN coverage ON coverage.id = coverage_story.coverage_id
        JOIN story AS extra ON extra.id = coverage_story.story_id
        JOIN (${CRITERION_SPEC}) AS criterion ON criterion.criterion_id = coverage.story_criterion_id
       WHERE extra.epic_id <> criterion.epic_id
       ORDER BY coverage_story.coverage_id, coverage_story.story_id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 5,
    invariant: 'number_sequence.next_value exceeds every number allocated for that kind',
    check: (db) => db.prepare(`
      SELECT number_sequence.kind, number_sequence.parent_id, number_sequence.next_value,
             max(coalesce(document.number, document.sequence)) AS highest
        FROM number_sequence
        JOIN document ON document.kind = number_sequence.kind
         AND (number_sequence.parent_id IS NULL OR document.parent_id = number_sequence.parent_id)
       GROUP BY number_sequence.kind, number_sequence.parent_id, number_sequence.next_value
      HAVING number_sequence.next_value <= max(coalesce(document.number, document.sequence))
       ORDER BY number_sequence.kind
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 6,
    invariant: "A dependency's ends are kinds that edge admits",
    check: (db) => db.prepare(`
      SELECT edge.edge_id, edge.kind, source.kind AS source_kind, target.kind AS target_kind
        FROM (${EDGE_NODES}) AS edge
        JOIN document AS source ON source.id = edge.source
        JOIN document AS target ON target.id = edge.target
       WHERE (edge.kind = 'builds_on'   AND (source.kind <> 'spec' OR target.kind <> 'spec'))
          OR (edge.kind = 'constrains'  AND (source.kind <> 'adr'  OR target.kind <> 'adr'))
       ORDER BY edge.edge_id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 7,
    invariant: "A review's scope_story_id names a story inside the epic it reviews",
    check: (db) => db.prepare(`
      SELECT review.document_id AS id, review.scope_story_id, story.epic_id, document.parent_id
        FROM review
        JOIN document ON document.id = review.document_id
        JOIN story ON story.id = review.scope_story_id
       WHERE review.scope_story_id IS NOT NULL
         AND document.parent_kind = 'epic'
         AND story.epic_id <> document.parent_id
       ORDER BY review.document_id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 8,
    invariant: 'An accepted ADR has exactly one chosen option',
    check: (db) => db.prepare(`
      SELECT adr.document_id AS id,
             (SELECT count(*) FROM adr_option
               WHERE adr_option.adr_id = adr.document_id AND adr_option.chosen = 1) AS chosen
        FROM adr
       WHERE adr.decision_status = 'accepted'
         AND (SELECT count(*) FROM adr_option
               WHERE adr_option.adr_id = adr.document_id AND adr_option.chosen = 1) <> 1
       ORDER BY adr.document_id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 9,
    invariant: "coverage.spec_fragment is a substring of its requirement's text",
    check: (db) => db.prepare(`
      SELECT coverage.id, coverage.requirement_id, coverage.spec_fragment
        FROM coverage JOIN requirement ON requirement.id = coverage.requirement_id
       WHERE instr(requirement.text, coverage.spec_fragment) = 0
       ORDER BY coverage.id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 10,
    invariant: 'Every reference into a retirable vocabulary is guarded against new rows',
    check: (db) => {
      const triggers = new Set(
        db.prepare("SELECT name FROM sqlite_schema WHERE type = 'trigger'").all().map((t) => t.name),
      );

      return vocabularyReferences(db).flatMap((reference) =>
        ['insert', 'update']
          .filter((event) => !triggers.has(guardName(reference, event)))
          .map((event) => ({
            table: reference.table,
            columns: reference.from.join(', '),
            parent: reference.parent,
            missing: guardName(reference, event),
          })));
    },
  },
  {
    entry: 11,
    invariant: 'session.superseded_by forms no cycle',
    check: (db) => cycles(db, `
      SELECT id, superseded_by FROM session WHERE superseded_by IS NOT NULL
    `),
  },
  {
    entry: 12,
    invariant: "A document_milestone row's document and milestone belong to the same spec",
    check: (db) => db.prepare(`
      SELECT document_milestone.document_id, document_milestone.milestone_id,
             root.root AS document_spec, milestone.spec_id AS milestone_spec
        FROM document_milestone
        JOIN milestone ON milestone.id = document_milestone.milestone_id
        JOIN (${ROOT_OF}) AS root ON root.id = document_milestone.document_id
       WHERE root.root <> milestone.spec_id
       ORDER BY document_milestone.document_id, document_milestone.milestone_id
    `).all().map((row) => ({ ...row })),
  },
  {
    entry: 13,
    invariant: 'Every {{ref:<id>}} marker in every prose column resolves to a live document',
    check: (db) => danglingMarkers(db),
  },
];

/** `{{ref:01J…}}` — the marker form, and the capture that gets resolved. */
const MARKER = /\{\{ref:([^}]+)\}\}/g;

/**
 * Every marker in the database that names no `document` row.
 *
 * **Every TEXT column is scanned, and the list is derived rather than declared.** A marker's
 * whole difficulty is that it lives inside prose where no foreign key can reach it, so a check
 * driven by a list of "the prose columns" fails in exactly the way the entry exists to prevent:
 * a column added later holds markers nothing sweeps, and the sweep still reports clean. Reading
 * `PRAGMA table_info` costs a wider scan and cannot miss a column. A marker in a column nobody
 * would call prose is a violation too.
 */
function danglingMarkers(db) {
  const tables = db
    .prepare("SELECT name FROM sqlite_schema WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
    .all()
    .map((table) => table.name);

  const documents = new Set(db.prepare('SELECT id FROM document').all().map((row) => row.id));
  const dangling = [];

  for (const table of tables) {
    const columns = db.prepare(`PRAGMA table_info(${table})`).all();
    const text = columns.filter((column) => column.type.toUpperCase() === 'TEXT');
    if (text.length === 0) continue;

    const key = columns.filter((column) => column.pk > 0).map((column) => column.name);
    const identify = key.length > 0 ? key : text.map((column) => column.name);

    for (const column of text) {
      const rows = db
        .prepare(`SELECT ${[...new Set([...identify, column.name])].join(', ')} FROM ${table}
                   WHERE ${column.name} LIKE '%{{ref:%'`)
        .all();

      for (const row of rows) {
        for (const [, id] of String(row[column.name]).matchAll(MARKER)) {
          if (documents.has(id)) continue;

          dangling.push({
            table,
            column: column.name,
            row: Object.fromEntries(identify.map((name) => [name, row[name]])),
            reference: id,
          });
        }
      }
    }
  }

  return dangling;
}
