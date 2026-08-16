# Spec: Report Disposition

**Date**: 2026-08-16  
**Discussion**: docs/discussions/33-discussion-report-disposition-labels.md

## Problem Summary

Agent reports conflate two states that demand different things from the reader. An agent that spots
a deficiency and fixes it, and one that spots a deficiency and leaves it, write the same sentence —
past tense, no actor, no disposition. The reader cannot tell whether the repo is different now or
whether an action is waiting, so every report must be read in full to find out, and the actions that
do exist are diluted by everything that is not one. DPM is structurally less exposed than CPM because
disposition is already a column at five sites and must be decided before the row is written; the
residual gap is the conversation, which is prose in both. DPM's fix is therefore preventive and goes
first.

## Functional Requirements

### Must Have

- **FR1 — Closed disposition vocabulary.** Exactly four dispositions — Fixed, Needs you, Left alone,  
  Unverified — each defined by what the reader does. The set is closed: a report uses these or omits  
  the item.
- **FR2 — The label names the reader's obligation, not the agent's action.** A deficiency fixed and  
  also worth a glance is Fixed with the note attached, never Needs you. Without this rule Needs-you  
  accumulates everything and stops meaning anything.
- **FR3 — Anything outside the four is not reported.** Considered-and-rejected work, process  
  narration, and restatements of what the reader just approved have no disposition and no place.
- **FR4 — Needs-you items come last, together, each an imperative naming what to do and where.**  
  Fixed, Left alone and Unverified precede it in that order, so the reader can stop early having  
  missed nothing actionable.
- **FR5 — Unverified means the check is impossible in this environment, and says why.** The  
  qualifying cases are structural: a `target` criterion, and a must-NOT with no control. A reason  
  about the run — the tests fail, I could not implement it — is Needs you.
- **FR6 — Where a disposition is already a row, the report is derived from those rows.** Five sites:  
  `do` Step 8 and its change moments, `quick` Step 4's tri-state `met`, `review`'s findings and  
  `remediation_task_id`, `pivot` Phase 4, `audit`'s findings.
- **FR7 — `do`'s autonomous mode uses this vocabulary rather than its own.** Its standalone  
  "surface the two sets separately" instruction is the same rule invented once for one case.
- **FR8 — `inspect`, `archive` and `clean` adopt the labels.** They hold no disposition rows, so they  
  take FR1–FR5 without FR6. Both `clean` and `archive` already carry private proto-dispositions.
- **FR10 — The four dispositions are seeded `taxonomy` rows** readable via `list_taxonomy` with  
  `domain: 'disposition'`, inserted if absent so an existing database gains them on next open.

### Won't Have (this iteration)

- The equivalent change to `cpm/` — separate work, and the reason DPM went first.
- An output style: reaches more, competes with skill text, not testable.
- Runtime enforcement of report shape: no mechanism parses an agent's prose reliably, and a check  
  that half-works would license the reports it happened to pass.
- A worked before/after example in the convention section.

## Non-Functional Requirements

- **NFR1 — The convention states the rule, not its history.** It is read at startup by every skill on  
  every invocation. Rationale that stops an agent routing around the rule stays; biography goes.
- **NFR2 — It does not restate or contradict Conversational Output.** That section governs cadence  
  and length; this one governs the state of a reported item.
- **ENV1 — Node 22.5.0 or later with `node --test` runnable from `dpm/`.**
- **ENV2 — The whole suite runs in one command.** A skill amendment can pass a feature's own tests  
  and fail a corpus sweep there was no obvious reason to run.
- **ENVX1 — Must not require a new dependency.** `package.json` carries none, and that is the state  
  to preserve.
- **ENVX2 — Must not require a running MCP server or a network call to verify.**
- **ENVX3 — Must not require a new `.sql` schema file or a `schema_version` bump.** The seed path is  
  insert-if-absent; this pins it.

No production environmental entries apply: the target for a plugin skill is a session reading a
markdown file, with no runtime version and nothing the host must supply.

## Architecture Decisions

### AD1 — Placement in the shared conventions

**Choice**: a Disposition subsection under Conversational Output.  
**Rationale**: every DPM skill reads the shared file and names the sections it uses. All 21 already
name Conversational Output, so a subsection reaches all of them with no uses-line edits.
**Alternatives considered**: a new top-level section (rejected — 21 edits, each a chance to write a
section name nothing dispatches on).

### AD2 — How the five site rules are expressed

**Choice**: the derivation principle shared, the mechanics local to each site.  
**Rationale**: `quick` derives from one tri-state; `do` Step 8 rolls up coverage across an epic and
already distinguishes a claim from a computation. One sentence covering both would have to be vague.
**Alternatives considered**: a single shared rule (rejected — vagueness is the thing being fixed).

### AD3 — How skills name the labels

**Choice**: skills name the `disposition` domain and read its terms; no skill hardcodes the four
strings. `do` Step 6 already does this for observation categories.
**Rationale**: drift is prevented by the data rather than by asking prose not to paraphrase itself,
and it makes a corpus sweep possible that a prose vocabulary could not support.
**Alternatives considered**: literal label strings in prose (superseded by AD4); semantic guidance
with free rendering (rejected — paraphrase is what happened to the autonomous-mode rule).

### AD4 — The vocabulary is data, not prose

