# Retro: Skills — spine

**Date**: 2026-08-09  
**Source**: docs/epics/47-06-epic-skills-spine.md  
**Stories**: 5/5 complete

## Summary

The three pipeline skills — `spec`, `epics`, `do` — were converted from markdown-and-glob storage to typed MCP calls, shrinking by 48%, 61% and 74% against their CPM originals while keeping every facilitation gate. The epic's recurring lesson is that **converting a skill is how you find out whether the tool surface it needs actually exists**: four of the five stories added exports inline because the conversion asked a question the schema admitted and no query answered. Its second lesson is that the three-direction skill/test binding paid for itself in every story it was used in, and always by sending the fix to the file rather than to the test.

## Observations

### Criteria Gaps

- **`status` is a two-value set, and three things need a third value.** The in-flight transition had nowhere to go and was rehomed to `session.phase`; CPM's `Superseded` and `Withdrawn` have no representation at all, so a retired epic reads as ready to the readiness clause. The rehoming is correct and stays. The retirement gap is not — it was out of scope here and it becomes load-bearing at Epic 47-09, where twenty-two skills inherit whatever answer exists by then. **Raise it at spec level before 47-09 starts**, not inside it: a status vocabulary is a schema decision, and discovering it mid-conversion is how a story acquires an inline change it should never have owned.

### Codebase Discoveries

- **A conversion is a consumer test the tools have never had.** Four separate gaps surfaced only when a skill tried to use the surface: nothing computed `binding_hash` (every test passed a literal and the `CHECK` accepted any string); `list_coverage` was scoped only by `requirement_id`, so a story-first caller had no route to its own rows; `dependency` had no list tool at all; and `list_requirement` withholds `text` unless `include_body` asks, so a stage binding a verbatim fragment would have hashed `undefined`. Each was a column or an edge the schema fully admitted with no query that read it. **The pattern to carry into 47-07 onward: before writing the SKILL.md, walk the reads it will need and call each one.** Three of the four were found that way and cost minutes; the fourth was found by running stages in sequence and cost a debugging pass.
- **A legal edge with no query is a wrong answer waiting.** A story blocked by a *document* had always been storable and never been read, so `readyClause('story')` needs two blocker sources where the document form needs one. Reading only `source_story_id` reports a story ready while an epic holds it up — wrong in the direction that starts work.
- **AD10's conformance seam only checks one way.** It reports a tool `enum` matching no column `CHECK`, but not a column whose `CHECK` no tool declares — so deleting a tool's enum silently moves validation from the boundary to the database and the suite stays green. Found by mutation, not by reading, which is the point.

### Testing Gaps

- **A green suite proved nothing about whether the server could start.** Every dpm test spawns the process itself, supplying the launch a real session does not, so five epics passed with nothing declaring the server in the manifest. The check that closes it reads the manifest, and its mutations break the manifest rather than the code. **Where the tests supply the environment, the environment is untested** — worth asking of any harness before trusting it.
- **Section-scoped assertions alias against nearby prose.** `/each one/i` matched an incidental phrase three lines above the rule it meant to pin, so deleting the rule left the test green. Match the **construction** (`require a disposition for **each one**`), not the words. Only the mutation found it.
- **When a grep *is* the requirement, the naive grep is wrong.** The FR3 SQL sweep false-positived on `spec`'s own sentence "Select the few most relevant rather than everything from the newest retro". The fix was to match ambiguous keywords case-sensitively and unambiguous ones either way — and to **state the residual gap** (a lowercase `select … from` passes) rather than pretend the sweep is total.

### Patterns Worth Reusing

- **The three-direction binding is the load-bearing test asset of this epic and should be the default for the remaining nineteen conversions.** Every tool the file names resolves; every tool the run drove is named; every fixed-vocabulary argument the run passed is named. It caught a skill describing gating edges without telling the run to read `gates_work`, a `polarity` dropped back into prose, and twice a test-side read counted as a run write. In every case the fix was to the SKILL.md — which is the tell that it is testing the file rather than the tools.
- **Assert each layer that can refuse the same call, separately.** `assert.throws(…, /plan/)` passed with the tool's enum deleted *and* with the column's `CHECK` deleted; one refusal is indistinguishable from the other from outside.
- **Hand a pipeline stage one id and nothing else.** "No step reads what the previous one wrote" stops being an inspection and becomes a function signature: a stage needing a second parameter is a stage that could not find something.

## Recommendations

1. **Raise the `status` vocabulary at spec level before Epic 47-09.** Retirement (`Superseded` / `Withdrawn`) has no representation and readiness currently treats a retired epic as workable. Twenty-two skills inherit whatever is decided; deciding it inside one of them is the failure mode this epic already paid for once.
2. **Open every remaining conversion with a consumer walk.** Before writing the SKILL.md, enumerate the reads it will need and call each one against the live surface. Three of this epic's four surface gaps would have been found in minutes instead of mid-story.
3. **Make the three-direction binding the standard opening of each conversion test**, not a per-story choice — `support/skills.js` already exports it, and every story that used it found something.
4. **Keep driving mutations, and keep the ones that survive.** Two mutations survived first in this epic and both drove real test fixes; neither gap was visible by reading.
5. **State residual gaps in sweep-style tests in the test itself.** Where a grep is the acceptance criterion, the sentence naming what it still cannot catch is part of the deliverable.
