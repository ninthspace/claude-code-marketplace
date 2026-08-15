# Retro: Spec 48 — the dpm board, end to end

**Date**: 2026-08-15  
**Source**: docs/specifications/48-spec-dpm-board.md  
**Epics**: 7/7 complete — 48-01 … 48-07  
**Stories**: 30/30 complete  
**Synthesised from**: docs/retros/47–53 (one per epic), their epic docs and coverage matrices

## Summary

Spec 48 asked for a cross-project TUI over dpm's planning database and one amendment to dpm's server
that makes observing a project inert. It delivered both: a read-only server mode, a three-column
browser with previews, row-derived state under a written contract, tmux launch and attach, live
pills, four named failure states, a freshness cache, ralph multi-select and cross-project search.
Seven epics, thirty stories, a board suite from nothing to **229 passing**, `dpm`'s Node suite at
**707** and unmoved by six of the seven epics. Every Must-have and every Should-have is built; the
two Could-haves (FR16, FR17) are still deferred, and the Won't-Have list held without pressure.

Three things run through the whole chain rather than through any one epic.

**The absence that asserts nothing** appeared in six of seven epics and was never fully learned. Each
epic recorded the lesson in a sharper form — plan the control at criteria time (47), ask what would
have to exist for it to fail (50), produce the condition rather than simulating it (52) — and each
next epic met a *new* instance the previous formulation did not cover. Consuming the lesson stopped
the named instance recurring; it did not stop the shape recurring.

**The outside witness**, by contrast, transferred cleanly and is the practice this spec should be
remembered for. From 48-02 onward almost nothing is asserted from a component's own account of
itself: a transcript the server wrote, a pid the OS holds, the strips Textual actually painted, a
message regexed out of the other project's source, a filesystem hashed before and after.

**The board changed dpm three times, and only the first was planned.** AD1's read-only mode was in
scope; the schema-skew message (48-06) and the `schemaVersion` in `serverInfo` (48-07) were not. Both
were the same shape — a requirement about what the *client* can tell apart is a requirement on what
the *server* emits — and neither was visible in the spec.

## Observations

### Smooth Deliveries

- **The seven-epic sequence held exactly as planned.** Strictly linear, every `**Blocked by**` real,  
  no epic re-scoped or re-planned mid-chain, and the two epics whose stories were genuinely  
  independent (48-01, 48-07) said so in advance and were right. A dependency chain that never needed  
  editing is evidence the decomposition matched the work, which is the rarer outcome.
- **Scope discipline was total.** FR16 and FR17 were deferred at spec time and stayed deferred with  
  the tool surface sitting right there. The Won't-Have list — any write path at all — was never  
  approached, and FR10's proof turned it from a promise into a measured property. Four palette  
  actions were deliberately left unbuilt in 48-04 and each arrived in the epic that owned it, rather  
  than being stubbed to look complete.
- **`dpm`'s suite stayed at 707 through six board epics.** Run at the end of each one on retro 50's  
  recommendation, at a cost of one command. The two epics that *did* change dpm changed it in one  
  message and one parameter respectively, each with an assertion in dpm's own suite.

### Scope Surprises

- **Two board requirements were unimplementable without a server change, and the spec named neither.**  
  FR11's schema-ahead state was only logged on the migrate branch a read-only server never reaches;  
  AD6's freshness stamp needs a schema version that crosses no channel but `initialize`. Both were  
  found by producing the condition, not by reading. **The generalisation is worth carrying: a  
  requirement of the form "the client distinguishes X" silently specifies the server's observable  
  surface, and the spec that writes it is not obviously a spec about two components.** Retro 47 found  
  the first instance (`rpc.js` puts only `error.message` on the wire) before the board existed.
- **`DPM_DATABASE` is a silent, total failure the spec never mentions.** Inherited by a spawned  
  server, every project renders the status of whichever project that variable named — no error,  
  every row plausible. A reasonable implementer passes the environment through whole. The clause is  
  in the code and in retro 48's recommendations and nowhere in spec 48.
- **The status-model reconciliation found four contradictions and three were the board's.** AD5 was  
  written expecting to correct `dpm:status`; walking passage-by-passage from the skill — the obvious  
  way to run that pass — would have amended the skill in all four places and made the answers worse.  
  The registry-against-parsed-headings reconciliation is what made the direction of each contradiction  
  a finding rather than an assumption.
- **A criterion was amended mid-epic once, and a wrong fix shipped once.** 48-06's Story 3 named a  
  derivation empty by construction and was amended with the coverage row reset and re-verified;  
  48-04's Story 1 misdiagnosed a harness bug as a CSS bug, shipped a workaround with a confidently  
  false comment, and it survived three stories. Both are recorded where they happened.

