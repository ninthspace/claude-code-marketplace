# Spec: cpm:pivot — Course Correction

**Date**: 2026-02-10
**Brief**: Party mode discussion on CPM plugin improvements

## Problem Summary

The CPM pipeline flows strictly forward: discover → spec → stories → do. But planning is iterative — mid-spec you might realise the problem brief was wrong, or mid-execution you might discover the scope needs to change. Currently there's no structured way to go back and revise an earlier artefact with changes cascading forward through dependent documents. `cpm:pivot` provides a way to revisit any planning artefact, surgically amend it, and walk the user through updating downstream documents.

## Functional Requirements

### Must Have
- Artefact selection: user specifies which document to revisit (brief, spec, or stories) by path, or picks from a discovered list of existing planning documents
- Pre-loaded amendment: open the selected document with full content visible. User describes what to change; Claude makes surgical edits using the Edit tool
- Change summary: after edits, present a clear summary of what changed and why it matters downstream
- Downstream impact analysis: identify which dependent documents are affected by the change and flag specific sections

### Should Have
- Cascading update facilitation: after editing the source document, walk downstream documents one at a time. For each, identify affected sections, propose changes with rationale, and gate each update with AskUserQuestion
- Task impact detection: if stories/tasks exist, match affected stories to tasks (via task ID if embedded, subject matching as fallback) and present the list. User decides action — pivot doesn't auto-modify tasks

### Could Have
- Version tracking: append a changelog entry to amended documents (date, what changed, why)
- Partial cascade: let the user choose which downstream documents to update rather than walking all of them

### Won't Have (this iteration)
- Automatic downstream document rewriting without user approval
- Git-level versioning (branches, commits for the pivot)
- Undo/rollback mechanism

## Non-Functional Requirements

### Usability
- Pivot workflow must feel lighter than re-running the original skill. If amending a brief takes longer than re-running discover, the skill has failed its purpose
- Artefact selection should auto-detect the most likely candidate when possible

### Reliability
- Surgical edits only (Edit tool, not Write) to minimise risk of accidental content loss
- If cascade fails midway, already-saved changes to upstream documents are preserved
- Handles partial dependency chains gracefully (spec without brief, stories without spec)

### Data Integrity
- Each edit saved to disk immediately — no content held only in memory

## Architecture Decisions

### Artefact Chain Discovery via Back-References
**Choice**: Glob `docs/plans/`, `docs/specifications/`, `docs/stories/`. Read `**Brief**:` and `**Source**:` fields to build the dependency chain. Fall back to slug matching when references are missing
**Rationale**: Documents already contain these back-references. Building on existing convention avoids adding new infrastructure. Slug matching provides graceful degradation for documents created outside the CPM pipeline
**Alternatives considered**: Separate dependency manifest file (over-engineering), no chain discovery — user always specifies the document (less useful)

### Edit-then-Cascade Workflow
**Choice**: After source document edits, walk downstream documents one at a time. For each: read, identify affected sections by comparing against changes, propose updates with rationale, gate with AskUserQuestion
**Rationale**: Automatic cascade would be dangerous — downstream documents may have been manually edited or contain context not derivable from the source. Human-in-the-loop for every downstream change ensures nothing is overwritten unintentionally
**Alternatives considered**: Fully automatic cascade (too risky), no cascade — just flag impact (misses the value of guided updates)

### Task Flagging Without Auto-Modification
**Choice**: Match affected stories to Claude Code tasks and present the list. User decides what to do with each task
**Rationale**: Tasks live in Claude Code's system and may be in-progress or have dependencies. Auto-modifying them could disrupt active work. Flagging gives the user full control
**Alternatives considered**: Auto-update task descriptions (too aggressive), ignore tasks entirely (leaves stale tasks)

## Scope

### In Scope
- New `cpm:pivot` SKILL.md — standalone skill for artefact selection, surgical editing, change summary, downstream impact analysis
- Cascading update facilitation — guided downstream document updates with per-section user approval
- Task impact flagging — identify affected tasks, present to user
- Artefact chain discovery via back-references and slug matching
- State management via `.cpm-progress.md`

### Out of Scope
- Automatic downstream document rewriting
- Git-level versioning
- Undo/rollback
- Modifying the task system

### Deferred
- Mid-skill invocation ("pivot" keyword recognised during other CPM skills)
- Version tracking / changelog entries
- Partial cascade (selective downstream updates)
- Audit/fix of back-reference consistency in discover/spec/stories skills
