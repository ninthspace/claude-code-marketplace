# Discussion: Fixing the /cpm:epics coverage matrix — from evaluative to procedural

**Date**: 2026-02-25
**Agents**: Jordan, Margot, Bella, Tomas, Casey, Ren

## Discussion Highlights

### Key points
- Three changes were added in commit 625daca (v1.17.0): criteria fidelity (Step 3), testability standard (Step 3), coverage matrix (new Step 3d)
- Margot flagged structural concern: Step 3 is instruction-dense with fidelity/testability layered on top of existing traceability, tag propagation, and degradation rules
- Bella identified the enforcement gap: fidelity and testability are advisory text, not enforced checkpoints. Coverage matrix catches missing requirements but not watered-down ones ("Partial" detection relies on the model noticing its own vagueness)
- **Concrete evidence from simple-cricket project** (spec 11, epics 26-29):
  - **600→700 line drift**: Spec Req 7 says "~600 lines" but Epic 28 Story 3 says "under 700 lines" — fidelity violation. Root cause: spec's own testing strategy table says 700 (internal spec inconsistency), and epics followed the table, not the requirement text
  - **Req 6 has no explicit story coverage**: "Simulation output unchanged" and "Random call order preserved" appear in spec but no story's Satisfies field references Req 6. Scattered golden master criteria are implicit coverage, not explicit
  - **Coverage matrix was produced** but didn't catch these issues — confirms evaluative self-assessment doesn't work
  - **Mechanical features work**: tag propagation, TDD ordering, testing task auto-generation all correct
  - **Evaluative features don't work**: fidelity checking, coverage verification — model treats them as advisory
- **Core pattern identified**: model follows procedural instructions reliably, struggles with evaluative/self-assessment instructions

### Decisions

1. **Make the coverage matrix procedural, not evaluative** — side-by-side verbatim text from spec requirements section and story criteria. The model extracts and presents; the human judges fidelity. Removed "Exact/Partial/GAP" subjective assessment. Quote from the requirements section, not the testing strategy table (requirements text is authoritative).

2. **Persist the coverage matrix per-epic** — saved as `docs/epics/{nn}-coverage-{slug}.md` using the same number and slug as its companion epic. The matrix is a durable traceability artifact, not a transient progress file entry.

3. **Step 3d runs per-epic in the production loop** — after Step 3c (integration testing), before saving the epic doc. Fidelity gets checked while the epic is still fresh. Production loop is now: 3 → 3b → 3c → 3d per epic.

4. **Cross-epic gap check in Step 4** — after all per-epic loops finish, scan all coverage matrices against the spec's full must-have list. Requirements that don't appear in any coverage matrix are flagged as GAPs. Two failure modes, two checkpoints: per-epic catches fidelity drift early, cross-epic catches coverage gaps late.

5. **Coverage file naming** — `{nn}-coverage-{slug}.md` follows epic naming convention. No special `00` prefix or unnumbered files. Won't collide with epic glob patterns (`[0-9]*-epic-*.md`).

### Changes implemented
All changes applied to `cpm/skills/epics/SKILL.md`:
- Step 3d rewritten: procedural side-by-side matrix, per-epic scoping, verbatim quoting from requirements section
- Production loop updated to include 3c and 3d
- Step 4 updated with cross-epic gap check
- Output section: per-epic coverage matrix artifact format
- Progress file template: updated Step 3d section
- Guidelines: updated coverage matrix guideline
