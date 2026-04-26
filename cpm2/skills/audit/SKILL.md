---
name: cpm2:audit
description: Codebase audit skill. Produces a commit-pinned audit document with `file:line (symbol)` citations across nine dimensions of code health (architectural decay, consistency rot, type & contract debt, test debt, dependency & config debt, performance, error handling & observability, security, documentation drift), then offers pipeline handoffs to library / spec / quick. Triggers on "/cpm2:audit".
---

# Codebase Audit

Run a structured audit of the current codebase, producing a numbered audit document at `docs/audits/{nn}-audit-{slug}.md` with concrete findings, citations, and prioritised recommendations. The skill orients on the codebase, sweeps nine dimensions of code health, and ends by offering to pipe findings into `/cpm2:library`, `/cpm2:spec`, or `/cpm2:quick`.

## Input

The skill is invoked via `/cpm2:audit`. Parse `$ARGUMENTS` as an optional **scope hint**:

1. If `$ARGUMENTS` is empty, the audit covers all nine dimensions evenly across the whole codebase.
2. If `$ARGUMENTS` contains a hint (e.g. `/cpm2:audit auth` or `/cpm2:audit src/billing`), record it as the declared scope. The hint shapes which areas of the codebase receive deeper attention but does **not** cause any of the nine dimensions to be skipped.
3. If the scope hint matches multiple plausible interpretations within the project (e.g. `auth` matches both `src/auth/` and `tests/auth/`), use `AskUserQuestion` to disambiguate before proceeding.

The declared scope is recorded in the deliverable header as `**Scope**: <hint>` and the chosen interpretation seeds orient-phase reads. When no hint is provided, the header records `**Scope**: full sweep`.

## Process

**State tracking**: Create the progress file before Step 1 and update it as orient, sweep, and deliverable generation complete. See State Management below for the format. Delete the file once the deliverable has been saved and the pipeline handoff is resolved.

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before the Library Check.

**Retro incorporation** (this skill):
- **Codebase discoveries**: Inform the orient phase — surfaced patterns, conventions, and limitations from past retros are treated as known context rather than rediscovered during the sweep.
- **Patterns worth reusing**: Inform finding-recommendation phrasing — when a past pattern is the right answer, the recommendation column points at it directly.
- **Testing gaps**: Inform the test-debt dimension — past testability observations are folded into evidence-gathering before the sweep produces findings.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `audit`. Deep-read selectively when a library document directly affects the current dimension being swept — e.g. coding standards before the consistency-rot dimension, security policies before the security-hygiene dimension.

### Step 1: Orient

(populated by Epic 31-02 — orient phase: README, package manifests, directory structure, git history, top-20 file rankings, commit SHA capture, passive cpm2 artifact read, stack detection, post-orient user-shaping question.)

### Step 2: Sweep

(populated by Epic 31-03 — 9-dimension sweep, stack-specific tool execution, graceful tool degradation, run-time progress signalling, re-orientation on failure.)

### Step 3: Deliverable Generation

(populated by Epic 31-04 — numbered output via shared Numbering, deliverable structure, citation format, severity & effort scales, no-rewrites/no-padding rules, scoped audit consistency, effort aggregates.)

### Step 4: Pipeline Handoffs

(populated by Epic 31-05 — final AskUserQuestion offering library / spec / quick / done; per-option behaviour; library wrapper entry creation.)

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before Step 1 (Orient).
- **Update**: at each step transition (orient complete, sweep dimension N/9 complete, deliverable saved, handoff resolved).
- **Delete**: only after the deliverable is saved and the pipeline handoff has been resolved.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:audit
**Current step**: {orient | sweep N/9 | deliverable | handoff}
**Scope**: {hint or "full sweep"}
**Commit SHA**: {40-char SHA captured during orient}
**Stacks detected**: {list, e.g. "TS/JS, PHP, Laravel"}

## Notes
{Running notes — surfaced findings, tool failures, dimensions completed.}

## Next Action
{What to do next}
```

## Guidelines

- **Cite, don't quote.** Every concrete finding cites a `file:line (symbol)` location. Never paste actual secret values into the deliverable, even for security-hygiene findings — the citation is the location only.
- **No rewrites.** Recommendations describe scoped changes only. Phrases like "rewrite", "replace entirely", or full-module replacement guidance are forbidden.
- **No padding.** Empty dimension sections are removed from the deliverable. Never insert "Nothing material" placeholders or filler content.
- **Independence from cpm2 artifacts.** `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` are read as passive context only. They must not bias or shortcut the independent sweep.
- **Tool failures never abort.** Missing/failing/timed-out stack tools are recorded as `Tool: <name> — <reason>` under "Open questions" and the audit continues.
