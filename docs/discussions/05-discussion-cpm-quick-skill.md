# Discussion: Adding a /cpm:quick skill for quick wins and small change requests

**Date**: 2026-02-21
**Agents**: Jordan, Margot, Bella, Priya, Ren

## Discussion Highlights

### Key points so far
- Jordan identifies a real gap: the CPM pipeline is designed for structured multi-phase work and is overkill for small changes.
- Group converged on a dedicated `/cpm:quick` skill as a separate entry point.
- Bella's flow: describe → confirm scope → do work → write completion record. One invocation, one artifact.

### Decisions / convergence
1. **Separate skill**: `/cpm:quick` as a standalone skill. Unanimous.
2. **Single artifact output**: A "quick win record" with schema — title, context/why, acceptance criteria, changes made, verification. Lives in `docs/quick/`.
3. **Scope gate with soft nudge**: Skill evaluates whether request is genuinely a quick win. If bigger, suggests full pipeline handoff — but user can override.
4. **Flow**: Describe change → skill proposes scope & acceptance criteria → user confirms → skill executes → writes completion record.
5. **Traceability**: Completion record is the artifact, discoverable by `/cpm:retro` and project history.
6. **No reverse gate in v1**: If a user starts `/cpm:spec` for something small, honour their choice. The cost of over-planning is low; the cost of under-planning is high. The upward escalation (quick → full pipeline) is high value; the downward suggestion (spec → quick) is low value and risks feeling patronising.
7. **Offer once, honour the decision**: If reverse awareness is ever added, it should be a single gentle observation, never blocking or repeated. But not for v1 — wait for user demand.
