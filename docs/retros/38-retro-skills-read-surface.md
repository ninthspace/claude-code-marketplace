# Retro: Skills — Read Surface

**Date**: 2026-08-10  
**Source**: docs/epics/47-08-epic-skills-read-surface.md  
**Stories**: 9/9 complete

## Summary

Eight of FR25's twenty-two skills converted to read through typed tools, plus a cross-story
sweep. Three substrate additions landed inside the epic (`document_section.superseded_at`,
`artifact.retired_at`, `preview_document_kind` with a readable `document_kind`), the register
became the projection's first non-document output, and eight findings were carried forward to
a pivot that turned five of them into spec amendments.

Two things dominate the thirty observations. The **three-direction binding is file-scoped**,
and five separate stories lost a mutation to that same fact before it was stated plainly —
each fixed locally, none fixed once. And **every schema gap was found by a consumer**: not one
came from reading the schema, which is the whole argument for walking the reads before writing
the file.

## Observations

### Testing Gaps

- **`bindings()` answers a question about the file, never about the step.** Stories 1, 2, 3, 4  
  and 7 each lost a mutation to this: a phase's inventory read went silent and the file still  
  answered yes on another phase's behalf; a scoped list rewritten as an unscoped one returned  
  the same rows; an intersection rewritten as a union computed the right answer in the test; a  
  step's `include_body` was covered by a shared section that names it for different reads. The  
  settled practice — reached story by story rather than up front — is that where a criterion is  
  about a *judgement* (which scope, which set operation, which shape of answer) rather than  
  about which rows come back, the assertion runs on that step's own text. Story 4 sharpened it  
  again: the numbered step and the paragraph under it can diverge, so `instructions()` and  
  `prose()` are not interchangeable.
- **Three quantifier failures, all of which make the assertion vacuous rather than wrong.** A  
  criterion saying *derived from the input* needs two inputs, or a fixed cast passes it. A sweep  
  saying *renders somewhere* is blind to a duplicated fact losing one copy — `artifact.description`  
  has two renders and survived the entire suite. And a mutation that never reached the path the  
  test drives is not a survivor at all; two of Story 9's thirteen were mis-aimed and both caught  
  once re-pointed.

### Criteria Gaps

- **A sweep's precondition can be false for exactly one table.** `document_kind` is a closed set  
  of thirteen with no create tool, and two of `reading.test.js`'s sweeps require fifty-plus rows  
  within reach. The exemption is named with its reason, scoped to those two sweeps rather than to  
  the whole `paged` set, and paired with a control asserting the table is still small — so it  
  fails when its reason expires instead of quietly outliving it.

### Codebase Discoveries

- **The surface refuses what it never anticipated, and refuses it quietly.** `entityTools` drops  
  nulls, so a waiver cannot be lifted and the refused clear reports success — the third story to  
  hit that, carried since retro 36. `list_artifact_document` was scoped one way only.  
  `artifact.url` and `published_at` are both `NOT NULL`. `review_agent` is kind-pinned to  
  `review`. `document_kind` was neither readable nor listable. The shared `Perspectives`  
  procedure loads a roster without `include_body` and renders voices off nothing. Every one was  
  found by a consumer reaching for it; none by reading the schema.  
  **Retired 2026-08-11**: promoted to docs/library/lessons-learned.md
- **Shared machinery encodes an assumption, and the first case that breaks it looks like it  
  works.** A `live` column is three changes (tool list, projection descriptor, pinned version),  
  not one. `retired_at` on a *record* is not `retired_at` on a *vocabulary*, so the retire-verb  
  enumeration needed a named exception rather than a second list. A hand-rolled list tool is a  
  list tool exempt from every guarantee `LISTS` makes — declaring it cost one line and picked up  
  the bound, the paging, the order, the shape and the tiebreaker. `driveStartup` is a decoy for a  
  skill whose startup is not the common one. And the projection had exactly one shape — one file  
  per `document` row — until the register; it fits only because `orphans()` keys on a seeded kind  
  and `index.md` carries none, which was verified rather than assumed.

### Patterns Worth Reusing

- **The fixture carries the decoy the wrong answer would also return.** Applied from retro 37 as  
  a disposition and paid across all nine stories: a source two artifacts do not share separates  
  union from intersection; a persona the plugin never seeded plus one retired catches a roster  
  read from anywhere but the table; a term held on a single child row catches a search reaching  
  one index; a control that must throw `ENOENT` after the deletion separates "the skills do not  
  read the tree" from "this test does not read the tree".
- **Assert against the consequence, not the argument.** A covered requirement placed past the  
  first page proves the bound mattered where `passed.has('limit')` only proves it was supplied.  
  An exclusion is counted in sections *consulted*, not documents *seen*. A preview is compared  
  with `renderDocument`'s bytes rather than checked for looking like an epic. And when a new  
  output moved four counts across three suites, each was fixed by naming the register and  
  re-asserting the remainder — so a fifth output fails with the name of what changed rather than  
  an off-by-one.
- **Drive both sides of a branch through the same function.** Create and update are one `run()`  
  against a project where the artifact exists and one where it does not; asserting only the  
  update half passes a skill that always reuses the first artifact it finds.

## Recommendations

- **Decide the `bindings()` question once, before Epic 47-09's first conversion.** Five stories  
  paid for the same file-scoped limitation with five local fixes. Either build a step-scoped  
  binding in `tests/support/`, or record that it cannot be built and make "which criteria are  
  judgements about shape?" an opening step of every test-writing task, so the assertion is  
  designed in rather than found by a survivor.
- **Walk the consumers before building the substrate, not after.** All five spec amendments came  
  from conversions reaching for something absent. Epic 47-09's Stories 8 and 9 build those  
  amendments — walk them against the fourteen remaining skills first, because the pattern says  
  the next gap is already sitting in an unconverted file.
- **Confirm a mutation reached the path under test before recording it as a gap.** Two of Story  
  9's thirteen read as survivors and were not. One line of evidence — the branch the test drives  
  — turns a false finding into a caught one.
- **Pin a column with more than one render; sweep only columns with one.** The four `artifact`  
  columns are pinned to `docs/artifacts/index.md`. Any new dual-render column needs the same, and  
  the way to find it is to mutate each render separately rather than to reason about the sweep.
- **Keep the exemption-with-a-control shape.** `document_kind`'s sweep exemption carries its  
  reason, its scope, and a test that fails when the reason stops being true. Any further  
  exemption in `reading.test.js` should be built the same way.
