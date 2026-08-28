# Supersession and warrant on a criterion

**Number**: 04-03  
**Source spec**: 04  
**Status**: complete — Stories 2 and 3 delivered here; story 1 was superseded and its work delivered under epic 04-01 as story 5, so nothing this epic promised is outstanding.  

## Story 1 — Superseding a criterion

**Status**: superseded — Moved into epic 04-01 as story 5, for the same reason as 04-02's story 1: the supersession columns and the tool arm that writes them cannot land in different epics without leaving the schema epic's sweeps unsatisfiable.  
**Blocked by**: —  

### Acceptance Criteria

- update_story_criterion sets superseded_at and superseded_reason together, and the criterion's own text is unchanged by that call. `[integration]`
- list_story_criterion omits a superseded criterion by default and returns it when include_superseded is passed. `[integration]`
- must NOT — A row must not exist with superseded_at set and superseded_reason null. `[integration]`
- must NOT — Superseding a criterion must not clear the verification of bindings on other criteria of the same story. `[integration]`
- control — The same call passing the criterion's text back byte-identical leaves its bindings' verification standing, so a cleared mark is the supersession rather than a trigger firing on any write. `[integration]`

### Task 1 — Add the supersession arm to update_story_criterion

**Status**: pending  

Sets the pair together and leaves the criterion's own text alone, which is the whole point of the requirement: the epic goes on recording what it delivered rather than being rewritten to match an amended requirement.

### Task 2 — Write tests for Superseding a criterion

**Status**: pending  

Covers all five criteria. The byte-identical control is the one the existing decay suite already uses, and it is what separates a trigger that fired from a trigger that fires on every write.

## Story 2 — A superseded criterion's bindings go quiet

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Superseding a criterion retires every binding hanging off it, each carrying a reason that names the supersession. `[integration]`
- Those bindings are still readable under include_retired, with their spec_fragment intact. `[integration]`
- must NOT — A superseded criterion's bindings must not remain in the set a completeness claim hashes over, so a requirement claimed before the supersession is unclaimed by it. `[integration]`
- control — Bindings on a live criterion of the same story are untouched, so the retirement follows the criterion rather than the story. `[integration]`
- control — The supersession-driven retirement satisfies the paired-reason constraint, which is the one retirement path where no caller supplies the reason. `[integration]`

### Task 1 — Add the trigger that retires a superseded criterion's bindings

**Status**: complete  

Addresses the supersession-and-retirement boundary: the reason the trigger composes has to satisfy exactly the constraint a caller's reason satisfies, with nobody there to be told an argument was missed.

### Task 2 — Write tests for A superseded criterion's bindings go quiet

**Status**: complete  

Covers all five criteria, including the control on the one retirement path no tool-level test reaches.

### Retro

- The trigger's reason had to satisfy a CHECK that, on every other retirement path, a caller is refused until they supply it — and there is no caller here. It is legal only because `story_criterion.superseded_reason` is itself paired by a CHECK one table over, so the concatenation can never be null. Nothing said that where either half lives, so the suite says it: the last test asserts both pairings by watching the constraints refuse the writes the trigger must not make, which means a future migration that unpaired `superseded_reason` would fail here rather than in a project. The other thing worth recording is what the trigger did not need to do — SQLite runs a trigger reached from inside another trigger's body under `recursive_triggers` both off and on, measured before writing anything, so migration 026's unclaim fires on its own and the unclaim is not duplicated here.

The measurement mattered: had nesting not fired, criterion 3 would have needed the unclaim written into this trigger too, and the two copies would have drifted the first time either changed.

## Story 3 — A criterion warranted by a decision

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- update_story_criterion sets warrant_adr_id, and refuses an id that does not name an accepted decision. `[integration]`
- The roll-up reads a criterion carrying a warrant and no binding as accounted for, and one carrying neither as unbound. `[integration]`
- must NOT — A criterion carrying a warrant must not be reported as an unbound gap. `[integration]`
- control — A criterion carrying neither a warrant nor a live binding is reported as an unbound gap, so the exemption above is the warrant rather than the report going quiet. `[integration]`
- control — A criterion carrying both a warrant and a live binding still counts its binding, so a warrant does not substitute for a binding where requirement text exists to quote. `[integration]`

### Task 1 — Add the warrant arm to update_story_criterion

**Status**: complete  

Sets warrant_adr_id and refuses an id naming no accepted decision. Scoped to the write; what the roll-up does with it is task 2.

### Task 2 — Teach the roll-up to read a warrant as accounting for a criterion

**Status**: complete  

Accounted for when it has either a live binding or a warrant, unbound only when it has neither. A warrant does not displace a binding where requirement text exists to quote.

### Task 3 — Write tests for A criterion warranted by a decision

**Status**: complete  

Covers all five criteria, including the control that the report still names a criterion carrying neither anchor.

### Retro

- The plan predicted the derived sweeps — parity-integration, sparse, conformance, prose-columns — would each have an opinion about `accounted_for`, and not one of them fired. They are keyed on columns and on tools, and `accounted_for` is neither: it is computed in `withAccountedFor` after the read, in the same place `reference` is computed, and it never reaches the schema or the tool registry. The sweep that did fire was `body-reads`, on the two SKILL.md paragraphs rather than on any code — it wanted `include_body` on the new `list_story_criterion` reads and a recorded judgement for each site, and one pre-existing entry had to be renumbered because the new paragraph precedes it in the same section.

Worth recording because the shape generalises: a derived response field is invisible to every sweep dpm has, so the pressure NFR5 exists to apply lands on the skill text that consumes the field, not on the field itself. Anything reached that way is judged by whoever writes the two sentences in the skills, and nothing else will ask.

## Dependencies

- blocks → 04-04
- blocks → 04-05
