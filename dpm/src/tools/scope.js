/**
 * Where a list's scope points, and what to say when the id points nowhere (FR8).
 *
 * A list given a scope id that matches no row returns an empty page, which is the same answer as a
 * scope that is genuinely empty. The incident behind the requirement is a run that read that empty
 * page as a failed write and re-wrote ten tags — and nothing in the page said which of the two it
 * was, because nothing could.
 *
 * **The parent table is derived, not declared.** The epic considered declaring it and accepted "a
 * second place to keep in step" as the cost; measured against the live registry, thirty-nine of the
 * forty-two scope arguments are plain foreign keys whose parent the schema already names, so the
 * declaration would restate the schema thirty-nine times and the test pinning it would compare a
 * hand-written copy against the original. That is the hazard `tests/support/conformance.js` exists
 * to warn about, and the reading here is the same one `childLists` already uses to derive `within`.
 *
 * **Three scopes are not references and are never probed.** `taxonomy.domain` is the one worth
 * being explicit about: a domain naming no taxonomy row and a domain that is genuinely empty are
 * the same state, so the distinction this module exists to draw has nothing to draw there.
 * `session.skill` is free text and `session.updated_before` is a bound rather than a scope.
 */

import { ToolError } from './convention.js';
import { defaultsOf, primaryKeyOf, referencesOf, settled } from './foreign-keys.js';
import { didYouMean } from './prefix.js';

/**
 * The scope arguments that are foreign keys of the listed table, and where each points.
 *
 * Read once when the tool is built rather than on every call — the schema does not move between
 * calls, and a `PRAGMA` per list per request would be the query this saves the caller, spent.
 *
 * A `to` of NULL means the parent's own primary key, resolved here so the probe has a column to
 * compare on in every case.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table The table being listed.
 * @param {string[]} candidates The tool's scope arguments.
 * @returns {Record<string, {parent: string, to: string}>} Keyed by argument; a scope that is not a
 *   reference is absent, which is what stops it being probed.
 */
export function scopeParents(db, table, candidates) {
  const defaults = defaultsOf(db, table);
  const found = {};

  for (const reference of referencesOf(db, table)) {
    // **The scope is the column a caller supplies; the rest of the reference is pinned.** This is
    // the difference between catching the mistake and missing it: `story.epic_id` is one half of
    // `(epic_id, epic_kind) → document(id, kind)`, with the kind fixed by the schema — so probing
    // `epic_id` alone finds a *spec*, which is a document, and waves through exactly the call FR8
    // is about. The pinned half is read from the table's own default.
    const [scope] = reference.columns.filter(({ from }) => candidates.includes(from));

    if (!scope) continue;

    // **A companion with no default is dropped rather than the whole reference.** Ten of these
    // exist — `document.parent_kind`, `observation.retro_kind` and the like — where the tool
    // derives the kind per call and the schema has nothing to fall back on. The id alone is still
    // worth probing: it catches every id that is not a row of the parent table, which is most of
    // the mistake, and it simply cannot tell one document kind from another.
    const pinned = reference.columns
      .filter(({ from }) => from !== scope.from)
      .map(({ from, to }) => ({ to, value: settled({}, defaults, from) }))
      .filter(({ value }) => value !== undefined && value !== null);

    found[scope.from] = { parent: reference.parent, to: scope.to, pinned };
  }

  return found;
}

/**
 * Every table some list scopes by, and which lists take an id of it.
 *
 * **This is the direction the epic was right about: a table does not name a list.** `document` is
 * the parent of twenty-one of the forty-two scopes, so an answer derived from the schema alone
 * could say which table an id belongs to and not which call would accept it. The registry is what
 * knows, so the registry is what is read — and for a document the answer is narrowed further by the
 * row's own kind, below.
 *
 * @param {object[]} lists Each `{ name, scopes: Record<string, {parent, to}> }`.
 * @returns {Map<string, {list: string, argument: string}[]>} Keyed by parent table.
 */
export function listsByParent(lists) {
  const byParent = new Map();

  for (const { name, scopes } of lists) {
    for (const [argument, { parent, pinned }] of Object.entries(scopes)) {
      if (!byParent.has(parent)) byParent.set(parent, []);

      // The kind this scope is pinned to, where the schema fixes one. It is what narrows the
      // answer for a document id from twenty-one lists to the handful that would take it.
      const kind = pinned.find(({ to }) => to === 'kind')?.value ?? null;

      byParent.get(parent).push({ list: name, argument, kind });
    }
  }

  return byParent;
}

