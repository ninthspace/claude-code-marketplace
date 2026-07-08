# /cpm:clean Command

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Date**: 2026-07-08
**Status**: Complete
**Blocked by**: Epic 38-01-epic-classifier-and-hooks
**Retro applied**: 04 · Patterns worth reusing · Applied — Story 1 makes /cpm:clean a thin consumer of the classifier's list-all records (one source of truth), not a re-globber; extend the classifier with a list-all mode rather than duplicating glob/stat logic in the skill.
**Retro applied**: 04 · Codebase discoveries · Applied — /cpm:clean's no-files / nothing-named case must explicitly do nothing (report "no files", exit), never fall back to broad action on empty input.
**Retro applied**: 05 · Testing gaps · Applied — the skill invokes the classifier via ${CLAUDE_PLUGIN_ROOT}; flag classifier-invocation-in-skill-Bash as a post-install validation item in the retro (unverifiable by [manual] review until republish).
**Retro applied**: 05 · Testing gaps · Applied — run the classifier test suite if Story 1 touches the classifier, and after Story 2's prose/config changes, even though all criteria are [manual] (test discovery skipped).

## Author the `/cpm:clean` skill
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR5, FR6, FR8, AD4
**Retro**: [Pattern worth reusing] Extending the shared classifier with an opt-in `list-all` mode (a second positional arg; default path byte-identical) let `/cpm:clean` reuse the one file-inventory contract instead of re-globbing (retro 04 applied) — a backward-compatible way to grow a shared helper for a new consumer without risking existing ones, proven by all hook suites staying green after the change. The compact-summary companion needed only a generalized session-id `sed` (`\.cpm-(progress|compact-summary)-`) and the same classify path; the "unknown" SKILL/PHASE for summaries is acceptable because PATH already identifies the kind.

**Acceptance Criteria**:

- `/cpm:clean` is invokable via `cpm/skills/clean/SKILL.md` with correct frontmatter (name, description, trigger), discoverable like other CPM skills [manual] — justification: skill-prose, verified by invocation + review
- Lists all `.cpm-progress-*.md` and `.cpm-compact-summary-*.md` files with age and session label (via the classifier's list-all mode) [manual]
- Compact-summary companion files are listed alongside their progress file [manual]
- Deletes only files the user explicitly names [manual]
- must NOT delete any file the user did not name [manual]
- must NOT apply a staleness filter or sentinel — exhaustive, on-demand listing every time [manual]

### Create `cpm/skills/clean/SKILL.md`
**Task**: 1.1
**Description**: Author the one-shot skill — frontmatter (name, description, trigger `/cpm:clean`); body lists all `.cpm-progress-*.md` + `.cpm-compact-summary-*.md` via the classifier's list-all mode with age + session labels, groups companions with their progress file, deletes only user-named files, applies no sentinel/staleness filter, and requires confirmation. Covers all Story 1 criteria.
**Status**: Complete

---

## Version bump & documentation
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: AD4
**Retro**: [Codebase discovery] The version bump touches three fields that must stay in sync — `cpm/.claude-plugin/plugin.json` (the epic's "cpm/plugin.json" actually lives under `.claude-plugin/`), the cpm entry in the root `.claude-plugin/marketplace.json`, and marketplace's own top-level version — and `test-audit-skill.sh` hardcodes an expected version, so `run-all-tests.sh` stays red on every bump until that test reads the version dynamically (recurring; retro 04/05 recommendation). A version-bump task here should update all three fields and expect the audit suite to need the same one-line fix.

**Acceptance Criteria**:

- `cpm/plugin.json` version is bumped for the new skill [manual]
- `cpm/README.md` documents `/cpm:clean` and the new non-blocking safety-net behaviour (3-day staleness, parallel-session awareness, no more BLOCKING) [manual]

### Bump `cpm/plugin.json` version
**Task**: 2.1
**Description**: Increment the plugin version for the new `/cpm:clean` skill, per the repo's versioning convention.
**Status**: Complete

### Update `cpm/README.md`
**Task**: 2.2
**Description**: Document `/cpm:clean` and the new non-blocking cleanup behaviour (3-day staleness, parallel-session awareness, BLOCKING removed). Covers the README criterion.
**Status**: Complete

---
