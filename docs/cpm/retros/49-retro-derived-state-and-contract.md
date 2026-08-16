# Retro: Row-Derived State and the Status-Model Contract

**Date**: 2026-08-14  
**Source**: docs/epics/48-03-epic-derived-state-and-contract.md  
**Stories**: 5/5 complete

## Summary

This epic derived a project's state from rows — readiness, blocking, *in progress*, progress counts,
an ordered candidate list — and then wrote the contract (AD5) that keeps the board and `/dpm:status`
from drifting into two answers about what that state is.

The derivations were the easy half. What this epic is actually about is the difficulty of testing a
rule whose *correct* answer and whose *wrong* answer look identical from outside: 0/0 is complete by
arithmetic, an unsorted list is in order when the fixture holds one kind, and a paragraph explaining
an ordering reads exactly like the table that obeys it. Three mutations survived across five stories,
and each one was a criterion that could be satisfied by code that never did the thing.

The other finding is the one that justifies AD5 existing at all. Reading `dpm:status` against the
contract turned up four contradictions and **three of them were the board's**. A reconciliation
written as "check the prose against the code" would have amended the skill in all four places and
made the answers worse.

## Observations

### Codebase Discoveries

- **A retired dependency *kind* still gates work, and the list tool hides it by default.**  
  `readyClause` joins on `gates_work` and mentions `retired_at` nowhere — retirement stops new edges  
  arriving, it does not release the work existing ones hold. `list_dependency_kind` omits retired  
  rows unless asked, so a consumer taking the default meets an edge whose kind it has never heard of  
  and calls a blocked epic workable. `include_retired: true` is the one place this board departs from  
  a tool's default, and nothing about the default reads as wrong.
- **`story.status` and `task.status` have four values, not two.** `020-status-lifecycle.sql` widened  
  all three tables together. Story 2 recorded the opposite in a test docstring — "a status the schema  
  does not yet allow" — and built the rule as a guard against a future migration. It was live: the  
  board counted a `withdrawn` story in the denominator forever. **A claim about the schema is  
  checkable in one grep and was instead carried three stories on plausibility.**
- **`retro_waived_at` is paired with its reason by a CHECK, so testing one is testing both.**  
  `015-retro-waiver.sql` makes both present or neither. A second condition on the reason could never  
  independently be false, and writing one would have implied a state that cannot exist.
- **Specs are root-numbered and epics child-numbered.** `number` versus `sequence`, in one ordering  
  function. Reading a single column orders one kind and piles the other at zero, where the id  
  tiebreak makes the result stable, plausible and wrong.
- **`SURFACE` is keyed on the tool name, so a tool may be declared exactly once.** Two  
  `declare("list_epic", …)` calls in two modules leave whichever imported last, and NFR5's  
  reconciliation then checks a set that depends on import order. All seven declarations moved into  
  `status_model.py`.

### Testing Gaps

- **A comparator that never sorts passes an ordering test whose *code* already emits in order.**  
  Story 3's `candidates()` appended one kind at a time, so FR9's order fell out of the statement  
  sequence; deleting `sorted()` left every test green. The fix was to the producer, not the test —  
  candidates are now emitted in row order, both epic kinds in one pass, so the sort is the only thing  
  that orders anything. **The fixture-side must-NOT (row 10 of the matrix) was written and passed;  
  the false pass was one level below it, in the emission order the fixture never sees.**
- **A floor over two empty sets cannot be checked one side at a time.** With the *other* side  
  populated, the per-rule loops complain anyway, so both one-sided floor tests passed with the floor  
  deleted. Only `reconcile({}, [])` — nothing against nothing — is the case a set-difference cannot  
  fail on. This is now asserted in its bare form in both reconciliations.
- **A text search cannot distinguish a passage that *states* a rule from the passage that *obeys*  
  it.** Story 5's ordering test searched the whole of `SKILL.md` for `/dpm:do`, `/dpm:epics` and  
  `/dpm:retro` — and the paragraph above the table names all three in the contract's order while  
  explaining that the order is the contract's. `find()` measured the sentence about the table, and  
  the test passed with the table's rows reversed. Fixed by parsing the table's rows. It is the same  
  confusion, one layer up, that makes the skill's half of AD5 unmechanisable at all.
