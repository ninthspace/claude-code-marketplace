# Integrity entry 6 refuses the builds_on edges dpm's own skills write

**Number**: 01  
**Status**: pending  

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

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
|  | `check_integrity` on this project's own database returns `ok: true`, with entry 6 held and no row reported. |  |
|  | Every `builds_on` edge a shipped skill instructs is either admitted by entry 6 or no longer instructed: spec → problem_brief, spec → product_brief, spec → discussion, and library document → audit are each covered by a test that writes the edge and reads the register's verdict. |  |
|  | A pair the rule does not admit is still reported, named by edge id and by both end kinds — so the fix is a widened rule rather than a deleted check. |  |
|  | The register's prose at `dpm/src/integrity/register.js:24` says what entry 6 now admits and why, rather than describing the spec→spec-only rule it replaced. |  |
