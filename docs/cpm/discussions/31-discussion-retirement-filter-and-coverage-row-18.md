# Discussion: What to do with the two open observations from Epic 47-05 — the inert `retirement.js` filter bug, and coverage row 18

**Date**: 2026-08-09  
**Agents**: Bella

## Discussion Highlights

### Key points so far

- Two observations carried out of Epic 47-05 (complete, 407/407 green, uncommitted since `1d27276`):
  1. `dpm/src/schema/retirement.js:39` keeps virtual tables in `authoredTables` (`name !== v &&`  
     where the fixed copy in `tests/support/introspection.js:45` has `name === v ||`). Recorded,  
     not fixed, on the grounds that no test could fail without the fix.
  2. Coverage row 18 is the only unverified row of twenty. Criterion says a persona "is offered by  
     `party`, `review` and `consult`"; those three skills still read `agents/roster.yaml` and  
     convert across two later epics (`review` → 47-07, `party`/`consult` → 47-08). The matrix's own  
     mapping note scopes the row to "the *tool* half", which Story 2 verified.

- **Evidence gathered before Bella responded** (probe against a live migrated database):
  - `PRAGMA foreign_key_list` returns `[]` for both `document_fts` and `entry_fts` — the bug is  
    inert because a virtual table cannot declare a foreign key.
  - `vocabularyReferences(db)` → 11 references, 0 naming a virtual table; `createRetirementGuards`  
    → 22 guards. Identical with or without the fix.
  - **`dpm/tests/vocabulary.test.js:343` already independently derives the expected guard set** using  
    the *fixed* `authoredTables` and `deepEqual`s it against the triggers actually in the schema.  
    So the divergence is not merely theoretically inert — it is fenced: the moment the bug had a  
    consequence (a virtual table acquiring a reference), the generator would emit a guard the test's  
    expected side does not list, and the deepEqual fails.

### Decisions taken (user, 2026-08-09) — both executed

**1. Fix `retirement.js`.** `name !== v &&` → `name === v ||` at line 39, docblock rewritten to say
virtual tables are excluded and why the divergence was inert. Output identical before and after (11
references, 22 guards); suite 407/407. Bella's fence claim was then driven rather than asserted:
dropping `finding` from the generator's table walk fails `vocabulary.test.js:343` ("every reference
into a retirable table carries a guard") plus one other — so generator/checker divergence in the
direction that matters is genuinely held. Reverted.

**2. Split row 18** — Bella's third option, neither narrowing nor moving:

- **47-05** Story 2 criterion 5 and matrix row 18 → the tool half only ("joins the roster in  
  position among the seeded personas, with no plugin change, no file edit and no schema  
  migration"). Marked ✓. Spec Text column left untouched — the sentence is what it is.
- **47-07** Story 4 (`review`) → new criterion + matrix row 32.
- **47-08** Story 7 (`consult`) → new criterion + matrix row 32.
- **47-08** Story 8 (`party`) → **no new row**: row 17 already says the roster loads from the  
  `agent` table with no YAML parse, and a roster read from the table offers an added row by  
  construction. A fourth row would assert the same thing twice.
- Mapping notes at all three ends record where the row came from and why the split beat both  
  alternatives. Epic 47-05 status → all twenty rows verified.

**3. A recurrence found while editing.** The roster count "ten" (seeds hold nine) was still in the
epic doc in two places the 2026-08-08 correction never reached — Task 2.1's description and the
Notes. Correcting the number a third time would have set up a fourth, so **the count was removed
from all three** ("the whole roster", "the seeded personas"). Retro 35's lesson applied rather than
cited.

Verified: every matrix row's criterion text matches a criterion in its epic doc, across all three
pairs (0 mismatches). dpm 407/407. cpm 6 pre-existing failures, unchanged and untouched — nothing
under `cpm/` is modified.

### Active thread

Bella gave her read on both. On (1) she rejected the "no test can hold it" reasoning — the fence
already exists at `vocabulary.test.js:343`, so the fix is one line held by an assertion that is
already there. On (2) she argued both options previously named were incomplete, because the
criterion names three skills converting in two different epics, and proposed splitting the row
instead. Both were executed and committed in `abb4390`.
