# Discussion: Carrying autonomy through from spec level

**Date**: 2026-07-26
**Agents**: Margot (Software Architect), Bella (Senior Developer), Tomas (QA Engineer), Jordan (Product Manager), Priya (UX Designer), Elli (Technical Writer), Sable (DevOps Engineer), Ren (Scrum Master)

## Topic

Now that spec 43 has fixed `cpm:ralph`'s continuity problems, extend autonomy upstream: Chris produces a spec, and `cpm:ralph` (or something new) generates the epics and implements all of them without further input.

## Key points

### The gap is `cpm:epics`, not `cpm:ralph`

`cpm:ralph` Step 1a **discovers epics as pre-flight validation** — it presupposes them. Between a spec and that starting line sits `/cpm:epics`, which carries seven `AskUserQuestion` calls and four present-and-refine gates. `cpm:do`'s overrides work because every gate they silence has a defensible default; "how should this spec be cut into epics?" does not.

The seven gates are not equal. Four are **approve / refine / stop** gates with a proposal already rendered — epic grouping (`:81`), stories (`:178`), tasks (`:214`), final confirmation (`:282`) — where "approve your own proposal" is trivially available as an autonomous default. Line 155 is different: must-NOT clauses on security and data-integrity criteria, where auto-accepting your own defensive boundary is the self-marking problem 43-02 solved with the citable-contradiction rule.

### Reuse ralph's machinery rather than build a new skill

Nothing about the stop hook, state file, resume detection or `[plan]`-strip is specific to `cpm:do`. The shape is **one loop, two phases**: iteration 1 runs `/cpm:epics` on the spec, iterations 2..n run `/cpm:do` over what it produced. `{epic_range}` resolves at iteration time rather than at launch.

Ren's decomposition: (1) pre-flight tolerates zero epics and resolves a spec instead — small; (2) an autonomous branch for `cpm:epics` mirroring 43-02's — the real epic; (3) a conditional prompt across phases — small.

### The blocking discovery: spec coverage has no home and no tests

Coverage lives **per-epic and nowhere else**. `epics` Step 3d writes one matrix per epic; `do` fills the ✓ marks. **No artefact spans a spec's epics** — nothing answers "did FR7 land in *any* of the three matrices?" Spec 43 required opening four files and diffing by eye.

Worse: grepping the suites for "coverage" returns four files, two of them written this week for spec 43's own behaviour and two using the word in a comment. **No test asserts anything about coverage matrices** — not the `-epic-` → `-coverage-` filename rule, not the verification rule that a criterion change resets a row, not that ✓ counts match. The traceability spine is convention held up by prose and human reading.

This reframes the stop condition: the loop cannot end on "the spec's coverage is satisfied" because there is no place that answer is written down.

### The spec-level coverage roll-up

Jordan's sequencing argument: the roll-up is worth building **even if autonomous epics never happens** — today you cannot answer "is spec 43 fully delivered?" without opening four files. It is the smaller piece, and the only part of the traceability spine that is genuinely testable (filename derivation, row unioning, unmapped-requirement detection are all real assertions). Building it second means the first thing an unattended `epics` run produces is an artefact set nobody can verify.

