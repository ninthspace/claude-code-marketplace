# Shared Convention Alignment

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Date**: 2026-05-28
**Status**: Complete
**Blocked by**: —

## Re-balance subagent delegation guidance for Opus 4.8
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R1 — Subagent delegation re-balanced for 4.8

**Acceptance Criteria**:

- The `Subagent Delegation` section in `shared/skill-conventions.md` states that Opus 4.8 spawns fewer subagents by default, so explicit fan-out guidance is load-bearing [manual]
- The "Delegate (fan-out) when" cases are framed as actively encouraged under 4.8 [manual]
- The "Work inline when…" guidance is retained — must NOT be removed (no regression to 4.6-style over-spawning) [manual]
- `review`'s fan-out instruction (3+ agents → spawn parallel subagents via the Agent tool) fires under 4.8 — verified imperative enough, tightened only if needed [manual]

### Update the Subagent Delegation section
**Task**: 1.1
**Description**: Add the 4.8 under-delegation note and reframe the "Delegate when" cases as encouraged; retain "Work inline when" guidance verbatim. Covers R1 criteria 1–3.
**Status**: Complete

### Verify/strengthen review fan-out instruction
**Task**: 1.2
**Description**: Confirm `skills/review/SKILL.md` fan-out (3+ agents) reads imperatively under 4.8; tighten wording only if needed. Covers R1 criterion 4.
**Status**: Complete

**Retro**: [Smooth delivery] The existing two-list (Delegate/Work inline) structure made the 4.8 re-balance a framing addition, not a restructure; review's fan-out was already imperative and needed only a one-clause tightening.

---

## Re-validate the Effort Recommendations table for Opus 4.8
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R3 — Effort Recommendations table re-validated for 4.8

**Acceptance Criteria**:

- Every medium-tier skill (`library`, `archive`, `retro`, `present`, `status`, `templates`) is assessed for 4.8 under-thinking risk; the rationale column reflects 4.8's strict effort adherence [manual]
- An advisory note is added: thinking is off by default on 4.8; set a large ~64k output budget at `xhigh`/`max` [manual]
- must NOT downgrade `do`/`epics`/`spec`/`architect`/`ralph` below `xhigh` [manual]

### Re-assess medium-tier skills and update rationale
**Task**: 2.1
**Description**: Review each medium-tier skill against 4.8 strict-adherence/under-thinking; adjust level only with rationale; keep reasoning-heavy skills at xhigh. Covers R3 criteria 1 and 3.
**Status**: Complete

### Add the 4.8 effort advisory note
**Task**: 2.2
**Description**: Add thinking-off-by-default + ~64k budget note to the Effort Recommendations section. Covers R3 criterion 2.
**Status**: Complete

**Retro**: [Smooth delivery] The assessment concluded all six medium-tier skills have bounded scopes where strict medium adherence is safe — a documented no-bump outcome, with the advisory note carrying the table-wide 4.8 framing to keep per-row rationales tight.

---

## Lessons

### Smooth Deliveries

- Story 1: The existing two-list (Delegate / Work inline) structure made the 4.8 re-balance a framing addition, not a restructure; `review`'s fan-out was already imperative and needed only a one-clause tightening.
- Story 2: The assessment concluded all six medium-tier skills have bounded scopes where strict medium adherence is safe — a documented no-bump outcome, with the advisory note carrying the table-wide 4.8 framing so per-row rationales stay tight.