**Choice**: a fifth seeded `taxonomy` domain, `disposition`, with terms `fixed`, `needs-you`,
`left-alone`, `unverified`.
**Rationale**: every other controlled vocabulary here is rows, and a project can then extend or
retire terms the way it can the agent roster. The cost is a seed edit: vocabulary migrations are
insert-if-absent keyed on `(domain, name)`, proven by `migration.test.js:188–215`, and nothing in the
suite pins a taxonomy row or domain count.
**Accepted cost**: the domain gains no CHECK pin, because pins are constraints on referring columns
and this domain has none. A project could hold a term nothing validates against.
**Alternatives considered**: prose-only (rejected); rows per reported item at the FR8 sites
(rejected — a storage answer to a legibility problem).

## Scope

### In Scope

- The Disposition subsection in `dpm/shared/skill-conventions.md`.
- Five projection sites: `do`, `quick`, `review`, `pivot`, `audit`.
- `do`'s autonomous mode restated in the shared vocabulary.
- Three report-only sites: `inspect`, `archive`, `clean`.
- `seeds/taxonomy.js`, and the two prose surfaces that say "four domains"  
  (`008-vocabularies.sql:22` and the seed file's header).
- Suite coverage in the affected `skill-*.test.js` files and the corpus sweeps.

### Out of Scope

- `cpm/`; an output style; runtime enforcement.
- `dpm:ralph`'s prompt. Its `target` rule is FR5's canonical Unverified case, but ralph instructs the  
  loop how to verify, not how to report; the report a human reads from a ralph run is `do`'s.

### Deferred

- The CPM equivalent, informed by whatever this one gets wrong.

## Testing Strategy

### Tag Vocabulary

- `[unit]` — assertions over file content
- `[integration]` — checks crossing into the database or the tool surface
- `[manual]` — criteria no assertion can reach

`[feature]`, `[tdd]` and `[target]` are unused: no user-facing workflow, no logic loop, and no
production environment to check against.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | A Disposition subsection under Conversational Output defines all four dispositions, each as what the reader does | `[unit]` |
| FR1 | must NOT define a disposition term privately in any skill file. *Control: `clean:86` and `archive:136` fail this before the change* | `[unit]` |
| FR2 | The subsection states the label names the reader's obligation, and resolves fixed-but-worth-a-glance to Fixed | `[unit]` |
| FR3 | The subsection states that an item fitting none of the four is omitted | `[unit]` |
| FR4 | The order is fixed, and each Needs-you item is an imperative naming the action and where | `[unit]` |
| FR4 | One real report from each of `do`, `quick` and `clean`: the reader can stop after the third block having missed nothing actionable | `[manual]` |
| FR5 | Unverified is defined as environment-impossible, requires the reason, and names the two structural cases | `[unit]` |
| FR5 | must NOT admit a run-side reason as Unverified. *Control: the routing sentence is what is removed to fail the check* | `[unit]` |
| FR6 | Each of the five sites states that its report is derived from its named rows | `[unit]` |
| FR6 | must NOT retain an instruction to summarise alongside the rows without deriving from them. *Control: removing the derivation sentence from any one site fails that site's test* | `[unit]` |
| FR7 | `do`'s autonomous section references the shared vocabulary **and** its standalone phrasing is gone — both halves asserted | `[unit]` |
| FR8 | `inspect`, `archive` and `clean` each name the domain; deleted/left and stamped/skipped use the shared labels | `[unit]` |
| FR10 | `list_taxonomy({domain:'disposition'})` returns exactly the four terms | `[integration]` |
| FR10 | An existing database gains them on next open; deleting one and reopening restores it. *Control: a term absent from the seed is not created* | `[integration]` |
| FR10 | must NOT hardcode a disposition label string in any skill file. *Control: a fixture skill file carrying one fails the sweep* | `[unit]` |
| NFR1 | The subsection carries no sentence about the rule's history | `[manual]` |
| NFR2 | The subsection neither restates nor contradicts Conversational Output's cadence guidance | `[manual]` |
| ENV1 | `package.json` keeps `engines.node >= 22.5.0` and `test: node --test`, and the suite runs | `[unit]` |
| ENV2 | `npm test` from `dpm/` runs every `tests/*.test.js`, corpus sweeps included | `[integration]` |
| ENVX1 | `dependencies` and `devDependencies` are both empty after the change | `[unit]` |
| ENVX2 | The full suite passes with no network available and no separately-started server | `[integration]` |
| ENVX3 | `src/schema/` gains no `.sql` file and `latestVersion()` is unchanged before and after | `[unit]` |

Each `[manual]` criterion states what blocks automation: FR4's is the only criterion that tests the
actual goal, and evaluating a generated report needs a reader; NFR1's asks a distinction between
load-bearing rationale and biography that no assertion draws; NFR2's would need a textual-overlap
proxy that passes on paraphrase and fails on legitimately shared vocabulary.

### Integration Boundaries

1. **Seed → database** — `seeds/taxonomy.js` through `migrate()`'s insert-if-absent pass.
2. **Database → tool surface** — `list_taxonomy` filtered by domain, the boundary a skill crosses at  
   runtime.
3. **Shared conventions → skill** — under AD1 no new reference is created; that non-crossing is the  
   claim, and a test confirms no uses-line was edited.
4. **Skill prose → corpus sweeps** — `skills-corpus`, `skills-authoring`, `reachability`.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance
criteria drive test coverage during implementation.
