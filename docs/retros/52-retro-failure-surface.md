# Retro: Failure Surface — Named States and Proven Non-Mutation

**Date**: 2026-08-15  
**Source**: docs/epics/48-06-epic-failure-surface.md  
**Stories**: 4/4 complete

## Summary

The two requirements a user notices only when something is wrong. FR11's four named states — a
missing database, a schema from a newer plugin, a Node below dpm's floor, a server that will not
start — each carrying a remedy and each contained to its own row; and FR10's proof that observing a
project leaves it byte-identical. The board's suite went from 183 to 205; `dpm`'s Node suite stayed
at 707, with one behaviour change in `src/server/index.js`.

**Two of this epic's tasks were written on premises that turned out to be false, and both were found
by trying to produce the condition rather than by reading the code.** Task 1.1 assumed a
schema-ahead database announces itself over the protocol: it does not — `tools/list` is byte-identical
and only the write tools FR10 forbids behave differently, so the state is read from stderr and dpm
had to start reporting the skew on the branch a board can actually hear. Task 3.3 assumed the
mutating tool set is the difference between the full and read-only tool lists: it is empty by
design, because a tool withheld from the list answers *Method not found* and explains nothing.
Neither premise was unreasonable and neither survived contact.

The third theme is **the assertion that only exists if you produce the condition**. Every state here
is produced rather than simulated — a real database with a version row above the server's, dpm's own
`assertNodeFloor` refusing, a `node` that fails differently depending on which project it was
launched in — and the one test that had a fixed sleep in place of a produced precondition was flaky
at one run in five.

## Observations

### Codebase Discoveries

- **Nothing about a schema-ahead database crosses the protocol channel.** The server serves it  
  read-only and logs the skew; the tool list is identical either way. So the board's only signal is  
  stderr — which is why `DIAGNOSTIC_STATES` exists and why NFR6's boundary had to be stated  
  precisely: a signature names a *state*, never a row, a count or a title.
- **The skew was only reported on the migrate branch, which a read-only server never reaches.** The  
  probe that found this was two runs of the same server, one with `DPM_READ_ONLY=1` and one without.  
  `aheadMessage` is now built in one place and logged from both branches — the board's classification  
  depends on it, and it was previously unreachable by any read-only client.
- **A read-only dpm server advertises every tool and refuses at call time.** 181 advertised either  
  way, 87 refusing. This is deliberate (`src/tools/index.js`): an absent tool answers *Method not  
  found*, which is what a client sees when a server is broken, and tells the user nothing about the  
  reason that applies.
- **`asyncio.CancelledError` is a `BaseException`.** An `except asyncio.CancelledError: raise` arm  
  written above an `except Exception` catch-all is dead code, and it reads as the thing that makes  
  the containment safe. What actually decides it is the *width* of the catch-all, which no test  
  distinguished until one was written for it.
- **`node` belongs to the pool, not to the project.** One board session has one interpreter for  
  every row in the registry, so a registry holding a healthy project *and* one whose Node is below  
  the floor cannot be built by configuring the pool. The stub dispatches on the working directory  
  the server is spawned in.
- **A Miller column clips rather than wraps.** Every FR11 remedy is short because the first drafts  
  were sentences and the row rendered `no-database: run a dpm skill in the` — which is worse than no  
  remedy for the user who thinks they read it. What does not fit is the occurrence's `detail`, on  
  the CLI's full-width row.
- **The built fixture holds `.dpm/` and nothing else.** "No file under a registered project is  
  written, `.dpm/` included" was true of a project that had nothing else in it, so the whole-tree  
  comparison had to furnish one first.

### Testing Gaps

- **Produce the precondition; do not sleep for it.** `test_attach.py`'s `use()` sent keys and slept  
  0.4s, betting on how long a shell takes to start before tmux records the activity. One run in  
  five, the session created *after* the one being used won the comparison. It now retries until  
  tmux's own `window_activity` says the precondition holds. **Found while running an unrelated  
  mutation over the whole suite** — a per-file mutation run would never have shown it.
- **A mutation that changes only an mtime is invisible to every static check.** `os.utime` on the  
  database was caught by the whole-tree and database comparisons and by nothing else — not by  
  48-02's opener sweep, not by the verb sweep. It is the clearest evidence that the two halves of  
  FR10's proof do different work and that neither is the whole of it.