### Criteria Gaps

- **Four gaps in a criteria table that is otherwise mechanically checkable end to end.** Every one of  
  the spec's sixty-odd rows carries an automated tag, no row is `[manual]`, and four still did not  
  say what they meant: NFR1's non-mutation criterion is vacuously true of any database at the current  
  version; FR11 names four states and the table lists three; FR15's "each result navigates back to  
  its project and epic" is unsatisfiable for ten of the fifteen entities `search` indexes; and the  
  `DPM_DATABASE` clause has no row at all because it has no requirement.
- **The common shape is a criterion written about a state of the world when the checkable fact is a  
  difference between two runs.** "Runs no migration and writes no row" is true of everything until  
  you have the ordinary open to compare against. "Renders normally without tmux" is true of a board  
  that never looks for tmux until `PATH` changes while it runs. Each of these was repaired by adding  
  the second run, never by rewording.
- **All four were recorded rather than quietly satisfied.** Each sits on a coverage row or a story  
  note with its reasoning, and none was fixed by an epic editing the spec it was implementing.  
  Repairing them is `/cpm:pivot`'s job and they are still open.

### Complexity Underestimates

- **The client shape, not any requirement, is where the cost was.** Nothing in FR2–FR4 reads as  
  expensive, and the hard problems were all consequences of owning no data: what can be asserted  
  about a process you cannot see inside, which guarantees are structural rather than checked, and  
  what a test can witness that is not the component's own account. Roughly a third of the chain's  
  test apparatus exists to answer those three questions.
- **Concurrency arrived a whole epic after the code that caused it.** One spawn lock for the entire  
  pool and `StreamReader`'s refusal of a second concurrent waiter were both written in 48-02 and both  
  surfaced in 48-04, under a twelve-project fixture that only existed because NFR3's single-project  
  criterion was known to be insufficient. Both were locks at the wrong granularity — one too coarse,  
  one missing.
- **External tools disagreed with their own documentation more than the codebase did.** 48-05's three  
  tmux findings were each documented behaviour, read correctly, and wrong for the case at hand;  
  Textual's `run_test()` silently disables the notifications an entire story's criteria depended on.  
  Neither class is visible in code review and both took one probe.

### Codebase Discoveries

- **The board's whole failure surface came out of asking what actually crosses the boundary.** dpm  
  splits a refusal across `error.message` (the JSON-RPC category) and `error.data.message` (the part  
  a user needs); the read-only server advertises all 181 tools and refuses 87 at call time, on  
  purpose, because an absent tool answers *Method not found* and explains nothing; a schema-ahead  
  database is byte-identical over the protocol and legible only on stderr. Every FR11 state is where  
  it is because of one of these.
- **dpm's derivations are subtler than their names.** A retired dependency *kind* still gates work  
  and `list_dependency_kind` hides it by default; `story.status` has four values, not two; specs are  
  root-numbered and epics child-numbered in one ordering function; `search` indexes fifteen entities  
  and no two share a parent column. Each of these produced a plausible, stable, wrong answer before it  
  was found, and three were found by reading a second document against the first rather than by a  
  failing test.
- **A single-file Python tool has resolution rules that read wrong.** ENV3's three server-path lookups  
  are two: the board ships inside the plugin, so one relative expression covers both checkout and  
  cache, and the glob is for the case where `board.py` was copied out alone — which PEP 723 invites.  
  Reading it as written would have preferred an installed 0.1.0 over the checkout being edited.
- **An app subclass shares one namespace with a large framework.** `self._register` and  
  `self._unregister` are Textual's; assigning injected callables over them broke screen mounting in a  
  traceback naming only framework code, and one of the two was shadowed for a whole story with  
  nothing failing.

### Testing Gaps

- **The absence that asserts nothing is this spec's signature defect, in six of seven epics.** A token  
  sweep that cannot follow a call. A must-NOT about not reading `.md` files, run against a project  
  with no `.md` files. A palette absence check both lists satisfied. A whole-session comparison whose  
  session did nothing. A derived set matched by every tool. A fixture constant structurally unable to  
  reach the guard it was aimed at. A tree hash blind to a file the session's own clear had deleted.  
  Every one passed review; not one was visible by reading the test.
- **The counter is always the same move, and it got cheaper each time it was made.** Produce the  
  forbidden condition, then watch the test not care. By 48-06 this was routine — every failure state  
  is produced rather than simulated — and 48-07 still found two tests passing for the wrong reason,  
  which is the honest measure of how far the habit had got.
- **Mutation testing compounded across the chain in a way no other practice did.** 48-03 established  
  that a surviving mutation is a question about the producer first; 48-05 that mutations run against  
  the *whole* suite, not the story's file; 48-06 that the breadth finds things the mutation was not  
  aimed at, including an unrelated fixture flaky at one run in five; 48-07 planted sixteen and had  
  four survive, each naming a missing test rather than a missing assertion. **Four of seven epics had  
  a finding that came from the breadth of the run rather than from the mutation chosen.**
