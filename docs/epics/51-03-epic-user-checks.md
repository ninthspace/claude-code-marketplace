# User checks for spec 51

**Source spec**: docs/specifications/51-spec-full-suite-when-justified.md  
**Date**: 2026-11-09  
**Status**: Pending  
**Blocked by**: Epic 51-02-epic-release  
**Amended**: review 08 (docs/reviews/08-review-targeted-runs.md) — rewritten with an exact fixture, a fixed story order, controls and exact expected counts (2026-11-09)

These checks are carried out by the user after release; `do` writes each `Evidence` line only from the user's answer. They share one fixture. A scratch Laravel app, made with `laravel new scratch51 --pest` and committed. It has `app/Support/Money.php` (`Money::format(int $pence): string`, returning `£1.00` for 100), used only by `app/Presenters/InvoicePresenter.php`, which only `app/Http/Controllers/InvoiceController.php` uses, on the route `GET /invoices/{id}`. It has a feature test `tests/Feature/InvoicePageTest.php`, asserting the page shows `£1.00`, a unit test `tests/Unit/InvoicePresenterTest.php`, which mocks `Money`, and `tests/Unit/MoneyTest.php`. It holds two epics, written with `/cpm-next:plan`:

- **Epic A**, four stories in this order:
  1. A new `GET /ping` route and invokable `PingController` with a feature test.
  2. A new `UserObserver` registered on `User`, with a test.
  3. `Money::format` changed to return `1.00 GBP`, with its own unit test updated.
  4. A new `GET /health` route and `HealthController` with a feature test.
- **Epic B**, two stories: 1, a new `GET /version` route with a feature test; 2, a new `GET /about` route with a feature test.

## Runs are chosen per story in an installed release
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR2, FR4, FR5, FR6, FR7, FR10

**Acceptance Criteria**:

- The user runs `/cpm-next:do {Epic A}`, then reads Story 1's `**Test run**` line.
  - Observation: it reads `targeted`, maps `app/Http/Controllers/PingController.php` (and `routes/web.php` only if listed as narrow) to the ping test, and shows a passed count equal to that test file's tests.
  - Control: the line does not read `none`, and its count is not zero `[user]`
- Story 2's `**Test run**` line.
  - Observation: it reads `full` with the reason `wide reach: app/Observers/UserObserver.php (observer)`, or the provider that registers it.
  - Control: Story 1's line, from the same run, reads `targeted` `[user]`
- Story 3's `**Test run**` line.
  - Observation: it reads `targeted`, mapping `app/Support/Money.php` to its own unit test and to the tests that reach it through one caller (`InvoicePresenterTest` does not count, since it mocks `Money`).
  - The feature test `InvoicePageTest`, two callers away, is not in the set, so Story 3 closes with that test failing unseen. If Story 3's audit instead reports `InvoicePageTest` as a test that runs a changed file but was left out, and the failure is found and fixed in Story 3, the user records that outcome: it is correct too, and check 4's failure then does not occur `[user]`
- Story 4's `**Test run**` line and its audit.
  - Observation: Story 4 closes its epic, so its line reads `full` with the reason `closes epic`, and its run shows `InvoicePageTest` failing.
  - The fix to `Money` (or to the test) is made under Story 4, named in its audit prompt with that test (seen in the transcript's auditor call), and Story 4 closes on a passing full run `[user]`
- At the end of that run, the **Changed** heading.
  - Observation: the full and targeted counts equal the sum of the four stories' `**Test run**` counters, plus 1 full for the baseline.
  - Control: Stories 1 and 3 add no full runs unless their lines name an FR3 or audit reason `[user]`
- The user runs `/cpm-next:do {Epic B, Story 1}` alone.
  - Observation: the run makes one full run (the baseline), and Story 1 closes on a `targeted` run.
  - Control: its line's counter shows 0 full `[user]`
- The user edits only an `Evidence` line of Epic B Story 1 by hand, then runs `/cpm-next:do {Epic B, Story 2}`.
  - Observation: the baseline result from the conversation, or a fresh baseline, and Story 2 (which closes Epic B) reading `full` with `closes epic`.
  - Then the user asks `do` to re-check Story 2 without changing a code file. The observation is no new run, since its snapshot hash is unchanged.
  - Control: after a one-character edit to `HealthController.php`, the same request makes a new run `[user]`

### Run the checks
**Task**: 1.1  
**Description**: Carried out by the user; `do` writes the `Evidence (user, …)` lines from their answers.  
**Status**: Pending

---
