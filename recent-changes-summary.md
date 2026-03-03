# Claude Code Marketplace — Changes Summary

**Period:** February 18 – March 3, 2026 (14 days)
**Commits:** 19
**Files changed:** 57 (~3,270 lines added, ~154 removed)
**Version progression:** CPM v1.16.0 → v1.18.0

---

## New Skills

### cpm:consult (Feb 19)
Focused one-to-one agent consultation skill. Allows structured discussion with a single CPM agent for targeted advice without convening a full party session. Includes epic specs and discussion docs (Epics 15–16).

### cpm:quick (Feb 21)
Lightweight execution skill for small changes that don't need the full `cpm:do` workflow. Later hardened with spec tracking, test discovery, and battle-tested patterns from `cpm:do`. Also gained a diagnostic fix mode (Feb 25).

### cpm:status (Mar 1)
Project status reconnaissance skill that produces a narrative briefing of current project state.

---

## Major Enhancements

### Coverage Matrix Overhaul (Feb 25, 4 commits)
- `cpm:epics` gained acceptance criteria fidelity checks, a testability standard, and a per-epic procedural coverage matrix
- `cpm:do` now loads and verifies coverage matrix context
- Added proof tracking and invalidation system across CPM skills
- Versions: v1.17.0 → v1.17.4

### Progress File Orphan Detection (Feb 22–26, 3 commits)
- Session ID matching detects orphaned progress files left behind when `/clear` generates a new session ID
- Orphan cleanup made a blocking requirement that stops execution before proceeding
- Final fix in v1.18.0 addressed the root cause

### Party Mode & Pivot Improvements (Feb 22)
- Party mode gained direction-of-travel recommendations
- Pivot gained completion-awareness
- Exit phrasing made consistent between `cpm:consult` and `cpm:party`

### Epic Completion Flow (Feb 26)
- `cpm:do` now prompts for the next epic when the current one completes

---

## Documentation & Specs

| Category | Items added |
|----------|------------|
| Discussion docs | 7 new (`docs/discussions/04–10`) |
| Epic definitions | 7 new (`docs/epics/15–21`) plus coverage files |
| Specifications | 6 new (`docs/specifications/18–23`) |
| Quick-change specs | 3 new (`docs/quick/01–03`) |
| README / training | Updated to reflect new skills and versions |

---

## Commit Log

| Date | Summary |
|------|---------|
| Mar 1 | Add /cpm:status skill — project status reconnaissance with narrative briefing |
| Feb 26 | Make cpm:consult exit phrasing consistent with cpm:party |
| Feb 26 | Add next-epic prompt when current epic completes in cpm:do |
| Feb 26 | Fix orphaned progress files when /clear generates new session ID (v1.18.0) |
| Feb 25 | Add coverage matrix proof tracking and invalidation to CPM skills (v1.17.4) |
| Feb 25 | Add coverage matrix awareness to cpm:do context loading and verification |
| Feb 25 | Make cpm:epics coverage matrix procedural and per-epic (v1.17.2) |
| Feb 25 | Bump marketplace and CPM plugin version to 1.17.1 |
| Feb 25 | Add diagnostic fix mode to cpm:quick and fix party mode exit trigger conflict (v1.17.0) |
| Feb 25 | Add acceptance criteria fidelity, testability standard, and coverage matrix to cpm:epics (v1.17.0) |
| Feb 22 | Harden cpm:quick with spec tracking, test discovery, and cpm:do battle-tested patterns (v1.16.4) |
| Feb 22 | Make orphan cleanup a blocking requirement that stops before proceeding (v1.16.3) |
| Feb 22 | Add direction-of-travel recommendations to party mode and completion-awareness to pivot (v1.16.2) |
| Feb 22 | Add progress file orphan detection via session ID matching (Epic 18) |
| Feb 21 | Update marketplace README with CPM version bump to v1.16.0 |
| Feb 21 | Add cpm:quick skill for lightweight execution of small changes (Epic 17) |
| Feb 19 | Strengthen task description guidance in cpm:epics for story intent clarity |
| Feb 19 | Update marketplace README with cpm:consult skill and version bump |
| Feb 19 | Add cpm:consult skill for focused one-to-one agent consultation (Epics 15–16) |
| Feb 18 | Add party discussion on story intent clarity for CPM epics |
