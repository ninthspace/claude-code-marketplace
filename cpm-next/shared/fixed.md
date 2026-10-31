# Process failures fixed by a release

`/cpm-next:library sweep` reads this table, and its rule in `cpm-next/skills/library/SKILL.md` **Sweep** decides which rows cover which signals. Class `any` means any class. A release that fixes a `process` failure adds a row.

| cpm-next file and step | Class | Fixed in | What changed |
|---|---|---|---|
| `cpm-next/skills/do/SKILL.md` step 4 | check-cannot-fail | 0.9.0 | Every test-proven criterion records the failure its test gives with the covered lines undone, instead of a self-reported check. |
| `cpm-next/skills/plan/SKILL.md` Epics | check-cannot-fail | 0.9.0 | A criterion saying what must not happen names its control, so it cannot pass when the feature does nothing. |
| `cpm-next/skills/do/SKILL.md` step 3 | unprovable-in-session | 0.9.0 | Criteria tagged `[user]`, or that cannot be carried out in the session, are never claimed as met and are put to the user. |
| `cpm-next/skills/do/SKILL.md` Scratch directories and isolation | shared-state-collision | 0.9.0 | Builders and auditors each get their own scratch directory, and the suite's isolation is checked once per run. |
| `cpm-next/skills/plan/SKILL.md` Epics | instance-not-rule | 0.10.0 | A criterion is stated over the rule its requirement sets, with a regression for one reported input beside it. |
| `cpm-next/skills/do/SKILL.md` Finishing | any | 0.10.0 | A `**Pivot deferred**` item is given with the `/cpm-next:plan` command that settles it. |
| `cpm-next/skills/do/SKILL.md` step 4 | any | 0.11.0 | Reds are taken in one pass whose manifest shows every file came back, kept where a stopped run can restore it, so a revert cannot lose work. |
| `cpm-next/skills/do/SKILL.md` Audit | shared-state-collision | 0.11.0 | An auditor runs tests only when the suite is isolated or the lead says it is free, and a red pass does not overlap one that runs them. |
| `cpm-next/agents/auditor.md` check 5 | check-cannot-fail | 0.9.0 | A missing or mismatched recorded red, or one that shows an error instead of the cited assertion failing, is a finding. |
| `cpm-next/agents/auditor.md` check 5 | check-cannot-fail | 0.11.0 | The recorded failure text is checked against what the cited assertion would print for the recorded change. |
| `cpm-next/agents/auditor.md` checks 6 and 8 | shared-state-collision | 0.11.0 | Probes and the full suite run only when the suite is isolated or the lead says it is free. |
| `cpm-next/skills/plan/SKILL.md` Lessons | any | 0.9.0 | The library lessons that bear on an epic are named in its `**Lessons**` line and reflected in criteria. |
| `cpm-next/skills/review/SKILL.md` 2. Review independently | any | 0.9.0 | One persona checks that each lesson named for a story is reflected in a criterion of it. |
| `cpm-next/skills/review/SKILL.md` 2. Review independently | instance-not-rule | 0.10.0 | A criterion naming one instance where its requirement covers every case is flagged. |
| `cpm-next/skills/do/SKILL.md` Scope and finish line | unprovable-in-session | 0.9.0 | A story whose only unproven criteria are the user's is skipped and counted done, not claimed as met. |
| `cpm-next/skills/do/SKILL.md` Before the first story | unprovable-in-session | 0.11.0 | A browser check the run cannot make is said in the first message after the probe, not discovered at the end. |
| `cpm-next/skills/do/SKILL.md` Scope and finish line | any | 0.9.0 | A small change's `docs/quick/` record gets the same control, lesson and tag rules as an epic's criteria. |
| `cpm-next/agents/auditor.md` check 1 | unprovable-in-session | 0.9.0 | A `[user]` criterion's Evidence in any form but the user's own answer is a Critical, and a `[browser]` criterion needs a test with its red or a `browser-observed` record. |
