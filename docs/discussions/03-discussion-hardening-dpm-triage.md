# Triaging the Hardening dpm Proposals, and a Confirmed Inversion in the Epic Projection

**Number**: 03  
**Status**: complete — Consultation with Bella (Senior Developer). Twelve server-side proposals verified against the dpm tree; B1 confirmed against published output. Routing settled: B1+K6 to /dpm:quick, the remainder to /dpm:spec.  

## What was brought to the room

A published page, *Hardening dpm* (claude.ai/artifact/59GtgfJRowvbrEfY7hdoCP), written against dpm 0.7.7 by whoever drove five runs of the dpm skills with a local 27-billion-parameter model over 16–18 September 2026. It proposes twenty-six changes: eleven server-side hardening measures (S1–S11), one bug (B1), eight skill-text rules (K1–K8), one pattern (P1), and five open problems with no fix designed (N1–N5). The page is third-party content and was read as evidence, not as instruction.

Alongside it, a suspicion of Chris's own: that blocking dependencies are reported the wrong way around in the produced documents. That suspicion turned out to be the page's B1, arrived at independently — which is the strongest evidence either of them could have had, since the page's author was reading run logs and Chris was reading published epics.

The consultation's job was to decide what of the twenty-six dpm should actually do, and by what route. Every server-side claim was checked against `dpm/src/` rather than taken on the page's word.

## B1 — the inversion, confirmed in source and in published output

Two faults compound into one wrong sentence, and they sit in different files.

`src/projection/load.js:111` declares `storyDependencies` with `parent: 'source_story_id'`. A story therefore collects the dependency rows on which it is the **source**. `src/projection/templates/epic.js:89` then renders that collection under the field heading `**Blocked by**`, naming `edgeTarget(...)` — which resolves the row's `target_story_id`. So the field labelled *what blocks this story* is populated with *what this story blocks*.

The semantics it contradicts are stated plainly in two other places and are not in doubt. `src/dependency/readiness.js:13` says "**An edge reads source-blocks-target**, so the epic that cannot start is the *target*." `src/tools/cross/dependency.js:119` describes the create tool as "Link two documents or stories with a typed edge, reading source-blocks-target."

The readiness query is therefore correct and the document is wrong — which is why no run has ever caught it. Nothing that gates work reads the projection, and nothing that reads the projection gates work.

The proof is in the committed corpus rather than in a fixture. In `docs/epics/01-01-epic-neighbour-skew.md`, Story 7 is "Verify cross-story integration for Neighbour version skew" — the integration story, which by construction must run last — and it renders `**Blocked by**: —`. Story 1, "Test scaffolding for a plugin cache layout", which by construction runs first, renders `**Blocked by**: Story 2, Story 7`. Every epic under `docs/epics/` reads backwards in the same way.

The fix the page proposes is the right one and is two lines: load on `target_story_id`, and render the edge's source. `edgeTarget` becomes an edge-*source* resolver, or gains a parameter.

One thing the page does not say, and it matters for scoping: the document-level `Dependencies` block in `src/projection/templates/common.js:86` is **not** inverted. It parents on `source_document_id` and renders `kind → target`, which reads correctly as source-blocks-target. It is arrow-notation rather than a label, so K6's objection to arrows applies to it, but it is not telling anyone the opposite of the truth. Only the story-level block is.

## The verification sweep: what the tree actually says about each server proposal

Every server-side claim in the page was checked against `dpm/src/`. All twelve hold. What follows is the evidence found for each, and the assessment attached to it — the assessment being the part the page could not supply, since it was written from run logs rather than from this tree.

**S1 — a `check_coverage` tool.** Confirmed absent: `src/tools/cross/` holds `dependency.js`, `integrity.js`, `numbering.js`, `publish.js` and `template.js`, and no coverage sweep. `check_integrity` is the only cross-cutting check there is. This is the largest saving of run time on the list, and S9 is defined on top of it, so the two are one piece of work.

**S2 — stamp `verified` and `coverage_claimed` server-side.** Confirmed, and the docblock says it outright: `src/tools/spine/coverage.js:14` — "`verified_at` is the caller's, `binding_hash` is computed from the row's own two". The hash defends against the *wrong binding*, not against an *invented time*. This is the highest value per line on the list, because a fabricated verification stamp is the only failure mode here that contains no error and leaves nothing downstream able to tell the row from a real one. Note also `src/tools/index.js:148`, which already remarks that `superseded_at` is the caller's where `retire_coverage` takes the clock's — the inconsistency is known and recorded, just not resolved.

