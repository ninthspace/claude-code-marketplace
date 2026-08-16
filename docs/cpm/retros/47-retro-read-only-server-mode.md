# Retro: Read-Only Server Mode

**Date**: 2026-08-14  
**Source**: docs/epics/48-01-epic-read-only-server-mode.md  
**Stories**: 2/2 complete

## Summary

Every acceptance criterion in this epic was an absence — no migration, no write, no file — and an
absence is exactly what a mode that does nothing at all reports. The work that made the epic
verifiable was not the read-only connection, which is one SQLite option; it was finding, for each
absence, the second run that produces the presence. Two of the six observations below are about
where those controls came from, and two are about assertions that looked like they were checking
the absence and were checking something else.

## Observations

### Codebase Discoveries

- **A sweep pinned to a list of one fails on the second member, and the obvious repair is the weak  
  one.** `baseline.test.js` asserted the environment-reader list was exactly `['src/db/location.js']`  
  with `examined === 1`, so the second sanctioned variable broke it on the first task of the epic —  
  predicted, and hit anyway. Widening the list would have restored green while leaving the sweep  
  blind: a module taking `env = process.env` and indexing it by an exported constant appears in the  
  file list, contributes nothing to the count, and reads the environment in a shape the sweep cannot  
  attribute to any name. The variable is now read by name statically and the list and the count are  
  asserted *against each other*, so the shape that evades the sweep fails it instead.
- **An error's shape in process is not its shape to a caller.** `rpc.js` puts only `error.message` on  
  the wire, so `ERR_SQLITE_ERROR` kept on the error object as `code` — correct, conventional, and  
  what an in-process test sees — reached no client at all. FR11's whole subject is which states a  
  board can *tell apart*, which made the classification a property of the message text rather than of  
  the error. Only driving the real binary found it. Any criterion about what a client can distinguish  
  has to be asserted on what crosses the boundary, not on what the throwing function constructed.
- **A capability probe written for a test can be wrong in ways the thing under test is not.**  
  `capability.js` claims its FTS5 probe answers on a read-only connection because it builds in  
  `temp.`, and the first reach at it appeared to disprove that — `vtable constructor failed` — which  
  turned out to be a scratch probe naming its virtual table and its column the same thing, a failure  
  a *writable* connection gives identically. The control that settled it was running the same  
  statement against the connection the claim is not about.

### Testing Gaps

- **A token sweep cannot prove a path writes nothing.** The must-NOT — "creates `.dpm/`,  
  `.dpm/dpm.db`, or an ignore file" — reads like something this suite's two existing write sweeps  
  would already catch, and neither can: both scan module source for tokens and neither follows a  
  call. Asserted instead against `readdirSync` after the real sequence, it becomes a fact about the  
  run. The mutation that proves the difference is moving the read-only branch below the mkdir  
  preamble: the sweeps stay green, the directory listing does not.

### Patterns Worth Reusing

- **The discriminator for a vacuous criterion was already in the tree.** NFR1's own wording — no  
  migration and no row written at the current schema version — is satisfied by any database that  
  needed nothing, which is every database at the current version. What rescued it was a fact about  
  the unmodified code rather than a new fixture: `migrate()` drops and recreates the retirement  
  guards on *every* open, so an ordinary open of the same untouched file is **not** byte-identical  
  and the read-only one is. Before adding a fixture to make a no-op criterion discriminate, read what  
  the path being compared against actually does.
- **A control belongs in the same fixture as the arm it controls, not beside it.** Story 2's paired  
  positive runs in the *same directory*, over the same messages, immediately after the read-only arm,  
  so the only difference between the two runs is the variable — not the fixture, not the working  
  directory, not the ordering. A control built in its own directory is a second experiment; built in  
  the same one it is the same experiment with one term removed.

## Recommendations

- **When a criterion asserts an absence, plan its control at criteria time, not at test time.** Both  
  of this epic's stories carried the pair in the criteria themselves, which is why neither test had  
  to be argued into existence later. Epic 48-06 inherits three more absence-shaped states from FR11.
- **Assert transport-visible facts over the transport.** The `rpc.js` message-only rule applies to  
  every future state the board learns from a server; 48-02 and 48-06 should drive the binary rather  
  than `main` wherever the criterion is about what the *client* can distinguish.
- **Treat a pinned allow-list in `baseline.test.js` as a place the next epic will fail.** The  
  environment-reader sweep is now self-checking, but the same shape (list plus count) exists in the  
  other sweeps; the repair pattern — assert the list and the count against each other — is cheaper to  
  apply before the failure than after it.
- **Keep the row-4 criteria gap open rather than quietly satisfied.** NFR1's vacuous wording stands  
  in spec 48 with the discriminating pair beside it. If it is to be repaired, `/cpm:pivot` over the  
  spec is where — not an edit from an epic that would rather it read differently.
