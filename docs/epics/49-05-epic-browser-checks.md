# Browser checks said early, retried together

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: Epic 49-04-epic-waiting-on-user

## Say what's missing at the start; retry together at the end
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 4 findings fixed
**Blocked by**: —  
**Satisfies**: FR12, FR13  
**Signal**: procedure-gap — project — the early browser warning named conditions it never probed, and the fixed branch of the grouped browser question left the story unfinished (`cpm-next/skills/do/SKILL.md:38,157`, audit round 1)

**Acceptance Criteria**:

- `do` **Before the first story** says that when the scope holds a `[browser]` criterion the run cannot check (no browser test tool, and no app answering at a local `APP_URL`, no connected browser, or no login session where one is needed), its first message says what is missing and how to fix it, then carries on; with the user present it asks once, before building, whether to fix it first `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:38` (**Before the first story**) — after loading claude-in-chrome and listing the connected browsers (again when the user says they have fixed it), the run probes the app as step 3 does (`APP_URL`'s host `localhost`, `127.0.0.1` or `.test`, and one HTTP request) and, with a browser connected and the app answering, opens the page in that browser to see whether it lands on a login page (no credentials entered), and "When the run then cannot check it (no connected browser, no app answering at a local `APP_URL`, or no login session where one is needed), say what is missing and how to fix it in the first message after the probe and carry on; with the user present, ask once, before building, whether to fix it first" — red: n/a — manual
- `do` **Finishing** says browser checks that fell back to the user are one question in the walk-through: fix the environment and have `do` run them all, or report the results; once fixed, `do` checks them through claude-in-chrome, records them `browser-observed` and removes their `- Waiting on user:` lines `[manual]`
  - Evidence: `do/SKILL.md:157` (**Finishing**) — "the `[browser]` criteria that fell back to the user (step 3): ask once for all of them, whether the user will fix the environment … so that you run them all, or report the results themselves. Once it is fixed, check each through claude-in-chrome as step 3 says, record it `browser-observed` and remove its `- Waiting on user:` line, and for each story whose criteria then all have `Evidence`, take step 4, audit it and close it as step 6 says; a check that fails gets a `Not met` line in place of its `- Waiting on user:` line and the contract's blocked note on its story" — red: n/a — manual

### Edit do
**Task**: 1.1  
**Description**: Amend `do/SKILL.md` **Before the first story** and **Finishing**.  
**Status**: Complete

---
