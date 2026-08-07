# Spec: Pivot CPM's HTML Story to Claude Artifacts

**Date**: 2026-07-25
**Brief**: direct input — established in conversation, following the artifact register added in `41bc7a5`

## Problem Summary

CPM emits HTML in three bounded roles: **companion assets** (visual content the Markdown references), **faithful renders** (a navigable view of a whole spec/ADR/review), and **`present` HTML communications**. Two of those three are mirrors — an HTML projection of a Markdown file that already renders anywhere you would read it — and a mirror earns nothing. What does earn its place is a *complementary interpretation*: something that shows what the source document cannot. Meanwhile the interpretations CPM does produce (`status`'s full picture, `epics`' dependency view, `present`'s reframed communication) are trapped in local files that must be attached to be shared, which is precisely the job a hosted artifact does better.

This spec deletes the mirrors, moves the interpretations to Claude artifacts, and tells the other skills where an artifact would earn its place in their own output.

### Surface survey

Run at spec time rather than deferred to an epic, per retro 14's closing recommendation (*"the planning artefact reliably under-counts the edit surface"*). It corrected the premise in three places:

1. **Eight test files reference `template.html`**, not the six assumed: `test-faithful-render.sh` and `test-epics-schema-tolerance.sh` were missed. Plus `html-test-helpers.sh` (14 validators) and `test-html-tooling.sh`.
2. **`status` Phase 4 and the `epics` dependency view are HTML-native — there is no Markdown source.** They synthesise directly from a live scan. They are not mirrors changing form; they are originals changing medium. Both already write to ephemeral paths (`docs/plans/epics-dependency-view.html`; save-on-request for `status`), which makes them the strongest artifact candidates in the pivot — a URL that redeploys in place strictly beats an ephemeral local file.
3. **The companion-asset carve-out has two downstream consumer sites**: `do:272` opens assets as visual design targets during execution, and `epics:138` tags mockup-referencing criteria `[manual]` because the oracle is visual. The carve-out is load-bearing in the pipeline, not merely a preference.

Two further findings shaped the architecture:

- **The publishing reference line sits at 6 sites and is byte-identical** (verified: `sort | uniq -c` → one unique string). Three of them live *inside* faithful-render sections and vanish with their host. The remaining three open with *"Any HTML output here can additionally be published…"*, which becomes false as soon as there is no local HTML. The line must be rewritten, not preserved.
- **The Tier 1 / Tier 2 vocabulary collapses.** Tier 2 exists solely to permit inline JavaScript in the two local tracking documents. Once those are artifacts, companion assets are the only local HTML remaining and they are static — the distinction has nothing left to distinguish.

## Functional Requirements

### Must Have

- **R1 — Delete the faithful-render mechanism.** Remove the three `Faithful Render (on request)` sections (`spec/SKILL.md:209`, `architect/SKILL.md:163`, `review/SKILL.md:239`), the `docs/{type}/html/` storage-path row from the shared convention, and the `test-faithful-render.sh` suite. No artifact replaces them — a faithful render is a mirror by definition, so replacing it in a new medium would reproduce the fault.
- **R2 — Pivot the three interpretations to Claude artifacts.** The `status` full-picture document, the `epics` dependency view, and `present`'s HTML communication are published via the Artifact tool rather than written as local HTML.
- **R3 — Rewrite the HTML Output convention.** Three roles become one (companion assets), with the publishing procedure promoted alongside it. Retire the Tier 1 / Tier 2 vocabulary.
- **R4 — Add per-skill "when an artifact earns its place here" guidance** to `discover`, `brief`, `architect`, `spec`, `epics`, `review`, `audit`, `retro` and `status`. Each names what an artifact could show for *that skill's* output — a problem map, a value-proposition canvas, an architecture explorer, a requirement explorer, a dependency and readiness view, a findings explorer by severity, a nine-dimension findings dashboard, a trend view across retros, a project dashboard. Each carries the same conservative heuristic the companion-asset sections already use: **if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place.**
- **R5 — Preserve the register invariant.** Every publish writes a row to `docs/artifacts/index.md` and an `**Artifacts**:` backlink on the source artifact, per `cpm:artifact`. No publishing path may omit either.
- **R6 — Companion assets remain repo files.** They are not published and not replaced by artifacts. `cpm:do` opens them as visual design targets mid-execution; a URL would make a pipeline step depend on network reachability.

### Should Have

- **R7 — A fragment validator.** Add `check_valid_fragment` to `html-test-helpers.sh` covering the artifact scratch path (`docs/plans/{skill}-artifact-{nn}-{slug}.html`): rejects `<!doctype>`, `<html>`, `<head>` and `<body>`; accepts a leading `<style>` block; asserts self-containment. Without it the pivot moves three outputs from validated to unvalidatable while the suite still reports green.

### Could Have

- A `/cpm:artifact` convenience path that lists artifacts by associated planning document, beyond the existing search term.

### Won't Have (this iteration)

- Migration or re-registration of any artifact published before this spec.
- Any change to `docs/artifacts/index.md`'s format, or to `cpm:artifact` itself.
- Any change to `cpm:do`'s companion-asset handling — `do:272` is protected, not modified.
- Publishing of companion assets.

## Non-Functional Requirements

**Deliberately no token or byte-count NFR.** Retro 14's criteria gap was an NFR constraining a global quantity attached to a pass whose requirements moved that quantity in both directions. The same shape applies here: R1 and R3 subtract, R4 adds across nine skills. The honest framing is *report the net*, not *reduce it*.

### Availability

No skill may hard-fail when the Artifact tool is absent from the session. Each affected skill states its degradation plainly and continues. Absence is never reported as a skill failure.

### Offline Integrity

Nothing in the `cpm:do` execution path may depend on network reachability. This is the constraint R6 exists to protect: a task that builds to match a mockup must be able to open that mockup from disk.

## Architecture Decisions

### AD1 — Artifacts change the medium, never the record

**Choice**: Every pivoted output either retains a Markdown record (`present`) or was already explicitly ephemeral (`status`, `epics`). No artifact becomes the sole copy of durable content.

**Rationale**: The pivot is about how work is *shared*, not about where it is *kept*. `present`'s Markdown carries the `**Source artifacts**` field that regeneration depends on, is committed, and is greppable — losing it would trade a durable record for a link.

**Consequence**: For `status` and `epics`, whose outputs were always ephemeral, the register row becomes the *only* durable trace. This promotes R5 from bookkeeping to load-bearing.

**Alternatives considered**: Artifact-only for `present` (loses the regeneration anchor and leaves no in-repo record of what was communicated to whom); keeping both Markdown and local HTML alongside the artifact (retires nothing, contradicts the premise).

### AD2 — Two design systems, cleanly separated

**Choice**: `cpm/assets/html/template.html` governs local companion assets. The `artifact-design` skill governs published pages. The publishing mechanics change from *"re-emit `template.html` as a body fragment"* to *"compose per `artifact-design`"*.

**Rationale**: These solve genuinely different problems. Companion assets are committed files that accumulate over a project's life and drift apart without a single enforced stylesheet. A published page is generated fresh and read once — cross-page consistency buys nothing there, and CPM's documentation chrome is the wrong register for something sent to a stakeholder. The Artifact tool additionally *requires* `artifact-design` before a page is written, so re-emitting CPM chrome would put two authorities over one page.

**Alternatives considered**: One system, artifacts re-emitting the template as a fragment (the status quo from `41bc7a5` — maximum visual consistency, but the two-authorities problem stands); retiring the template entirely (reintroduces the divergent-CSS problem the convention was written to prevent, and companion assets are exactly where that bites).

### AD3 — Degradation is to text, never to HTML

**Choice**: No local-HTML fallback path exists. When the Artifact tool is unavailable, `status` degrades to its existing Phase 1–3 stdout narrative and `epics` states its ready/blocked list in the conversation.

**Rationale**: `status` already has a complete narrative fallback, so the local dashboard was never the only way to get the information. Retaining a fallback would keep the entire generation path, the template consumption model, and four test files alive to serve a case that rarely fires — the half-measure costs more than the capability is worth.

**Alternatives considered**: Artifact-first with local HTML fallback (safer, but roughly doubles the instruction surface in both skills).

### AD4 — `Artifact Publishing` is promoted to a top-level convention section

**Choice**: `## Artifact Publishing` becomes a top-level section of `skill-conventions.md`. `## HTML Output` shrinks to companion assets only. A new byte-identical reference line propagates to **10 skills** — the 3 pivoted plus the 9 R4 sites, with `status` and `epics` overlapping.

**Rationale**: The convention currently reads "HTML Output, and by the way you may publish it." After the pivot that hierarchy is backwards for every output except companion assets: most publishing has no local HTML at all. Leaving publishing as a subsection would make every one of its reference sites inherit a false premise.

**Alternatives considered**: Keeping publishing nested and rewording the reference line only (leaves the structural claim wrong while patching its symptom).

### AD5 — Export affordances are carried across provisionally

**Choice**: The copy-as-prompt / copy-as-JSON affordances move to the published artifacts, but their viability is treated as **unverified**, with a stated fallback: render the payload as selectable `<pre>` text.

**Resolved (2026-07-25)**: verified working on a live published page — `writeText` succeeded inside the cross-origin frame and the paste confirmed it. The affordance is carried across unconditionally; the `<pre>` payload is retained for readability rather than as a fallback. Recorded in the shared **Artifact Publishing → Export affordances** convention.

**Artifacts**: [Artifact clipboard probe](https://claude.ai/code/artifact/60c498ab-587b-4b00-bb7c-ed70f783e183) — the live test settling this decision's open question.

**Rationale**: Inline JavaScript is permitted by the Artifact tool's CSP (which blocks external hosts, not inline script). But `navigator.clipboard.writeText` inside a cross-origin embedded frame is gated by permissions policy, and that has not been verified here. Writing "the affordances transfer" into the spec as settled would be an assumption dressed as a decision.

**Alternatives considered**: Dropping the affordances outright (loses a genuinely useful feature on an unconfirmed suspicion); asserting they work (the failure would surface only after the local path had been deleted).

## Scope

### In Scope

- R1–R7 and AD1–AD5.
- The `skill-conventions.md` restructure: `HTML Output` reduced to companion assets, `Artifact Publishing` promoted, Tier 1/Tier 2 retired, storage table reduced.
- Propagation of the new byte-identical reference line to 10 skills.
- Test suite prune plus `check_valid_fragment`.
- Documentation updates: `cpm/README.md` and `cpm-training-guide.html`.
- Plugin version bump to 3.1.0, applied at every site (per retro 13/14: `grep -rn` the current version string first — three epics running, the named site has not been the only site).

### Out of Scope

- Retiring or restructuring `cpm:artifact`.
- Migrating artifacts published before this spec.
- Any edit to `do:272` or `epics:138`.
- Publishing companion assets.

### Deferred

- Publishing of companion assets — they remain design targets, and the deliverable-mockup prohibition already makes them the riskiest category to publish.
- The `/cpm:artifact` list-by-association convenience path (R-could-have).

## Testing Strategy

### Tag Vocabulary

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: red-green-refactor. Composable with any level tag.

Most criteria here are `[integration]` against the existing shell suite. These validators test *contracts*, and a prose-instruction change is verified by structural, grep-shaped assertions — not by observing model output, which has no oracle. Per retro 14, no criterion is phrased "the suite is green": each names the specific assertion it depends on, so it cannot silently annex unrelated repo maintenance.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| R1 | `grep -rn "Faithful Render" cpm/ --include="*.md"` returns zero hits | `[integration]` |
| R1 | `test-faithful-render.sh` is deleted and `run-all-tests.sh` no longer references it | `[integration]` |
| R1 | must NOT delete the Companion Assets sections in `spec` or `architect` | `[integration]` |
| R2 | `status`, `epics` and `present` contain no instruction to write a local HTML file | `[integration]` |
| R2 | each of the three states its non-HTML degradation path | `[manual]` — prose adequacy is a judgement with no automatable oracle |
| R2 | must NOT remove `present`'s Markdown output or its `**Source artifacts**` field | `[integration]` |
| R3 | `Artifact Publishing` exists as an `##` section in `skill-conventions.md` | `[integration]` |
| R3 | `grep -rn "Tier 1\|Tier 2" cpm/ --include="*.md"` returns zero hits | `[integration]` |
| R3 | the storage-path table retains the companion-asset row and no other | `[integration]` |
| R4 | all 10 skills carry the new reference line; `grep -rh … \| sort \| uniq -c` shows exactly one unique string | `[integration]` |
| R4 | each of the 10 adds a skill-specific sentence naming what would earn its place | `[manual]` — content judgement per skill |
| R5 | must NOT allow any publishing path that omits the register row or the `**Artifacts**:` backlink | `[integration]` |
| R6 | `git diff` shows no change to `do/SKILL.md:272` or `epics/SKILL.md:138` | `[integration]` |
| R6 | must NOT introduce any URL dependency into the `cpm:do` execution path | `[integration]` |
| R7 | `check_valid_fragment` rejects `<!doctype>`, `<html>`, `<head>`, `<body>` and accepts a leading `<style>` block | `[integration]` |
| R7 | `check_valid_fragment` asserts self-containment on the scratch path | `[integration]` |
| AD5 | clipboard behaviour verified on a live published artifact, or the `<pre>` fallback applied | `[manual]` — requires a published page; no local oracle |
| Release | version string is consistent across every site carrying it | `[integration]` — structural cross-file agreement, not a pinned literal (retro 14) |

### Integration Boundaries

No ADRs pre-date this spec, so boundaries derive from AD1–AD5:

- **Skill instruction ↔ shared convention** — the byte-identical reference line. The seam that breaks silently: a variant phrasing at one site passes every per-file check while defeating the propagation guarantee. `sort | uniq -c` is the only assertion that catches it.
- **Publish ↔ register** — the invariant in R5. The artifact URL and the register row must be produced by one step, not two, or a failure between them loses the URL permanently.
- **Skill ↔ Artifact tool** — the availability boundary. Every crossing needs a stated degradation.
- **Skill ↔ `html-test-helpers.sh`** — the validators are the executable form of the convention. A convention rule with no validator is unenforced; a validator with no rule is dead weight. R1 and R7 move both ends together.

### Test Infrastructure

None required. The shell suite under `cpm/hooks/tests/` and the validator library in `html-test-helpers.sh` already provide the harness. R7 adds one validator to the existing file rather than introducing anything new.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
