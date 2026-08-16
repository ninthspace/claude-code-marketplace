# Retro: Freshness, Ralph Multi-Select and Cross-Project Search

**Date**: 2026-08-15  
**Source**: docs/epics/48-07-epic-freshness-selection-search.md  
**Stories**: 3/3 complete

## Summary

The spec's three Should-haves, built on foundations the earlier epics had already verified: a
freshness cache so a warm board does not re-query everything, a `space` multi-select that turns
several ready epics into one `/dpm:ralph` command, and a search that crosses every registered
project. The board's suite went from 205 to 229; `dpm`'s Node suite stayed at 707, with one addition
to its handshake.

**The recurring shape this time is the derivation that has nowhere to derive from.** Three times the
obvious implementation needed a fact the board had no way to obtain, and each time the answer was
different. The schema version genuinely did not exist on the wire, so dpm now reports it. The ralph
eligibility rule looked like a list of three excluded kinds and turned out to be one property of a
table that already existed. The search's document resolution had *no* honest derivation for ten of
dpm's fifteen indexed entities, and the right answer was to carry the absence rather than invent it.

The second theme is **the mutation that survives because the test does not exist**. Retro 51's rule —
treat a survivor as a question about the producer before treating it as a missing assertion — was
applied at this epic's gate and earned its place four times across three stories. Two of those
survivors were tests that passed for the wrong reason and would have gone on doing so.

## Observations

### Codebase Discoveries

- **The schema version reaches an MCP client only through the `initialize` handshake.** The  
  connection is not open when `initialize` is answered (AD12 defers it) and no read tool reports it,  
  so `serverInfo` was the only surface available. `src/server/mcp.js` now takes the block as a  
  parameter rather than closing over its module constant, and `serve()` defaults it to  
  `targetVersion()` — which keeps `mcp.js` knowing nothing about schemas.
- **A cache consulted before the spawn cannot know the schema on its first read.** That is not a bug  
  to work around: the first read of every session goes out, as does every read that started before  
  that first handshake came back. An entry is never served against an unknown schema, because a  
  guessed version serves the wrong derivation silently. The docstring first claimed "one handshake  
  per session" and the concurrency makes that optimistic; it now says what is true.
- **`search` answers over fifteen indexed entities and none of them shares an ancestor column.**  
  `requirement.spec_id`, `story_criterion.story_id`, `task.story_id`, and so on — each its own. There  
  is no tool that answers "which document is this row under", so a board resolving a hit to an epic  
  would be reimplementing ancestry per table.
- **The `document_section` entity is the one that resolves cheaply**, because its own row carries  
  `document_id`. It is also where every document's prose is indexed, so one extra unscoped read per  
  project covers the bulk of what a search matches.
- **A `Result` can name a document that is not a row on the board.** The Epics column is built from  
  epics alone; a spec's section carries a perfectly good `document_id` that the cursor cannot be moved  
  to. "Resolved to a document" and "resolved to a row on the board" are two different properties and  
  the second is the one that matters.
- **`●` was already taken.** The live-session pill uses it, on the same board, meaning a session  
  running *now*. The ralph marker is `▸`. Two markers a user has to tell apart by position are one  
  marker as far as a glance is concerned.
- **A leading marker is invisible to every existing assertion.** `text_of` strips each painted strip,  
  so a blank in the marker's place leaves an unselected row's text byte-identical to what every test  
  before this story asserted. That is what made a marker on every epic row a safe change, and it is  
  worth knowing before designing the next one.

### Testing Gaps

- **A test can be discriminating for a reason you did not choose.** The empty-selection criterion  
  compares the board's target against `launch_target()` called with *two* arguments — 48-05's own  
  signature. Comparing against the board's own three-argument call would agree with the always-ralph  
  board the criterion exists to catch. That was accidental when written and is now stated in the  
  test, because the next person to tidy the call would silently remove the whole point of it.
- **A whole-tree hash cannot see what the session itself deleted.** The cache must-NOT hashes the  
  project before and after a full board session — and that session runs the clear, which removed a  
  cache redirected into the project before the second snapshot. The mutation survived. The test now  
  also asserts the path the cache is *still pointing at* when the session ends, which outlives the  
  clear.
