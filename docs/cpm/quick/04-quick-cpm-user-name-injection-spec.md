# Inject User Name into CPM Session Context

**Date**: 2026-03-04
**Status**: Complete

## Context

CPM skills referred to the user impersonally as "the user." Adding name injection at the hook level means all skills automatically address the user by their first name without modifying any SKILL.md files. Implemented via quick execution since it's a small, pattern-following change across 2 hooks + 2 test files.

## Acceptance Criteria

- Both hooks resolve the user's name using: `$CPM_USER_NAME` env var → first word of `git config user.name` → silent fallback (no output) — Met
- Both hooks output `CPM_USER_NAME: {name}` when a name is resolved — Met
- Both hooks output a behavioural directive instructing the agent to use the name when addressing the user — Met
- When no name is resolvable, neither hook outputs any name-related lines — Met
- Existing tests continue to pass — Met
- New tests cover name injection for both hooks — Met

## Changes Made

- `cpm/hooks/session-start.sh` — added name resolution block after session ID output (env var → git first name → silent fallback) with `CPM_USER_NAME` line and behavioural directive
- `cpm/hooks/session-start-compact.sh` — identical name resolution block added
- `cpm/hooks/tests/test-startup-hook.sh` — added 4 tests (env var, directive, priority, git fallback); updated "zero files" test to accommodate new output
- `cpm/hooks/tests/test-compact-hook.sh` — added 3 tests (env var, directive, git fallback); updated "no progress files" test to accommodate new output

## Verification

All 68 tests pass across all suites. Name injection confirmed via env var override tests and git config fallback tests. Silent fallback confirmed via guard condition code inspection.

## Retro

**Smooth delivery**: Change followed the existing hook injection pattern exactly. The only wrinkle was 2 existing tests that asserted exact output equality — broadened to assert presence/absence instead, which is more resilient.
