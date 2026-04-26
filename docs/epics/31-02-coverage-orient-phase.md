# Coverage Matrix: Orient Phase

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Epic**: docs/epics/31-02-epic-orient-phase.md
**Date**: 2026-04-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 3 | Orient phase | Orient phase: README, package manifests, directory structure, `git log --oneline -200`, `git log --stat --since="6 months ago"`, top-20 largest, top-20 most-modified files. | Skill reads README during orient (when present) | Story 1 | `[manual]` | |
| 3 | Orient phase | (same) | Skill reads each detected package manifest (`package.json`, `composer.json`, `pyproject.toml`/`requirements.txt`/`setup.py`, `Cargo.toml`, `go.mod`) | Story 1 | `[manual]` | |
| 3 | Orient phase | (same) | Skill reads top-level directory structure | Story 1 | `[manual]` | |
| 3 | Orient phase | (same) | Skill captures git history via `git log --oneline -200` and `git log --stat --since="6 months ago"` | Story 1 | `[manual]` | |
| 3 | Orient phase | (same) | Skill identifies top-20 largest files and top-20 most-modified files in the past 6 months | Story 1 | `[manual]` | |
| 4 | Passive cpm2 artifact read | Orient phase reads `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` as **passive context only** — must not bias or shortcut the independent sweep. | Skill reads `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` if present, surfacing them as context to the user | Story 2 | `[manual]` | |
| 4 | Passive cpm2 artifact read | (same) | (must NOT) Skill must NOT use cpm2 artifact contents to skip dimensions, shortcut findings, or otherwise bias the independent sweep | Story 2 | `[manual]` | |
| 5 | Commit SHA capture | Capture `git rev-parse HEAD` during orient and record in deliverable header as `**Audited at**: <sha>`. | `git rev-parse HEAD` is captured during orient and recorded in deliverable header as `**Audited at**: <40-char-sha>` | Story 1 | `[unit]` | |
| 6 | Stack detection | Auto-detect TS/JS, PHP, Laravel (PHP overlay), Python, Rust, Go from manifests. | `package.json` present → TS/JS detected | Story 3 | `[manual]` | |
| 6 | Stack detection | (same) | `composer.json` present → PHP detected | Story 3 | `[manual]` | |
| 6 | Stack detection | (same) | `composer.json` + `artisan` present → Laravel detected (PHP overlay remains active) | Story 3 | `[manual]` | |
| 6 | Stack detection | (same) | `pyproject.toml` or `requirements.txt` or `setup.py` present → Python detected | Story 3 | `[manual]` | |
| 6 | Stack detection | (same) | `Cargo.toml` present → Rust detected | Story 3 | `[manual]` | |
| 6 | Stack detection | (same) | `go.mod` present → Go detected | Story 3 | `[manual]` | |
| 6 | Stack detection | (same) | Multi-stack projects detect every applicable stack | Story 3 | `[manual]` | |
| 9 | User-shaping question | After orient, present `AskUserQuestion`: "Specific areas to focus on, or sweep all 9 dimensions evenly?" | After orient completes, skill presents an `AskUserQuestion`: "Specific areas to focus on, or sweep all 9 dimensions evenly?" | Story 4 | `[manual]` | |
| 9 | User-shaping question | (same) | User input shapes the subsequent sweep (focus area noted as a hint) but does NOT cause any dimension to be skipped | Story 4 | `[manual]` | |
| 9 | User-shaping question | (same) | (must NOT) Skill must NOT use the user response as license to skip dimensions | Story 4 | `[manual]` | |
