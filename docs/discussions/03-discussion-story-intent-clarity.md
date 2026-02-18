# Discussion: Should CPM Epic Stories Be More Explicit About Implementation Details?

**Date**: 2026-02-18
**Agents**: Jordan, Margot, Bella, Elli

## Key Points

### The current format is deliberately intent-oriented
- Stories describe *what* to deliver, not *how* — this is by design
- `cpm:do` has Step 3 (Plan) where implementation details are discovered fresh against the current codebase state
- Embedding implementation guidance creates a second source of truth that goes stale immediately

### Code snippets and step-by-step tasks are both problematic
- Code snippets are concrete artifacts pretending to be specifications — they go stale as surrounding code moves
- Step-by-step tasks encode assumptions about codebase state that may no longer hold after earlier tasks execute
- Other systems use these to compensate for an executor that can't explore the codebase — `cpm:do` can

### The real gap is layer 2: task scope clarity
- Three layers of intent clarity identified:
  1. "What are we building?" — story title + acceptance criteria (stable)
  2. "What's this task's slice?" — description field (stable when tied to criteria, flaky when tied to implementation)
  3. "How do we build it?" — code snippets, file paths, steps (immediately flaky)
- The current system handles layers 1 and 3 correctly; the gap is layer 2
- The `**Description**` field exists but is optional and guidance for when to write one is vague
- The producing agent often skips it because it has full context and *thinks* the title is obvious

### What doesn't go stale: constraints and relationships
- "This task must not introduce new dependencies"
- "This task produces the interface that Task 2.3 consumes"
- "This task addresses the error handling path, not the happy path"
- These are architectural intent — they scope work without prescribing how it's done

## Decision

Strengthen the description field's guidance in `cpm:epics` Step 3b, not add new fields. Three concrete changes:

1. **Make descriptions default-on for multi-task stories** — flip the guidance from "write one when the title isn't obvious" to "write one unless the story has a single task or the title is unambiguous"
2. **Anchor descriptions to acceptance criteria** — descriptions should reference which criteria the task addresses, creating a traceable link from task → criteria → spec requirement
3. **Allow constraint-style descriptions** — encourage descriptions that state scope boundaries ("handles the error path," "produces the interface for Task 2.3") rather than implementation steps

None of these inject implementation detail. They're all stable references to other stable content. The epics skill can do this during Step 3b without needing extra user input — it already has the acceptance criteria when writing task descriptions.