- **A full-session test's real risk is that the session was not full.** A board session that did  
  nothing at all leaves every file exactly as it found it, so the comparison passes. The session  
  driver reports which of the board's own `COMMANDS` it ran and is reconciled against that table in  
  both directions, with an exclusion list carrying a reason each — which also means 48-07's search  
  is already in scope rather than something to remember.
- **A derived set needs bounding on both sides.** "Non-empty" is the obvious floor; a derivation  
  that matched *every* tool is equally vacuous and passes it. The refusal signature is read out of  
  dpm's source and the derived set is asserted to be a proper subset.
- **Assert before you build the thing that depends on the assertion.** Two tests here first crashed  
  with `IndexError` on an empty derived set and an empty epic list, replacing a legible failure with  
  a traceback. The floor assertions moved above the code that indexes.
- **The healthy row is the discriminator, not the failing ones.** A survey that reads a project and  
  reports nothing of it passed the entire suite until Story 2 asserted the healthy project's real  
  figure and its own epics beside four failures.

### Patterns Worth Reusing

- **Generate the other side's message from the other side's source.** dpm's Node refusal comes from  
  calling `assertNodeFloor` itself, the floor version is regexed out of `node-floor.js`, the  
  read-only sentence out of `read-only.js`, and both stderr signatures are reconciled against dpm's  
  tree. A transcription passes for exactly as long as it takes someone to reword the original —  
  which is the only circumstance under which the classification is wrong.
- **Read the requirement's own words from the document.** FR11's four phrases are asserted to still  
  be in the spec's body, so a requirement reworded underneath the board fails here rather than  
  leaving a state nothing asks for.
- **Reconcile in both directions, with a floor.** A state with a remedy nothing requires fails as  
  loudly as a required state with no remedy, and `reconcile({}, {})` must complain — nothing against  
  nothing is the only case a set difference cannot fail on.
- **Compare against the same thing under different conditions.** Story 4's whole discriminating  
  criterion is an equality between two copies of one built fixture, one writable and one not. Any  
  difference at all is the filesystem's, which is what makes equality the right shape rather than a  
  list of properties someone thought to check.
- **Assert the harness's own premise from outside it.** The read-only fixture asserts that the  
  *operating system* refuses a write, not that a mode bit is set: a suite running as root has the  
  bits exactly as the fixture left them and writes straight through.
- **Sweep the source for what a name could be, and the declared surface for what it is.** The  
  mutating-verb check does both, because a bare tool name passed to `pool.read` never reaches  
  `SURFACE` until the moment it is called.
- **Move a story's producers to `support/` the moment a second story needs them.** Story 1's four  
  conditions became `tests/support/failures.py` when Story 2 needed the same four in one registry.  
  Two copies of "what a Node below the floor is" would agree until one was edited.

### Scope Surprises

- **A board epic changed dpm.** FR11's schema-ahead state was unreachable without it, and the change  
  is in dpm's server rather than in the board. It was small — one message, built once and logged  
  from both branches — but it means this epic's blocker on 48-01 was real in a way the epic did not  
  spell out.
- **Story 4 needed no production code, as it predicted.** Its value is entirely in what it would  
  have found: the mutation that removes `DPM_READ_ONLY` from a spawned server's environment renders  
  a read-only project as `server-failed`, which is the wrong answer arriving quietly.
- **A criterion was amended mid-story.** Story 3's fourth criterion named a derivation that is empty  
  by construction; it was amended to the behavioural one, with the measurement recorded on the task  
  and the coverage row reset and re-verified. The intent — nothing transcribed, a floor that fails  
  on a vacuous set — is unchanged.

## Recommendations

- **48-07 inherits a session driver that will fail if search is not exercised in it.** That is  
  deliberate. Add the action to `COMMANDS`, drive it in `session.run`, and FR10's proof covers it;  
  excusing it needs a reason written in `NOT_IN_A_SESSION`.
- **Keep running planted mutations against the whole suite.** Two of this epic's findings — the  
  flaky attach fixture and a mutation caught only by another story's test — came from the breadth  
  and not from the mutation.
- **When a task's premise is about what another component does, produce the condition before  
  building on it.** Both false premises here would have survived any amount of code reading; both  
  took one probe to disprove.
- **A state read from a diagnostic is a dependency on another project's prose.** Two signatures are  
  reconciled against dpm's source today. A third would be the point to ask dpm for a real signal  
  instead — the gap is recorded on Task 1.1.
