# Retro: Spec 50 — report disposition

**Date**: 2026-08-16  
**Source**: docs/specifications/50-spec-report-disposition.md  
**Epics**: 2/2 complete — 50-01, 50-02  
**Stories**: 6/6 complete  
**Coverage**: 30/30 rows verified across both matrices  
**Synthesised from**: the two epic docs and their coverage matrices, their story-level observations,
spec 50's Notes, discussion 33, and the run's own conduct notes. Retros 54 and 55 supplied the four
lessons consumed at the gate; this is the delivery retro for what they were applied to.

## Summary

Four dispositions — Fixed, Left alone, Unverified, Needs you — are now a seeded `taxonomy` domain,
defined once under Conversational Output in `dpm/shared/skill-conventions.md`, and *named* rather
than transcribed by eight skills. Five row-backed sites derive their report from rows they already
held; three report-only sites take the labels without the derivation. No schema file, no version
bump, no dependency. The suite ran `718 → 723 → **730**` across the two epics.

**The rule named a distinction every site already had.** That is why eight skill edits took two
passes and broke nothing: `quick`'s tri-state `met`, `review`'s `remediation_task_id`, `pivot`'s
changed-versus-unchanged split, `audit`'s `recommendation`, `do`'s existing separation of a claim
from a computation. What the rule could *not* do was supply a case none of them had — and that is
exactly where the work got interesting. `clean`'s "deleted / left" and `archive`'s "stamped /
skipped" are complete accounts of a finished run and misleading accounts of an interrupted one,
because neither pair has a slot for what the run never reached.

**Every check that could not fail passed on its first run.** All three of Story 4's cross-site
sweeps were written vacuous — a phrase-present match, a label check whose control only asserted the
fixture contained a label, a derivation check that exercised `String.replace` rather than the
reading. Twenty of the twenty-one automated criteria were green while the first real report rendered
under this epic still printed "Left alone — nothing was skipped". The criterion that found it was
the `[manual]` one.

## Observations

### Smooth Deliveries

- **Six stories, no re-planning, one real blocker and it held.** 50-01's Story 2 is blocked by  
  Story 1 because the subsection *names* a domain, and writing the prose first leaves a window in  
  which it points at nothing. Stated in the epic, respected in the run.
- **Four sites, one pass, nothing broken.** 50-02's Story 2 edited `quick`, `review`, `pivot` and  
  `audit` together because each already held the state its disposition derives from. A rule that  
  names an existing distinction is a different size of change from one that introduces it, and  
  grouping on that basis was correct at breakdown rather than in hindsight.
- **AD4's cost was paid by an existing mechanism.** Vocabulary migrations are insert-if-absent keyed  
  on `(domain, name)`, already proven with a control at `migration.test.js:188–215`, so a fifth  
  domain cost a seed edit and satisfied ENVX3 — no `.sql`, no `latestVersion()` change — without  
  anything being built for it.

### Scope Surprises

- **Replacing a two-outcome pair with a four-term vocabulary is not a relabelling.** The three  
  report-only sites had no rows to derive from, so the disposition had to come from the run itself,  
  and that exposed a state the private wordings had no room for. "Stamped and skipped" and "deleted  
  and left" both partition a *completed* run. Neither can express what an interrupted run never  
  reached. FR8 read like the cheap story and was the one that changed a meaning.
- **A requirement that closes a set at the item level does not close it at the level above.** FR3  
  says an item fitting none of the four is omitted, and its criterion was met exactly. Nothing said  
  anything about a *block* with no items, so the first report rendered under this epic printed  
  "Left alone — nothing was skipped" and "Unverified — nothing" and read as precisely the padding  
  the vocabulary exists to remove. Decided after the epic closed, in favour of omitting all four.
- **An enumeration criterion scoped to "the prose surfaces" misses the surfaces that are prose to a  
  reader and data to a runtime.** 50-01's criterion named two places that state the domain count.  
  There were four: `tools/vocabulary.js`'s taxonomy `noun` and `domain` description enumerate the  
  domains too, and are read by the model at runtime rather than by a maintainer. Widened inline to  
  "every surface"; all four fixed.
- **AD1's count was wrong and its claim was not.** The spec says 21 skills all naming Conversational  
  Output; `dpm/skills/` holds 23, of which 22 do, the exception being `ralph` — which Out of Scope  
  already excluded for an unrelated reason. The subsection still reaches every skill in scope with no  
  uses-line edited, which is the whole of what AD1 buys.

### Criteria Gaps

- **A must-NOT belongs on the epic where it has content to check, not on the epic that introduces the  
  rule.** Both of the spec's sweeps were deliberately held back from 50-01 and for different  
  reasons: FR1's *cannot* pass until `clean` and `archive` are fixed, and FR10's would pass  
  **vacuously**, because at that point no skill mentioned a disposition at all. The second is the  
  dangerous one — it goes green and looks like coverage.
- **A criterion that names an ordering does not constrain prose that defines the terms being  
  ordered.** `do` Step 8's four derivation bullets run Fixed, Unverified, Left alone, Needs you — the  
  order the derivation falls out in — while the sentence above them requires `position` order, which  
  puts Left alone second. Both are correct and they disagree on the page. Raised at the `[manual]`  
  gate and left as it stands, recorded in the epic's Notes so a later reader knows it was seen.

### Codebase Discoveries