/**
 * Where an id that missed its scope does live, if anywhere.
 *
 * Probed across the tables some list scopes by — thirteen of them — rather than across the schema,
 * because a table nothing lists by is not somewhere a caller could have meant to point a scope.
 *
 * @returns {{table: string, kind: string|null}|null}
 */
function whereItLives(db, byParent, value, exclude) {
  for (const table of byParent.keys()) {
    const [key] = primaryKeyOf(db, table);
    const row = db.prepare(`SELECT * FROM ${table} WHERE ${key} = ?`).get(value);

    if (!row) continue;

    // **`document` is not excluded even when the scope pointed at it**, because the reference that
    // missed was pinned to a kind: a spec passed where an epic belongs *is* a document, and saying
    // "it is a spec" is the whole answer. A table excluded by name would have nothing to report on
    // the commonest mistake there is.
    if (table === exclude && row.kind === undefined) continue;

    return { table, kind: row.kind ?? null };
  }

  return null;
}

/**
 * The lists that would accept this id, narrowed by what the row actually is.
 *
 * For anything but a document the registry's answer is already one or two entries. For a document
 * it is twenty-one, and naming all of them is noise — so the kind decides: `list_story` takes an
 * epic as `epic_id`, and `document_kind_parent` says which `list_<kind>` tools take it as
 * `parent_id`. That table is already the one `documentLists` reads to decide which kinds have a
 * parent scope at all, so the narrowing and the scope come from one place.
 */
function acceptedBy(db, byParent, { table, kind }) {
  const candidates = byParent.get(table) ?? [];

  if (table !== 'document' || kind === null) return candidates;

  // The kinds that may sit under this one, which is what decides whether a `parent_id` scope would
  // take it. Read from `document_kind_parent`, the same table `documentLists` reads to decide which
  // kinds have a parent scope at all — so the offer and the scope come from one place.
  const children = new Set(db
    .prepare('SELECT kind FROM document_kind_parent WHERE parent_kind = ?')
    .all(kind)
    .map((row) => `list_${row.kind}`));

  return candidates.filter((candidate) => {
    // A scope pinned to a kind takes this id only if it is that kind — `list_story.epic_id` is
    // pinned to `epic`, `list_requirement.spec_id` to `spec`, and offering both for an epic would
    // send the caller to a call that refuses them for the same reason.
    if (candidate.kind !== null) return candidate.kind === kind;

    return candidate.argument === 'parent_id' && children.has(candidate.list);
  });
}

/** `list_story (epic_id), list_retro (parent_id)`, joined for a message. */
const phrase = (accepted) => accepted
  .map(({ list, argument }) => `${list} (${argument})`)
  .join(', ');

/**
 * Refuse a scope id that matches no row, naming where it does belong.
 *
 * **Before the query, never after.** A refusal derived from an empty result would fire on the
 * scope that is genuinely empty, which is the one state this must go on returning a page for — and
 * every assertion about the rejection would pass while the distinction the requirement is about was
 * destroyed.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {object} args The call's arguments.
 * @param {Record<string, {parent: string, to: string}>} scopes This tool's derived scope parents.
 * @param {Map<string, {list: string, argument: string}[]>} byParent The registry, by parent table.
 * @param {string} where The tool name, for the message's prefix.
 * @throws {ToolError} When a supplied scope names no row in the table it points at.
 */
export function refuseUnknownScope(db, args, scopes, byParent, where) {
  for (const [argument, { parent, to, pinned }] of Object.entries(scopes)) {
    const value = args[argument];

    if (value === undefined || value === null) continue;

    const sql = `SELECT 1 FROM ${parent} WHERE ${to} = ?`
      + pinned.map(({ to: column }) => ` AND ${column} = ?`).join('');

    if (db.prepare(sql).get(value, ...pinned.map((column) => column.value))) continue;

    const elsewhere = whereItLives(db, byParent, value, parent);

    if (!elsewhere) {
      // FR22, at the place story 2 said would want it: an id that is nowhere is most often one
      // that lost its tail. The offer is over the table the scope actually points at, because that
      // is the row the caller was reaching for.
      throw new ToolError(
        `${where}: ${argument} '${value}' matches no ${parent}, and no other row in this project`
        + (didYouMean(db, parent, to, value)
          || ' — check the id rather than reading the empty page as a scope with nothing in it'),
      );
    }

    const accepted = acceptedBy(db, byParent, elsewhere);
    const named = elsewhere.kind ? `${elsewhere.kind} in ${elsewhere.table}` : elsewhere.table;

    throw new ToolError(
      `${where}: ${argument} '${value}' matches no ${parent} — it is a ${named}, `
      + (accepted.length > 0
        ? `which is a scope of ${phrase(accepted)}`
        : 'which no list takes as a scope'),
    );
  }
}
