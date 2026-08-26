# The rebuild replaced the database, then refused to replace it

**Number**: 04  
**Status**: complete — Delivered. The assertion that should have caught this had been green since epic 49-04 and could not vary.  

**Closed**: 2026-08-26T14:10:00.000Z  

## The change

`rebuild` restored into a staging database, renamed it into place, and only then asked whether the dump survived its own restore. So the refusal — "committing it would commit a state nobody reviewed" — was issued about a state that was already the database. Observed doing exactly that: an import refused, having first replaced a one-document database with a twenty-seven-document one.

The staging file and the rename exist to make a failed rebuild leave the user where they started. Putting the check after the rename gave that up for the one failure the check exists to catch.

The check now runs on the staging connection, before the rename. A refusal discards the staging file and the target is untouched. Publish and the re-guard stay after the rename, where they need the database in place.

## Files affected

- `dpm/src/rebuild/index.js` — the round-trip check moved inside the staging block; the catch re-throws a `RebuildError` unwrapped so a refusal keeps its own words.
- `dpm/tests/rebuild.test.js` — the refused dump now describes a different database, with a control asserting it does.

## How it was found

Not by the suite, and not by inspection. The assertion for this exact property has been in `rebuild.test.js` since epic 49-04 and passed throughout, because its two states were indistinguishable by the slugs it compared: the fixture built the refused dump by editing the dump the database had been restored from, so both sides read `[already-here]` whether or not the replacement happened.

It surfaced because an import refused in a real repository and the database afterwards held what the refused dump described. A test whose subject cannot vary is a test that reports on nothing, and a control is what would have caught it — which is why one is now beside it.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A rebuild whose dump does not survive its own restore leaves the database as it found it. | The round-trip check moved inside the staging block, before `renameSync`. A refusal now discards the staging file and returns without the target having been touched. |
| ✓ | The refusal still says what it refused, in the words both callers print. | The catch re-throws a `RebuildError` unwrapped and frames only errors arriving from elsewhere. Without that, a round-trip refusal raised inside the try would be reworded as "the dump did not restore into…", which is a sentence about a restore that in fact succeeded. `merge.test.js`’s verbatim-message assertion still passes. |
| ✓ | The assertion that claimed this property can now see it fail. | It could not before: the fixture built the refused dump by editing the same dump the database was restored from, so it compared `[already-here]` against `[already-here]` and passed either way. The refused dump now describes a different database, with a control asserting the two differ. Verified by restoring the old ordering and re-running: the test fails. |
| ✓ | `node --test` stays green across the whole DPM suite. | 819 tests, 819 passing. |
