# cpm-next (experimental)

Six skills for Opus 5.5, in place of CPM's twenty-one. They read and write the CPM v3 artefact formats, so the board, `/cpm:status` and the v3 skills all keep working on the same `docs/` tree.

| Skill | Absorbs from v3 | Finish line |
|---|---|---|
| `/cpm-next:party` | party, consult | Record concluded, next step named |
| `/cpm-next:plan` | discover, brief, architect, spec, epics, pivot | Artefacts down to the target exist and trace upward |
| `/cpm-next:do` | do, ralph, quick | Stories in scope Complete, suite no worse than baseline |
| `/cpm-next:library` | library, retro learn and retire | Library documents carry complete front-matter; chosen retro lessons promoted and retired at source |
| `/cpm-next:review` | review | Critical and Warning findings fixed in Pending stories or waiting on the user; review record written |
| `/cpm-next:status` | status | One-screen report and the next command; nothing written |

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
