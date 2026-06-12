# Bring Filament Mockup Skill into the Marketplace

**Date**: 2026-06-12
**Status**: Complete

## Context

The `filament-mockup` skill existed only as a global skill at `~/.claude/skills/filament-mockup/`. Chris wanted it brought into this marketplace as a distributable plugin. Done via quick execution because it follows the established single-skill-plugin pattern (precedent: record 07, add-js-simplifier-skill) — no architectural decisions, low risk.

## Acceptance Criteria

- `filament-mockup/` contains all 6 skill files matching the global source, plus `.claude-plugin/plugin.json` (MIT) — Met
- `marketplace.json` includes a `filament-mockup` entry and marketplace version is `3.1.0` — Met
- `README.md` has a Filament Mockup section with description + quick start, and install/uninstall commands — Met
- `CLAUDE.md` plugin list and directory table both include `filament-mockup` — Met
- Script comment headers reference the plugin path, not the global skill path — Met
- The global skill at `~/.claude/skills/filament-mockup/` no longer exists — Met

## Changes Made

- `filament-mockup/SKILL.md` — copied from global source (byte-identical; `license: Proprietary` frontmatter left as-is)
- `filament-mockup/assets/mockup-shell.html` — copied from global source
- `filament-mockup/references/fi-grammar.md`, `references/pitfalls.md` — copied from global source
- `filament-mockup/scripts/capture.mjs`, `scripts/verify.mjs` — copied; comment-header usage path changed from `/Users/<you>/.claude/skills/filament-mockup/...` to `$CLAUDE_PLUGIN_ROOT/scripts/...`
- `filament-mockup/.claude-plugin/plugin.json` — new manifest, v1.0.0, MIT, 10 keywords
- `.claude-plugin/marketplace.json` — added `filament-mockup` plugin entry; bumped marketplace version 3.0.1 → 3.1.0
- `README.md` — added Filament Mockup section (workflow, quick start, key features, Playwright requirement); added install + uninstall lines; updated overview sentence
- `CLAUDE.md` — added `filament-mockup` to the plugin list and the source-directory table
- `~/.claude/skills/filament-mockup/` — removed (marketplace plugin is now the single source)

## Verification

Both JSON manifests parse cleanly (`json.load`). Confirmed the 6-file plugin tree plus manifest via `find`. Programmatically confirmed the `filament-mockup` entry exists in marketplace.json and version is `3.1.0`. Grepped README.md (3 matches) and CLAUDE.md (2 matches) for the new references. Grepped scripts/ to confirm the old global path is gone. Confirmed the global skill directory no longer exists.

## Retro

**Pattern worth reusing**: Adding a single-skill plugin to this marketplace is a stable 6-step recipe (copy files → plugin.json → marketplace.json entry + version bump → README section → CLAUDE.md tables → optional source cleanup). Record 07 served as a near-exact template, short-circuiting re-exploration — worth treating as the canonical "add a plugin" playbook for future `/cpm:quick` runs.
