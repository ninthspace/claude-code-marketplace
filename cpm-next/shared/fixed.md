# Process failures fixed by a release

`/cpm-next:library sweep` reads this table, and its rule in `cpm-next/skills/library/sweep.md` (**Fixed rows**) decides which rows cover which signals and lessons. Class `any` means any class. A release that fixes a `process` failure adds a row, dated the day its version is set; a lesson the maintainer judges is not cpm-next's gets a `declined` row naming the place it was reported at and its class, dated the day it is declined, with `—` for its version.

| cpm-next file and step | Class | Fixed in | Date | Outcome | What changed |
|---|---|---|---|---|---|
| `cpm-next/agents/auditor.md` check 1 | criterion-contradicts-input | 0.22.0 | 2026-11-16 | fix | A runtime claim with no probe entry, and a criterion standing against its own probe, are findings. |
| `cpm-next/agents/auditor.md` check 5 | check-cannot-fail | 0.22.0 | 2026-11-16 | fix | A red is checked for each alternative and the control, and a red through an unnamed test double is a finding. |
| `cpm-next/agents/auditor.md` check 6 | identity-key | 0.18.0 | 2026-11-12 | fix | Records that collide on a non-key attribute, and the same identity twice in one delivery, are among the inputs the audit tries. |
| `cpm-next/skills/do/SKILL.md` The loop, Independent tests; `cpm-next/skills/do/independent-tests.md` | shared-assumption | 0.18.0 | 2026-11-12 | fix | A marked story's acceptance tests are written before the build by a separate test-writer, from the spec and real samples, and the builder may not change them. |
| `cpm-next/skills/do/SKILL.md` step 1 | criterion-contradicts-input | 0.22.0 | 2026-11-16 | fix | Claims about a runtime outside the repository are probed before any test or code is written, and a contradicted one is settled first. |
| `cpm-next/skills/do/SKILL.md` step 4 | identity-key | 0.18.0 | 2026-11-12 | fix | The new code is fed records that collide on an attribute that is not their key, and the same identity twice in one delivery. |
| `cpm-next/skills/do/SKILL.md` step 4 | check-cannot-fail | 0.22.0 | 2026-11-16 | fix | A red is taken for each alternative and the control, never through a test double the criterion does not name. |
| `cpm-next/skills/plan/SKILL.md` Epics | identity-key | 0.18.0 | 2026-11-12 | fix | A story that stores, upserts or merges records has criteria that records sharing every attribute but their documented identity are all kept and that a repeat delivery changes nothing, each with its control, and that every record received is accounted for. |
| `cpm-next/skills/review/SKILL.md` 2. Review independently | decision-relitigated | 0.16.0 | 2026-11-10 | fix | Review picks personas the spec's challenge did not use where the roster allows, names any it reuses, and briefs its personas from a copy of the spec without its Challenge section. |
| `cpm-next/skills/review/SKILL.md` 3. Weigh and fix | decision-relitigated | 0.16.0 | 2026-11-10 | fix | A finding that repeats a rejected challenge decision is recorded as decided at challenge and left out of Needs you, unless it is Critical against an unconfirmed rejection or raises something the decision did not cover. |
