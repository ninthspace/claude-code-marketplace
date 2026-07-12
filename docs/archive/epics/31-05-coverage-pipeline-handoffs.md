# Coverage Matrix: Pipeline Handoffs

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Epic**: docs/epics/31-05-epic-pipeline-handoffs.md
**Date**: 2026-04-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 18 | Pipeline handoff offer | Pipeline handoff offer: final `AskUserQuestion` (library / spec / quick / done); selected option invokes downstream skill via Skill tool with audit document path as args. | After deliverable is saved, skill presents a final `AskUserQuestion` with options: "Send findings to `/cpm2:library`", "Promote priorities to `/cpm2:spec`", "Run quick wins through `/cpm2:quick`", "Done" | Story 1 | `[manual]` | ✓ |
| 18 | Pipeline handoff offer | (same) | "Done" option ends the session with no further skill invocation | Story 1 | `[manual]` | ✓ |
| 18 | Pipeline handoff offer | (same) | Library handoff creates a wrapper entry at `docs/library/{nn}-library-audit-{slug}.md` with frontmatter (scope keywords selected via `AskUserQuestion`) referencing the audit document | Story 1 | `[unit]` | ✓ |
| 18 | Pipeline handoff offer | (same) | Spec handoff invokes `/cpm2:spec` via the Skill tool, passing the audit document path as args | Story 1 | `[manual]` | ✓ |
| 18 | Pipeline handoff offer | (same) | Quick handoff invokes `/cpm2:quick` via the Skill tool, passing the audit document path as args | Story 1 | `[manual]` | ✓ |
| 22 | Scope hint disambiguation | Scope hint disambiguation: if hint matches multiple plausible interpretations, confirm with user. | When the scope hint argument matches multiple plausible interpretations (e.g. user says `auth` and project has both `src/auth/` and `tests/auth/`), skill presents an `AskUserQuestion` to disambiguate before proceeding | Story 2 | `[manual]` | ✓ |