- **Editing a skill needs the *product's* suite, not the tool's.** The Story 5 amendment wrote a bare  
  `list_epic` into a table cell and failed `reachability.test.js` — the exported name is not the one  
  the harness dispatches. The board's 103 tests were green throughout. A corpus sweep already guarded  
  exactly the thing the amendment broke, in a suite there was no obvious reason to run.

### Patterns Worth Reusing

- **Reconcile in both directions, and put a floor under it.** `DERIVATIONS` (a registry the code  
  filled at import) against the contract's parsed `###` headings: a rule added to either side alone  
  fails. Neither list is transcribed. The same shape as `declare()` one layer down, for the same  
  reason — a hand-kept list agrees with the document while disagreeing with the code.
- **Where the two sides cannot both be enumerations, disposition every rule.** `dpm:status` is prose  
  and no parse tells a passage that agrees with a rule from one that never met it. What *is*  
  checkable is that every rule was looked at, so `docs/maintenance/README.md` carries a disposition  
  table keyed on the contract's rule names: a rule added later fails until someone says what happened  
  to the skill under it. The prose in the cells is for the reader; the keys are the machinery.
- **The dispositions that are not "amended" carry the most.** *blocking* records a bounded omission —  
  the skill does not read `gates_work`, so it can name an edge that holds nothing — and *retired  
  blockers* records conformance the skill achieves by delegating to `readyClause`: real, invisible,  
  and exactly the passage a later maintainer would "fix" by hand.
- **Return `None`, not a zero.** `progress([])` refuses to answer for an epic with no stories rather  
  than returning `Progress(0, 0)`, because 0/0 is complete by every reading available to it —  
  `done == total` holds, "every story is done" is vacuously true, and a percentage is 100 or a  
  division by zero. Refusing forces the caller to say what it shows instead.
- **Roll up the rows, never average the parts.** The project figure is one call over every story row,  
  so both edge cases fall out of one rule. Averaging per-epic completion gives an epic with no  
  stories a 100% of its own, and a project with one untouched epic and one empty one reads as half  
  done.
- **Point at the rule, do not restate it.** The contract cites `readyClause` and the status enum  
  rather than reproducing them. A rule transcribed into a document is a third implementation, and  
  the first change to the clause makes the document confidently wrong.
- **Derive test expectations from the fixture.** Two assertions that had transcribed the fixture's  
  shape (`"2 epics, 2 stories, 2 tasks"`, a literal list of epic titles) broke as the fixture grew  
  across three stories. Both now read `CONTENT`, which is data for exactly this reason.

### Scope Surprises

- **Three of the four contradictions the reconciliation found were the board's.** The skill was right  
  that retired stories leave the count, and right that a truncated read is a wrong count rather than  
  a smaller project; the board did neither. Amendments landed in four files, only two of them the  
  skill. Walking passage-by-passage from the skill — the obvious way to do this pass — would have  
  found the one genuinely skill-side pair and missed the rest.
- **The board was silently reading one page.** Every `list_*` call took a `limit` and ignored `more`.  
  It came out of the contract's inputs paragraph, not from any failing test, because every fixture  
  fits in one page and always will.

## Recommendations

- **48-04's TUI renders states this epic named; do not let it re-derive them.** `epic_state()` holds  
  the precedence (complete → retired in its own word → blocked → in progress → ready/pending), and a  
  widget that recomputes any part of it is the second implementation AD5 exists to prevent.
- **Run `node --test` in `dpm/` after touching anything under `dpm/skills/`,** even when the change  
  is a sentence. The corpus sweeps are the only thing that checks a skill against the harness, and  
  the board's own suite cannot see them.
- **Treat a surviving mutation as a question about the producer, not only the test.** Two of the  
  three here were fixed in the code under test — the emission order, and the counting rule — because  
  the test was asserting the right thing and the code had another way to be right by accident.
- **When a test's docstring makes a claim about the schema, check it.** The `story.status` error  
  survived a mutation check, a verification gate and a coverage row, and was found only when a second  
  document was read against the first.
- **The disposition table needs re-reading whenever `dpm/shared/status-model.md` gains a rule.** The  
  suite forces a disposition to *exist*; nothing forces it to still be true. That is the known limit  
  of the skill half of AD5, and it is recorded in the record itself.
