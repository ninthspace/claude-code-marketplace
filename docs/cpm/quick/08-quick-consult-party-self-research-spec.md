# Fix consult/party agents asking user code questions instead of researching

**Date**: 2026-03-22
**Status**: Complete

## Context

The `/cpm:consult` and `/cpm:party` skills had a broad "Ask the user questions" instruction that encouraged agents to ask the user about code/implementation details they could look up themselves. Users had to repeatedly tell agents "you can find this out yourself" and "you need to research this." Fixed by replacing the instruction with a "Research before asking" rule that distinguishes code questions (use tools) from intent questions (ask user).

## Acceptance Criteria

- Agent response rules explicitly instruct agents to use Read/Grep/Glob to investigate code questions rather than asking the user — Met
- The instruction distinguishes between questions about user intent (ask) and questions about code details (research) — Met
- The old blanket "ask the user questions" instruction is replaced in both skills — Met

## Changes Made

- `cpm/skills/consult/SKILL.md` — Replaced "Ask the user questions" bullet (line 91) with "Research before asking" rule that directs agents to use Read, Grep, Glob for code questions and reserve user questions for intent/decisions
- `cpm/skills/party/SKILL.md` — Same replacement at line 99

## Verification

Grep confirmed "Research before asking" present in both files, "Ask the user questions" absent from both files.

## Retro

**Smooth delivery**: Small, targeted fix — the root cause was a single overly broad instruction duplicated across two skill files.
