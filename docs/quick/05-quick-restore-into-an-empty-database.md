# A database that exists and holds nothing is a database the dump should restore into

**Number**: 05  
**Status**: complete — Delivered. The state this covers is the one this repository was in for three months.  

**Closed**: 2026-08-26T12:37:35.000Z  

## The change

The automatic restore fired on an *absent* database and nothing else. "Nothing worth keeping" was implemented as "no file", and that is too narrow by exactly one case: a database can exist and have never held an artefact — created by a run that opened it and wrote nothing, or by a version whose first call created the file before deciding anything. It then sits beside a dump full of rows and `existsSync` declines to restore forever, while every read succeeds by returning nothing.

Silent in both directions, which is why it survived. An empty planning database and a project with no planning yet answer every question identically.

The condition is now `document` and `number_sequence` both empty. The second half is what makes it safe to act on: every artefact is a document and every document allocates a number, numbers are not reclaimed, so a user who deleted their corpus still has the sequences and is never restored over. An existing file that passes the test is removed before the restore, because a dump carries its own `CREATE TABLE` statements and needs a schema-less database.

## Files affected

- `dpm/src/server/from-dump.js` — `restoreIfMissing` becomes `restoreIfUnwritten`, returning `false | 'absent' | 'unwritten'`; new private `unwritten()` helper; an existing empty file is removed before the restore.
- `dpm/src/server/index.js` — two report lines, so the unusual open names what actually happened to the file (FR10).
- `dpm/tests/restore-on-create.test.js` — two new tests, one integration and one with a control.
- `dpm/tests/support/recorders.js` — the renamed import.

## How it was found

From the question of which starting states are covered: without a database, with an empty one, with a populated one. The first and third were; the middle one was not, and this repository had been sitting in it since 13 August — a database created empty, a committed dump holding 27 documents beside it, and three months of DPM work invisible to every session that opened it.

The dump-ordering defect fixed earlier in the same session is what made it visible. Without an import that refused, nothing about an empty database looks like a fault.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A database that exists and has never held a planning artefact restores from the dump beside it. | `restoreIfUnwritten` now tests the file rather than only its presence: `document` and `number_sequence` both empty. Covered by an integration test that opens a directory with no dump (creating an empty database), commits a dump beside it, and asserts the next session answers from it. |
| ✓ | A corpus somebody cleared on purpose is not restored over. | The second half of the condition is what buys this. Numbers are never reclaimed, so a `number_sequence` row outlives the document that caused it and a cleared corpus is distinguishable from one that was never written. Asserted with a control that deletes the sequences too and watches the same location restore. |
| ✓ | A user whose file was replaced is told that, rather than told there was no file. | `restoreIfUnwritten` returns `false \| 'absent' \| 'unwritten'` and `open()` prints a different line for each. The integration test matches the replacement wording on stderr; the existing one-line/silent-create assertions are unchanged. |
| ✓ | Anything the check cannot positively prove empty is left alone. | `unwritten()` returns `false` on every throw — an unreadable file, a database with no schema. The caller is deciding whether to delete a file, so "could not tell" and "has been used" have to reach it as the same answer. |
| ✓ | `node --test` stays green across the whole DPM suite. | 821 tests, 821 passing, including the two new ones. |
