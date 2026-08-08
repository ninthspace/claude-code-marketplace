# Discussion: dpm development readiness

**Date**: 2026-08-08  
**Agents**: Bella (Senior Developer)

## Discussion Highlights

### Key points so far

- Startup checks: no project roster (plugin default used); no `docs/library/` (Library Check skipped silently); stale-progress classifier returned no records.
- Planning corpus is settled: spec `docs/specifications/47-spec-dpm-sqlite-persistence.md`, nine epics `47-01`…`47-09`, 63 stories, 229 acceptance criteria, nine coverage matrices. Review 05 found 12 findings (3 critical); all fixed via pivot (commit `b6e086a`) plus later commits `34dc548`, `fc1c6eb`, `f20d0c4`.
- Epic `47-01-epic-substrate` is `Blocked by: —`, 9 stories, tasks written down to file level. It is the correct first pick.
- **Gap found**: nothing on disk. No `dpm/` directory exists. Grep across all nine epics and the spec finds no story or task creating `package.json`, a plugin manifest, a `.claude-plugin/marketplace.json` entry, or an MCP server registration. Epic 47-01 Story 1 Task 1 begins at DDL.
- **Gap found**: no test runner is named anywhere. CPM's suites are bash under `cpm/hooks/tests/`; dpm is Node. 229 tagged criteria assume a runner that no artefact chooses.
- **Verified locally**: `node --version` → v22.18.0 (above NFR2's `>=22.5.0` floor); `require('node:sqlite')` loads, emitting the ExperimentalWarning on stderr only — matching NFR3's stated verification.
- Open risk raised: `[target]` criteria (e.g. "a clean clone starts the server with no compilation step") are not self-assessable in an autonomous run, which matters if `/cpm:ralph` is the intended execution mode.

### Outcome

Bella's verdict: the planning is ready, the ground is not — the substrate epic models the *database* substrate and skips the *project* substrate. Chris chose to close the gap by adding a skeleton story to `47-01-epic-substrate` via `/cpm:pivot`, so the new story lands in the epic's coverage matrix rather than accreting inside Story 1.
