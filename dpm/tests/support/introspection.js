/**
 * Reading the schema back out of SQLite, for the tests that check it against itself.
 *
 * Several of the schema-wide criteria are of the form "every X has Y", and the only honest way
 * to write one is to enumerate X from the database rather than from a list a person keeps. A
 * hand-kept list is a second description of the schema, and a second description is the drift
 * this spec exists to remove — a table added three stories from now is covered on the day it
 * lands, without anyone remembering.
 *
 * **This is deliberately not `src/schema/retirement.js`'s copy of the same walk.** That module
 * uses its walk to *generate* the guards; these tests use theirs to *check* them. A test that
 * asked the generator which references it found could not notice the generator missing one.
 * The duplication is the independence.
 */

/** Tables dpm authored — excluding everything SQLite maintains for itself or a virtual table. */
export function authoredTables(db) {
  const all = db
    .prepare("SELECT name, sql FROM sqlite_schema WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
    .all();

  // FTS5 creates `x_data`, `x_idx`, `x_docsize`… beside every virtual table `x`. Epic 47-05
  // brings the first of those; the exclusion is derived from the virtual tables actually
  // present rather than from a list of suffixes, so it excludes nothing today and the right
  // things later.
  const virtual = all
    .filter((t) => /^\s*CREATE\s+VIRTUAL\s+TABLE/i.test(t.sql ?? ''))
    .map((t) => t.name);

  return all
    .filter((t) => !virtual.some((v) => t.name !== v && t.name.startsWith(`${v}_`)))
    .map((t) => t.name);
}

/** One entry per foreign key, columns in declaration order — so composite keys stay whole. */
export function foreignKeys(db, table) {
  const rows = db.prepare(`PRAGMA foreign_key_list(${table})`).all();

  return [...new Set(rows.map((row) => row.id))].map((id) => {
    const columns = rows.filter((row) => row.id === id).sort((a, b) => a.seq - b.seq);

    return {
      from: columns.map((column) => column.from),
      table: columns[0].table,
      to: columns.map((column) => column.to),
    };
  });
}

/** Column names, in declaration order. */
export function columnNames(db, table) {
  return db.prepare(`PRAGMA table_info(${table})`).all().map((column) => column.name);
}

/** Trigger names, sorted — the guards `applySchema` generated, read back as the schema has them. */
export function triggerNames(db) {
  return db
    .prepare("SELECT name FROM sqlite_schema WHERE type = 'trigger' ORDER BY name")
    .all()
    .map((row) => row.name);
}
