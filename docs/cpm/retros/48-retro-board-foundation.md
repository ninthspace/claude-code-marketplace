# Retro: Board Foundation

**Date**: 2026-08-14  
**Source**: docs/epics/48-02-epic-board-foundation.md  
**Stories**: 6/6 complete

## Summary

This epic built the first thing in the repository that is a *client* — a Python tool in `dpm/tools/board/`
that owns no data and learns everything by asking a process it spawns. Almost every hard problem in it
came from that shape rather than from any one requirement: what is asserted about a process you cannot
see inside, what a test can witness that is not the component's own account of itself, and which
guarantees are structural rather than checked.

Four of the observations below are about the same move made in four places — replacing "the code says
so" with an outside witness: a transcript the server wrote, a pid the server registered, an environment
the server reported, a filesystem after a real run. The rest are about defects that only appeared when
something real was driven, three of which no amount of unit testing would have produced.

## Observations

### Codebase Discoveries

- **The checkout case and the installed case are one rule, and the plugin cache is a third thing.**  
  ENV3 names three ways to resolve `bin/dpm-mcp.js`, which reads as three lookups. It is two: the board  
  ships *inside* the plugin, so `../../bin/dpm-mcp.js` resolves to whichever copy the running `board.py`  
  belongs to — checkout or cache, the same expression. The cache glob is not "the installed case" at  
  all; it is the case where `board.py` was copied out on its own, which PEP 723 single-file distribution  
  actively invites. Reading the requirement as three lookups would have produced a resolver that  
  preferred an installed 0.1.0 over the checkout a developer was editing.
- **dpm's server puts the useful half of a refusal in `error.data.message`, and the JSON-RPC category  
  in `error.message`.** A client that surfaced only the second tells a user their call was invalid and  
  never says which argument. Both halves are joined; 48-06 renders the result.
- **A stale `PROTOCOL_VERSION` fails silently in both directions.** dpm *echoes* a revision it knows and  
  answers anything else with its own newest, so drift between the board's constant and  
  `SUPPORTED_PROTOCOLS` is a downgrade with no error at either end. The only thing that catches it is a  
  test that reads the server's list and asserts the board's constant is in it.
- **`DPM_DATABASE` is a live hazard for any tool that spawns dpm.** It is dpm's own override for where  
  the database lives and it is plausibly set in the shell a user starts the board from. Inherited, every  
  spawned server opens the *same* database whatever project it was launched in — so every row renders,  
  without error and identically, the status of whichever project that variable named. dpm's own suite  
  already carries this lesson as `NO_OVERRIDE`; nothing in spec 48 mentions it.

### Testing Gaps

- **An in-process guard says nothing about a spawned process, and the fix has a failure mode of its  
  own.** ENVX4's network guard reaches children through `sitecustomize` on their `PYTHONPATH` — the only  
  hook that runs before their script. The first version replaced `socket.socket` with a *function*, and  
  `ssl.py` executes `class SSLSocket(socket)` at import time while `asyncio` imports `ssl`: every child  
  touching asyncio died at startup. It was invisible for two stories because the only children the suite  
  spawned imported neither, and it would have become fatal in Story 6 when `board.py` reached the client.  
  A guard that patches the standard library needs a test that the standard library still works.
- **The child control has to assert the exception *type*.** A test that plants a network reach in a child  
  and asserts a non-zero exit proves nothing: an unresolvable host fails on a machine with no network  
  whether or not the guard was ever installed. Only `NetworkUnavailable` in the traceback distinguishes  
  a guarded child from an unguarded one.
- **"No socket at all" stopped being the right assertion halfway through the epic, and weakening it was  
  not the repair.** From Story 6 the board runs an asyncio event loop, which builds an `AF_UNIX`  
  socketpair for its own self-pipe — two descriptors joined to each other inside the process. The record  
  is now compared against `AF_UNIX` rather than against nothing, while every network family stays refused  
  outright and a planted control proves it. The criterion's words were "outside the stdio pipes"; the  
  first reading of them happened to also be true.
