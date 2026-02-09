---
name: cpm:spec
description: Build a structured requirements and architecture specification through facilitated conversation. Takes a problem brief or user description as input and produces a spec document with functional requirements, architecture decisions, and scope boundaries. Triggers on "/cpm:spec".
---

# Requirements & Architecture Specification

Build a structured spec through facilitated conversation. Each section uses AskUserQuestion to gate progression — never dump everything at once.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the starting context.
2. If `$ARGUMENTS` contains a description, use that as the starting context.
3. If neither, look for the most recent `docs/plans/*.md` file in the current project and ask the user if they want to use it.
4. If no brief exists, ask the user to describe what they want to build.

## Process

Work through these sections **one at a time**. Use AskUserQuestion for every gate.

### Section 1: Problem Recap

Briefly summarise the problem from the input (brief or description). Confirm understanding with the user. If starting from a brief, this should be quick — just verify nothing has changed.

### Section 2: Functional Requirements

Facilitate conversation about what the system must do. Use MoSCoW prioritisation:

- **Must have**: Core functionality without which the system fails
- **Should have**: Important but the system works without them
- **Could have**: Nice-to-haves if time allows
- **Won't have**: Explicitly out of scope for this iteration

Present a draft list and refine with the user. Don't try to capture everything at once — iterate.

### Section 3: Non-Functional Requirements

Only cover what's relevant to this project. Skip anything that doesn't apply.

Areas to consider:
- Performance (response times, throughput)
- Security (auth, data protection, access control)
- Scalability (expected load, growth)
- Reliability (uptime, error handling, data integrity)
- Usability (accessibility, device support)

### Section 4: Architecture Decisions

Key technical choices with rationale. For each decision:
- What was chosen
- Why (brief rationale)
- What alternatives were considered

If there's an existing codebase, explore it first with Read, Glob, and Grep to understand existing patterns and constraints before proposing architecture.

Areas to cover as relevant:
- Tech stack / framework choices
- Data storage approach
- Key integrations
- Deployment model
- Major structural patterns

### Section 5: Scope Boundary

Consolidate from the conversation:
- What's **in scope** for this iteration
- What's **explicitly out of scope**
- What's **deferred** to future iterations

### Section 6: Review

Present the complete spec to the user for review. Use AskUserQuestion to confirm or request changes.

## Output

Save the spec to `docs/specifications/{slug}.md` in the current project, where `{slug}` matches the brief slug if one was used as input, or is derived from the project name.

Create the `docs/specifications/` directory if it doesn't exist.

Use this format:

```markdown
# Spec: {Title}

**Date**: {today's date}
**Brief**: {link to brief if applicable}

## Problem Summary
{One-paragraph recap}

## Functional Requirements

### Must Have
- {requirement}

### Should Have
- {requirement}

### Could Have
- {requirement}

### Won't Have (this iteration)
- {item}

## Non-Functional Requirements
{Only sections that are relevant}

## Architecture Decisions

### {Decision Title}
**Choice**: {what was chosen}
**Rationale**: {why}
**Alternatives considered**: {what else was evaluated}

## Scope

### In Scope
- {item}

### Out of Scope
- {item}

### Deferred
- {item}
```

After saving, suggest next steps: `/plan` (native plan mode) to design implementation, or `/cpm:stories` to break directly into tasks.

## Guidelines

- **Facilitate, don't prescribe.** Present options and trade-offs. Let the user decide.
- **Build on existing context.** If there's a brief or existing code, use it. Don't re-ask what's already known.
- **Stay practical.** Skip sections that don't add value for the project's scale.
- **One section at a time.** Complete each before moving on.
- **Match depth to complexity.** A small feature needs a lean spec. A new product needs more detail.
