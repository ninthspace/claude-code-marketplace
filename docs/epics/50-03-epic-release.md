# Release cpm-next 0.12.0

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Pending  
**Blocked by**: Epic 50-01-epic-versioned-signals, Epic 50-02-epic-sweep-for-everyone

## Release with the docs
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR8, NFR1, NFR2

**Acceptance Criteria**:

- `cpm-next/README.md` gains a `(0.12.0)` bullet for each of epics 50-01 and 50-02, and its "How cpm-next learns" section describes the version on `process` signals, the fixed list and the issue draft for users outside the plugin's repository `[manual]`
- The root `README.md` CPM Next section and `cpm-next-training-guide.html`'s sweep passages say a sweep outside the plugin's repository offers an issue draft, shown in full and filed only on a yes `[manual]`
- `docs/maintenance/README.md` records that a release fixing a `process` failure adds a row to `cpm-next/shared/fixed.md`, and that the draft files to the `repository` field of cpm-next's `plugin.json` `[manual]`
- `cpm-next/.claude-plugin/plugin.json` and its marketplace entry read `0.12.0`, the marketplace `4.0.7`; no other plugin's version changes `[manual]`
- The added lines of `git diff -- cpm-next/skills cpm-next/shared` are read and none records history; `claude plugin validate cpm-next` passes and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next `[manual]`

### Write the docs and versions; run the checks
**Task**: 1.1  
**Description**: Edit the READMEs, the training guide, the maintenance record and the JSON files, and run the commands.  
**Status**: Pending

---
