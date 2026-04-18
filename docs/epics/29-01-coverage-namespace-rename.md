# Coverage Matrix: Namespace Rename

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Epic**: docs/epics/29-01-epic-namespace-rename.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R12 — Namespace rename | Zero `cpm:` occurrences in skill files (grep) | Zero occurrences of `cpm:` remain in any `cpm2/skills/*/SKILL.md` file (grep verification) | Story 1 | `[manual]` | ✓ |
| 2 | R12 — Namespace rename | All `cpm2:` references resolve correctly | All `cpm2:` skill references in prose match actual skill names in the plugin | Story 1 | `[manual]` | ✓ |
| 3 | R12 — Namespace rename | Hook test suites updated and passing | All hook test suites pass with `cpm2:` namespace | Story 2 | `[unit]` | ✓ |
| 4 | R12 — Namespace rename | Plugin registers and invokes under cpm2 | `cpm2/.claude-plugin/plugin.json` has `"name": "cpm2"` | Story 1 | `[manual]` | ✓ |
