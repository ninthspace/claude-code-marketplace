# A restore replayed the coverage rows through the decay triggers and cleared 40 claims

**Number**: 03  
**Status**: complete — Delivered. Found by rebuild’s round-trip check during an unrelated import; the 819-test suite had passed over it.  

**Closed**: 2026-08-26T13:30:00.000Z  

## The change

`dpm-import.js` refused to rebuild this project's database, reporting that the dump did not survive its own restore. It was right to.

The dump emitted every trigger before any row, which is deliberate and load-bearing for one class of trigger: an FTS5 index is not carried in the file, so restoring `document_section` row by row is the only thing that rebuilds it. But the same ordering also replayed the `coverage` rows through `requirement_unclaim_on_coverage_insert`, whose job is to decay a completeness claim when a user adds coverage. A restore is a replay, not an edit. Forty of this project's fifty-four requirements lost both `coverage_claimed_at` and `coverage_claim_hash` — recorded facts, with a time and a hash, that nothing regenerates.

The fix splits the triggers by what they write to. A trigger that maintains a virtual table goes before the rows, because the thing it maintains is derived and absent from the file. Every other trigger goes after them, because replaying a row is not editing it. The retirement guards are deferred by the same rule; they write nothing, so deferring them costs only their validation during the replay, and `checkIntegrity` runs over the restored database afterwards holding the same invariants from the register.

## Files affected

- `dpm/src/dump/objects.js` — new `maintainsVirtualTable` predicate, matching on the trigger's body rather than its name.
- `dpm/src/dump/schema.js` — `dumpSchema` returns `sql` and `deferred`, each in `sqlite_schema` order so the same database still produces the same bytes.
- `dpm/src/dump/index.js` — four parts, not three: preamble, schema, rows, deferred triggers.
- `dpm/tests/decay.test.js` — the regression, in the suite that owns the decay triggers.
- `.dpm/dpm.sql` and `.dpm/dpm.db` — this project's own artefacts, repaired and re-emitted.

## How it was found

Not by the suite. 818 tests passed over the defect, and the existing assertion that a refused rebuild leaves the database unreplaced cannot see it either — its before and after are indistinguishable by the slugs it compares.

What found it was `rebuild`'s round-trip check, on real data, during an unrelated import. That is the check earning its keep: it compares the dump a restored database produces against the dump it was built from, and refuses rather than committing a state nobody reviewed.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A dump whose requirements carry completeness claims restores into a database that still carries them. | Asserted over the mechanism rather than over the ordering: `decay.test.js` builds a claimed requirement with a bound coverage row, dumps, restores into a fresh database, and reads the claim back. Ordering is how it is fixed today; surviving the restore is what has to stay true however it is fixed tomorrow. |
| ✓ | The dump emits the triggers that maintain a derived index before the rows, and every other trigger after them. | `dumpSchema` returns two halves and `dump` composes PREAMBLE, schema, rows, deferred. The split is `maintainsVirtualTable`, which asks what the trigger writes to rather than what it is called — a naming-convention test would defer a future index trigger and restore into an empty index, which is the false pass the existing exclusion logic already warns about. |
| ✓ | The regression fails without the fix. | Verified by reverting the composition in `dump/index.js` to the old order and re-running: 13 pass, 1 fail, and the failing one is the new test. |
| ✓ | `node --test` stays green across the whole DPM suite. | 819 tests, 819 passing. 818 before the new test, and none of them had caught the defect — the round-trip guard in `rebuild` was the only thing that did. |
| ✓ | This project’s committed dump and database carry the 40 claims, in the new ordering, with the guard clean. | The committed dump was in the old ordering, so restoring it would still have decayed the claims. Repaired by restoring it, re-asserting each claim through `claimComplete` with the recorded timestamp, and refusing unless every one of the 40 hashes reproduced from the bound set — all 40 did, so the values were recovered rather than invented. The re-emitted dump is byte-identical in size to the committed one and has a zero-line difference when sorted: a pure reordering. `dpm-guard.js` reports 21 projected files and the dump matching the database. |
