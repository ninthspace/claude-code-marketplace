# Integrity entry 6 refuses the builds_on edges dpm's own skills write

**Number**: 01  
**Status**: complete — Delivered as resolution 2 — the pairs are rows in dependency_kind_endpoint, read by register entry 6 and enforced at create_dependency. Needs a plugin build carrying schema 24 before dpm can write to this project again.  

**Closed**: 2026-08-16T21:10:00Z  

## What is wrong

`check_integrity` on this project's own database returns `ok: false` on entry 6 — *"A dependency's ends are kinds that edge admits"* — naming edge `01M05J88V2WYQPDEFCZJM1G89J`, a `builds_on` from spec 2 to discussion 1.

The edge is not a mistake. It is the lineage `/dpm:spec` Section 1 instructs, one document kind over: *"If the input was a brief, record the lineage with `create_dependency`: `kind: 'builds_on'`, this spec as `source_document_id`, the brief as `target_document_id`."* Spec 2 was built from a discussion rather than a brief, so the edge names a discussion; a spec built from a brief would name a brief, and entry 6 would report that one too.

Entry 6 admits `builds_on` **spec → spec only** (`dpm/src/integrity/register.js:193`). So three shipped writers disagree with the register:

- `dpm/skills/spec/SKILL.md:111` — spec → problem_brief / product_brief
- `dpm/skills/audit/SKILL.md:215` — library document → audit
- this project's own corpus — spec → discussion

`create_dependency` writes all of them without complaint: the only thing it refuses at the write is a cycle over an edge kind that gates work, and `builds_on` does not gate. So the disagreement surfaces at `check_integrity`, at an arbitrary distance from the call that caused it, in a check the skills cannot see.

**This predates the board-parity work entirely.** The edge was written when spec 2 was created on 2026-08-16; nothing in spec 1 or spec 2 touches it.

## Why it is not simply a widened WHERE clause

The register states its own reasoning at `dpm/src/integrity/register.js:24-29`, and it argues against the quick fix:

> **#6 checks only the two edge kinds the register names.** `builds_on` spec→spec and `constrains` ADR→ADR are the rules stated; the rest of the matrix is deliberately unknown, because `blocks` alone spans epic→epic and story→story and inventing the remainder before dpm's own pipeline exists would fix guesses in a check. A kind with no declared rule is passed over rather than guessed at, and that is why this is a register entry and not the `dependency_kind_endpoint` table it will one day become.

Two things follow. First, the narrowness was deliberate and the resolution is a decision rather than a typo fix. Second, the argument has been overtaken: dpm's pipeline now exists, has run four epics, and has written the edges the rule did not anticipate — so the evidence the comment says it was waiting for is in the corpus.

Three resolutions, and this record does not pick one:

1. **Widen entry 6's rule** to the pairs the skills write. Cheapest, and it puts a second copy of the endpoint matrix in a SQL string that nothing keeps in step with the skills.
2. **Promote it to the `dependency_kind_endpoint` table** the comment names, seeded per kind, checked at the write rather than at the audit. Refuses a wrong edge where it is made, and makes the vocabulary a project's to extend — the shape the rest of dpm already uses for taxonomies and approaches.
3. **Narrow the skills** so `builds_on` stays spec→spec and lineage to a brief, a discussion or an audit is carried some other way. This is the one that needs arguing for rather than against: it says the edges are wrong, not the rule, and something has to then hold the lineage.

Whichever is chosen, the parity test at `dpm/tests/integrity.test.js` and the register's prose both move with it, and `dpm/tests/skill-audit.test.js:179` already writes a library→audit edge that the current rule would refuse.

## What changed

Resolution 2 of the three: the pairs are rows, and both the write and the audit read them.

- **`src/schema/024-dependency-endpoint.sql`** — `dependency_kind_endpoint (kind, source_kind, target_kind)`, composite TEXT primary key, foreign keys to `dependency_kind` and to `document_kind` at both ends. The shape is `document_kind_parent`'s, which is the same idea for parentage.
- **`src/schema/seeds/dependency-endpoints.js`**, registered in `VOCABULARIES` — seven rows, each naming the skill and step that writes it: `builds_on` spec→spec, spec→problem_brief, spec→product_brief, spec→discussion and library→audit; `constrains` and `supersedes` adr→adr.
- **`blocks` gets no rows and is therefore unconstrained.** Its ends may be stories, a story is not a document kind, and no pair over this table can say what it admits. Reading the absence as "admits nothing" would refuse every blocking edge in every project.
- **Register entry 6 declares nothing itself** — it reports an edge whose kind has rows and whose own pair is not among them. An edge with a story at either end is passed over, which is what its `document` join at both ends has always done.
- **`create_dependency` refuses the same edge at the write**, by finding the new row's id in entry 6's own report — the pattern the file already uses for entry 1's cycles, and for the reason it states there: two `WHERE` clauses would be two answers, and a disagreement produces a database the integrity tool calls broken and the link tool will not let anyone repair.