- **Retro consumption prevents the instance, not the shape.** Sixty-six `**Retro applied**`  
  breadcrumbs across the seven epics, all Applied, twenty-five of them citing retros written earlier  
  in this same chain — the chain genuinely fed itself in real time. And the three largest findings of  
  the last four epics were all found by running, not by consuming. Both facts are true and the second  
  is the one to plan around.
- **Editing a skill needs the product's suite, not the tool's.** 48-03's amendment to `dpm:status`  
  wrote a name the harness does not dispatch and failed `reachability.test.js`, while the board's  
  own 103 tests stayed green throughout. A corpus sweep guarded exactly the thing the amendment  
  broke, in a suite there was no obvious reason to run.

### Patterns Worth Reusing

- **Assert from an outside witness.** The recording stand-in server, configured entirely by  
  environment, made four unrelated criteria assertable at once and kept test apparatus out of the  
  shipped binary. Pids are signalled rather than counted. Rendered strips are read rather than widget  
  state. Filesystems are hashed. The rule that generalises: if the only thing that can fail the test  
  is the component agreeing with itself, it is not a test yet.
- **Reconcile two enumerations in both directions, and put a floor under it.** Used four times —  
  `declare()` against `tools/list`, `DERIVATIONS` against the contract's headings, FR11's states  
  against their remedies, the session driver against `COMMANDS`. Every one has a `reconcile({}, {})`  
  case, because nothing-against-nothing is the only comparison a set difference cannot fail.
- **Generate the other side's expectation from the other side's source.** dpm's Node refusal comes  
  from calling `assertNodeFloor`; the floor version is regexed out of `node-floor.js`; the picker's  
  message is derived by running `run_cli`; the system command list is asked of Textual. A  
  transcription passes for exactly as long as it takes someone to reword the original, which is the  
  only moment it matters.
- **Refuse rather than default, and carry an absence rather than inventing a value.** `style_for()`  
  raises on an unknown state; `progress([])` returns `None` because 0/0 is complete by every reading;  
  a highlighted row with no candidate raises `NoTarget`; a search hit with no row on the board keeps  
  its project and a `None` document. In each case the default would have rendered as a working board.
- **Ask at the point of use, not at startup.** `shutil.which` per keypress, `self._driver.can_suspend`  
  where the suspend happens, `include_retired: true` at the one call that needs it. The difference  
  between a board that is wrong for a session and one that is wrong for a keystroke, and it costs  
  nothing.
- **Derive the rule from the table that already encodes it.** FR14's three exclusions fall out of  
  `CANDIDATE_COMMANDS` rather than being listed, so a sixteenth candidate kind is excluded until  
  someone says what it launches. The same instinct as `declare()` and `COMMANDS`: one table, several  
  questions, no second list to drift.
- **Point at a rule; never transcribe it.** AD5's contract cites `readyClause` and the status enum  
  instead of reproducing them; test expectations read `CONTENT` rather than the fixture's shape;  
  fixture rows are named by role. Every transcription this chain contained eventually disagreed with  
  its source.

## Recommendations

- **Before writing a requirement about what a client can distinguish, name the channel that carries  
  it.** Three of this spec's surprises were this exact question asked too late, and each cost a  
  change to a component the spec did not think it was about. Spec 49 touches the same boundary.
- **Keep the whole-suite mutation pass as the epic gate.** It is the only practice here that found  
  something in every epic it was applied to, and it found things nobody was looking for in four.  
  Per-file runs would have reported three of those as coverage gaps and produced the wrong fix.
- **Repair spec 48's four recorded criteria gaps through `/cpm:pivot`, not through a future epic.**  
  NFR1's vacuous non-mutation wording, FR11's missing fourth state, FR15's partial resolution and the  
  unrequirement of `DPM_DATABASE` are all documented at their site with the discriminating pair  
  beside them. An epic that would rather they read differently is the wrong instrument.
- **FR16 and FR17 are now cheaper than when they were deferred.** `list_coverage` and  
  `check_integrity` are one declaration each over a surface that exists, a pool that reconciles it,  
  a cache in front of it and a column that renders states. The reason they were deferred — not needed  
  for the board to earn its place — has been settled by the board earning it.
- **Re-read the AD5 disposition table whenever `dpm/shared/status-model.md` gains a rule.** The suite  
  forces a disposition to *exist*; nothing forces it to still be true. That is the known limit of the  
  skill half of the contract and it is the one guarantee in this spec that decays with time rather  
  than failing loudly.
