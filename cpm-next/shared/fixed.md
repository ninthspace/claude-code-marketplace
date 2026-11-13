# Process failures fixed by a release

`/cpm-next:library sweep` reads this table, and its rule in `cpm-next/skills/library/sweep.md` (**Fixed rows**) decides which rows cover which signals. Class `any` means any class. A release that fixes a `process` failure adds a row.

| cpm-next file and step | Class | Fixed in | What changed |
|---|---|---|---|
| `cpm-next/agents/auditor.md` check 6 | identity-key | 0.18.0 | Records that collide on a non-key attribute, and the same identity twice in one delivery, are among the inputs the audit tries. |
| `cpm-next/skills/do/SKILL.md` The loop, Independent tests; `cpm-next/skills/do/independent-tests.md` | shared-assumption | 0.18.0 | A marked story's acceptance tests are written before the build by a separate test-writer, from the spec and real samples, and the builder may not change them. |
| `cpm-next/skills/do/SKILL.md` step 4 | identity-key | 0.18.0 | The new code is fed records that collide on an attribute that is not their key, and the same identity twice in one delivery. |
| `cpm-next/skills/plan/SKILL.md` Epics | identity-key | 0.18.0 | A story that stores, upserts or merges records has criteria that records sharing every attribute but their documented identity are all kept and that a repeat delivery changes nothing, each with its control, and that every record received is accounted for. |
| `cpm-next/skills/review/SKILL.md` 2. Review independently | decision-relitigated | 0.16.0 | Review picks personas the spec's challenge did not use where the roster allows, names any it reuses, and briefs its personas from a copy of the spec without its Challenge section. |
| `cpm-next/skills/review/SKILL.md` 3. Weigh and fix | decision-relitigated | 0.16.0 | A finding that repeats a rejected challenge decision is recorded as decided at challenge and left out of Needs you, unless it is Critical against an unconfirmed rejection or raises something the decision did not cover. |