**Stakeholder framing (Chris's addition).** The loop's predicate and the stakeholder's page are not the same document. The loop needs yes/no. A stakeholder needs to know which of the things they asked for now exist, **in the words they used** — and coverage matrices already preserve exactly that in their `Spec Text (verbatim)` column, the only place original wording survives all the way to a ✓.

Priya's design constraints:

- Organise by the **spec's MoSCoW structure**, not the epic structure. The stakeholder never asked for epic 43-02.
- Design for **partial**, the common mid-flight case. "FR7 is covered by two rows, one ✓ and one not" rendered as a bare percentage is actively misleading. Three honest states: *delivered*, *in progress*, and **not traced to any story at all**.
- The third state is the product. A requirement that fell through the breakdown is a *finding*, not reporting — bright, top, unavoidable. It is also exactly the failure mode autonomous `epics` would introduce at scale, detected regardless of whether a human or a loop did the breakdown.

Publishing reuses the existing shared **Artifact Publishing** procedure — eleven skills already carry it, `epics` among them. No second path.

### Machine-readable output: script, not model-emitted JSON

Chris asked whether a machine-readable `cpm:status` changes the design. It does — but only if machine-readable means **a script**.

A `--json` flag on a skill is a model reconstructing an inventory each run. The evidence is direct: `clean` enumerated files itself and reported an empty inventory on every run for months. The fix was `progress-classify.sh` plus a skill that "**never globs or `stat`s files itself**" — the precedent is live and five scripts deep in `cpm/hooks/lib/`.

This dissolves the new-skill-vs-`cpm:status` question, which was the wrong axis. The structure is **one producer, several consumers**: the script owns the computation; `status` renders a project-wide slice, the stakeholder artifact a spec-scoped one, and ralph reads a predicate off the same records. Same property 43-01 bought by making both guards share a resolver.

**Sable's operational additions:**

- A script gives **observability during the run** — call it between iterations and watch traced-requirement counts move. This surfaces a failure mode nobody had named: a loop that is neither stalled nor finished but **not converging**, burning iterations while the numbers stay flat. Ralph defaults to fifty of those, and no number currently exists that would reveal it.
- **Fail closed.** 43-01's helpers deliberately fail open and never block. A completion predicate must fail the other way: if the roll-up cannot compute, the answer is *not complete*, never *complete by default*.

### The completion condition

`completion_promise` is **matched against `<promise>` tags in assistant output** (`ralph:223`). The stop hook belongs to the ralph-wiggum plugin — the loop can never *call* the roll-up. What it can do is instruct the model to run the script and emit the tag **only on a passing exit code**. Model discretion drops from *making the judgement* to *relaying a verdict*. Not zero — a model could emit the tag having skipped the check — which argues for the promise text naming its evidence, so a wrong emission is visible in the log rather than indistinguishable from a right one.

**One promise, not two** (Tomas). If epic mode keeps `ALL_EPICS_COMPLETE` and spec mode gets a new tag, the old path is the weaker of the two and everyone will keep using it, because empty arguments is the convenient invocation. Use one script-backed tag with only the **scope** differing: epic mode asks "are these epics' matrices fully verified"; spec mode asks that plus "are all the spec's must-haves traced". Epic runs get strictly better as a side effect.

**Backward compatibility** (Bella). Input already parses epic paths, a range, or nothing. Add *a spec path* as a fourth shape and mode detection is free — no flag, no new skill. Empty arguments must keep meaning "auto-discover all incomplete epics"; silently promoting that to spec-hunting breaks a working invocation.

**Sequencing wrinkle.** Spec mode has two completion conditions, not one. Iteration 1 must produce epics before anything can be implemented, so *no epics yet* is phase one, never done. Conflating them yields a loop that reports success on an empty spec because zero requirements are untraced.

## Decisions

1. **Build the spec-level coverage roll-up first**, as its own spec, before any autonomy work. Independently valuable today; the first genuinely testable piece of the traceability spine; the thing that makes autonomous `epics` checkable rather than trusted.
2. **The computation is a script** in `cpm/hooks/lib/`, not model-emitted JSON. Three consumers: `cpm:status`, the stakeholder artifact, and ralph's completion predicate.
3. **One completion promise**, script-backed, scoped differently per mode — not two.
4. **Spec mode is a fourth input shape** on `cpm:ralph`, not a flag or a new skill. Empty arguments keep today's meaning.
5. **Fail closed** on the predicate: uncomputable means not complete.

## Open questions carried forward

- Whether the roll-up's stakeholder view is a new read-only skill scoped to one spec, or a phase of `cpm:status` (Jordan leaned new-skill: the stakeholder question is "is **my** thing done", never "how is the project" — but flagged it as Chris's boundary to set).
- The autonomous rule for `epics`'s must-NOT gate (`:155`), the one gate with no defensible default.
- Test to write regardless: an epic whose stories are all `Complete` while its matrix still has unverified rows. Today's promise ends that run successfully; the new one must not.
