# Coverage Matrix: Sweep & Tooling

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Epic**: docs/epics/31-03-epic-sweep-and-tooling.md
**Date**: 2026-04-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 7 | Stack-specific tooling | Run stack-specific tooling per detected stack (toolset listed in SKILL.md). | For TS/JS detected: at least one of `npm audit`, `npx knip`, `npx madge --circular`, `npx depcheck`, `tsc --noEmit` is invoked | Story 2 | `[manual]` | ✓ |
| 7 | Stack-specific tooling | (same) | For PHP detected: at least one of `composer audit`, `composer outdated`, `phpstan` or `psalm` is invoked | Story 2 | `[manual]` | ✓ |
| 7 | Stack-specific tooling | (same) | For Laravel detected: at least one of `larastan`, `pint`, `php artisan about` is invoked (in addition to PHP tooling) | Story 2 | `[manual]` | ✓ |
| 7 | Stack-specific tooling | (same) | For Python detected: at least one of `pip-audit`, `ruff check`, `vulture`, `pydeps --show-cycles`, `mypy --strict` is invoked | Story 2 | `[manual]` | ✓ |
| 7 | Stack-specific tooling | (same) | For Rust detected: at least one of `cargo audit`, `cargo udeps`, `cargo machete`, `cargo clippy -- -W clippy::pedantic` is invoked | Story 2 | `[manual]` | ✓ |
| 7 | Stack-specific tooling | (same) | For Go detected: at least one of `govulncheck`, `go vet`, `staticcheck`, `golangci-lint run` is invoked | Story 2 | `[manual]` | ✓ |
| 8 | Graceful tool degradation | Graceful tool degradation: missing/failing tools recorded as `Tool: <name> — <reason>` under "Open questions"; never abort. | When a tool is missing, fails, or times out, audit completes and "Open questions" section contains `Tool: <name> — <reason>` line | Story 2 | `[manual]` | ✓ |
| 8 | Graceful tool degradation | (same) | (must NOT) Skill must NOT abort on tool failure | Story 2 | `[manual]` | ✓ |
| 10 | 9-dimension sweep | 9-dimension sweep: architectural decay, consistency rot, type & contract debt, test debt, dependency & config debt, performance & resource hygiene, error handling & observability, security hygiene, documentation drift. | Skill defines and executes the 9 dimensions in documented order: architectural decay, consistency rot, type & contract debt, test debt, dependency & config debt, performance & resource hygiene, error handling & observability, security hygiene, documentation drift | Story 1 | `[manual]` | ✓ |
| 10 | 9-dimension sweep | (same) | Each dimension's procedure is documented in SKILL.md (scope, signals to look for, evidence to capture) | Story 1 | `[manual]` | ✓ |
| 21 | Re-orientation on failure | Re-orientation on failure: when a stack tool surfaces a finding that invalidates a recommendation drafted earlier in the same run, the recommendation is updated and the conflict noted in Open questions. | When a stack tool surfaces a finding that invalidates a recommendation drafted earlier in the same run, the recommendation is updated | Story 4 | `[manual]` | ✓ |
| 21 | Re-orientation on failure | (same) | The conflict between the late finding and the earlier recommendation is noted in the deliverable's "Open questions" section | Story 4 | `[manual]` | ✓ |
| 23 | Run-time progress signalling | Run-time progress signalling: emit `Sweeping dimension N/9: <name>...` at each transition. | During the 9-dimension sweep, skill emits a transition message at the start of each dimension in the form `Sweeping dimension N/9: <name>...` | Story 3 | `[manual]` | ✓ |
