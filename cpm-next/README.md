# cpm-next (experimental)

Seven skills for Opus 5.5, in place of CPM's twenty-one. They read and write the CPM v3 artefact formats, so the board, `/cpm:status` and the v3 skills all keep working on the same `docs/` tree.

| Skill | Absorbs from v3 | Finish line |
|---|---|---|
| `/cpm-next:party` | party, consult | Record concluded, next step named |
| `/cpm-next:plan` | discover, brief, architect, spec, epics, pivot | Artefacts down to the target exist and trace upward |
| `/cpm-next:do` | do, ralph, quick | Stories in scope Complete, suite no worse than baseline |
| `/cpm-next:library` | library, retro learn and retire | Library documents carry complete front-matter; chosen retro lessons promoted and retired at source |
| `/cpm-next:review` | review | Critical and Warning findings fixed in Pending stories or waiting on the user; review record written |
| `/cpm-next:status` | status | One-screen report and the next command; nothing written |
| `/cpm-next:calibrate` | — | A model and effort recommendation for an artefact, skill or task, or a table of them for a set; nothing written |

## What changed, and why

- **Outcomes over procedure.** Each skill states what "done" means and when to stop. How to get there is left to the model.
- **State lives in the artefacts.** The discussion record and the epic doc are the state. No progress files, stale-progress checks, compaction hooks or `/cpm:clean`.
- **plan works from inventory.** It takes stock of what exists, asks its questions in one batch, records its own decisions as Assumptions, and writes only what's missing. It covers greenfield and brownfield from any starting state.
- **do stops only when it has to.** Its stop rules follow the Opus 5.5 guidance: keep going when the user isn't needed, and stop for unexplained failures, scope changes and destructive actions. An unattended (`all`) run marks blocked stories instead of stopping.
- **Kept on purpose:** the "unmet isn't wrong" rule from the Change Type Decision, citation-backed amendments, and `**Pivot deferred**` breadcrumbs. This is the one failure mode that is known to be expensive.
- **Dropped:** coverage matrices (`**Satisfies**` carries the traceability), the retro disposition gate, template hints, and the `AskUserQuestion` handoff menus.

## Running the experiment

1. Pick three real starting states: nothing but an idea; an existing brief; existing epics in a brownfield Laravel repo.
2. For each, run v3 and cpm-next on separate branches from the same commit.
3. Run every session, v3 and cpm-next alike, at `medium` effort (`/effort medium` in Claude Code), so effort isn't a variable in the comparison. If an `all` run is driven headless (`claude -p` in a loop, as ralph did), treat a turn that ends with text as a progress report, not completion. Continue it by naming the open stories, and give up after two or three continuations on the same story.
4. Compare wall-clock time, how often the user had to intervene, spec and epic quality (blind if possible), and whether `do` finished with the suite green.
5. When cpm-next fails in a way v3 guarded against, add back the smallest rule that prevents it. Log each addition here, so the growth stays deliberate.

## Additions

- **library** (0.2.0): brought over from v3 so reference documents can be imported and consolidated without switching plugins. Same front-matter and amendment formats, now in `shared/artifacts.md`; progress files, the stale-progress check and per-step gates dropped.
- **Per-criterion evidence** (0.2.0): `do` now writes an `Evidence` (or `Not met`) line under each acceptance criterion instead of one story-level `**Evidence**` field. In practice the two blocks drifted apart, and a reader couldn't tell which proof backed which criterion, or whether any criterion had none.
- **library learn, review, status** (0.3.0): `learn` moves durable retro lessons into the library, since otherwise only v3 does it and `consolidate` has nothing to fold in. `review` gives the epics the independent challenge that `plan` gives the spec. `status` is a read-only reading of the artefacts, which are the only state. Retro and review formats and the `**Retired**` marker join the contract, matching v3 so its skills read them unchanged.
- **Prompt audit for Opus 5.5** (0.3.0): `/claude-api prompt-audit` over the skills removed `do`'s self-review of each story's diff and the "Time matters" lines in `do` and `plan`, since Opus 5.5 checks its own work and effort is the control for how long it thinks. It also removed phrasing that only made sense against v3 ("No gate, no dispositions", "Don't present a menu"), and replaced the fixed counts in `review` and `status` with descriptions of what to keep. The persona subagents in `plan` and `review` were flagged and kept, because independent reviewers are the point of those steps. Worth confirming by running one epic with and without the self-review.
- **calibrate** (0.4.0): recommends a model and effort level for an artefact, a skill or a described task, or for a whole set of them as a table, one row per item, with the skill each needs next. It advises rather than setting either, since a skill's `model` and `effort` frontmatter only lasts for the invoking turn and would pin a variable this experiment holds fixed.
- **review personas on Sonnet** (0.4.0): `review` starts its persona subagents on `sonnet`. A per-call model outranks `CLAUDE_CODE_SUBAGENT_MODEL`, so this is the one subagent choice the plugin makes for you; `plan` and `do` subagents follow that variable, or the session model when it's unset. When comparing runs, note that review cost now differs from a v3 review on the same model.
- **Stories close as they finish** (0.4.1): `do` was writing every `Evidence` line and leaving the story `In Progress` and its tasks `Pending`, which also left dependent stories blocked, because the unblocked rule reads only the status. The simplifier pass, which came between verifying and closing, moves ahead of verification. A story now closes in the same edit as its last `Evidence` line, and the epic closes with its last story. `do` re-reads the finished story before starting the next one. On resume, an evidenced story left `In Progress` is closed before any other work.
- **Sonnet builds, Opus plans and audits** (0.5.0): `do` declares `model: sonnet` and starts its parallel subagents on Sonnet; `plan` and `review` declare `model: opus`, and their subagents, including the review personas that 0.4.0 put on Sonnet, now start on Opus. Before closing each story, or a small change, `do` hands it to a new read-only `auditor` agent (`agents/auditor.md`, `model: opus`), which re-runs the cited tests and reads the diff for unmet criteria, defects, scope creep and convention breaches. `do` fixes Critical and Warning findings, audits once more, and records the result in a new `**Audit**` story field; a story that fails the second audit is blocked. This restores a per-story review that the 0.3.0 audit removed on the grounds that Opus checks its own work, which no longer holds once Sonnet builds. Frontmatter models last only for the invoking turn, so a turn that continues a `do` run falls back to the session model unless the `cpm-next-models` mod is installed, which holds the skill's model until another skill runs, the model is switched, or `/clear`; `calibrate` now says so and recommends effort only for these three skills. This pins the model variable the experiment previously held fixed, so compare runs against v3 with that in mind.