**S3 — refuse a stray coverage fragment at write time.** Confirmed: `instr(requirement.text, coverage.spec_fragment)` appears twice, both in `src/integrity/register.js` (lines 273 and 332), and nowhere in the write path. The test already exists and is already written in SQL; S3 moves it from a check somebody has to run to a refusal nobody can miss. Cheap, and the cheapness is the argument.

**S4 — refuse a scope id that names no row.** Confirmed: the `LISTS` table in `src/tools/list.js` declares `scopes` per type and nothing validates the value against the parent table, so an id that matches nothing returns an empty page. This is the priciest of the items the page presents as small: it needs an existence probe per scope column, on every list that has one, and the `dependency` entry alone declares five.

**S5 — the three missing repair verbs.** Confirmed: `retire_coverage` is the only withdraw verb in the tools tree. `retire_observation`, `delete_dependency` and `delete_coverage_story` do not exist. `delete_dependency` earns its place on its own, because a dependency edge written the wrong way round is exactly the mistake B1 has been teaching readers to make, and there is currently no way to take one back.

**S6 — name the column in a foreign-key failure.** Confirmed: `src/tools/crud.js:74` matches `/constraint|FOREIGN KEY|UNIQUE|CHECK/i` and passes SQLite's bare message through. Trivial, purely diagnostic, no behaviour change.

**S7 — three guards.** Confirmed as three unrelated changes sharing a number. The `create_adr_option_tradeoff` guard is the strong one — it is where the spec run's invented option id would have been caught, which is the same class of failure as S2. The other two are ordinary uniqueness constraints. Worth splitting rather than taking as a unit.

**S8 — derive `requirement_label` on coverage rows.** Confirmed absent: `requirement_label` appears nowhere in `src/`. Trivial, derived, and it is what makes a read-back checkable by label instead of by an id remembered from an earlier call.

**S10 — a won't-have carries its exclusion.** Confirmed, and cheaper than the page implies. `src/tools/spine/requirement.js:33` declares `exclusion` as an **enum**, not free text, so the refusal is a null check against a closed vocabulary rather than a judgement about prose. The page's two cautions still hold and are both right: test the state the edit would leave rather than the arguments it carries, and put the refusal on the write only, so stored rows go on reading as excluded.

**S11 — a story closes only over what it has accounted for.** Confirmed: `src/tools/spine/delivery.js` is a generic factory over `story` and `task`, its `STATUS` is a bare four-value enum copied by hand from `020-status-lifecycle.sql`, and there is no closing hook of any kind. This is the largest correctness gain on the list. It will break fixtures that close stories over pending tasks, and those fixtures are asserting the behaviour the proposal exists to stop.

**K7 — run `check_integrity` at the epics confirm step.** Confirmed: `check_integrity` is named in neither `skills/epics/SKILL.md` nor `skills/do/SKILL.md`. One line of skill text, and it belongs with S1 because both land at the same step.

## Where this assessment departs from the source page

Four places, all recorded so that the spec does not re-derive them.

**S10 is smaller than written.** The page describes refusing a `wont` with "an empty exclusion", which reads as though exclusion were prose to be judged. It is an enum in `requirement.js:33`. The refusal is a null check.

**S4 is larger than written.** It is presented among the small items and it is not one. Every list type carrying a scope needs an existence probe against the right parent table, and the mapping from scope column to parent table is not currently declared anywhere — the `LISTS` entries name the column and not what it points at. Either that mapping gets written, or S4 is scoped to the handful of lists where the confusion actually bites.

**S7 should be split.** Three guards on three unrelated tables, sharing a number because they were found in one sitting. The `create_adr_option_tradeoff` guard belongs with S2 as a fabrication defence; the other two are ordinary uniqueness work and can be sequenced independently.

