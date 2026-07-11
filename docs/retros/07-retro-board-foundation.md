# Retro: Board Foundation — Contract & Python Scaffolding

**Source**: docs/epics/39-01-epic-foundation-contract-scaffolding.md
**Date**: 2026-07-11

## Summary

Epic 39-01 delivered the foundation for the cross-project CPM board: the shared
`status-model.md` contract, a `uv`-runnable PEP 723 Textual scaffold, and a
pytest + Textual-Pilot + fixture-repo test harness. All 3 stories completed; the
coverage matrix is 4/4 verified. Two of three stories were smooth; one surfaced a
criteria gap that reshaped the contract and has a flagged downstream ripple.

## Observations

### Criteria gap

- **The contract's "recommended next command" was specified as a single value, but a  
  real repo routinely has several actionable next steps at once** (two specs awaiting  
  epics, two in-progress epics, a completed epic needing a retro alongside another  
  mid-flight). Caught by Chris during the Story 1 `[plan]` gate, before any code. The  
  contract was extended mid-story to derive an **ordered candidate list** (primary +  
  rest) rather than one command. **Downstream ripple flagged**: epics 39-04 (roll-up  
  says "recommended next action", singular) and 39-05 (launches "the recommended  
  command") will need a criteria pivot to let the user *choose among* candidates —  
  surface this at those epics, do not let it slip silently.

### Smooth delivery

- **PEP 723 single-file script + a separate dev `pyproject.toml`** cleanly separated  
  the distributable ("clone and run" via `uv run board.py`) from the test harness  
  (`uv run pytest` with dev-group deps). Worked first try; a good pattern to reuse for  
  other single-file uv tools in this repo.
- **The `make_project` factory fixture** (temp git repo + arbitrary `docs/` tree +  
  commit) gives derivation tests in 39-02 a deterministic substrate; landed with 4  
  unit tests (docs-tree write, resolvable HEAD, commit-skip, per-call isolation).

## Recommendations

- **Pivot 39-04 and 39-05 criteria for the multi-action model** when those epics are  
  picked up — the roll-up should show a primary action with a candidate count, and the  
  launcher should offer a picker when >1 candidate exists. Consider `/cpm:pivot` on  
  those epic docs at that point.
- **Reuse the PEP 723 + dev-pyproject split** as the default shape for future Python  
  tooling in this marketplace repo.
