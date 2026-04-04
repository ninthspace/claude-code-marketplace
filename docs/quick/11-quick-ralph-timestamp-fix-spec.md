# Fix Ralph Loop started_at Timestamps

**Date**: 2026-04-04
**Status**: Complete

## Context

The ralph loop state file (`started_at` field) recorded incorrect timestamps — typically rounded to the nearest hour (e.g., `12:00:00Z` instead of `12:45:00Z`). This happened because the SKILL.md instructed the LLM to generate the current UTC time, but LLMs approximate timestamps and the example biased toward round values. Fixed via quick execution since it was a single-file instruction change.

## Acceptance Criteria

- `started_at` in the state file reflects the actual current UTC time (second-accurate), not a rounded approximation — Met
- The SKILL.md explicitly instructs use of `date -u` command, removing reliance on LLM time generation — Met

## Changes Made

- `cpm/skills/ralph/SKILL.md` — Added instruction in Step 3b to capture UTC time via `date -u +"%Y-%m-%dT%H:%M:%SZ"` before displaying or writing the state file. Updated dry-run template, Step 3c write instruction, and maintenance coupling example to use the Bash-captured `{utc_timestamp}` instead of LLM-generated times.

## Verification

Grepped `started_at|utc_timestamp|date -u` across SKILL.md — all four references are consistent: the Bash capture instruction at line 128, dry-run display at line 140, state file write at line 161, and maintenance coupling example at line 234.

## Retro

**Smooth delivery**: Single-file change, clear root cause, straightforward fix. The example value (`12:00:00Z`) in the maintenance coupling section was likely the primary bias source.
