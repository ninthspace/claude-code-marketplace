# Spec: cpm:retro — Lightweight Retrospective

**Date**: 2026-02-10
**Brief**: Party mode discussion on CPM plugin improvements

## Problem Summary

When `/cpm:do` executes a batch of tasks, valuable observations are lost — tasks that were harder than expected, acceptance criteria that missed what mattered, codebase surprises. Traditional retrospectives don't fit the agentic workflow. `cpm:retro` provides a lightweight capture-and-feed-forward mechanism that records observations during task execution and synthesises them into actionable input for the next planning cycle.

## Functional Requirements

### Must Have
- Per-task observation capture integrated into `/cpm:do` (new step 6.5, after marking complete). Claude self-assesses and only records when something noteworthy happened — no user prompt, no friction
- Observations stored as a `**Retro**:` field under completed stories in the stories doc
- Batch summary synthesised when `/cpm:do`'s work loop completes, written as a "Lessons" section appended to the stories doc
- Feed-forward output: batch summary structured for use as input context to `/cpm:discover` or `/cpm:spec`

### Should Have
- Standalone `/cpm:retro` skill invocation — run against a completed stories doc to generate/regenerate the synthesis retro file
- Categorised observations tagged by type: scope surprise, criteria gap, complexity underestimate, codebase discovery

### Could Have
- Git history analysis when invoked standalone (reconstruct from commits/diffs)
- Cross-batch learning — read previous retro files to identify recurring patterns
- Suggested planning improvements based on observed patterns

### Won't Have (this iteration)
- Automated acceptance criteria rewriting
- Numeric metrics, difficulty scoring, or velocity tracking
- Interactive retro facilitation (guided Q&A ceremony)

## Non-Functional Requirements

### Usability
- Inline capture must be non-disruptive to `/cpm:do` flow — no user prompts per task
- Batch summary must be scannable in under 30 seconds

### Reliability
- Retro is additive, never blocking. If capture fails (stories doc deleted, write error), `/cpm:do` continues unaffected
- Same graceful degradation pattern as existing stories doc integration

### Data Integrity
- Observations written to disk immediately via Edit tool — survive context compaction

## Architecture Decisions

### Inline Capture via Self-Assessment
**Choice**: Claude automatically generates observations after each task, gated by a noteworthy-only check
**Rationale**: User-prompted observation after every task would destroy `/cpm:do`'s momentum. Automatic capture with a quality gate (only record when something surprising or notable happened) balances signal quality with zero friction
**Alternatives considered**: User-prompted per task (too disruptive), record every task (noise dilutes signal)

### Split Storage
**Choice**: Per-task observations in stories doc (`**Retro**:` field), batch synthesis in `docs/retros/{nn}-retro-{slug}.md`
**Rationale**: Per-task notes are contextual and belong with the task. The synthesis is a standalone reference document for the next planning cycle — it needs its own home, consistent with the existing convention (plans, specs, stories each have their own directory)
**Alternatives considered**: Everything in stories doc (clutters working document), everything in retro file (loses per-task context)

### Feed-Forward via Pipeline Handoff + Proactive Check
**Choice**: Standard pipeline handoff from retro (AskUserQuestion offering discover/spec/stories) plus discover/spec proactively check for recent retro files on startup
**Rationale**: Pipeline handoff follows the existing pattern. The proactive check ensures retro insights feed forward even when the user doesn't come directly from retro — across separate sessions
**Alternatives considered**: Handoff only (retro output sits unused unless explicitly passed)

## Scope

### In Scope
- New `cpm:retro` SKILL.md — standalone skill that reads completed stories doc, synthesises observations, writes retro file
- Modify `cpm:do` SKILL.md — add step 6.5 (observation capture with noteworthy-only gate)
- Retro file format and naming convention (`docs/retros/{nn}-retro-{slug}.md`)
- Pipeline handoff from retro to discover/spec/stories
- Categorised observations (scope surprise, criteria gap, complexity underestimate, codebase discovery)
- Modify `cpm:discover` and `cpm:spec` SKILL.md — add startup check for recent retro files and offer to incorporate

### Out of Scope
- Automated criteria rewriting
- Metrics, scoring, or velocity tracking
- Interactive retro facilitation

### Deferred
- Git history analysis for standalone reconstruction
- Cross-batch learning from previous retro files
- Suggested planning improvements based on recurring patterns
