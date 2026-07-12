# Pipeline Handoffs

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Complete
**Blocked by**: Epic 31-04-epic-deliverable-generation

## Pipeline handoff offer + library/spec/quick handlers
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: #18 (pipeline handoff offer)

**Acceptance Criteria**:

- After deliverable is saved, skill presents a final `AskUserQuestion` with options: "Send findings to `/cpm2:library`", "Promote priorities to `/cpm2:spec`", "Run quick wins through `/cpm2:quick`", "Done" `[manual]`
- "Done" option ends the session with no further skill invocation `[manual]`
- Library handoff creates a wrapper entry at `docs/library/{nn}-library-audit-{slug}.md` with frontmatter (scope keywords selected via `AskUserQuestion`) referencing the audit document `[unit]`
- Spec handoff invokes `/cpm2:spec` via the Skill tool, passing the audit document path as args `[manual]`
- Quick handoff invokes `/cpm2:quick` via the Skill tool, passing the audit document path as args `[manual]`

### Document final AskUserQuestion handoff offer
**Task**: 1.1
**Description**: Document the final AskUserQuestion in SKILL.md with the four options (library / spec / quick / done) and the per-option behaviour. Covers the offer-presentation and "Done" criteria.
**Status**: Complete

### Document library wrapper entry creation
**Task**: 1.2
**Description**: Document in SKILL.md the library handoff procedure: when user selects library, ask for scope keywords via AskUserQuestion, write a wrapper file at `docs/library/{nn}-library-audit-{slug}.md` with library frontmatter (scope, keywords) referencing the audit document. Covers the library-wrapper criterion. Implements Architecture Decision 6 (single library wrapper entry per audit).
**Status**: Complete

### Document spec and quick handoff invocation
**Task**: 1.3
**Description**: Document in SKILL.md the spec/quick handoff procedure: invoke the named skill via the Skill tool, passing the audit document path as args. Covers the spec/quick handoff criteria.
**Status**: Complete

### Write tests for library wrapper path
**Task**: 1.4
**Description**: Write automated tests asserting that library wrapper entries are written to `docs/library/{nn}-library-audit-{slug}.md` with proper library frontmatter (scope keywords as a YAML list), and that the slug matches the source audit document's slug.
**Status**: Complete

---

## Scope hint disambiguation
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: #22 (scope hint disambiguation — should-have)

**Acceptance Criteria**:

- When the scope hint argument matches multiple plausible interpretations (e.g. user says `auth` and project has both `src/auth/` and `tests/auth/`), skill presents an `AskUserQuestion` to disambiguate before proceeding `[manual]`

### Document scope hint disambiguation procedure
**Task**: 2.1
**Description**: Document in SKILL.md the disambiguation procedure: detect ambiguous scope hints by globbing for matches across the project, and if multiple plausible interpretations exist, present an AskUserQuestion to let the user pick. Include a representative example (e.g. `auth` matching `src/auth/` and `tests/auth/`). Covers the sole criterion.
**Status**: Complete

---

## Lessons

### Smooth Deliveries

- Story 1: Single multi-section edit covered the four handoff options plus the library wrapper frontmatter; tests for library wrapper path reuse the same vacuous-pass-when-empty pattern as the audit deliverable tests.
- Story 2: Scope hint disambiguation slotted naturally into the Pipeline Handoffs section even though it runs at the start of the audit — keeping all "user-shaping" interactions documented near each other improved readability over scattering them across the SKILL.md.

### Patterns Worth Reusing

- Library wrapper slug-matching test (slug from wrapper filename must match a source audit document) catches stale wrappers if an audit gets renumbered or archived without updating the wrapper. Worth applying to any wrapper-style indirection in cpm2.
