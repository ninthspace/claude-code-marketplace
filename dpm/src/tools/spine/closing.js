/**
 * What a story has to be true of before it can be called finished (FR3, FR4).
 *
 * These are the conditions `deliveryTools` asks for through its `closing` seam. They live here
 * rather than in `index.js` because the registry's job is to say which tables get which tools, and
 * a paragraph of reasoning about outstanding work inside a registration is a paragraph nobody
 * reading either file expects to find.
 *
 * **Each condition refuses and names what to do instead**, which is NFR4 and the difference between
 * a guard and an obstacle. A run told only that its story cannot close has to go and list the tasks
 * to find out why; told which tasks are outstanding, it has the reconciliation it did not perform.
 */

import { ToolError } from '../convention.js';

/**
 * The tasks beneath a story that nobody has resolved.
 *
 * **Outstanding is `pending` and nothing else.** A task that is `superseded` or `withdrawn` has been
 * decided about — the work was replaced or dropped, and both are answers. Counting them would refuse
 * a story whose every open question is settled, which is the state this check exists to *reach*.
 *
 * Ordered by number, because the refusal reads as a list someone works through.
 */
const OUTSTANDING = `
  SELECT number, title
    FROM task
   WHERE story_id = ? AND status = 'pending'
   ORDER BY number
`;

/**
 * The live bindings on a story's criteria that nobody has verified.
 *
 * Named by the requirement's label rather than by an id, so a run reading the refusal can check it
 * against the spec in front of them — the same reason `coverage.requirement_label` exists. A
 * retired binding is excluded: somebody decided about it, and a withdrawal carries its reason.
 */
const UNVERIFIED = `
  SELECT requirement.label, coverage.spec_fragment
    FROM coverage
    JOIN story_criterion ON story_criterion.id = coverage.story_criterion_id
    JOIN requirement ON requirement.id = coverage.requirement_id
   WHERE story_criterion.story_id = ?
     AND coverage.retired_at IS NULL
     AND coverage.verified_at IS NULL
   ORDER BY requirement.label, coverage.position
`;

/** Whether a status note says anything. Whitespace is an empty note that looks like a full one. */
const stated = (note) => typeof note === 'string' && note.trim() !== '';

/**
 * Refuse a story being finished while a task beneath it is still outstanding (FR3).
 *
 * **It lists them rather than counting them**, so the refusal performs the reconciliation the run
 * did not. A message saying *three tasks are outstanding* leaves the caller exactly where they
 * started; one naming them is the answer.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {(row: object, where: string) => void} The `closing` hook for `story`.
 */
export const storyClosing = (db) => (row, where) => {
  const outstanding = db.prepare(OUTSTANDING).all(row.id);

  if (outstanding.length > 0) {
    throw new ToolError(
      `${where}: story ${row.number} has ${outstanding.length === 1 ? 'a task' : 'tasks'} still `
      + `outstanding — ${outstanding.map((task) => `${task.number}. ${task.title}`).join('; ')}`
      + ' — so finish or retire each before closing the story',
    );
  }

  // FR4 — a story may legitimately finish over work somebody else verifies, so what is refused is
  // the **silent** close and never the unverified binding itself. The note is the whole of the
  // requirement: say why, and the close proceeds.
  //
  // **Judged on the resolved row, which is what makes the stored note count.** A story that already
  // records why it is closing early does not have to repeat itself in the closing call — the hook
  // is handed the state the edit would leave rather than the arguments it carries, and this is the
  // condition that needs it.
  if (stated(row.status_note)) return;

  const unverified = db.prepare(UNVERIFIED).all(row.id);

  if (unverified.length === 0) return;

  throw new ToolError(
    `${where}: story ${row.number} closes over `
    + `${unverified.length === 1 ? 'a binding' : 'bindings'} nobody has verified — `
    + `${unverified.map((binding) => binding.label).join(', ')}`
    + ' — which is allowed, so record why in status_note and the close proceeds',
  );
};

/**
 * Refuse a second live criterion with the same text under one story (FR13).
 *
 * **Live only.** A superseded criterion keeps its text — that is the point of marking rather than
 * rewriting it — so a new criterion may legitimately restate one an amendment overtook. Counting
 * those would make the ordinary way of correcting a criterion impossible.
 *
 * **Exact text, where the report's duplicate *warning* normalises whitespace.** The asymmetry is
 * deliberate and worth stating: a refusal stops a caller, so it takes the narrow reading and
 * catches only what is unarguably the same sentence; the warning advises, so it takes the wide one
 * and catches what is probably the same obligation written twice. A refusal on the wide reading
 * would block two criteria that differ only in how they were wrapped.
 *
 * The twin's position is named, because that is what the caller needs to go and look at.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {(row: object, where: string) => void} The `guard` for `story_criterion`.
 */
export const refuseDuplicateCriterion = (db) => (row, where) => {
  if (row.superseded_at || typeof row.text !== 'string') return;

  // **Whether a criterion can be superseded at all is asked of the schema, not assumed.** The
  // column arrived in a later migration than this table, and a database opened at a version before
  // it — a fixture built at an older schema, a project not yet migrated — has criteria that are all
  // live by construction. Naming the column unconditionally turns this guard into a hard error
  // there, which is a refusal about the wrong thing entirely.
  const supersedable = db
    .prepare("SELECT 1 AS present FROM pragma_table_info('story_criterion') WHERE name = ?")
    .get('superseded_at') !== undefined;

  const live = supersedable ? 'AND superseded_at IS NULL' : '';

  const twin = db
    .prepare(`SELECT position FROM story_criterion
               WHERE story_id = ? AND text = ? AND id <> ? ${live}
               ORDER BY position LIMIT 1`)
    .get(row.story_id, row.text, row.id ?? '');

  if (!twin) return;

  throw new ToolError(
    `${where}: this story already has a live criterion with that text, at position ${twin.position}`
    + ' — amend that one, or supersede it if this is meant to replace it',
  );
};

/**
 * Refuse attaching a coverage row to a story in a different epic (FR14).
 *
 * `coverage_story` records that a story *also* delivers a binding — "Covered by: Story 2, Story 4".
 * Both stories are meant to be doing the same epic's work; a story in another epic delivering this
 * one's binding is an id from the wrong place, and it reads afterwards as a matrix row belonging to
 * two epics at once.
 *
 * **Both epics are named**, because the caller cannot see from the ids which of the two they got
 * wrong — and either might be: the binding may be right and the story mistyped, or the other way
 * about.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @returns {(row: object, where: string) => void} The `guard` for `coverage_story`.
 */
export const refuseCrossEpicDelivery = (db) => (row, where) => {
  const ends = db
    .prepare(`SELECT owner.epic_id AS owner_epic, also.epic_id AS also_epic
                FROM coverage
                JOIN story_criterion ON story_criterion.id = coverage.story_criterion_id
                JOIN story AS owner ON owner.id = story_criterion.story_id
                JOIN story AS also ON also.id = ?
               WHERE coverage.id = ?`)
    .get(row.story_id, row.coverage_id);

  // Either end missing is a foreign key's business, not this guard's — refusing here would name
  // the wrong fault for a row that has a different problem.
  if (!ends || ends.owner_epic === ends.also_epic) return;

  const name = (id) => db.prepare('SELECT slug FROM document WHERE id = ?').get(id)?.slug ?? id;

  throw new ToolError(
    `${where}: the binding belongs to epic '${name(ends.owner_epic)}' and the story to epic `
    + `'${name(ends.also_epic)}' — a story delivers a binding within its own epic, so check `
    + 'whichever of the two was meant',
  );
};
