#!/bin/bash
# test-environmental-deferral.sh — Epic 46-01 Story 3: a Scope deferral cannot exclude an
# environmental constraint.
#
# Asserts the three [integration] acceptance criteria of "A Scope deferral cannot exclude
# an environmental constraint". Under test is the guard in coverage-rollup.sh's
# rollup_emit_derived, which decides which requirements leave the untraced count.
#
# --- What spec 46 changed, and what it deliberately did not ----------------------
#
# There are two routes out of the count, because cpm:spec writes "not this iteration" in
# two places: the Won't Have MoSCoW heading, and a `### Deferred` bullet under `## Scope`.
# FR6 closes the second route to environmental constraints only. An ENV1 the spec defers
# in a Scope sentence is still a fact about the host -- the host does not acquire PHP 8.2
# because a paragraph said the requirement could wait -- so it stays untraced and the
# spec cannot report itself delivered over the top of it.
#
# The Won't Have route stays open, and that is the point of AD2 rather than an oversight.
# It is the explicit ruling-out, written where a reader looks for one. The Scope route is
# the quiet one, and only the quiet one is closed.
#
# --- Why the controls carry the weight -------------------------------------------
#
# Retro 23, applied as this epic's plan asked. The positive criterion is satisfied by a
# guard that excludes nothing at all: delete the whole `deferred` disjunct and ENV1 is
# untraced, exactly as asserted. Only the two controls tell that apart from the change
# actually wanted --
#
#   * an ordinary NFR1 deferred by the identical Scope bullet is still EXCLUDED, so the
#     Scope route was narrowed rather than removed;
#   * an ENVX1 under Won't Have is still EXCLUDED, so the narrowing did not leak into the
#     route AD2 keeps open.
#
# One fixture spec serves all three, deferring NFR1 and ENV1 in the same bullet. Two
# fixtures would let the two labels differ in something other than their prefix, and the
# prefix is the whole of what the guard reads.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

ROLLUP_SRC="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing the Scope-deferral guard against environmental constraints (Epic 46-01 Story 3)"

excluded_labels() {
  printf '%s\n' "$1" | awk -F'\t' '$1 == "EXCLUDED" { print $2 }' | LC_ALL=C sort
}

# --- Fixture ----------------------------------------------------------------------
#
# NFR1 and ENV1 are deferred by one Scope bullet, so nothing distinguishes them but the
# prefix. FR9 is a Should Have deferred the same way -- the behaviour that existed before
# spec 46 and must survive it.
#
# ENV2 and ENVX1 sit under Won't Have, the route that stays open. Both classes are there
# rather than one: the criterion is written about an `ENV1`-shaped label, and a fixture
# carrying only the restriction would leave the requirement class verified by analogy. ENV2
# is a second requirement-class label because ENV1 is already spoken for by the Scope route,
# and one label cannot sit under two MoSCoW headings.
#
# FR1 is covered by a matrix row and exists only so the run has a delivered requirement in
# it: a spec where every label is excluded or untraced would let a catastrophically broken
# guard still look plausible.

DEFERRED_BULLET="NFR1, ENV1, FR9 — deferred to a later iteration."

FIX_DIR=$(coverage_fixture_dir env-deferral)

SPEC=$(coverage_fixture_spec 46-spec-env-deferral --dir "$FIX_DIR" \
  --must FR1 "a requirement covered by the matrix" \
  --should FR9 "a should-have the spec defers in its Scope section" \
  --nfr NFR1 "an ordinary non-functional requirement, deferred alongside ENV1" \
  --nfr ENV1 "PHP 8.2 or later available on the target host" \
  --wont-labelled ENV2 "a redis instance available, explicitly ruled out for this iteration" \
  --wont-labelled ENVX1 "must not require a queue worker" \
  --deferred "$DEFERRED_BULLET")

MATRIX=$(coverage_fixture_matrix 46-01-coverage-env-deferral \
  "docs/specifications/46-spec-env-deferral.md" \
  --dir "$FIX_DIR" \
  --row FR1 "a requirement covered by the matrix" "the covering criterion" "Story 1" '✓')

OUT=$(coverage_rollup_run --spec "$SPEC" --matrix-dir "$FIX_DIR")

# Non-vacuity first. Every assertion below reads STATE and EXCLUDED records; if the run
# produced neither, an absence-assertion would pass on an empty string.
test_start "control: the run found its matrix"
assert_equals "1" "$(coverage_count_type "$OUT" MATRIX)"

