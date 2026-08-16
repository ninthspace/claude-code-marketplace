# Ensure quick spec is always written out and tracked, plus bring across cpm:do features

**Date**: 2026-02-22
**Status**: Complete

## Context

The `/cpm:quick` skill sometimes skipped from scope assessment straight to implementation without writing out the agreed specification. Additionally, it lacked several features from `/cpm:do` that improve verification quality and traceability. This change adds mandatory spec file tracking and ports four features from `/cpm:do`: test runner discovery, ADR awareness, emphatic progress file language, and retro observations.

## Acceptance Criteria

- Step 2 includes instruction to write confirmed proposal to `docs/quick/{nn}-quick-{slug}-spec.md` — Met
- Step 3 begins with explicit instruction to read spec file back before executing (hard gate) — Met
- Completion record template references the spec file path — Met
- Spec file format includes change summary, files affected, and acceptance criteria — Met
- Test Runner Discovery section added after Library Check — Met
- Step 3 includes ADR awareness before implementation — Met
- Progress file instructions include HARD RULE and KNOWN FAILURE MODE language — Met
- Completion record template includes mandatory Retro field with observation categories — Met
- Step 4 verification runs cached test command before self-assessment — Met
- Progress file template includes `**Test command**` field — Met

## Changes Made

- `cpm/skills/quick/SKILL.md` — Added "Write the Spec File" subsection to Step 2 (mandatory, with spec file template). Added hard gate paragraph at start of Step 3 requiring spec file read-back. Changed completion record to replace the spec file in-place. Added Test Runner Discovery startup section (lines 41-58) with library/config/user discovery priority and caching. Added ADR awareness paragraph to Step 3 (line 154). Added HARD RULE blockquote to Process section (line 26) and KNOWN FAILURE MODE blockquote to State Management (line 264). Added Retro section to completion record template (lines 226-240) with seven observation categories. Updated Step 4 verification (lines 181-188) to run cached test command before self-assessment. Added `**Test command**` to progress file template (line 276).

## Verification

Full re-read of SKILL.md (307 lines) confirmed all ten acceptance criteria are met. Test Runner Discovery at lines 41-58 with discovery priority and cache instruction. ADR awareness at line 154 with glob pattern. HARD RULE at line 26 and KNOWN FAILURE MODE at line 264. Retro field in completion template at lines 226-240 with all seven categories. Step 4 verification at lines 183-186 runs test command with pass/fail handling. Progress file template includes Test command field at line 276.

## Retro

**Pattern worth reusing**: Porting battle-tested language from a mature skill (cpm:do) into a lighter skill is more effective than writing new instructions from scratch — the emphatic progress file language exists because real failures happened.
