# Disposition Vocabulary

**Source spec**: docs/specifications/50-spec-report-disposition.md  
**Date**: 2026-08-16  
**Status**: Complete  
**Blocked by**: —  
**Retro applied**: 54 · Testing gaps · Applied — every must-NOT in this epic has its control run before the fix, confirming it fails; a sweep that passes on first write is treated as broken.  
**Retro applied**: 54 · Testing gaps · Applied — the whole `dpm` suite runs after every skill or seed edit, not the story's own test file.  
**Retro applied**: 54 · Patterns worth reusing · Applied — Task 1.3's tests read the database through `list_taxonomy` rather than re-reading the seed module, so the seed cannot pass by agreeing with itself.  
**Retro applied**: 54 · Patterns worth reusing · Applied — FR10's four-term check is a two-way reconcile between the seed's terms and `list_taxonomy`'s rows, with an empty-set floor case.

## Seed the disposition taxonomy domain [plan]

**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR10, ENV1, ENV2, ENVX1, ENVX2, ENVX3

**Acceptance Criteria**:

- `list_taxonomy({domain:'disposition'})` returns exactly four terms: `disposition:fixed`, `disposition:needs-you`, `disposition:left-alone`, `disposition:unverified` [integration]
- An existing database gains the four terms on next open; deleting one and reopening restores it, with a control that a term absent from the seed is not created [integration]
- `src/schema/` gains no `.sql` file and `latestVersion()` is unchanged before and after [unit]
- Every surface that enumerates the domains names `disposition` — `008-vocabularies.sql`'s domain comment, `seeds/taxonomy.js`'s header, and `tools/vocabulary.js`'s taxonomy `noun` and `domain` description [unit]
- `dependencies` and `devDependencies` are both empty after the change [unit]
- `package.json` keeps `engines.node >= 22.5.0` and `test: node --test`, and the suite runs [unit]
- `npm test` from `dpm/` runs every `tests/*.test.js`, corpus sweeps included [integration]
- The full suite passes with no network available and no separately-started server [integration]

**Inline change**: the domain-enumeration criterion named two prose surfaces; `tools/vocabulary.js`'s taxonomy `noun` and `domain` description enumerate them too, and are read by the model at runtime rather than by a maintainer. Criterion widened to "every surface", all four fixed. (2026-08-16)

### Add the `disposition` domain to `seeds/taxonomy.js`

**Task**: 1.1  
**Description**: Adds the term list and its `domain('disposition', …)` entry alongside the existing four. Covers the four-term and insert-if-absent criteria; the stable-slug id convention is already established by the file.  
**Status**: Complete

### Update the two prose surfaces that state the domain count

**Task**: 1.2  
**Description**: `008-vocabularies.sql`'s `domain` column comment and the seed file's header both say four. Covers that criterion and nothing else — no behaviour changes here.  
**Status**: Complete

### Write tests for Seed the disposition taxonomy domain

**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit], [integration] or [feature]. The restore-after-delete test models on `migration.test.js:188–215`, which already proves that path with a control.  
**Status**: Complete

---

## Write the Disposition subsection

**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR1, FR2, FR3, FR4, FR5, NFR1, NFR2

Blocked by Story 1 because the subsection names a domain; writing it first leaves a window where it
points at nothing.

**Acceptance Criteria**:

- A Disposition subsection under Conversational Output in `dpm/shared/skill-conventions.md` defines all four dispositions, each stated as what the reader does [unit]
- The subsection states the label names the reader's obligation, and resolves fixed-but-worth-a-glance to Fixed [unit]
- The subsection states that an item fitting none of the four is omitted [unit]
- The order Fixed → Left alone → Unverified → Needs you is fixed, and each Needs-you item is an imperative naming the action and where [unit]
- Unverified is defined as environment-impossible, requires the reason, and names the two structural cases [unit]
- must NOT admit a run-side reason as Unverified. Control: the routing sentence is what is removed to fail the check [unit]
- No uses-line in any of the 21 skill files is edited [unit]
- The subsection carries no sentence about the rule's history [manual] — no assertion distinguishes load-bearing rationale from biography; both are prose about the rule
- The subsection neither restates nor contradicts Conversational Output's cadence guidance [manual] — a textual-overlap proxy would pass on paraphrase and fail on legitimately shared vocabulary

### Write the Disposition subsection under Conversational Output

**Task**: 2.1  
**Description**: One edit to `dpm/shared/skill-conventions.md`: the four dispositions defined by reader obligation, the reader's-obligation rule, the omission rule, the fixed ordering with imperative Needs-you items, and Unverified's environment-impossible boundary. Covers all seven automated criteria; NFR1 and NFR2 are judged at the gate rather than built.  
**Status**: Complete

### Write tests for Write the Disposition subsection

**Task**: 2.2  
**Description**: Write automated tests covering the story's [unit] criteria, including the negative check that no skill file's uses-line was edited — AD1's claim that the subsection reaches all 21 skills without one.  
**Status**: Complete

---

## Notes

Two of the spec's must-NOT rows are deliberately **not** in this epic. FR1's "must NOT define a
disposition term privately in any skill file" cannot pass until `clean` and `archive` are fixed,
which is epic 50-02. FR10's "must NOT hardcode a disposition label string in any skill file" would
pass here **vacuously**, because no skill mentions dispositions yet. Both sweeps sit on 50-02, where
they have content to check.

No integration story: two stories, whose relationship is sequential rather than an integration point.

**AD1's count is wrong and its claim is not.** The spec says 21 skills, all naming Conversational
Output. `dpm/skills/` holds **23**, of which **22** name it; the one that does not is `ralph`, which
the spec's Out of Scope already excludes for an unrelated reason. The subsection therefore reaches
every skill in scope with no uses-line edited, which is what AD1 buys. Story 2's test asserts
against the tree rather than against either number, and names `ralph` as the sole exception so a
second one cannot join it silently.