- **`tools/vocabulary.js` enumerates the taxonomy domains in its tool descriptions**, which makes it  
  an enumeration surface that no "update the docs" instinct reaches: it looks like prose and is read  
  by the model on every call.
- **Nothing in the suite pins a taxonomy row or a domain count**, which is what makes adding a domain  
  a seed edit. The same property means a wrong seed would not be caught by anything except a test  
  written for it.
- **The `disposition` domain gains no CHECK pin, and this is accepted rather than overlooked.** Pins  
  are constraints on referring columns; this domain has none, so a project could hold a term nothing  
  validates against. Recorded in AD4 as a cost, repeated here because the first referring column to  
  arrive is the moment to revisit it.
- **23 skills, 22 naming Conversational Output, `ralph` the sole exception.** Story 2's test asserts  
  against the tree rather than against either number and names `ralph` explicitly, so a second  
  exception cannot join it silently.

### Testing Gaps

- **A must-NOT that cannot be handed a broken corpus is a must-NOT nobody has checked.** All three  
  of Story 4's sweeps passed on their first run, which is what a vacuous sweep looks like. The fix  
  was the same move each time: extract the *reading* into a function taking a `read(skill)`  
  callback, then drive it against a corpus with the defect planted. Until the reading is separable  
  from the corpus, there is nothing to point at a broken one.  
  **Retired 2026-08-16**: promoted to the library document *Promoted Retro Lessons*, under "A check  
  that passes may be passing for a reason other than the one you want", where it is stated together  
  with retro 42's criterion-level form of the same rule.
- **The only criterion that found a defect was the one no assertion could reach.** Twenty-one  
  automated criteria across two epics were green over a report that read as padding. FR4's  
  `[manual]` read is the only criterion that tests the goal rather than the mechanism, and it was  
  worth the whole of the rest.
- **A control mutation needs a revert that cannot take the tree with it.** This run used  
  `git checkout` to undo one, which discards whatever else is uncommitted; the correction was to  
  copy the file to the scratchpad and `cp` it back. The run also made programmatic edits to files  
  rather than using the Edit tool. Both breach the shared Implementation Guidelines, both were  
  caught mid-run and written into the progress file as conduct notes, and both are worth naming here  
  because a control mutation is exactly the moment the reflex reaches for `git`.  
  **Retired 2026-08-16**: promoted to the library document *Promoted Retro Lessons*, under "A control  
  mutation needs a revert that cannot take the tree with it".

### Patterns Worth Reusing

- **Express the disposition by the reader's obligation, not by its label.** This let `do` satisfy  
  FR6 and FR10's must-NOT in a single paragraph: the derivation reads naturally *without* the four  
  strings, so the vocabulary stays in the domain where a project can extend it. Writing the labels  
  out would have satisfied one requirement by breaking the other.
- **Cite the domain and read its terms — in the skills and in the tests alike.** Story 1's tests read  
  the database through `list_taxonomy` rather than re-reading the seed module, so the seed cannot  
  pass by agreeing with itself; the sweeps derive their expectations from `VOCABULARIES` rather than  
  from a transcribed list.
- **A shared test helper that four suites delegate to needs its own direct test.**  
  `domainTerms(domain)` and `dispositionProblems(body, label)` in `tests/support/vocabulary.js`  
  replaced two independent derivations and four copies of the same checks. A helper that quietly  
  stopped looking would leave every caller green, so `vocabulary.test.js` tests the helpers  
  themselves.
- **Pair every naming check with its complement.** Containment proves only that the three edited  
  skills were edited. The sweep that earns its place is the one asking whether any disposition-like  
  wording survives *anywhere else* in the corpus, outside the domain.
- **Write the replacement as a replacement.** `clean:86` and `archive:136` had their private wordings  
  removed rather than supplemented, and that is the only reason Story 4's first sweep means  
  anything. An addition alongside a survivor passes the addition's test and fails the point.

## Recommendations

- **At breakdown, ask of every must-NOT: what would make this pass for the wrong reason today?**  
  FR10's sweep on 50-01 would have been green and empty. The question sorts sweeps onto the epic  
  that gives them content, and it is cheaper than discovering it from a passing suite.
- **When a spec closes a set, ask what the next level up does with an empty one.** FR3 closed the  
  item level and the block level went unstated, which cost a post-close decision and a paragraph of  
  convention. Any rule of the form "anything outside the set is omitted" has a container.
- **Before trusting a corpus sweep, plant the defect.** The three written here were indistinguishable  
  from working ones until a broken corpus existed to hand them. Budget the fixture, not just the  
  assertion.
- **Grep for enumeration surfaces the runtime reads, not just the ones a maintainer reads.** Tool  
  descriptions, `noun` fields and schema comments all state facts about the system, and only some of  
  them are anybody's idea of documentation.
- **Keep the `[manual]` criterion, and run it.** It found the one thing twenty-one automated criteria  
  could not. A spec whose manual criteria each state *what blocks automation* — as this one's do —  
  makes that gate a step rather than a formality.
- **The CPM equivalent is deferred and now has evidence.** Spec 50's Deferred entry said it would be  
  informed by whatever this one got wrong. Three things: the block-level omission rule, the vacuous  
  sweep, and the report-only sites needing a case their private pairs could not express. CPM's  
  `clean` and `archive` carry the same proto-dispositions.
