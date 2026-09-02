# What the Tree Already Holds, and What a Change Costs

**Number**: 02  
**Status**: complete — In force. Promoted retro lessons about budgeting a breakdown against the tree and the suite that already exist. Each entry's source observations are retired at source and point here by library_doc_id.  

**Type**: architecture  
**Scope**: do, epics  

## Read the tree before budgeting, and expect the ratio to favour already-there

An epic written from a spec describes what must be true, not what must be added. Across four retros the same result: three of four tasks already built; whole stories delivered with no production code; two of three tasks satisfied when reached; a task duplicated across two epics shaped from one spec at the same time. Finding each out cost one grep or one read of `tests/support/`.

- **Read the target file before implementing the task, not after.** The loop's instinct on reaching a step that already says what the task asks is to write it again, and a second copy of a rule in one step is worse than the duplicate task — the two drift and nothing notices.
- **Read `tests/support/` before writing a fixture.** Helpers here are routinely written for a story by name, in a note, an epic before that story is reached.
- **Already-built is not already-verified.** Code that is right with nothing saying so is a criterion unmet in the most ordinary way there is; a story that needs no production code still needs the assertion and its control.
- **Where a spec restates an environmental requirement another spec carries, assert only the narrowing and cite the existing file for the rest** — then say in the new file which claims it is deliberately not restating, or the next reader adds them back.
- **Close such a task with a `status_note` naming where the work actually landed**, so the next reader does not read it as skipped.

## A schema or tool change costs several derived-sweep registrations, and the number is discoverable before the work

This suite carries sweeps — `parity`, `parity-integration`, `conformance`, `sparse`, `entry-index`, `prose-columns`, `naming`, `schema`, `body-reads` — that derive their subject from the schema and the tool registry. None is discoverable from `src/schema/`; nothing in a migration file mentions them.

- **Budget the registrations into the plan.** A table added to this schema cost five, against a plan that predicted one. Each failure was a sweep doing its job.
- **Run the sweep's own reader against the intended change before writing a line of it.** A new tool's cost was established this way — four sweeps silent, one live — before the tool existed.
- **A derived response field is invisible to every sweep here.** A value computed after the read reaches neither the schema nor the registry, so the pressure lands on the skill text that consumes it and nowhere else. Anything reached that way is judged by whoever writes those two sentences.
- **Check new DDL against the schema rules before writing it.** `INTEGER PRIMARY KEY` aliases the rowid, so a must-NOT about a second row passes on the named-id form and fails on the id-less one.

## A column and the tool that writes it belong in one epic

Three sweeps read a corpus built by driving the registered tools, and each asks whether every state the schema admits is reachable. A story that adds a column with no verb to set it turns them red the moment its migration lands, and no work inside that story can clear them.

- **A breakdown that splits schema from surface has to check the derived sweeps before it splits.** The sweeps are what make the split unbuildable rather than merely awkward; this one was corrected by a pivot that moved two write-arm stories into the schema epic.
- **A shared corpus is version-agnostic and has to stay that way.** Guard a new call with the schema's own answer — `columnNames(db, 'coverage')` — not a version number written into the fixture.

## Read what iterates a set before adding a member to it

Three instances. A property every current member of an enumerated set happens to share is a contract nobody wrote down, and the next member is where it breaks.

`restore` throws on any violation `checkIntegrity` reports, and `restore.test.js` requires a refusal fixture per register entry in both directions — so "the register grows an entry" silently meant "a dump holding this state is refused". Thirteen entries all named corruption, so the coupling had never had to be stated, and the ADR that decided to add a fourteenth could not see it because the property lives one module over from anything the decision names. The entry then cost five things that iterate the register, none of them the entry's own code. Separately, an epic that put one detector's verdict flat in a field paid for the second detector in eight existing assertions that had encoded "there is one detector" without ever saying so.

- **Read the consumers of the set before writing the member**, not the set's own definition. A register, a tool list, a taxonomy, a vocabulary — the constraint is in what iterates it.
- **A shape asserted flat is a shape claimed to be final**, and nothing marks which assertions are load-bearing and which are incidental to a shape that happened to have one member.
- **Put the remedy on the member, not a condition in the consumer.** `restore` asking "is this entry 14?" would be the decision written a second time, in the module least likely to be read when a fifteenth arrives.
- **A new member that fires on the existing corpus is the strongest available answer to "is this check about anything?"** — and it arrives as a red test rather than as a claim.
