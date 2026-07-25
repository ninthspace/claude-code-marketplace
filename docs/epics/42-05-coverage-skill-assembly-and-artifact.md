# Coverage Matrix: Skill Assembly and Artifact

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Epic**: docs/epics/42-05-epic-skill-assembly-and-artifact.md
**Date**: 2026-07-25

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

> **Partly retired 2026-07-26.** Spec 42's architecture was withdrawn — see the Retirement
> section of the source spec. The `SKILL.md` this epic assembled was rewritten, and Story 2's
> artifact projection (`inspect-project.sh`, `inspect-findings.sh`, `inspect-record.sh` and
> their suites) was deleted. **The AD1 rows outlived the architecture**: the two `description`
> fields still lead with their subject, `/cpm:audit` is still untouched, and
> `test-inspect-skill.sh` still guards both — it is the one suite from this epic that
> survives. Rows covering the projection, the JSON source and the register backlink describe
> deleted code. Every `✓` records what was verified on 2026-07-25, not what the current tree
> does.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | AD1 | Change-set review ships as a new skill (`/cpm:inspect`), sitting between `do` and `retro`. | The skill accepts every selector form from R1 and dispatches to the resolution built in Epic 42-01 | Story 1 | — | ✓ |
| 2 | AD1 | **both skills' `description` fields must lead with their subject, not their verb** | Its `description` leads with its subject — code, after execution | Story 1 | — | ✓ |
| 3 | AD1 | **both skills' `description` fields must lead with their subject, not their verb** | `/cpm:review`'s `description` leads with its subject — plans, before execution | Story 1 | — | ✓ |
| 4 | AD1 | The new skill ships in the CPM plugin but **must not require CPM artifacts in the target repository**. | must NOT require CPM artifacts in the target repository | Story 1 | — | ✓ |
| 5 | Scope — Out of Scope | Any change to `/cpm:audit`. | must NOT modify `/cpm:audit` | Story 1 | — | ✓ |
| 6 | R8 | Publish a page projected from the JSON, registered in `docs/artifacts/index.md` with a backlink per `cpm:artifact`. | The published artifact registers a row in `docs/artifacts/index.md` and records an `**Artifacts**:` backlink | Story 2 | `[integration]` | ✓ |
| 7 | R8 | Publish a page projected from the JSON | The page is projected from the JSON record, and re-publishing the same run redeploys to the same URL | Story 2 | `[integration]` | ✓ |
| 8 | R8 | must NOT embed source content in the published page | must NOT embed source content in the published page | Story 2 | `[integration]` | ✓ |
| 9 | NFR — Offline Integrity | Only R8's publish step touches the network, and its absence must not fail the run. | The run does not fail when the Artifact tool is unavailable | Story 2 | — | ✓ |
| 10 | AD4 | The page is disposable; the JSON is the record. | The page is projected from the JSON record, and re-publishing the same run redeploys to the same URL | Story 2 | — | ✓ |
| 11 | R9 | In a repository with no recognised intent source, the review still runs and every file is reported as an orphan. | The same invocation in a repository with no intent sources completes with every file an orphan and a review still produced | Story 3 | `[integration]` | ✓ |
| 12 | R1 | Accept an **intent-anchored** selector (a ticket, an issue, a CPM spec/epic/story — e.g. `epic 41-03`, `story 41-03.2`) | `epic NN-MM` and `story NN-MM.K` each resolve to the commits that produced them, through an adapter registered by `/cpm:inspect` rather than a test stub | Story 4 | `[integration]` | ✓ |
| 13 | R2 | Intent-anchored selectors resolve **forward** (intent → files). Git-anchored selectors resolve **reverse** (files → intent). One join, two entry points. | The commits an intent-anchored selector resolves to yield the same file set as a git-anchored selector over those same commits | Story 4 | `[integration]` | ✓ |
| 14 | R1 | must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back | must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back | Story 4 | `[integration]` | ✓ |
| 15 | AD1 | The new skill ships in the CPM plugin but **must not require CPM artifacts in the target repository**. | must NOT require the selector's intent record to exist in the repository being inspected for a *git-anchored* run to work | Story 4 | `[integration]` | ✓ |

## Notes

