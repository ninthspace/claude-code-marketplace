# Discussion: Prompt Engineering Best Practices Audit for CPM

**Date**: 2026-03-15
**Agents**: Jordan, Margot, Bella, Priya, Elli

## Discussion Highlights

### Key points so far

**Round 1 — Initial themes:**
1. Over-prompting is counterproductive on Claude 4.6 — aggressive language causes overtriggering (Margot, Bella)
2. State management is well-aligned but could improve with structured formats (Margot)
3. Subagent orchestration guidance is missing, especially for cpm:do (Margot)
4. Prescriptive step-by-step instructions may limit Claude's reasoning (Bella)
5. Default-to-action pattern needed in cpm:do (Bella)
6. Investigate-before-answering for discovery/spec skills (Bella)
7. Add motivation/context to instructions consistently (Elli)
8. Reframe "Do NOT" patterns as positive instructions (Elli)

**Round 2 — Grounded in actual skill files, MoSCoW prioritisation:**

**Must-do (3):**
1. Soften aggressive progress file language in cpm:do and cpm:quick — rewrite "YOU ARE ABOUT TO SKIP THIS" / "HARD RULE" as calm instructions with context/motivation.
2. Add `<investigate_before_answering>` block to cpm:discover and cpm:spec.
3. Add subagent orchestration guidance to cpm:do.

**Should-do (4):**
4. Add motivation/context ("Do X so that Y") to key instructions across all skills.
5. Reframe "Do NOT" patterns as positive instructions across all skills.
6. Add context-awareness guidance to state management boilerplate.
7. Add `<default_to_action>` block to cpm:do guidelines.

**Deferred (2):**
8. Structured state (JSON) for progress files — low ROI, breaks human-readability.
9. Reducing prescriptive step-by-step in cpm:do — risky without testing.

**Round 3 — XML tag strategy:**

Elli distinguished two XML uses from the best practices doc:
- **Semantic blocks** (named behavioural directives like `<default_to_action>`) — HIGH VALUE
- **Structural separation** (`<instructions>`, `<context>`, `<documents>`) — LOW VALUE for us, markdown already handles this

Priya raised readability concern: XML-heavy prompt files become write-only for human developers. Rule: max 3-4 XML blocks per skill file.

Bella proposed concrete rule: **XML blocks for cross-cutting behavioural directives only, not procedural steps.**

Team agreed on 4 specific XML blocks:

| Block | Skills | Purpose |
|-------|--------|---------|
| `<default_to_action>` | cpm:do | Implement rather than suggest |
| `<investigate_before_answering>` | cpm:discover, cpm:spec | Ground in codebase, don't speculate |
| `<progress_file_discipline>` | cpm:do, cpm:quick, cpm:party | Calm but firm progress file rule, replaces ALL CAPS |
| `<subagent_guidance>` | cpm:do | When to delegate vs. work directly |

### Decisions
- **Decision 1**: Adopt semantic XML blocks selectively — behavioural directives only
- **Decision 2**: Do NOT adopt structural XML wrapping — markdown headings are sufficient
- **Decision 3**: Limit to max 3-4 XML blocks per skill file
- **Decision 4**: The 4 specific blocks above are the complete set for this change
- **Decision 5**: 7 concrete changes prioritised as 3 must-do, 4 should-do
- **Decision 6**: Defer structured JSON state and prescriptive step reduction

### Source material
- Anthropic prompt engineering best practices: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Skills reviewed: cpm:do, cpm:discover, cpm:spec, cpm:quick, cpm:party
