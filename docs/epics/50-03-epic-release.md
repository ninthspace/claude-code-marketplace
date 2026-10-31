# Release cpm-next 0.12.0

**Source spec**: docs/specifications/50-spec-sweep-for-an-open-source-plugin.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: Epic 50-01-epic-versioned-signals, Epic 50-02-epic-sweep-for-everyone

## Release with the docs
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 4 findings fixed  
**Blocked by**: —  
**Satisfies**: FR8, NFR1, NFR2  
**Signal**: fix-not-carried-through — project — the training guide's signal-form passage was amended at one line (`:644`) and its explanation at the next (`:646`) left unchanged, and the root README and guide's sweep passages omitted the fixed list (`cpm-next-training-guide.html`, `README.md`, audit round 1) — recurs: docs/epics/49-06-epic-release.md (a release left a doc describing the old behaviour, as here) — promoted 2026-10-31  
**Amended**: two criteria now cover the signal-form passages the audit of 50-01 Story 1 found would otherwise miss the version segment (2026-10-31) — cited: `cpm-next-training-guide.html:644,646` and `docs/maintenance/README.md:67`

**Acceptance Criteria**:

- `cpm-next/README.md` gains a `(0.12.0)` bullet for each of epics 50-01 and 50-02, and its "How cpm-next learns" section describes the version on `process` signals, the fixed list and the issue draft for users outside the plugin's repository `[manual]`
  - Evidence: `cpm-next/README.md` has three `(0.12.0)` bullets (**Signals carry the version**, **The fixed list**, **Sweep outside the plugin's repository**), an **Upgrading to 0.12.0** section, and its "Across repositories" paragraph describes the version on `process` signals, the fixed list and the issue draft for users outside the plugin's repository — red: n/a — manual
- The root `README.md` CPM Next section and `cpm-next-training-guide.html`'s sweep passages say a sweep outside the plugin's repository offers an issue draft, shown in full and filed only on a yes `[manual]`
  - Evidence: root `README.md` CPM Next section has a **Sweep.** paragraph (discussion record in the plugin's repository, issue draft elsewhere, shown in full, filed only on a yes); `cpm-next-training-guide.html` changes the **Sweep** list item, the first-steps item and the commands table row, each naming the issue draft and the yes; the root README paragraph and the guide's **Sweep** item also say a `process` signal carries its version and that a release fixing a failure adds a row to `shared/fixed.md`; the three HTML files' version lines read 0.12.0 — red: n/a — manual
- `docs/maintenance/README.md` records that a release fixing a `process` failure adds a row to `cpm-next/shared/fixed.md`, that the draft files to the `repository` field of cpm-next's `plugin.json`, and, in its "Contract strings a mod may later parse" record, the ` — cpm-next {version}` segment of a `process` signal `[manual]`
  - Evidence: `docs/maintenance/README.md` has a new record, **The fixed list and the issue draft** (a release fixing a `process` failure adds a row to `cpm-next/shared/fixed.md`; the draft files to the `repository` field of cpm-next's `plugin.json`), and its **Contract strings a mod may later parse** record now lists ` — cpm-next {version}` on a `process` signal — red: n/a — manual
- `cpm-next-training-guide.html`'s passage quoting the signal form shows the ` — cpm-next {version}` segment on a `process` signal, and says a `project` signal has none `[manual]`
  - Evidence: `cpm-next-training-guide.html` signal-form `<pre>` now ends `({file and step, rule or check involved}){ — cpm-next {version}}{ — recurs: …`, the `#art-signals` bullet at `:646` says a `process` signal also carries ` — cpm-next {version}` and a `project` signal carries none, and the learning passage says a `process` signal ends with ` — cpm-next {version}` read from the installed plugin's `plugin.json` and a `project` signal carries none — red: n/a — manual
- `cpm-next/.claude-plugin/plugin.json` and its marketplace entry read `0.12.0`, the marketplace `4.0.7`; no other plugin's version changes `[manual]`
  - Evidence: `git diff -- .claude-plugin cpm-next/.claude-plugin` shows `cpm-next/.claude-plugin/plugin.json` 0.11.0 → 0.12.0, the cpm-next marketplace entry 0.11.0 → 0.12.0 and the marketplace 4.0.6 → 4.0.7, with no other version line changed — red: n/a — manual
- The added lines of `git diff -- cpm-next/skills cpm-next/shared` are read and none records history; `claude plugin validate cpm-next` passes and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next `[manual]`
  - Evidence: the added lines of `git diff -U0 -- cpm-next/skills cpm-next/shared` were read (the contract's table row, signal form and examples, `do` **Signals**, and **Sweep**'s paragraphs) and the untracked `cpm-next/shared/fixed.md` (a rule and a table, no history) and none records history; `claude plugin validate cpm-next` and `claude plugin validate .` — Validation passed; `claude plugin test`: cpm-next 15, cpm-next-models 18, cpm-next-progress 54, whats-next 32 passed, 0 failed — red: n/a — manual

### Write the docs and versions; run the checks
**Task**: 1.1  
**Description**: Edit the READMEs, the training guide, the maintenance record and the JSON files, and run the commands.  
**Status**: Complete

---