**Row 11 completes Epic 42-03's deferred verification.** The 42-03 coverage matrix records that its row 5 quotes the same spec sentence but cannot be fully verified there, because the review does not exist until Epic 42-04. R9 therefore appears in two matrices: 42-03 verifies the degradation path (zero adapters, every file an orphan, no hard failure), and this row verifies the full observable outcome once a review is actually produced. **Both must be ✓ for R9 to be covered.**

**Row 5 quotes a Scope entry, not a requirement.** "Any change to `/cpm:audit`" appears in the spec's Out of Scope list. It is carried as a story criterion because an out-of-scope boundary is only enforceable if something asserts it — a scope line with no criterion is a hope. The same reasoning applies to the spec's other Out of Scope entries, which are not separately asserted; this one is, because AD1's whole rationale is that `audit` keeps its identity.

**Seven rows carry no Spec Test Approach.** Rows 1–5 and 9–10 trace to architecture decisions, a scope boundary, and a non-functional requirement. The spec's Acceptance Criteria Coverage table tags only R1–R9 criteria, so these rows quote the authoritative prose and their tags are story-originated.

**Story 1's first criterion depends on R1 being complete across two epics.** "Every selector form from R1" spans the git-anchored forms (Epic 42-01 Story 2) and the intent-anchored forms (Epic 42-01 Story 3). Story 1 asserts the **dispatch**, not the resolution — that a selector is routed to the correct direction, with the resolution verified where it is built.

**Rows 6–10 are verified below the page, and that is a limit worth naming.** Nothing in `test-inspect-artifact.sh` calls the Artifact tool, composes HTML, or reaches the network. What is asserted is the boundary underneath: that the projection the page is composed from reads the record and never the repository (row 8, with a sentinel string living inside a source file and appearing nowhere in the projection), that the build path is a pure function of the selector (rows 7 and 10), and that both recording sites refuse a URL that does not exist (rows 6 and 9). Row 6's *register row* is verified as a correctly-shaped row, not as a row appended to the live register — writing it there is the shared **Artifact Publishing** procedure's step, and `cpm:artifact` is unchanged by this epic. A green suite therefore means a published page **could not** carry source content and **would** land on the same URL; it does not mean a page was published.

**Rows 12–15 close a gap this matrix previously mis-stated.** The note above originally said the real intent adapters arrive in Epic 42-02. They do not: 42-02 built the **link** adapters, which resolve files → intent (the reverse direction). The forward `<name>_intent_commits` contract from Epic 42-01 Story 3 has only ever been implemented by `cpm/hooks/tests/stub-intent-adapter.sh`, so 42-01's coverage rows 5–7 are stub-verified and no production channel answers `epic 41-03`. Story 4 supplies one, and rows 12–15 are its own criteria rather than a re-verification of 42-01's — a row verified against a stub and a row verified against a registered adapter are different claims, and collapsing them would hide which one held.

**Row 12's ✓ covers the CPM half of its spec text and not the ticket half.** The quoted requirement reads "a ticket, an issue, a CPM spec/epic/story", and the criterion beside it deliberately narrows to `epic NN-MM` and `story NN-MM.K` — the spec's In-Scope list defers issue-tracker adapters, so no channel in this iteration answers `AUTH-4`. What the row asserts is that the *contract* now has a production implementation and that a selector outside its vocabulary is **declined** (exit 2) rather than answered empty, which is what keeps a deferred adapter addable without reopening R4's answerability distinction. A reader taking the ✓ to mean tickets resolve would be reading more than the criterion says; a reader taking it to mean the intent direction is no longer stub-only is reading it correctly.

**Row 13 is a round-trip, not two fixtures.** `epic 42-05` resolved forward and `--since <base>` resolved in reverse are compared over the same commits, as file sets *and* as commit sets, with the fixture built so the epic's commits are contiguous at the tip. Comparing file sets alone would pass for a pair of empty results, so the matched set is also asserted to span planning documents and code.

**Rows 12–15 verify the adapter's reach, not the repository's.** `cpm_intent_commits` reads three channels — the epic document, its coverage matrix, and commit messages naming the id — and a commit that did the work while mentioning none of them is invisible to all three. That is a limit of what a repository records, and Story 4's first retro documents what it costs here in practice.
