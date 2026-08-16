# Discussion: A cross-project CPM status dashboard / launcher

**Date**: 2026-07-11
**Agents**: Jordan (PM), Margot (Architect), Bella (Dev), Priya (UX), Tomas (QA), Sable (DevOps), Ren (SM)

## Discussion Highlights

### Key points so far

- `/cpm:status` already exists and solves the *single-project* recon (scans docs/, reads epic `**Status**:` + story counts, checks git, narrative + next steps, optional HTML). The new need is **cross-project** aggregation.
- Requirement added by Chris: dashboard must be **always up to date** (no manual refresh, no asking) and let him **choose what's next and auto-start it** (it's a launcher, not just a report).
- Freshness mechanism (Sable): per-project status is a **cache with cheap invalidation** — compare `git rev-parse HEAD` + max mtime under `docs/` against the cached stamp; re-derive only changed projects. No daemon, no per-repo hooks, pull-based and self-healing.
- Solo (soloterm.com) is a **desktop agent workspace** (macOS/Win, Tauri) hosting Claude Code etc. as panes. **Correction from Chris: Solo's MCP is for its own agents to report into — it does NOT consume external MCP servers except via agents.** So Solo can't render a `cpm://status` resource directly.
- Reconciliation: build a **standalone CLI/TUI** that Solo simply **hosts as a pane** (like a dev server). Zero dependency on Solo internals; also works in tmux/iTerm/anywhere.
- Launch model: **copy-to-clipboard** the recommended `cd /path && claude "/cpm:do docs/epics/NN-epic.md"`; paste into a new pane. Preferred over exec-handover (works on mobile/Solo, no PTY multiplexing).
- Packaging: this repo is a **plugin marketplace** with a strict **clone-and-run, zero-build** ethos (markdown skills + shell + `.mjs`; no compiled binaries). That rules out Rust/Go and points at a **Node CLI/TUI**. The planning docs belong in this repo's `docs/` next to cpm's own meta-development.

### Decisions locked by Chris

1. **Standalone, terminal-invoked** tool (Solo or otherwise). Not a Solo integration.
2. **Project discovery is opt-in** — an explicit registry, not auto-scan.
3. **Do NOT reuse `/cpm:status`** — the tool derives status itself (no Claude dependency).
4. **Build it in this repo.** Planning artifacts (spec/epics) live in this `docs/` tree; the tool is a **Node CLI/TUI** (zero-build, matching repo ethos), most likely **bundled inside the `cpm` plugin** to start (promotable to its own plugin later).

### Guardrails to carry into spec

- **Shared status contract** (Margot): don't share code, share the *definition* — RAG rule, `**Status**:`/story-count → state mapping, "recommended next command" — so the binary and `/cpm:status` don't drift.
- **Graceful degradation** (Tomas): stale/missing registry paths → "unreachable" row; malformed/half-written epic front-matter → visible `?` state. Never abort the whole sweep on one bad file.

### Open question for the spec

- **Personal tool vs shipped plugin** — sets how much polish/versioning/README the tool needs, and whether it stays bundled in `cpm` or becomes its own marketplace entry. Chris deferred this into the spec as an open question.

### The team's recommendation

Build a **standalone, terminal-invoked Node CLI/TUI** with an **opt-in project registry** that **derives CPM status independently** (git HEAD + `docs/` mtime for freshness, no Claude dependency), renders a **cross-project roll-up**, and acts as a **launcher via copy-to-clipboard** of each project's recommended next command. Pin it in a Solo pane or run it anywhere. Carry forward a **shared status contract** (so it never drifts from `/cpm:status`) and **graceful degradation** (unreachable paths and unparseable files render as states, never crashes).
