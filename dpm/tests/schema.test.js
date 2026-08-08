/**
 * Story 1 — the four schema-wide criteria, each read out of `sqlite_schema` and the
 * `PRAGMA`s rather than out of a list someone maintains.
 *
 * That is the point of writing them this way: a hand-kept list of "tables with a composite
 * foreign key" is a second description of the schema, and a second description is the drift
 * this whole spec exists to remove. A table added in Story 3 is covered by these tests on the
 * day it lands, without anyone remembering to add it.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openDatabase } from './support/database.js';
import { applySchema } from '../src/schema/index.js';
import { authoredTables, foreignKeys } from './support/introspection.js';

test('every column named *_id is a foreign key, with no exceptions list (AD7)', (t) => {
  const db = applySchema(openDatabase(t));
  const loose = [];

  for (const table of authoredTables(db)) {
    const constrained = new Set(foreignKeys(db, table).flatMap((fk) => fk.from));

    for (const column of db.prepare(`PRAGMA table_info(${table})`).all()) {
      if (column.name.endsWith('_id') && !constrained.has(column.name)) {
        loose.push(`${table}.${column.name}`);
      }
    }
  }

  assert.deepEqual(loose, [], 'an unconstrained *_id column is the **Source spec** string in a column');
});

test('every foreign key into document is kind-pinned, except the ones the Data Model names', (t) => {
  const db = applySchema(openDatabase(t));

  // Transcribed from the Data Model's paragraph "The references that stay unpinned are
  // enumerated here, and this list is the authority." It is a list and not a count on
  // purpose: the count went stale four cycles running and a list cannot. `number_sequence`
  // arrives in Story 3 and `dependency`'s two ends in Story 4, so three of these seven are
  // legitimately absent here — the assertion is that nothing outside the list is unpinned,
  // never that everything in it exists yet.
  const KIND_AGNOSTIC = new Set([
    'document_section.document_id',
    'artifact_document.document_id',
    'retro_application.applied_to_id',
    'number_sequence.parent_id',
    'document_milestone.document_id',
    'dependency.source_document_id',
    'dependency.target_document_id',
  ]);

  const pinned = [];
  const unpinned = [];

  for (const table of authoredTables(db)) {
    for (const fk of foreignKeys(db, table)) {
      if (fk.table !== 'document') continue;
      const name = `${table}.${fk.from.join('+')}`;
      ([...fk.to].sort().join(',') === 'id,kind' ? pinned : unpinned).push(name);
    }
  }

  assert.deepEqual(
    unpinned.filter((name) => !KIND_AGNOSTIC.has(name)),
    [],
    'a foreign key naming document(id) alone is only correct where every kind is a legal target',
  );

  // Without this the test passes on a schema with no composite foreign keys at all — every
  // reference unpinned, nothing outside the list, and a green run saying so.
  assert.ok(pinned.length > 0, 'and the kind-pinned references are the majority of them');
  assert.ok(
    pinned.length > unpinned.length,
    `${pinned.length} pinned against ${unpinned.length} deliberately unpinned`,
  );
});

test('every primary key is TEXT, and every table has one', (t) => {
  const db = applySchema(openDatabase(t));
  const missing = [];
  const wrongType = [];

  for (const table of authoredTables(db)) {
    const key = db.prepare(`PRAGMA table_info(${table})`).all().filter((c) => c.pk > 0);

    // "Every primary key is TEXT" is vacuously true of a table with no primary key, which is
    // the false pass this half is here to close.
    if (key.length === 0) missing.push(table);

    for (const column of key) {
      if (column.type.toUpperCase() !== 'TEXT') wrongType.push(`${table}.${column.name} ${column.type}`);
    }
  }

  assert.deepEqual(missing, [], 'a table with no primary key satisfies any claim about its primary key');
  assert.deepEqual(wrongType, [], 'AD9: every surrogate key is a ULID stored as TEXT');
});

test('no UNIQUE constraint rests on a column that can be NULL', (t) => {
  const db = applySchema(openDatabase(t));

  const indexSql = new Map(
    db.prepare("SELECT name, sql FROM sqlite_schema WHERE type = 'index'").all().map((r) => [r.name, r.sql ?? '']),
  );
  const resting = [];

  for (const table of authoredTables(db)) {
    const notNull = new Map(
      db.prepare(`PRAGMA table_info(${table})`).all().map((c) => [c.name, c.notnull === 1]),
    );

    for (const index of db.prepare(`PRAGMA index_list(${table})`).all()) {
      if (index.unique !== 1) continue;

      for (const column of db.prepare(`PRAGMA index_info(${index.name})`).all()) {
        if (column.name === null) continue;               // an expression, not a column
        if (notNull.get(column.name)) continue;
        // A nullable column is admissible only where the index's own WHERE clause excludes
        // the NULLs. An implication that runs through a CHECK elsewhere does not count:
        // nothing reading the index can follow it.
        if (new RegExp(`\\b${column.name}\\s+IS\\s+NOT\\s+NULL`, 'i').test(indexSql.get(index.name) ?? '')) {
          continue;
        }
        resting.push(`${table}.${column.name} (index ${index.name}, origin ${index.origin})`);
      }
    }
  }

  // `origin: 'pk'` entries are included on purpose. SQLite implies NOT NULL only for
  // INTEGER PRIMARY KEY, so an undeclared TEXT primary key is a unique index over a nullable
  // column — which this test caught, on `document.id`, before anything joined to it.
  assert.deepEqual(resting, [], 'SQLite treats NULLs as distinct, so such a UNIQUE rejects nothing');
});
