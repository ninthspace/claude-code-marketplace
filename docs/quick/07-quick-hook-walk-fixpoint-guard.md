# The repository walk cannot outlive its exit condition

**Number**: 07  
**Status**: complete — Closed. All five criteria met; four settled by the suite, one by construction with the reason recorded in the source.  

**Closed**: 2026-08-27T15:40:00.000Z  

## What changes, and why it is a backstop

`repositoryAbove()` walks upward from the resolved database directory looking for a `.git`, and stops on `directory === root`, where `root` came from `parse(absolute)`. That is one exit condition for a loop with no other, so the walk is only bounded for as long as `dirname` is guaranteed to reach exactly the string `parse().root`.

**The guard.** Compute `const next = dirname(directory)` in the loop body and `return null` when `next === directory`, continuing on `next` otherwise. The root comparison stays as the ordinary exit; the fixpoint comparison is the backstop underneath it.

**Files affected.** `src/server/hook-check.js` only. No test file changes.

## What the assessment found, because it changes what this record claims

No constructible input reaches the spin. Across `win32` — UNC `//server/share`, `\\?\C:\a`, `\\.\pipe\x`, bare `C:`, rooted-without-drive `/a/b` — and across `posix` — `//foo/bar`, `//`, `/` — `parse(resolve(p)).root` equals the `dirname` fixpoint in every case.

UNC is the form that looks like it should diverge, because `parse().root` carries a trailing separator: `\\server\share\`. But `dirname('\\server\share\dir')` returns `\\server\share\` with that separator, so the existing comparison fires and the walk ends where it should.

So this is a hardening change and not a fix, and the record says so rather than claiming a repair it did not make. What it buys is that the loop's termination stops depending on a coincidence between two path functions that were never specified to agree.

**One consequence worth stating.** Nothing can drive the new branch through `unguardedMessage`, because no input makes the two exits disagree. It ships asserted by reading rather than by a test, which is why one of the criteria is that the source says so — an uncovered line with no explanation reads either as dead code to delete or as a gap somebody forgot to close, and it is neither.

## The alternative that was declined

The fixpoint check subsumes the root check: made the sole exit, it would drop `parse` and `root` from the module, be reachable, and be shorter. It was offered at the gate and not taken, because it is a different change from the one asked for.

## What changed, and how it was verified

One file, `src/server/hook-check.js`, and one function.

`repositoryAbove()`'s `for` loop lost its update expression. The body now computes `const next = dirname(directory)` after the two existing exits, returns `null` when `next === directory`, and assigns `directory = next` otherwise. Every iteration therefore either finds a `.git`, reaches `root`, or advances to a strictly different string — and a chain of strictly different strings under `dirname` is finite, which is the whole of the termination argument.

## The doc comment had to change too, and not only to add a paragraph

The paragraph above the function said `resolve` was the line that ends the loop, "the loop has no other stopping condition". That was true when it was written and stopped being true the moment the guard landed: an unresolved `.dpm` now terminates on the fixpoint and returns `null`.

`resolve` is still load-bearing, for a different reason, and the comment now says that reason instead. Walked unresolved, the `.dpm`, `.`, `.` chain never reaches a `.git` — so without `resolve` the function returns `null` for a database that is plainly inside a repository. It is the difference between a wrong answer and no answer, and `tests/hook-check.test.js`'s relative-path case is what holds it.

A new paragraph records the path forms that were checked and states that the second exit is deliberately uncovered.

## Verification

- `node --test tests/hook-check.test.js` — 7 of 7 pass, file unchanged.
- `npm test` — 882 tests, 882 pass, 0 fail.

The first criterion is the one no test settles. It is met by construction and recorded as such: the branch cannot be driven, because no input makes `parse(resolve(p)).root` and the `dirname` fixpoint disagree. Asserting it would have meant reaching past the public function into a stub, which buys a green tick and no confidence.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | repositoryAbove() terminates on any input, including one whose dirname reaches a fixpoint that is not parse().root. | Met by construction rather than by a test, and deliberately so. The loop body now computes `next = dirname(directory)` and returns null when it equals `directory`, so every iteration either finds a `.git`, hits `root`, or advances to a strictly different string — and a chain of strictly different strings under `dirname` is finite. No input drives the new branch, which is why it is asserted by reading; the reason is in the source. |
| ✓ | The ordinary walk is unchanged: a database directory under a repository still returns that repository root, and one outside any repository still returns null. | Settled by the existing suite: "a database outside any repository is not reported, and the same directory inside one is" passes, and it is the paired control that turns the null back into a sentence. The root comparison still runs first, so the ordinary walk reaches the same answer by the same route. |
| ✓ | tests/hook-check.test.js passes unchanged, including the relative-path case that the resolve() line exists for. | tests/hook-check.test.js: 7 of 7 pass, unchanged, including "a relative database directory is answered, because the default one is relative" — the case that keeps resolve() load-bearing now that termination no longer depends on it. |
| ✓ | The full dpm suite passes. | npm test: 882 tests, 882 pass, 0 fail. |
| ✓ | The unreachability of the new branch is recorded in the source, so a future reader does not mistake it for dead code to delete or for a line missing a test. | The doc comment carries a "Two exits, and the second one cannot be driven" paragraph naming the path forms checked and saying the branch is deliberately uncovered rather than untested. The paragraph above it was also corrected: resolve() was previously documented as the thing that ends the loop, which stopped being true the moment the fixpoint guard landed — it is now documented as what makes the search look in the right place. |