The retirement guards needed no work: they are derived from `PRAGMA foreign_key_list`, so the new table's reference into `dependency_kind` acquired its pair the moment the migration ran.

Five sweeps had to be told about the table, which is the cost retro 2 recorded and this change paid exactly: `parity.test.js`'s `NO_CREATE_TOOL`, `parity-integration.test.js`'s `UNPROJECTED` and the writable-set assertion beside it, and `prose-columns.js`'s classification. A sixth was a genuine correction rather than a registration — `create_dependency` first declared the table in `reads`, which is what NFR7's closure treats as *written*, and it demanded a read tool for a vocabulary no caller may add to.

## How it was verified, and what the migration costs the reader

**818 tests, 817 passing before this project's own database was brought up, 818 after.** Six of them are new, in `tests/dependency-endpoints.test.js`.

Two mutations, run and reverted, because a suite that goes green is not the same as a check that discriminates:

- **Restoring the old hardcoded rule** fails the admission test with `'builds_on' does not admit spec → problem_brief` — the defect this change exists to remove, named in the failure.
- **Removing the refusal at the write** (`false &&` before the check) fails the refusal test and its control, and fails neither of the register-side tests, which is the right shape: they are two rules and the tests tell them apart.

**Three tests went red for a reason worth recording, and it is not this change's fault.** `previousVersion()` means "the version before the newest", so a test written when `023-plugin-stamp.sql` was newest silently became a test about a database that already has the stamp table. The helper's own comment predicted a number going stale; what actually went stale was the derivation. Fixed with `versionBefore('plugin-stamp')`, which names the migration the test is about, and by deriving the tables an upgrade is allowed to add from the DDL that ran rather than from a list in the test.

A fourth needed `vocabularyAsOf`: a fixture at an older schema version was being seeded with *this* release's whole vocabulary, which fails on the first table a later migration adds. What a release seeded is bounded by what that release's schema held.

**What the reader has to do about it.** This migration takes the schema to 24, and dpm 0.5.0 targets 23. Once this project's own `.dpm/dpm.db` is migrated, the installed 0.5.0 server sees a database ahead of it and serves this project read-only — which is spec 1's protection working exactly as designed, and it means DPM writes here need a build carrying this migration. The version bump and the reinstall are what restore them.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | `check_integrity` on this project's own database returns `ok: true`, with entry 6 held and no row reported. | Verified against a copy of this project's own `.dpm/dpm.db`, migrated to schema 24 by the new code: all thirteen register entries hold, and entry 6 returns no rows where it previously named edge 01M05J88V2WYQPDEFCZJM1G89J. The MCP server running in the session that made this change is the installed 0.5.0, whose schema target is 23, so its own `check_integrity` answers for a database it has not migrated — hence the copy, which is the same rows against the code under test. |
| ✓ | Every `builds_on` edge a shipped skill instructs is either admitted by entry 6 or no longer instructed: spec → problem_brief, spec → product_brief, spec → discussion, and library document → audit are each covered by a test that writes the edge and reads the register's verdict. | `tests/dependency-endpoints.test.js`, first test: every pair a shipped skill instructs is written through `create_dependency` and then read back through register entry 6 — spec→spec, spec→problem_brief, spec→product_brief, spec→discussion and library→audit for `builds_on`, adr→adr for `constrains` and for `supersedes`. Each row in the table names the skill and step that writes it. Driven by mutation: restoring the old hardcoded rule fails that test with "'builds_on' does not admit spec → problem_brief". |
| ✓ | A pair the rule does not admit is still reported, named by edge id and by both end kinds — so the fix is a widened rule rather than a deleted check. | Two tests, because the rule is now enforced in two places: an epic→spec `builds_on` is refused at the write with both the pair and the admitted set in the message and no row left in the table, and an edge written past the tool is reported by entry 6 with its id and both end kinds. The control deletes `builds_on`'s endpoint rows and shows the same call accepted, so the refusal is the data rather than the code. |
| ✓ | The register's prose at `dpm/src/integrity/register.js:24` says what entry 6 now admits and why, rather than describing the spec→spec-only rule it replaced. | `src/integrity/register.js:24` now says the entry reads `dependency_kind_endpoint` and declares nothing itself, why a kind with no rows is unconstrained rather than admitting nothing, that a story-ended edge is passed over, and that `create_dependency` enforces the same rule from the same source. The paragraph it replaced described the spec→spec rule and its deferral. |
