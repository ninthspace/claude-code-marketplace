# cpm:ralph Direct State File Write

**Date**: 2026-04-03
**Status**: Complete

## Context

The `/cpm:ralph` skill depended on the ralph-wiggum plugin's `setup-ralph-loop.sh` bash script to initialise a ralph loop. The script failed when invoked through Claude Code's Bash tool because execute permissions weren't preserved during marketplace installation, forcing the user to manually copy-paste and run the bash command. Since the setup script only writes a state file that the stop hook reads, `cpm:ralph` now writes it directly.

## Acceptance Criteria

- Step 1b checks for ralph-wiggum stop hook registration instead of setup script skill availability — Met
- Step 1c no longer checks for `Bash("...setup-ralph-loop.sh":*)` permission — Met
- Step 3 writes `.claude/ralph-loop.local.md` directly via Write tool with correct frontmatter (`active`, `iteration`, `max_iterations`, `completion_promise`, `started_at`) and prompt text — Met
- Before writing, existing `.claude/ralph-loop.local.md` is checked and user warned if it exists — Met
- Dry-run shows the state file content that would be written — Met
- After writing, an activation message is output with iteration count, max iterations, and completion promise status — Met
- Maintenance coupling section documents the state file schema contract with all five fields — Met

## Changes Made

- `cpm/skills/ralph/SKILL.md` — Rewrote Step 1b (stop hook detection instead of skill availability check), removed setup script permission pattern from Step 1c, replaced Step 3 with direct state file write mechanism (3a: guard, 3b: dry-run, 3c: confirm/execute), added Ralph Wiggum State File Schema to Maintenance Coupling section, updated prompt hygiene rules to reference state file body instead of CLI argument

## Verification

All seven acceptance criteria verified by manual inspection of the final SKILL.md file. Each section was read and confirmed to match the specified behaviour.

## Retro

**Smooth delivery**: Single-file change with well-defined scope from the party discussion and spec. The existing setup script code provided a clear schema contract to document.
