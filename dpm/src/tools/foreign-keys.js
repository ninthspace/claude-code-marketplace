/**
 * Which id a write named that nothing answers to (FR7).
 *
 * SQLite says `FOREIGN KEY constraint failed` and stops there. It names no column, no table and no
 * value — which is bearable on a write carrying one id and useless on one carrying four. A
 * `create_coverage` call names a requirement, a criterion and nothing else that could be wrong, and
 * a caller told only that a foreign key failed has to try them one at a time to find out which.
 *
 * **So the answer is worked out after the failure rather than before every write.** The probe below
 * runs only when a constraint has already fired, which is the rare path; the common path pays
 * nothing. Written the other way round — checking each reference before the insert — it would be a
 * second enforcement point that has to agree with the database about what a reference is, and the
 * two would disagree the first time a migration added one.
 *
 * **It reports the first miss, not every miss.** A caller fixes one id and writes again; naming
 * three at once reads as three separate faults when it is usually one mistyped value and two that
 * were never looked at. `foreign_key_list` orders references as the table declares them, which is
 * the order a reader of the DDL expects.
 */

/**
 * The references a table declares, each as its local columns and the parent they point at.
 *
 * Composite references arrive from `PRAGMA foreign_key_list` as several rows sharing an `id`, so
 * they are grouped rather than read one row at a time — `document(parent_id, parent_kind)` is one
 * reference and reporting half of it would name a column that is not, on its own, wrong.
 *
 * A `to` of NULL means the parent's own primary key, which is what `PRAGMA table_info` calls `pk`.
 * It is resolved here rather than left to the caller so the probe below has a column name to
 * compare on in every case.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table
 * @returns {{parent: string, columns: {from: string, to: string}[]}[]}
 */
export function referencesOf(db, table) {
  const grouped = new Map();

  for (const row of db.prepare(`PRAGMA foreign_key_list(${table})`).all()) {
    if (!grouped.has(row.id)) grouped.set(row.id, { parent: row.table, columns: [] });

    grouped.get(row.id).columns.push({ from: row.from, to: row.to });
  }

  return [...grouped.values()].map((reference) => ({
    ...reference,
    columns: reference.columns.map((column) => ({
      ...column,
      to: column.to ?? primaryKeyOf(db, reference.parent)[0],
    })),
  }));
}

/** A table's primary key columns, in declaration order. */
export function primaryKeyOf(db, table) {
  return db.prepare(`PRAGMA table_info(${table})`).all()
    .filter((column) => column.pk > 0)
    .sort((one, other) => one.pk - other.pk)
    .map((column) => column.name);
}

/**
 * What a column will hold, which is what the call supplied or what the table falls back to.
 *
 * **The default matters because a reference can be half-defaulted.** `finding(category_id,
 * category_domain)` points at `taxonomy`, and `category_domain` is `DEFAULT 'finding'` — so a call
 * supplies one column of the pair and the schema supplies the other. Reading only the supplied
 * columns made that reference look unsupplied, the probe skipped it, and the caller got SQLite's
 * bare message on exactly the mix-up this story exists to name: a severity written into a category
 * slot.
 *
 * SQLite reports a default as the SQL literal it was declared with, quotes and all, so a string
 * default arrives as `'finding'` and is unwrapped here.
 *
 * @returns {unknown} The value, or `undefined` where the column has neither.
 */
export function settled(values, defaults, column) {
  if (values[column] !== undefined) return values[column];

  const declared = defaults.get(column);

  if (declared === null || declared === undefined) return undefined;

  return typeof declared === 'string' ? declared.replace(/^'(.*)'$/, '$1') : declared;
}

/**
 * The first reference in `values` whose parent row is not there.
 *
 * **Only references the call actually supplied are probed.** A column left out, or written NULL, is
 * not a reference that missed — it is a reference not made, and SQLite does not enforce one. A
 * composite reference is probed only when every one of its columns carries a value, for the same
 * reason: half of `parent_id`/`parent_kind` names nothing to look for.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table The table being written.
 * @param {Record<string, unknown>} values The columns the write carried.
 * @returns {{parent: string, columns: {column: string, value: unknown}[]}|null} The miss, or `null`
 *   where every supplied reference resolves — which is the honest answer when the constraint that
 *   fired was somebody else's, and the caller is better served by SQLite's own words than by a
 *   guess.
 */
export function defaultsOf(db, table) {
  return new Map(db.prepare(`PRAGMA table_info(${table})`).all()
    .map((column) => [column.name, column.dflt_value]));
}

export function missingParent(db, table, values) {
  const defaults = defaultsOf(db, table);

  for (const reference of referencesOf(db, table)) {
    const held = reference.columns.map(({ from }) => settled(values, defaults, from));

    if (held.some((value) => value === undefined || value === null)) continue;

    const sql = `SELECT 1 FROM ${reference.parent} `
      + `WHERE ${reference.columns.map(({ to }) => `${to} = ?`).join(' AND ')}`;

    if (db.prepare(sql).get(...held)) continue;

    // **A composite reference is named whole, rather than one column of it being blamed.** The
    // first draft reported the leading column and was wrong on the first case it met: a review
    // under a spec fails `document(kind, parent_kind) → document_kind_parent`, whose leading
    // column is `kind` — so it said the review's own kind matched nothing, when what the caller
    // got wrong was the parent. Which half of a pair is the mistake is not knowable from the
    // failure, and a refusal that picks one sends the caller to a value they may never have
    // written. Both are named, and the caller can see which is theirs.
    return {
      parent: reference.parent,
      columns: reference.columns
        .map(({ from }, index) => ({ column: from, value: held[index] })),
    };
  }

  return null;
}
