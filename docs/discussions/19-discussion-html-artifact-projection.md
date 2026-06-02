# Discussion: Adopting the "Unreasonable Effectiveness of HTML" philosophy for CPM2 artifacts

**Date**: 2026-06-02
**Agents**: Jordan (PM), Margot (Architect), Bella (Senior Developer), Priya (UX Designer), Sable (DevOps Engineer), Elli (Technical Writer), Ren (Scrum Master)

**Source reviewed**: https://claude.com/blog/using-claude-code-the-unreasonable-effectiveness-of-html — Anthropic's argument that Claude Code work benefits from rich, interactive, shareable HTML artifacts (side-by-side spec explorations, rendered code-review diffs, interactive editors with "copy as prompt" export) over Markdown.

**Question assessed**: Should CPM2 adopt this philosophy — each skill *producing* and/or *consuming* HTML artifacts — to improve communication, tracking, and achievement of goals?

## Discussion Highlights

### Key points so far

- **Substrate decision (strong consensus):** Markdown stays the source of truth for all CPM2 artifacts — grep-able, diffable, git-friendly, machine-parseable by downstream skills. HTML is only ever a *projection generated from* Markdown, never a replacement substrate. (Margot, Bella, Elli)
- **"Consume HTML" = rejected.** Making any skill consume HTML imposes a parsing burden on every downstream skill and breaks `git diff`. The article's value is on the *produce/present* axis only — matching Chris's "present or consume" wording, only "present" survives. (Margot)
- **"Benefits from HTML" test:** an artifact benefits only when the reader must *navigate/move around* it (comparisons, diffs, large structured docs, dashboards) — not when it's prose read top-to-bottom. (Priya, Elli)
- **Tier 1 (clear win, low cost — static renders):** `architect` ADRs (side-by-side option/trade-off comparison — the article's sweet spot), `review` findings (severity-coded, sortable/filterable, file-anchored), and large `spec` docs (contents sidebar for navigation). (Priya)
- **Tier 2 (high value for *tracking*, higher cost — interactive):** `status` as a dashboard (progress bars, completion grid, blocked panel, RAG) and `epics` as a dependency graph / unblocked-task view. Strongest case for Chris's "tracking" goal. (Sable)
- **Skip:** prose artifacts — `brief`, `discover`, `retro`, `quick` (nothing to navigate). (Priya)
- **Cost split:** static one-shot renders are cheap/throwaway/safe; interactive dashboards are "little apps" with JS state + copy-as-prompt export that rot when the Markdown schema shifts and need an owner. (Bella)
- **Mapping to Chris's goals:** Communication → Tier 1 (spec/architect/review). Tracking → Tier 2 (status/epics). Achievement → review findings + plans.

### Decision: two specs

- **Spec 1 — "HTML projection of structured artifacts" (Tier 1):** static navigable HTML renders of `spec`, `architect` (ADRs), `review`, generated from Markdown source. Likely an output mode of the existing `cpm2:present` skill. Establishes load-bearing contracts: Markdown-stays-source-of-truth invariant, generate-from-source-never-replace rule, shared HTML template/styling foundation. Ship now; near-zero risk.
- **Spec 2 — "Interactive tracking dashboards" (Tier 2):** interactive `status` and `epics` views (progress grids, dependency graphs, copy-as-prompt export). Explicitly *depends on and reuses* Spec 1's foundation (avoid divergent scaffolding). Framed as a value-to-validate bet — spec the hypothesis, don't pre-commit `do` cycles until the tracking value is proven.
- Rationale for splitting: different definitions of done, risk, and readiness; bundling would force the fast/safe work to wait on the slow/uncertain work. (Ren, Margot, Jordan)

### Active thread
Chris asked whether we can spec both tiers, possibly as two specs. Team landed on: yes, two specs, Spec 1 as substrate/foundation, Spec 2 depending on it and deferred-but-specifiable. Ready for pipeline handoff to cpm2:spec — write Spec 1 first.

### Agents who participated
Round 1: Jordan, Margot, Elli. Round 2: Priya, Sable, Bella. Round 3: Ren, Margot, Jordan.
