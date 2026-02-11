# Spec: cpm:review — Adversarial Review

**Date**: 2026-02-11

## Problem Summary

The CPM pipeline has `/cpm:retro` for looking back at completed work, but nothing for critically examining planning artifacts before or during execution. `/cpm:review` takes an epic doc or a specific story and runs an adversarial review using the party agent roster — each persona examines the artifact through their professional lens, challenging assumptions, spotting gaps, and flagging risks. Like retro, it's optional. The output is a structured review document with severity-tagged findings and an optional autofix that generates remediation tasks.

## Functional Requirements

### Must Have
- Accept epic doc or story as input — file path via `$ARGUMENTS`, or auto-discover the most recent epic doc
- Load agent roster — same mechanism as party mode (project override → plugin default)
- Contextual agent selection — dynamic by scope: 2-3 agents for single stories, 3-4 for full epics, selected by content relevance
- Structured adversarial review — each agent reviews in character, identifying unclear requirements, missing acceptance criteria, hidden complexity, architectural risks, testability concerns, scope creep
- Review against library docs — agents reference relevant library documents (same scope-filtering as other skills)
- Severity classification — each finding tagged as critical (blocks execution), warning (likely to cause problems), or suggestion (improvement opportunity)
- Review output file — saved to `docs/reviews/{nn}-review-{slug}.md`, per-concern grouping with agent attribution
- Works at epic level or story level
- Autofix task generation — convert actionable findings into remediation items; adaptive: amend epic doc if active, create standalone Claude Code tasks if epic is complete or missing
- Adaptive pipeline handoff — options adjust based on epic status (pre-execution: pivot/do/exit; post-execution: retro/pivot/discover/spec/exit)
- Pipeline-compatible output — review file structured for consumption by downstream skills

### Should Have
- Cross-agent synthesis — consolidated summary where multiple agents converge on the same concern

### Could Have
- Diff review — review changes between updated and original artifacts
- Inline annotation — annotate the epic doc itself with review comments

### Won't Have (this iteration)
- Interactive back-and-forth — agents deliver their review, not a conversation
- Automatic fixing without approval — autofix generates tasks, doesn't silently rewrite
- Review of specs or briefs — scoped to epic docs and stories

## Non-Functional Requirements

### Usability
- Review file digestible in under 2 minutes — findings are bullet points with brief rationale
- Clear agent attribution on each finding via icon + bold name
- Non-disruptive — review is read-only until user explicitly opts into autofix

### Reliability
- Graceful degradation — roster, library, or format issues degrade gracefully, never block
- Compaction resilience via `.cpm-progress.md` following established patterns

### Data Integrity
- Read-only by default — source epic doc is never modified unless autofix is triggered
- Autofix is additive only — appends stories/tasks, never removes or edits existing content

## Architecture Decisions

### Review Output Structure
**Choice**: Per-concern grouping with agent attribution on each finding
**Rationale**: Groups actionable findings together (all "missing acceptance criteria" in one place) while preserving who raised each concern via icon + name tags. More actionable than per-agent sections.
**Alternatives considered**: Per-agent sections (preserves context but harder to action), both views (adds complexity without proportional value)

### Autofix Mechanism
**Choice**: Adaptive — amend epic doc if it has pending work, create standalone Claude Code tasks if epic is complete or no epic doc exists
**Rationale**: Active epics benefit from remediation stories that `cpm:do` picks up naturally. Completed epics shouldn't be reopened — standalone tasks are cleaner.
**Alternatives considered**: Tasks only (simple but loses planning context for active epics), epic amendment only (awkward for completed epics)

### Agent Selection Strategy
**Choice**: Dynamic by scope — 2-3 agents for single stories, 3-4 for full epics, selected by content relevance
**Rationale**: Matches review depth to artifact scope. A single API validation story doesn't need 4 agents; a full-stack epic does.
**Alternatives considered**: Fixed count (wastes perspectives on small scope), all agents curated (noisy)

### Review File Location
**Choice**: `docs/reviews/{nn}-review-{slug}.md` — new directory
**Rationale**: Follows CPM convention where each artifact type has its own directory (plans, specifications, epics, retros).
**Alternatives considered**: Alongside epic in `docs/epics/` (muddies the directory's purpose)

## Scope

### In Scope
- New `cpm:review` SKILL.md with adversarial review instructions
- Review output file format and `docs/reviews/` directory convention
- Contextual agent selection (dynamic by scope)
- Library doc integration during review
- Severity classification (critical / warning / suggestion)
- Autofix task generation (adaptive: epic amendment or standalone tasks)
- Adaptive pipeline handoff based on epic status
- State management via `.cpm-progress.md`
- Plugin registration — `manifest.yaml` entry and trigger phrases
- Plugin version bump

### Out of Scope
- Interactive back-and-forth conversation
- Automatic rewriting of artifacts without user approval
- Review of specs or briefs
- Diff review
- Inline annotation of epic docs

### Deferred
- Cross-agent synthesis (consolidated convergence analysis)
- Diff review mode (compare artifact versions)
- Inline annotation mode
- Extension to specs and briefs as reviewable artifacts
