# Sweep & Tooling

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Pending
**Blocked by**: Epic 31-02-epic-orient-phase

## 9-dimension sweep procedure
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: #10 (9-dimension sweep)

**Acceptance Criteria**:

- Skill defines and executes the 9 dimensions in documented order: architectural decay, consistency rot, type & contract debt, test debt, dependency & config debt, performance & resource hygiene, error handling & observability, security hygiene, documentation drift `[manual]`
- Each dimension's procedure is documented in SKILL.md (scope, signals to look for, evidence to capture) `[manual]`

### Document 9-dimension sweep procedure
**Task**: 1.1
**Description**: Document in SKILL.md the sequential 9-dimension sweep with the exact dimension order, then for each dimension specify scope, signals to look for, and evidence to capture. Adapt material from the source skill (ksimback/tech-debt-skill) verbatim where appropriate. Covers both criteria.
**Status**: Pending

---

## Stack-specific tool execution + graceful degradation
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: #7 (stack-specific tooling), #8 (graceful tool degradation)

**Acceptance Criteria**:

- For TS/JS detected: at least one of `npm audit`, `npx knip`, `npx madge --circular`, `npx depcheck`, `tsc --noEmit` is invoked `[manual]`
- For PHP detected: at least one of `composer audit`, `composer outdated`, `phpstan` or `psalm` is invoked `[manual]`
- For Laravel detected: at least one of `larastan`, `pint`, `php artisan about` is invoked (in addition to PHP tooling) `[manual]`
- For Python detected: at least one of `pip-audit`, `ruff check`, `vulture`, `pydeps --show-cycles`, `mypy --strict` is invoked `[manual]`
- For Rust detected: at least one of `cargo audit`, `cargo udeps`, `cargo machete`, `cargo clippy -- -W clippy::pedantic` is invoked `[manual]`
- For Go detected: at least one of `govulncheck`, `go vet`, `staticcheck`, `golangci-lint run` is invoked `[manual]`
- When a tool is missing, fails, or times out, audit completes and "Open questions" section contains `Tool: <name> — <reason>` line `[manual]`
- (must NOT) Skill must NOT abort on tool failure `[manual]`

### Document stack-tool invocation table
**Task**: 2.1
**Description**: Document the per-stack tool list in SKILL.md (TS/JS, PHP, Laravel, Python, Rust, Go) and how each tool's output feeds the relevant audit dimensions. Covers the per-stack invocation criteria.
**Status**: Pending

### Document graceful tool degradation rule
**Task**: 2.2
**Description**: Document the rule that any tool failure (missing binary, non-zero exit, timeout, unparseable output) is recorded as `Tool: <name> — <reason>` in the deliverable's "Open questions" section and the audit continues without aborting. Include the must-NOT clause prominently as a non-negotiable. Covers the degradation criteria.
**Status**: Pending

---

## Run-time progress signalling
**Story**: 3
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: #23 (run-time progress signalling — should-have)

**Acceptance Criteria**:

- During the 9-dimension sweep, skill emits a transition message at the start of each dimension in the form `Sweeping dimension N/9: <name>...` `[manual]`

### Document run-time progress signal format
**Task**: 3.1
**Description**: Document the per-dimension transition message format `Sweeping dimension N/9: <name>...` in SKILL.md as part of the sweep orchestration section. Covers the sole criterion.
**Status**: Pending

---

## Re-orientation on failure
**Story**: 4
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: #21 (re-orientation on failure)

**Acceptance Criteria**:

- When a stack tool surfaces a finding that invalidates a recommendation drafted earlier in the same run, the recommendation is updated `[manual]`
- The conflict between the late finding and the earlier recommendation is noted in the deliverable's "Open questions" section `[manual]`

### Document re-orientation on failure protocol
**Task**: 4.1
**Description**: Document in SKILL.md the protocol for handling late-breaking findings that invalidate earlier recommendations: detect the conflict, update the recommendation, note the conflict in "Open questions". Cite a representative example (e.g. `composer audit` flagging a CVE in a dep that was about to be recommended). Covers both criteria.
**Status**: Pending

---