- **`pytest.raises`'s "DID NOT RAISE" is a true verdict that names the wrong harm — twice in one epic.**  
  For a broken server-path override, the harm is not that nothing raised; it is that the board would have  
  answered every query correctly *from the wrong tree*. For a project with no database, the harm is not  
  that nothing raised; it is that a process was spawned to learn what was on disk all along. Both were  
  rewritten as try/except/else so the failure names the harm, and in the second case so the  
  empty-transcript assertion could run *first*.

### Patterns Worth Reusing

- **A recording stand-in server, configured entirely by environment.** It answers the same handshake,  
  appends every line it receives to a file, and reports its own cwd, argv and `DPM_` variables as data.  
  That one component made four different criteria assertable from outside: that every read is a  
  `tools/call`, that a server is launched read-only at the project root, that a mismatched surface is  
  refused, and that the row's numbers came from tool calls. Adding a transcript to `bin/dpm-mcp.js` would  
  have put test apparatus in the shipped server; the real binary is still driven where the question is  
  whether the protocol is dpm's.
- **Ask the operating system, not the component.** "Every spawned process is terminated" is asserted by  
  signalling pids — from the client for the pool's tests, and from a file the *servers themselves* write  
  for the CLI's. A `close()` that returns without doing anything passes every form of that test that asks  
  the pool what it closed.
- **The declaration *is* the call.** `declare()` returns the object that is then passed to  
  `client.call()`, so the reconciled surface cannot drift from the code without the code failing to run.  
  The other direction — a tool called without being declared — cannot appear in any runtime set at all,  
  because it is a bare string in the source; that half is an AST sweep for literal names at call sites,  
  with a planted control. Two directions, two mechanisms, neither able to do the other's job.
- **Fixtures built by the product's own tools.** The fixture database is created by calling the server's  
  `create_*` tools rather than by writing SQL. The schema is dpm's and it migrates; a fixture that  
  inserted rows directly would be a second, silent implementation of it — correct until a migration  
  lands, and then wrong in a way that looks like a board bug.
- **Static sweep plus behavioural companion.** FR2's "no file under a project" must-NOT is undecidable  
  statically past "which modules open files at all", because a path is built from variables. The sweep  
  bounds the source; a real read against the fixture, recording every `open`, bounds the run. Applied as  
  retro 47 recommended, and it earned itself: neither half would have been convincing alone.

### Scope Surprises

- **Wiring `list` reached a state none of the previous five stories could produce.** A database the  
  server *starts* against and then cannot answer for — the `project()` fixture's empty marker file, which  
  is neither a real database nor an absent one. It surfaced as an uncaught `ServerFailed` on the first  
  end-to-end run. It is now `SERVER_FAILED`, FR11's own words, contained per row.
- **Story 5 pulled a piece of Story 6 forward.** A declaration with no call site is exactly the central  
  list NFR5 forbids, so there was nowhere honest to put the declared surface until something called it;  
  `read_project()` arrived one story early.

## Recommendations

- **48-03 inherits four named states and should treat them as the contract, not as strings.**  
  `NO_DATABASE`, `SURFACE_MISMATCH` and `SERVER_FAILED` exist with remedies attached; FR11's fourth  
  (a Node below dpm's floor) does not. 48-06 renders them, and the split between "the board declined  
  before spawning" and "the server started and could not answer" is load-bearing for what a remedy says.
- **Carry the outside-witness habit into 48-04's TUI tests.** A pilot harness makes it very easy to  
  assert what the app *thinks* it rendered. The equivalents there are the rendered text and the process  
  table, not the widget's state.
- **Expect the `project()` fixture's empty database to keep surfacing states.** It is now the suite's  
  cheapest source of a broken project and it will reach every new failure path added; that is useful, but  
  a test that wants a *healthy* project must ask for `fixture_project`.
- **`DPM_DATABASE` removal belongs in the spec, not only in the code.** Nothing in spec 48 requires it,  
  a reasonable implementer would inherit the environment whole, and the failure it prevents is silent and  
  total. If the board's spawn environment is ever restated, that clause has to survive.