test_start "control: the run emitted the requirements to reason about"
assert_equals "6" "$(coverage_count_type "$OUT" REQ)"

test_start "control: FR1 is delivered, so the guard did not exclude everything"
assert_equals "FR1" "$(coverage_states_in "$OUT" delivered)"

# The fixture only proves anything if both labels really are in the same bullet. Asserted
# against the written document rather than against the variable, so a builder that dropped
# the option cannot leave the controls comparing nothing.
test_start "control: NFR1 and ENV1 are deferred by one and the same Scope bullet"
assert_contains "$(cat "$SPEC")" "$DEFERRED_BULLET"

# --- Criterion 1: a Scope-deferred ENV1 stays untraced --------------------------------

test_start "ENV1 named in a ### Deferred bullet is left untraced"
assert_equals "ENV1" "$(coverage_states_in "$OUT" untraced)"

test_start "and it is not excluded"
assert_not_contains "$OUT" "$(printf 'EXCLUDED\tENV1\t')"

# The count is what a consumer acts on. cpm:ralph reads a non-zero untraced count as
# "phase 1 unfinished" and --verdict exit 3 as "work remains"; an ENV1 that left the count
# would hand back the false-clean result spec 46 exists to prevent.
test_start "the untraced count reflects it"
assert_equals "1" "$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "SUMMARY" { print $4 }')"

test_start "--verdict reports outstanding work rather than done"
assert_equals "3" "$(coverage_rollup_rc --spec "$SPEC" --matrix-dir "$FIX_DIR" --verdict)"

# --- Criterion 2 (control): the same bullet still excludes an ordinary NFR --------------

test_start "control: NFR1, deferred by that same bullet, is still excluded"
assert_contains "$OUT" "$(printf 'EXCLUDED\tNFR1\tNon-Functional')"

test_start "control: and a Should Have deferred the same way is still excluded"
assert_contains "$OUT" "$(printf 'EXCLUDED\tFR9\tShould Have')"

# --- Criterion 3 (control): the Won't Have route is untouched ---------------------------

test_start "control: an environmental requirement under Won't Have is still excluded"
assert_contains "$OUT" "$(printf 'EXCLUDED\tENV2\tWon')"

test_start "control: and so is an environmental restriction"
assert_contains "$OUT" "$(printf 'EXCLUDED\tENVX1\tWon')"

# The two routes stated as one comparison, over labels of the *same* class. ENV1 and ENV2
# are both environmental requirements and differ only in the route that reaches the guard;
# asserting them separately would pass for a guard keyed on something other than the route
# -- the class, say, or the heading alone.
test_start "the class alone does not decide it: the route does"
assert_equals "untraced/excluded" "$(
  printf '%s\n' "$OUT" | awk -F'\t' '
    $1 == "STATE"    && $2 == "ENV1" { a = $4 }
    $1 == "EXCLUDED" && $2 == "ENV2" { b = "excluded" }
    END { printf "%s/%s", a, b }
  '
)"

test_start "exactly the four labels the spec ruled out by a permitted route are excluded"
assert_equals "$(printf 'ENV2\nENVX1\nFR9\nNFR1')" "$(excluded_labels "$OUT")"

# --- NFR4: the partition still holds ----------------------------------------------------
#
# Spec 44's property, which FR6 changes the exclusion rules underneath: every requirement
# is in exactly one of STATE and EXCLUDED. Asserted from the records rather than from the
# parser's intent, so a label that fell out of both -- the silent-drop failure mode -- is
# caught here even if no assertion above named it.

test_start "REQ = STATE ∪ EXCLUDED is an exact partition with the new guard in play"
assert_empty "$(coverage_partition_errors "$OUT")"

# --- Retro 27: the prose and the guard state the same rule ------------------------------
#
# coverage-rollup.sh explains its exclusion rules in a header comment and then implements
# them in awk thirty lines later. Task 3.1 changed the implementation, which is the moment
# the explanation goes stale. This does not verify the prose is *correct* -- no assertion
# can -- only that it was not left describing the previous behaviour.

ROLLUP_TEXT=$(cat "$ROLLUP_SRC")

test_start "the header comment records that an environmental constraint survives Scope deferral"
assert_contains "$ROLLUP_TEXT" "Nor is an environmental constraint"

test_start "the guard consults the shared predicate rather than a prefix of its own"
assert_contains "$ROLLUP_TEXT" "!cov_is_environmental(label)"

test_start "control: no environmental prefix is restated in the roll-up"
assert_not_contains "$ROLLUP_TEXT" '"ENVX"'

test_summary
