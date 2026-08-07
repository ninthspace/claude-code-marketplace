# Retro: Change-Set Resolution

**Date**: 2026-07-25
**Source**: docs/epics/42-01-epic-change-set-resolution.md
**Stories**: 3/3 complete

## Summary

Spec 42's first epic: synthetic git-repository fixtures, the change-set structure both resolution directions converge on, git-anchored (reverse) resolution, and the intent-adapter contract with forward resolution against a stub. Three new suites — 27, 22 and 17 assertions, all 1:1 — and 27 suites green overall.

Three defects were found after their tests were green, by three different means: a follow-up check, a human reading the code, and a deliberate end-to-end read. None was findable by any assertion in the suite that covered the criterion.

## Observations

### Criteria Gaps

- **A criterion that names a thing without naming what it is measured against will be satisfied by the wrong reading.** R1 says "a branch" is a selector; the story criterion says a branch name "resolve[s] to a change-set structure". Both are silent on what a branch is measured *against*, and the readings differ by most of the repository. Resolution measured against the default branch tip, wrote seven assertions, and they all passed — because the fixture's branch was cut from `main`, where default-branch and fork-point semantics coincide. Chris read the code and named the correct rule: the change between the branch head and where it split. The stacked-branch case that distinguishes them (`feature/b` cut from `feature/a`, where measuring against `main` reports the parent branch's commits as this branch's own) existed in neither the criterion nor the fixture. **The fixture only exercised the case where the two readings agree, which is why the tests could not arbitrate between them.** Two lessons, and the second is the transferable one: when a criterion admits more than one reading, the fixture must contain the case that separates them, or the suite is testing the implementation's assumption rather than the requirement.

### Testing Gaps

- **An equality assertion between two things needs a preceding assertion that they are two things.** `git_fixture_create` numbered repositories from a shell counter, but the intended call form `repo=$(git_fixture_create x)` runs the function in a *subshell*, so the counter never advanced in the caller and every call returned the same path. The determinism test compared a repository against itself, and passed. The failure was visible only as stray `nothing to commit` output from a `git commit` nobody was watching. This is the same shape as retro 18's absence-assertion lesson — "gone as intended" versus "gone too far" — one level up: an equality that holds trivially is indistinguishable from an equality that holds meaningfully unless something asserts the operands are distinct. The fix was `mktemp -d`, and the guard is a follow-up check that two creates yield different directories.

- **Tests written from criteria cover the outcomes the criteria name, and contracts have more branches than that.** The adapter contract has three exit codes — answered, cannot-answer, error. Story 3's criteria name the first two, so the suite exercised the first two, and `changeset_intent_answerable` treated an *erroring* adapter as having answered. That would let a broken adapter turn "not answerable" into "none found" — precisely the conflation R4 exists to prevent, two epics before R4 is implemented. A criteria-derived suite is complete with respect to the criteria and silent about everything else the code can do.

### Patterns Worth Reusing

- **The end-to-end read at the gate is now five-for-five.** Retro 15 proposed it, 16 and 17 confirmed it, 19 applied it, and here it found the answerability defect above in a file whose suite was 14/14 green. Retro 17 argued it should stop being a per-epic disposition and become part of the verification gate itself; that case is now stronger, and it is worth noting *what* it catches: in every instance the defect was a claim in prose or in a branch that no assertion had a reason to reach.

- **Making a shared property true by construction beats asserting it in two places.** R2 requires an intent-anchored run and a git-anchored run over the same commits to yield the same file set. Rather than assert it of two implementations, both directions derive files from commits through one `changeset_emit_from_commits`, and the file set is the union of what the commits touched rather than the range's net diff — which makes it a *pure function of the commit set*. The criterion is then true by construction, and the byte-identical assertion is a regression net rather than the guarantee. The same move settled ordering: adapter return order is normalised through `git rev-list --no-walk` before emitting, so an adapter's internal ordering can never reach the structure.

- **A stub that knows nothing is what proves a contract.** The intent stub resolves selectors from a lookup table and knows nothing of git, trailers or CPM documents. A stub that understood commit trailers would have been an early draft of Epic 42-02's git-native adapter, and the suite would have been making claims about that adapter instead of about the interface. Keeping it ignorant is what makes "an adapter needs to supply only SHAs and an answerability signal" a demonstrated claim rather than an intended one.

- **Deciding a contract question two epics early cost one return channel.** The adapter contract carries `exit 2` (cannot answer) from the start, which nothing in Epic 42-01 needs — empty still errors. It exists because 42-03's R4 requires "none found" and "not answerable" to render differently, and a commits-only contract cannot express that. Adding it later would have reopened the contract this story exists to freeze, *after* 42-02 implemented against it. Surfaced at the `[plan]` gate rather than discovered at 42-03's.

## Recommendations

- **Epic 42-02 inherits a frozen contract; read `changeset-intent.sh`'s header before writing either adapter.** Three things it fixes that an adapter author would otherwise guess: order is not part of the contract, the selector is opaque and must not be parsed, and `exit 2` is not an error.
- **Reverse resolution (files → intent) is 42-02's, and R2 is only half-covered here.** Both coverage matrices record it. Step 4's cross-epic check is where R2 is confirmed complete — neither matrix may be read as covering it alone.
- **When 42-02 builds real adapters, extend the fixtures rather than the stub.** `git-fixture-helpers.sh` already produces all four shapes AD2's git-native adapter parses — trailers, conventional subjects, branch names, co-commits — and its vocabulary was fixed in Story 1 specifically so 42-02 would not have to grow it.
- **Add the stacked-branch case to any future selector work.** The fork-point rule is now asserted, but the general lesson stands: a fixture whose branch is always cut from `main` cannot distinguish default-branch semantics from fork-point semantics, and the same blind spot will exist for any rule about branch relationships.
