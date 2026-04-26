# Coverage Matrix: Skill Scaffolding & Plugin Registration

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Epic**: docs/epics/31-01-epic-skill-scaffolding.md
**Date**: 2026-04-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | Trigger and argument parsing | Skill triggers on `/cpm2:audit`; accepts an optional scope hint argument. | Skill recognises `/cpm2:audit` and parses optional argument as scope hint | Story 1 | `[manual]` | |
| 2 | cpm2 plumbing | Standard cpm2 plumbing: Library Check (scope `audit`), Retro Awareness, progress file lifecycle. | Skill references shared procedures (Library Check with scope `audit`, Retro Awareness, Progress File Management) per the cpm2 conventions | Story 1 | `[manual]` | |
| 19 | Plugin manifest registration | Plugin registered: skill source at `cpm2/skills/audit/SKILL.md` (auto-discovered); cpm2 plugin version bumped to `0.1.0` in `cpm2/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; optional `audit` keyword added. | File exists at `cpm2/skills/audit/SKILL.md` | Story 1 | `[unit]` | |
| 19 | Plugin manifest registration | (same) | `cpm2/.claude-plugin/plugin.json` version is `0.1.0` | Story 2 | `[unit]` | |
| 19 | Plugin manifest registration | (same) | `.claude-plugin/marketplace.json` cpm2 entry version is `0.1.0` | Story 2 | `[unit]` | |
| 19 | Plugin manifest registration | (same) | Both manifests include `audit` keyword in their keyword arrays | Story 2 | `[unit]` | |