- **The first read of a session always misses, so a two-session test proves nothing about staleness.**  
  The schema-invalidation test looked correct: write under schema 1, reload under schema 2, observe a  
  call. The call was the unconditional first-read miss. It now runs three sessions with a warm-up read  
  each, and the middle one — same schema — is the control that makes the third mean something.
- **Containment width needs its own test, every time there is a new containment arm.** Retro 52  
  established this for the survey; the search's arm was written with the same comment and no test, and  
  `Exception` → `BaseException` survived the whole suite until a cancellation test existed.
- **A fixture constant can be structurally unable to reach a case.** `IN_A_SECTION` sits under an  
  epic, so no query using it can exercise the guard that keeps a resolved document inside the Epics  
  column. The mutation dropping that guard survived 228 tests. The fix was a second constant pointing  
  at the fixture's *spec* section.
- **A test whose subject is a set should assert the set, not a member.** The eligibility test asserts  
  a floor (something is selectable — a rule admitting nothing passes every must-NOT while making the  
  feature unreachable) and a ceiling (the admitted set is a **proper** subset of the model's kinds — a  
  rule admitting everything is the must-NOT itself).

### Patterns Worth Reusing

- **Derive the rule from the table that already encodes it.** A kind may go into a ralph selection  
  exactly when it launches `/dpm:do` singly, because `/dpm:ralph <epics…>` is the multi-epic form of  
  `/dpm:do <epic>`. All three of FR14's exclusions then fall out of `CANDIDATE_COMMANDS` rather than  
  being remembered, and a sixteenth kind is excluded until someone says what it launches.
- **Name the string the derivation turns on.** `DO` became a constant the moment three things depended  
  on it being one string. A literal in any one of them would have broken the derivation with nothing  
  failing.
- **Declare the call and let the reconciliation find the gap.** Adding `declare("search", …)` failed  
  every stand-in test as a surface mismatch until the stand-in advertised the tool. NFR5 doing exactly  
  what it is for, with no test written to check it.
- **Carry the absence rather than inventing the value.** A search hit the board holds no row for keeps  
  its project and a `None` document. Hiding those results would be the false negative dpm's own search  
  tool documents at length — an empty answer read as an absence.
- **Register two copies of one fixture to test attribution.** Identical corpora make the projects  
  indistinguishable by their hits, so the only thing that can tell results apart is the field naming  
  where each came from. Two *different* projects let attribution succeed by accident, from the text.
- **Put the failing project first.** The containment case registers the dead server ahead of the  
  healthy one, so a fan-out that stopped at the first failure returns nothing at all — and the  
  assertion is on the healthy project's own hits, because a fan-out that swallowed everything returns  
  an empty list without raising.
- **Drive the modal, do not dispatch the action.** Running `search` through `app.run_action` opens and  
  closes a screen and reaches neither the `search` call nor the read behind it. The session driver  
  types a query and waits for results, which is what makes 48-06's FR10 proof cover this path.

### Scope Surprises

- **A board epic changed dpm again, for the same shape of reason as 48-06.** The freshness stamp needs  
  the schema version and the protocol did not carry it. One parameter and one default, with an  
  assertion in dpm's own suite — but it is the second time in two epics that a board requirement was  
  unimplementable without a server change, which is worth noticing before the third.

### Criteria Gaps

- **FR15's "navigates back to its project and epic" is satisfiable for every result only if every  
  result has an epic, and not every hit does.** The criterion was verified as written for the results  
  that resolve, with the limit recorded on the coverage row and the reasoning on the story. Resolving  
  the remaining entities is a real feature and belongs to a spec that asks for it, not to a quiet  
  widening of this one.

### Smooth Deliveries

- **Three independent stories over verified foundations behaved exactly as the epic's Notes predicted.**  
  No integration story was written because the three share no seam — a cache failure cannot affect a  
  selection, and neither can affect a search — and nothing during the work contradicted that. The one  
  cross-cutting property, NFR2's containment over the fan-out, was asserted where the fan-out happens.