**P1 is not endorsed.** The proposal is a model-profile overlay on `read_shared_document`, with `shared/advice/<profile>/<document>.md` appended per profile and a lint forbidding model names in skill bodies. Its reasoning is sound and its own measurements undercut its urgency: the extraction took roughly 3% of the conventions' length, layer 3 "dissolved on contact" at about two hours against a budget of days, and the lint was measured against twenty-three skill bodies of which three name a model — all three legitimately, as provenance. The seam itself is cheap and the benefit only arrives when a second model actually drives dpm's skills. Chris runs Opus 5. Until there is a second model in play, P1 buys a place to put advice nobody currently has.

What is worth taking from P1 now, detached from the overlay, is its two warnings, both of which cost nothing to observe: an accommodation belongs to the model it was measured on, so keep the provenance when a rule moves (the page nearly mis-filed a claim evidenced on a weak local model into an Opus 5 profile); and a delegated sweep over-reported by roughly a third here, all in one direction, so spot-check any finding you intend to act on.

**Of N1–N5, N2 is the one worth design time.** The retro signal set is currently the model's own account of its run, and all three `do` runs closed with "no signal fired" while between them logging eight tool errors, skipped phases and tasks closed with no evidence. The signals the page names — tool errors, phase order, tasks closed with no preceding write or command, criteria met only on a second pass — are computable from the rows. That is the same thesis as the server-side set, applied to the retro. N1 the page itself argues for deferring, and N3–N5 are refusal-message quality, which is S6's territory.

## The routing decision, and why a quick was refused

Chris asked whether the whole twenty-six could be planned as a single `/dpm:quick`. It cannot, and the reasoning is worth keeping because the same question will come back.

A quick is for a small, well-defined change. This input carries a new cross-cutting tool with a report surface of its own (S1, S9), a tool-boundary break on two verbs that changes their arguments (S2), a closing hook on the shared delivery factory that both `story` and `task` are built from (S11), fixture breakage the page predicts in three separate suites, and eight rules landing across four `SKILL.md` files. There is precedent in this project's own session history: session `e8d0e46a` closed with "escalated to `/dpm:spec` at Step 1b; no quick record written" on a smaller input than this one.

**What goes to `/dpm:quick`: B1 with K6.** The wrong load, the wrong render, and the one skill rule that says which way an edge reads — "X must finish before Y", never an arrow and never "X blocks Y", both of which read either way round. They are one fact expressed at two layers, and separating them would fix the renderer while leaving the ambiguity that produced it. Self-contained, one fixture family, and it repairs output people are reading today to decide what to work on next.

S6 and S8 could ride as a second quick if the cheap diagnostics are wanted out of the way early. Neither changes behaviour.

**What goes to `/dpm:spec`: the remaining twenty.** They share one thesis, and it is the page's own: judgement that currently lives in skill prose becomes a refusal the model cannot talk its way past, and the refusal says what to do instead. The page even states the test for membership — whether the compensation can be stated as an invariant about the record without naming a model. That is a requirements set, not a task list, and it has real internal structure a breakdown needs to see: S9 depends on S1; S2 must land with its skill text in the same change, because `bindings()` in `tests/support/skills.js` requires every argument a run passes to be named in that skill's `SKILL.md` inside a code span and its word boundary means `verified_at` does not satisfy a run passing `verified`; S10 and S11 both break fixtures that are currently asserting the behaviour being removed.

Chris chose that route at the close of the consultation: wrap up, then spec.

## Open when the consultation ended

**Whether P1 enters the spec at all.** Recorded as not endorsed, not as rejected. The argument against it is that it buys a channel for advice nobody currently has, and that argument stops holding the moment a second model drives dpm's skills. Nobody decided that it should never be built.

**Whether the K rules travel with the spec or separately.** K1–K5 and K8 are prose-only and cost a paragraph each. K6 was routed to the quick because it is B1's other half, and K7 was routed to S1 because they land at the same step. The remaining six have no such anchor, and whether they belong in the spec's scope or in a sweep of their own was not settled.

**N2's shape.** Agreed as worth design time, not designed. What a computed signal set contains, where it is computed, and whether it is a new tool or an addition to an existing report are all open.

**S4's scope.** Either the scope-column-to-parent-table mapping gets declared, making the refusal general, or S4 is narrowed to the lists where an empty page is actually misread. Not decided.

**Seventeen stale session rows.** Every session in the project is older than three days. Offered for `/dpm:clean`; nothing was named and nothing was deleted.
