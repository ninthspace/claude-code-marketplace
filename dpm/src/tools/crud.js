/**
 * The three statements every entity tool is built from.
 *
 * Table and column names are interpolated rather than bound, because SQLite binds values and not
 * identifiers. That is safe here and only here: every name reaching these functions comes from a
 * tool descriptor in this repository, never from a caller's arguments — `validate` has already
 * refused any argument the schema does not name, so an unknown key cannot arrive as a column. A
 * future caller-supplied column name would have to be checked against `PRAGMA table_info` first,
 * and there is no such caller today.
 *
 * **A constraint violation becomes a refusal, not a crash.** FR3 puts rejection at the tool
 * boundary, and `validate` does most of it — but the constraints only the database can check,
 * foreign keys and `CHECK` sets among them, still surface here. Reported as an internal error
 * they would read to a caller as a broken server rather than a bad call, so they are translated.
 */

import { ToolError } from './convention.js';

/** Run a statement, turning SQLite's constraint failures into caller-facing refusals. */
function attempt(where, run) {
  try {
    return run();
  } catch (error) {
    if (/constraint|FOREIGN KEY|UNIQUE|CHECK/i.test(error.message)) {
      throw new ToolError(`${where}: ${error.message}`);
    }
    throw error;
  }
}

/**
 * Insert a row and return it as read back from the database.
 *
 * Read back rather than returned from the arguments, so what the caller sees is what was stored —
 * a column with a default the tool did not set, or a value the database normalised, is visible
 * instead of being reported as whatever was sent.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table
 * @param {Record<string, unknown>} values
 * @param {string} where The tool name, for the message.
 * @returns {object}
 */
export function insert(db, table, values, where) {
  const columns = Object.keys(values);

  // **`undefined` is not a value SQLite can bind, and the failure it produces is the wrong one.**
  // Found by mutation: dropping a column from a create tool's `required` list left the handler
  // reading `args.<column>` as `undefined`, and `node:sqlite` answered with a bare `TypeError` —
  // "Provided value cannot be bound to SQLite parameter 3", carrying no `rpc` code and so
  // reaching the caller as *Internal error*. That tells them the server is broken when what
  // happened is that their call was. A column with no value is NULL, said explicitly, or it is a
  // refusal that names the column; it is never a crash.
  for (const column of columns) {
    if (values[column] === undefined) {
      throw new ToolError(`${where}: no value supplied for ${table}.${column}`);
    }
  }
  const sql = `INSERT INTO ${table} (${columns.join(', ')}) `
    + `VALUES (${columns.map(() => '?').join(', ')})`;

  attempt(where, () => db.prepare(sql).run(...columns.map((column) => values[column])));

  return readById(db, table, values.id, where);
}

/**
 * Read one row by primary key.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table
 * @param {string} id
 * @param {string} where
 * @param {string} [key] The primary key column, where it is not `id`.
 * @returns {object}
 * @throws {ToolError} If there is no such row — an absent artefact is a caller mistake, and
 *   returning null for it would let a read failure pass as an empty artefact.
 */
export function readById(db, table, id, where, key = 'id') {
  const row = db.prepare(`SELECT * FROM ${table} WHERE ${key} = ?`).get(id);

  if (!row) throw new ToolError(`${where}: no ${table} with ${key} '${id}'`);

  return row;
}

/**
 * Update the named columns of one row and return it as read back.
 *
 * @param {import('node:sqlite').DatabaseSync} db
 * @param {string} table
 * @param {string} id
 * @param {Record<string, unknown>} values Only the columns present are written.
 * @param {string} where
 * @param {string} [key]
 * @returns {object}
 * @throws {ToolError} If no row was changed. `UPDATE` matching nothing reports success, which is
 *   the same silent-nothing shape `allocateNumber` guards against for the same reason.
 */
export function update(db, table, id, values, where, key = 'id') {
  const columns = Object.keys(values);

  if (columns.length === 0) throw new ToolError(`${where}: nothing to update`);

  const sql = `UPDATE ${table} SET ${columns.map((column) => `${column} = ?`).join(', ')} `
    + `WHERE ${key} = ?`;

  const changed = attempt(where, () =>
    db.prepare(sql).run(...columns.map((column) => values[column]), id));

  if (changed.changes === 0) throw new ToolError(`${where}: no ${table} with ${key} '${id}'`);

  return readById(db, table, id, where, key);
}
