# Discussion: New `/cpm:status` Skill

**Date**: 2026-03-01
**Agents**: Jordan, Margot, Bella, Tomas, Elli, Ren

## Discussion Highlights

### Key points so far

1. **Core purpose**: A read-only, observational skill that scans CPM artifacts and git history to produce a status report and recommend next steps. First CPM skill that is purely observational — no artifact produced or transformed.

2. **Dropped Claude log analysis**: Claude session logs are not useful to the end user and not reliably structured. Replaced with reviewing recent codebase and documentation changes via git, which is tool-agnostic and deterministic.

3. **Four-section report structure**:
   - **Artifact inventory** — What CPM docs exist (specs, epics, discussions, retros), their states (story counts, completion status)
   - **Recent activity** — Git commits grouped by what they touched (code vs docs vs config), recently modified CPM artifacts highlighted
   - **Current state** — Branch status, uncommitted changes, in-progress work visible from epic task statuses
   - **Recommended next steps** — Based on what's incomplete, blocked, or naturally next in the CPM pipeline

4. **Ephemeral output**: Prints structured markdown to stdout. No saved file, no progress file. If the user needs to discuss the status further, they can use other CPM skills.

5. **Edge states handled naturally**: No special-case logic. Empty project → inventory is empty, recommend `/cpm:discover` or `/cpm:brief`. All complete → recommend `/cpm:retro` or `/cpm:archive`. The output naturally reflects what exists (or doesn't).

6. **Adaptive time window for git history**: Rather than a fixed window, adapt based on commit recency — if last commit was recent, show a short window; if there's been a gap, widen to capture the last burst of activity. Show commits since the last significant gap, or last 20 commits, whichever gives better context.

7. **Simple implementation**: The SKILL.md is the entire deliverable. No state management needed. One of the simpler skills to build — glob artifacts, run git commands, synthesise report.

### Decisions
- **Objective 1**: Read-only reconnaissance skill — gathers and reports, never modifies
- **Objective 2**: Ephemeral stdout output, no saved artifact
- **Objective 3**: Four-section report (inventory, recent activity, current state, next steps)
- **Objective 4**: Git history + artifact scanning replaces Claude log analysis
- **Objective 5**: Edge states fall out naturally from conditional output, no special casing
- **Objective 6**: Adaptive git history time window
