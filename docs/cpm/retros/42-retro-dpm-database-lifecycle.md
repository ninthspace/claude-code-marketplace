# Retro: Two Specs, One Seam

**Date**: 2026-08-13  
**Source**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Stories**: n/a — ad-hoc retro over a spec pivot, not an epic

## Summary

Specs 48 and 49 were written the same day against the same call site — `main()` creating *and*
migrating the database at launch — and each asserted something the other made false or vacuous. The
pivot that reconciled them is the subject here. Both specs are still unbuilt, so nothing was
delivered and nothing broke; what this records is that the defect was in the planning layer and was
invisible from inside either document.

Provenance, because the usual inputs are absent: this arrived through `cpm:pivot`'s handoff, which
passes the amended source path — a spec. A spec carries no story-level `**Retro**:` fields, so the
observations below are the ones the pivot surfaced rather than ones gathered from the source.

## Observations

### Criteria Gaps

- **An absence can be delivered by something other than the mechanism under test.** Spec 48's FR3  
  must-NOT read "must NOT spawn a server against a project with no `.dpm/dpm.db`, and no file is  
  created there". Spec 49 removes creation at the source for every caller, so that criterion goes  
  green whether or not AD1's read-only mode works at all. This is retro 40's "green before the work  
  started" arriving from a direction no single spec could see — not a weak assertion inside one  
  epic, but a correct assertion undermined by a sibling document. The fix was to re-ground it on the  
  mechanism: spawn read-only against a missing database, call a read tool, assert the refusal and  
  the absence. That sequence creates a file without the flag, so it discriminates.  
  **Retired 2026-08-16**: promoted to the library document *Promoted Retro Lessons*, under "A check  
  that passes may be passing for a reason other than the one you want". It had been carried into the  
  CPM library as a 2026-08-13 amendment without being retired here; the migration folded that  
  amendment into the body and closed the gap.

### Scope Surprises

- **The document that constrained the new spec was invisible to every startup check, and the  
  relationship had no field to live in once it was found.** Spec 49's facilitation never accounted  
  for a read-only server mode. ADR discovery globs `docs/architecture/` and found nothing;  
  constraint inheritance walks the problem-brief chain, and there was none; the library check filters  
  by scope. Nothing globs `docs/specifications/` for architecture decisions that bind a new spec —  
  and spec 48 was sitting there. Then, once the overlap was known, there was nowhere to record it:  
  CPM's chain is vertical (brief → product brief → ADR → spec → epics), so two peer specs  
  constraining each other are unrepresentable and `cpm:pivot` correctly reported "no downstream  
  documents". The reconciliation had to go into both documents' prose, in an AD Consequence and a  
  Scope note, where nothing but a reader will find it.

### Codebase Discoveries

- **This project's binding architecture decisions are inside a spec, not in `docs/architecture/`.**  
  dpm's AD1–AD11 live in spec 47 and are cited by name in comments throughout `dpm/src/` — AD4 on  
  the committed dump form, AD5 on the Node floor, AD11 on regeneration being explicit. A skill that  
  discovers ADRs by globbing `docs/architecture/` reports "no ADRs found", which is true and  
  misleading in the same breath; the decisions were found only by chasing what "AD4" meant in a code  
  comment. Any spec written here without reading spec 47's AD section is written without its  
  architecture.

### Patterns Worth Reusing

- **Decompose the seam into its distinct harms before deciding whether one fix subsumes another.**  
  `main()` does two harmful things: it creates a database where none existed, and it migrates and  
  re-seeds one that did. Named separately, the two specs are obviously complementary — 48 stops an  
  observer migrating a project, 49 stops any caller creating one, and neither covers the other's  
  half. Named as one hazard ("create-on-open"), they read as the same fix written twice, and the  
  reconciliation would have deleted one of them.

## Recommendations

- **Read sibling specifications' Architecture Decisions during spec startup, not only  
  `docs/architecture/`.** In this project that is where the binding decisions are, and the existing  
  ADR-discovery step cannot see them. Reporting "no ADRs" while spec 47 holds eleven is the failure  
  worth closing.
- **When a must-NOT asserts an absence, state the mechanism that produces it.** "No file is created"  
  is satisfiable by any number of parties, including a crashed process and a sibling spec's fix.  
  "The read-only connection refuses with `ERR_SQLITE_ERROR` and no file is created" is not.
- **Give a cross-artefact constraint an explicit home.** Two peer specs bearing on one component  
  currently have no representable relationship, so the only durable record is prose in both. Until  
  there is a field, write the note in both directions deliberately rather than in the one being  
  edited.
- **`cpm:retro`'s synthesis input should admit what `cpm:pivot` hands it.** Pivot's Step 5 passes the  
  amended source path, which for a spec pivot is a spec; retro's input contract accepts only  
  `docs/epics/` and `docs/quick/`, and its status-only fallback would have produced a Batch Outcome  
  over stories that do not exist. The two shipped skills disagree about a handoff they share.
