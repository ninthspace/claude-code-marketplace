# Retro: /cpm:clean Command

**Date**: 2026-07-08
**Source**: docs/epics/38-03-epic-cpm-clean-command.md
**Stories**: 2/2 complete

## Summary

Epic 38-03 completed feature 38 by adding `/cpm:clean` — the exhaustive, on-demand
counterpart to the 38-02 passive safety-net. Story 1 extended the 38-01 classifier
with an opt-in `list-all` mode (also globs `.cpm-compact-summary-*.md`) and authored
`cpm/skills/clean/SKILL.md`: a light, interactive-only, stateless skill that lists every
progress file and its compaction companion with age + session label, groups companions
by session ID, and deletes only user-named files after showing the exact paths. Story 2
bumped the plugin to 2.7.0 (marketplace 3.9.0) and documented `/cpm:clean` plus the
non-blocking safety-net behaviour in the README. Coverage matrix: 4/4 requirements
verified. The classifier extension shipped with 7 new tests and left every hook suite
green — the default mode is byte-identical, so the hooks were untouched.

## Observations

### Patterns Worth Reusing

- **Grow a shared helper for a new consumer via an opt-in mode, default path  
  untouched.** `/cpm:clean` needed the classifier to also enumerate compact-summary  
  companions, but the two hooks must keep seeing progress files only. A second  
  positional arg (`list-all`) that defaults to the existing behaviour added the new  
  capability with zero risk to existing callers — proven by all five hook suites  
  staying green after the change. The per-file logic was extracted into one  
  `classify_file()` function reused by both globs, and a single generalized session-ID  
  `sed` (`^\.cpm-(progress|compact-summary)-`) handled both filename shapes. When a  
  shared contract must serve a new consumer, prefer an additive opt-in over a fork or a  
  breaking signature change, and verify the untouched path with the existing consumers'  
  own suites.
- **A thin consumer over one inventory source stays honest.** Per retro 04, the skill  
  does no globbing or `stat`ing itself — it reads the classifier's records and only  
  decides presentation (grouping companions, marking the current session). The empty  
  inventory is handled explicitly as "do nothing and report", applying retro 04's  
  "scrutinise the no-match case" lesson to a fresh surface.

### Codebase Discoveries

- **The plugin version lives in three fields that must move together — and one test  
  hardcodes it.** A version bump touches `cpm/.claude-plugin/plugin.json` (the epic's  
  shorthand "cpm/plugin.json" is actually under `.claude-plugin/`), the `cpm` entry in  
  the root `.claude-plugin/marketplace.json`, and marketplace's own top-level version.  
  `test-audit-skill.sh` asserts a hardcoded expected version, so `run-all-tests.sh`  
  goes red on every bump regardless. Any version-bump task in this repo should update  
  all three fields and expect the audit suite to need the same one-line fix.

### Testing Gaps

- **`${CLAUDE_PLUGIN_ROOT}` resolution in the skill's Bash is still unverified — third  
  epic running.** `/cpm:clean` invokes the classifier via  
  `${CLAUDE_PLUGIN_ROOT}/hooks/lib/progress-classify.sh list-all`, the same token the  
  38-02 safety-net convention relies on. The list-all *logic* is proven (dogfooded  
  against the real `docs/plans/` using the source path — correct CURRENT/STALE  
  inventory, companions grouped, sentinel excluded, default mode unaffected), but  
  whether the token expands in a skill-invoked Bash environment can only be confirmed by  
  republishing the plugin and running a real `/cpm:clean`. Carry forward as post-install  
  validation (flagged in retros 04 and 05 too).
- **`run-all-tests.sh` still cannot go green** because of the same  
  `test-audit-skill.sh` version drift carried since retro 04. Story-scoped suites  
  (`test-progress-classify.sh` + the hook suites) were the evidence, treating the audit  
  failure as known/unrelated.

## Recommendations

- **Feature 38 is complete — republish and run one consolidated post-install  
  validation.** All three epics (classifier + hooks, safety-net + rollout, `/cpm:clean`)  
  have landed. After republishing the plugin, in a real session confirm: (a)  
  `${CLAUDE_PLUGIN_ROOT}` resolves in skill-invoked Bash; (b) a `/cpm:*` startup runs the  
  once-per-session safety-net and presents the three-way non-blocking check; (c) an  
  active ralph loop suppresses it silently; and (d) `/cpm:clean` lists progress files +  
  compact-summary companions, and deletes only named files after confirmation.
- **Fix `test-audit-skill.sh` now — it has been flagged in three consecutive retros  
  (04, 05, 06).** Have it read the version dynamically from  
  `plugin.json`/`marketplace.json` instead of hardcoding, so `run-all-tests.sh` reflects  
  real health and stops masking regressions in the aggregate. Best done alongside the  
  feature-38 republish so the whole battery is green afterward.
- **Reuse the opt-in-mode pattern for future classifier consumers.** If another skill  
  needs a different slice of the inventory, add a mode rather than a second helper —  
  keep the one-source-of-truth contract intact.
