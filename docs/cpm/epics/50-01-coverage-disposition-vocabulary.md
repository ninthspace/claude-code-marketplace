# Coverage Matrix: Disposition Vocabulary

**Source spec**: docs/specifications/50-spec-report-disposition.md  
**Epic**: docs/epics/50-01-epic-disposition-vocabulary.md  
**Date**: 2026-08-16

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR10 | The four dispositions are seeded `taxonomy` rows readable via `list_taxonomy` with `domain: 'disposition'`, inserted if absent so an existing database gains them on next open. | `list_taxonomy({domain:'disposition'})` returns exactly four terms: `disposition:fixed`, `disposition:needs-you`, `disposition:left-alone`, `disposition:unverified` | Story 1 | `[integration]` |  ✓ |
| 2 | FR10 | The four dispositions are seeded `taxonomy` rows readable via `list_taxonomy` with `domain: 'disposition'`, inserted if absent so an existing database gains them on next open. | An existing database gains the four terms on next open; deleting one and reopening restores it, with a control that a term absent from the seed is not created | Story 1 | `[integration]` |  ✓ |
| 3 | ENVX3 | Must not require a new `.sql` schema file or a `schema_version` bump. The seed path is insert-if-absent; this pins it. | `src/schema/` gains no `.sql` file and `latestVersion()` is unchanged before and after | Story 1 | `[unit]` |  ✓ |
| 4 | ENVX1 | Must not require a new dependency. `package.json` carries none, and that is the state to preserve. | `dependencies` and `devDependencies` are both empty after the change | Story 1 | `[unit]` |  ✓ |
| 5 | ENV1 | Node 22.5.0 or later with `node --test` runnable from `dpm/`. | `package.json` keeps `engines.node >= 22.5.0` and `test: node --test`, and the suite runs | Story 1 | `[unit]` |  ✓ |
| 6 | ENV2 | The whole suite runs in one command. A skill amendment can pass a feature's own tests and fail a corpus sweep there was no obvious reason to run. | `npm test` from `dpm/` runs every `tests/*.test.js`, corpus sweeps included | Story 1 | `[integration]` |  ✓ |
| 7 | ENVX2 | Must not require a running MCP server or a network call to verify. | The full suite passes with no network available and no separately-started server | Story 1 | `[integration]` |  ✓ |
| 8 | FR1 | Closed disposition vocabulary. Exactly four dispositions — Fixed, Needs you, Left alone, Unverified — each defined by what the reader does. The set is closed: a report uses these or omits the item. | A Disposition subsection under Conversational Output in `dpm/shared/skill-conventions.md` defines all four dispositions, each stated as what the reader does | Story 2 | `[unit]` |  ✓ |
| 9 | FR2 | The label names the reader's obligation, not the agent's action. A deficiency fixed and also worth a glance is Fixed with the note attached, never Needs you. | The subsection states the label names the reader's obligation, and resolves fixed-but-worth-a-glance to Fixed | Story 2 | `[unit]` |  ✓ |
| 10 | FR3 | Anything outside the four is not reported. Considered-and-rejected work, process narration, and restatements of what the reader just approved have no disposition and no place. | The subsection states that an item fitting none of the four is omitted | Story 2 | `[unit]` |  ✓ |
| 11 | FR4 | Needs-you items come last, together, each an imperative naming what to do and where. Fixed, Left alone and Unverified precede it in that order, so the reader can stop early having missed nothing actionable. | The order Fixed → Left alone → Unverified → Needs you is fixed, and each Needs-you item is an imperative naming the action and where | Story 2 | `[unit]` |  ✓ |
| 12 | FR5 | Unverified means the check is impossible in this environment, and says why. The qualifying cases are structural: a `target` criterion, and a must-NOT with no control. | Unverified is defined as environment-impossible, requires the reason, and names the two structural cases | Story 2 | `[unit]` |  ✓ |
| 13 | FR5 (must NOT) | A reason about the run — the tests fail, I could not implement it — is Needs you. | must NOT admit a run-side reason as Unverified. Control: the routing sentence is what is removed to fail the check | Story 2 | `[unit]` |  ✓ |
| 14 | NFR1 | The convention states the rule, not its history. It is read at startup by every skill on every invocation. Rationale that stops an agent routing around the rule stays; biography goes. | The subsection carries no sentence about the rule's history | Story 2 | `[manual]` |  ✓ |
| 15 | NFR2 | It does not restate or contradict Conversational Output. That section governs cadence and length; this one governs the state of a reported item. | The subsection neither restates nor contradicts Conversational Output's cadence guidance | Story 2 | `[manual]` |  ✓ |
