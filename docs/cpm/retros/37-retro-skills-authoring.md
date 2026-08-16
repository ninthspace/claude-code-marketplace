# Retro: Skills — Authoring

**Date**: 2026-08-10  
**Source**: docs/epics/47-07-epic-skills-authoring.md  
**Stories**: 8/8 complete

## Summary

Seven skills converted onto the tool surface, and the corpus swept as a whole on Story 8. The
substrate needed four additions the plan did not foresee, every one of them found by walking the
surface before writing a word — and the epic's dominant lesson is about the *tests*, not the
skills: eight mutations survived their first run, and six of them survived for the same two
reasons, both now fixed at source rather than papered over per story.

## Observations

### Codebase Discoveries

- **A consumer walk before writing found every gap this epic had, and found them cheaply.** Four  
  substrate additions came out of it — `product_brief` parentage, ADR sections rendering, a  
  `library_doc_id` scope, two text columns on `audit_finding` — each a one-line or one-migration  
  change, and each of which would have surfaced as a half-written SKILL.md if the walk had been  
  skipped. Two stories needed nothing, which is the same finding: the walk tells you that too.
- **Writes that allocate before they refuse leave a hole.** `create_product_brief` takes its number  
  and *then* lets the composite key reject a wrong-kind parent, so a refused create still burns a  
  number. Nothing in the epic depends on it; a reader of the numbering sequence will.
- **Retirement is one-directional and the file said otherwise until a test failed.** `entityTools`  
  drops nulls from a change set, so "clear the column to un-retire" is accepted, changes nothing,  
  and reports success. CPM's markers are deletable; these columns are not, and two passages in  
  `retro` now say so.
- **A guard that reads stored state refuses edits it should not.** `DETAIL.adr`'s exactly-one-chosen  
  check running on every `update_adr` blocked a title edit on an accepted ADR. Guards belong on the  
  change, not on the row.
- **Objects generated outside the schema files do not appear in any reading of them.** The  
  `observation` rebuild rolled back on a retirement guard `createRetirementGuards` had generated —  
  invisible on a fresh database, because those guards are created after the migration loop, so only  
  the upgrade path failed.
- **A vocabulary boundary here is enforced three deep and cannot be tested by breaking it.**  
  `taxonomy`'s primary key is `id` alone and ids are namespaced `{domain}:{slug}`, so a term cannot  
  exist in two domains before the composite foreign key or the domain CHECK is reached. Two  
  mutations against it survived because there was nothing to break.

### Testing Gaps

- **The binding could not see two thirds of the values it existed to check, and it took three  
  stories to say so.** `valuedArguments` read `enum` declarations only, so a boolean (`chosen`) or a  
  foreign key (`scope_story_id`, `parent_id`) could be deleted from a SKILL.md outright with every  
  test still passing — the *test* supplies the argument whatever the file says. Stories 2, 3 and 4  
  each closed their own instance with a prose assertion before the direction itself was widened to  
  every optional argument of a write tool. **Three workarounds is two too many**: the second  
  occurrence is the signal, not the third.
- **A rationale paragraph outlives the step it explains, and a section-wide assertion cannot tell  
  them apart.** Four survivors across Stories 5, 6 and 7 were this: the numbered step was rewritten  
  to do the forbidden thing while the paragraph beneath went on forbidding it, and every assertion  
  matched the paragraph. The step is the rule; the paragraph is why it is kept. Now  
  `instructions(source, heading)`, shared.
- **An assertion about a column written for a reader must read it.** Deleting the `Recommendation`  
  column from the audit projection passed all 454 tests, because every assertion about the column  
  was about the *write*. A column added so a pairing is answered is only added if the pairing renders.
- **A control needs a body, not just a row.** The out-of-scope library document in the shared  
  fixture had no section, so a run that ignored the scope filter entirely consulted the same one  
  section and passed. An exclusion counted in things-not-consulted needs something to not consult.
- **Two checks that agree are not two checks.** The migrated-versus-fresh schema comparison cannot  
  see a trigger dropped from a rebuild, because both paths lose it equally. It proves the paths  
  agree, not that what they agree on is complete.
- **A pattern anchored on a literal does not see the generalised form of the same instruction.**  
  `RECOVERY`'s story-suffix pattern matched `-s2` and not `-s{n}`, so a mutation that reintroduced  
  filename scoping in placeholder form walked straight through.

### Patterns Worth Reusing

- **Drive the same run twice, approved and refused.** An approved run alone cannot distinguish  
  "writes after the gate" from "writes whenever" — both leave the same rows. The refused run is  
  where the gate becomes observable.
- **Seed the decoy the wrong heuristic would pick.** A second, newer problem brief is what makes  
  "never take the most recent" checkable; a persona the plugin never shipped is what makes "the  
  roster is a table" checkable; a tenth audit dimension is what makes the sweep the project's.  
  Without the decoy the assertion passes on a fixture that could not have failed.
- **Test the thing the new mechanism replaced, not only the new mechanism.** Asserting that the  
  remediation step composes no findings-to-tasks table caught the mutation's real shape, where  
  asserting the edge exists did not.
- **Check the assumption instead of writing around it.** The Story 5 plan assumed SQLite refuses a  
  table-level CHECK on `ADD COLUMN` and budgeted a rebuild; it does not, and the migration stayed  
  additive. Story 7's rebuild was then genuinely unavoidable, and the contrast is what made that  
  legible.

## Recommendations

1. **Make the second occurrence the consolidation trigger, not the third.** Both of this epic's  
   source-level test fixes — the widened binding and the step/paragraph split — cost three stories  
   of per-story workarounds first. Epic 47-09 converts twelve more skills; a second survivor of a  
   shape already seen is a signal to fix the harness.
2. **Survey the callers before recording a consolidation's home.** The `raw`-dispatcher note filed  
   it under `support/skills.js`; ten of its twenty-three call sites are tool tests, and nine already  
   used the name. It landed in `support/planning-database.js` as `handlers`, which cost two edits  
   per file instead of a half-migration.
3. **Raise `document.status` at spec level before Epic 47-09.** It admits `pending` and `complete`  
   only, so `Superseded` and `Withdrawn` have no representation and a retired epic reads as ready.  
   Carried since retro 36 and now one epic from the skills that would write it.
4. **Decide where "the tool surface is absent" belongs, also before 47-09.** No skill and no shared  
   convention says what a run should do when the server did not launch, and the obvious  
   improvisation — compose the markdown by hand — makes the failure look like success. It is an  
   addition to skills FR25 defines by subtraction, so it is a spec-level call.
5. **Extract the four startup blocks into `dpm/shared/skill-conventions.md`.** They are near-verbatim  
   in ten SKILL.md files and will be in twenty-two; the tests already share them and the files  
   do not.  
   **Done 2026-08-10**, at the head of Epic 47-08 rather than as its own story — the binding audit  
   that epic's second disposition called for put 56 of its 76 hits inside these blocks, so widening  
   the binding and extracting the blocks were one change. Three sections, not four: Session Startup,  
   Library Check and Retro Awareness. See that epic's `**Inline change**`.
