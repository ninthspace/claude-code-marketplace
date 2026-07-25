#!/bin/bash
# test-linkset-cross-adapter.sh — Tests both real adapters running together.
#
# These back Epic 42-02 Story 6's `[integration]` acceptance criteria (spec 42 R7,
# cross-adapter behaviour).
#
# **Every other suite in this epic proves a property one adapter at a time.** Story 4
# proved precedence with stubs, which can be made to emit anything; Stories 2 and 3 each
# exercise their own adapter in a repository the other has little to say about. None of
# them reaches the case where `gitnative` and `cpm` resolve the *same* (file, intent) pair
# from different channels at different confidences — and that handoff is where a defect
# would live, because it is the only place the two adapters' output has to be reconciled
# rather than merely concatenated.
#
# --- What the fixture is built to contain --------------------------------------------
#
# One repository carrying a contested pair in **each direction**, so that neither adapter
# can win by identity:
#
#   commit 1  `Refs: epic 42-01`, touching the 42-01 epic doc, its coverage matrix,
#             and src/resolve.sh
#             gitnative : src/resolve.sh → epic 42-01   declared  (trailer)
#             cpm       : src/resolve.sh → epic 42-01   derived   (co-commit)
#
#   commit 2  `fix(epic 42-02):`, touching the 42-02 epic doc and src/join.sh
#             gitnative : the 42-02 doc  → epic 42-02   derived   (subject scope)
#             cpm       : the 42-02 doc  → epic 42-02   declared  (the doc is the record)
#
#   commit 3  a plain subject, no trailer, no epic doc, touching src/orphan.sh
#             neither adapter has anything to say
#
# In the first, git carries the declaration; in the second, CPM does. A join that
# preferred an adapter rather than a confidence would pass one and fail the other, which
# is why both are here and why neither is sufficient alone. The third is the control on
# both: without a file neither channel reaches, every assertion about *which* links exist
# would hold equally over a join that linked everything to something.
#
# The coverage matrix in commit 1 is what supplies the CRITERION records, and it carries
# one verified row and one unverified row against a story its epic doc marks Complete —
# R4's gap in miniature, and a shape only the CPM adapter can produce.
#
# --- On the third criterion ------------------------------------------------------------
#
# Story 6's third criterion reads "Disabling one adapter changes which links are present
# but never their labels". Taken literally that is unsatisfiable by any correct
# implementation, and the fixture above shows why: with both adapters active
# `src/resolve.sh → epic 42-01` is **declared** because git's trailer says so, and with
# `gitnative` disabled it is **derived**, because the only remaining evidence is a
# co-commit. The label changed. It had to — Story 4's criterion is "a declared marker
# always wins over a derived one for the same (file, intent) pair", and whether a declared
# marker exists is exactly what disabling an adapter decides. A join that held labels fixed
# across adapter sets would be one that had stopped resolving precedence across adapters,
# which is the property this story exists to prove.
#
# So the criterion is verified as the property it was reaching for, in two parts:
#
#   **Adapter-output stability** — an adapter's own emitted triples are identical
#   whether or not its peer is registered. No adapter changes its judgement based on
#   what company it keeps; that is the sense in which a label is never affected.
#
#   **Monotonicity** — removing an adapter only ever removes links or weakens a surviving
#   pair. It never strengthens one and never invents one. Evidence can accumulate; it
#   cannot be manufactured by taking a channel away.
#
# Together those say what the criterion meant and are checkable against the real join.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/link-adapter-git.sh"
source "$SCRIPT_DIR/../lib/link-adapter-cpm.sh"
source "$SCRIPT_DIR/../lib/inspect-record.sh"

echo "Testing both real adapters running together..."
echo ""

TAB="$LINKSET_TAB"

# Registration and the join are two functions rather than one, and deliberately so: the
# obvious `join_with gitnative cpm` helper has to be called inside a command substitution
# to capture its output, which runs it in a subshell — so every `linkset_register` it made
# would be discarded, and the parent would still hold whatever registry it had before.
# `inspect_json` reads that registry to fill the record's `adapters` array, so the two
# byte-identity tests below would then be comparing two documents that both named *no*
# adapters, and would agree for exactly the wrong reason.
use_adapters() {
  linkset_reset
  local a
  for a in "$@"; do linkset_register "$a"; done
}

join_now() {
  linkset_join "$REPO" "$CHANGESET"
}

# The resolved confidence for one (file, intent) pair, or `none`.
conf_for() {
  local out="$1" path="$2" id="$3" c
  c=$(printf '%s\n' "$out" | linkset_links \
    | awk -F'\t' -v p="$path" -v i="$id" '$1 == p && $2 == i { print $3 }')
  printf '%s\n' "${c:-none}"
}

# Every pair the join resolved, as `path<TAB>intent<TAB>confidence`.
pairs_of() {
  printf '%s\n' "$1" | linkset_links | LC_ALL=C sort
}

# Monotonicity: no pair in the subset may be absent from the full join, and none may
# carry a *stronger* confidence there than it does with every adapter active.
#
# Returns the offending lines on stdout, empty if the subset is well-behaved.
monotonicity_breaches() {
  local full="$1" subset="$2"
  printf '%s\n' "$full" > "$TEST_TMPDIR/mono-full"
  printf '%s\n' "$subset" | LC_ALL=C awk -F'\t' -v full="$TEST_TMPDIR/mono-full" '
    function rank(c) { return c == "declared" ? 2 : 1 }
    BEGIN {
      while ((getline line < full) > 0) {
        n = split(line, f, "\t")
        if (n < 3) continue
        fullconf[f[1] "\t" f[2]] = f[3]
      }
      close(full)
    }
    NF >= 3 {
      key = $1 "\t" $2
      if (!(key in fullconf)) {
        printf "INVENTED: %s (%s) appears with fewer adapters\n", key, $3
        next
      }
      if (rank($3) > rank(fullconf[key]))
        printf "STRENGTHENED: %s is %s with fewer adapters, %s with all\n", key, $3, fullconf[key]
    }
  '
}

# --- Fixture -----------------------------------------------------------------------------

REPO=$(git_fixture_create cross-adapter)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)

# Commit 1 — git declares (trailer), CPM derives (co-commit).
git_fixture_commit "$REPO" "chore: land the resolver" --trailer "Refs: epic 42-01" -- \
  "docs/epics/42-01-epic-change-set-resolution.md" "# Change-Set Resolution

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Status**: Complete

## Resolve a change set from a selector
**Story**: 1
**Status**: Complete
**Satisfies**: R1, AD5
" \
  "docs/epics/42-01-coverage-change-set-resolution.md" "# Coverage Matrix: Change-Set Resolution

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | R1 | A selector resolves to a change set. | An epic selector resolves to the commits that epic produced | Story 1 | \`[unit]\` | ✓ |
| 2 | AD5 | Resolution order is selector-shaped. | A bare ref resolves without consulting any planning document | Story 1 | \`[unit]\` |  |
" \
  "src/resolve.sh" "resolve"

# Commit 2 — git derives (subject scope), CPM declares (the document is the record).
git_fixture_commit "$REPO" "fix(epic 42-02): adjust the join" -- \
  "docs/epics/42-02-epic-intent-adapters.md" "# Intent Adapters

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Status**: Pending

## Join the adapters
**Story**: 1
**Status**: Pending
**Satisfies**: R7
" \
  "src/join.sh" "join"

# Commit 3 — no epic doc, no trailer, no scope. Neither adapter has anything to say, which
# is what keeps the assertions below from being satisfied by a fixture where everything
# happens to be linked.
git_fixture_commit "$REPO" "tidy up the stray helper" -- "src/orphan.sh" "orphan"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"

use_adapters gitnative cpm; BOTH=$(join_now)
use_adapters gitnative;     GIT_ONLY=$(join_now)
use_adapters cpm;           CPM_ONLY=$(join_now)

EPIC1_DOC="docs/epics/42-01-epic-change-set-resolution.md"
EPIC2_DOC="docs/epics/42-02-epic-intent-adapters.md"

# --- Criterion: precedence applied across adapters, not within one ----------------------

# The fixture only tests anything if it really does contain a pair each adapter resolves
# differently. Asserted first and on its own, because every assertion after it would pass
# vacuously against a fixture where the two adapters never meet.
test_start "the fixture contains a contested pair in each direction, one per adapter"
assert_equals "derived declared|declared derived" \
  "$(conf_for "$CPM_ONLY" src/resolve.sh 'epic 42-01') $(conf_for "$GIT_ONLY" src/resolve.sh 'epic 42-01')|$(conf_for "$CPM_ONLY" "$EPIC2_DOC" 'epic 42-02') $(conf_for "$GIT_ONLY" "$EPIC2_DOC" 'epic 42-02')"

test_start "a trailer in git upgrades a pair CPM only derived"
assert_equals "declared" "$(conf_for "$BOTH" src/resolve.sh 'epic 42-01')"

test_start "a CPM document upgrades a pair git only derived"
assert_equals "declared" "$(conf_for "$BOTH" "$EPIC2_DOC" 'epic 42-02')"

# The two above resolve in opposite directions, so a join that preferred whichever adapter
# was registered first — or last — would fail one of them. Stated as its own assertion
# because "declared wins" and "this adapter wins" are indistinguishable from either alone.
test_start "the winner is the stronger confidence, not a fixed adapter"
assert_equals "gitnative cpm" \
  "$([ "$(conf_for "$GIT_ONLY" src/resolve.sh 'epic 42-01')" = declared ] && echo gitnative) $([ "$(conf_for "$CPM_ONLY" "$EPIC2_DOC" 'epic 42-02')" = declared ] && echo cpm)"

# Enumerated in full rather than grepped for a single row: Story 3's defect was an extra
# member of the result set, and only a whole-set comparison makes an extra member visible.
test_start "the joined link set is exactly the union of what the two adapters resolve"
assert_equals "docs/epics/42-01-coverage-change-set-resolution.md${TAB}epic 42-01${TAB}declared
$EPIC1_DOC${TAB}epic 42-01${TAB}declared
$EPIC2_DOC${TAB}epic 42-02${TAB}declared
src/join.sh${TAB}epic 42-02${TAB}derived
src/join.sh${TAB}spec 42 R7${TAB}derived
src/join.sh${TAB}story 42-02.1${TAB}derived
src/resolve.sh${TAB}epic 42-01${TAB}declared
src/resolve.sh${TAB}spec 42 AD5${TAB}derived
src/resolve.sh${TAB}spec 42 R1${TAB}derived
src/resolve.sh${TAB}story 42-01.1${TAB}derived" "$(pairs_of "$BOTH")"

# One INTENT record, not two. Story 2's retro raised this: git knows neither a status nor a
# title and emits `unknown` with the ID as the title, while CPM reads both from the
# document. No criterion in this epic governs it, and the visible failure would be an
# artifact page listing the same epic twice — once named after itself.
test_start "an intent both adapters name carries CPM's status and title, not git's placeholder"
assert_equals "epic 42-01${TAB}done${TAB}Change-Set Resolution" \
  "$(printf '%s\n' "$BOTH" | linkset_intents | grep -F 'epic 42-01')"

# Both states, on a story the epic doc marks Complete — which is R4's shape exactly: the
# story says the work is finished, the matrix says one of its criteria was never verified.
# git contributes nothing here and must not dilute it, since a channel that carried no
# claim would otherwise look like a channel that carried an unverified one.
test_start "verified and unverified claims both survive the join, from the only adapter that has any"
assert_equals "story 42-01.1${TAB}unverified${TAB}A bare ref resolves without consulting any planning document
story 42-01.1${TAB}verified${TAB}An epic selector resolves to the commits that epic produced" \
  "$(printf '%s\n' "$BOTH" | linkset_criteria)"

# A file neither channel reaches stays unreached. Without this the union assertion above
# could be satisfied by an adapter that linked everything to something.
test_start "a file neither adapter can speak for is linked by neither"
assert_empty "$(printf '%s\n' "$BOTH" | linkset_links | grep -F 'src/orphan.sh')"

test_start "that unreached file is labelled absent once the join has both adapters"
assert_equals "LABEL${TAB}src/orphan.sh${TAB}absent" \
  "$(printf '%s\n' "$BOTH" | linkset_labels "$CHANGESET" | grep -F 'src/orphan.sh')"

# --- Criterion: JSON byte-identical across runs with both adapters active ----------------

adapters_of() {
  printf '%s\n' "$1" | awk '
    /^  "adapters": \[\],$/ { next }
    /^  "adapters": \[$/    { f = 1; next }
    f && /^  \],$/          { f = 0; next }
    f                       { gsub(/^ +"|",?$/, ""); print }
  '
}

use_adapters gitnative cpm
DOC=$(printf '%s\n' "$BOTH" | inspect_json "$REPO" "$CHANGESET" "epic 42-01")

# Byte-identity is worth nothing if neither run had any adapter contributing, and the
# document names its own inputs — so this is the positive control the two tests below rest
# on. It is also what catches the subshell trap `use_adapters` exists to avoid: an empty
# `adapters` array here means the registry never reached the serialiser.
test_start "the emitted record names both adapters as active"
assert_equals "cpm
gitnative" "$(adapters_of "$DOC")"

test_start "two runs with both adapters active produce byte-identical JSON"
use_adapters gitnative cpm
assert_equals "$DOC" "$(join_now | inspect_json "$REPO" "$CHANGESET" "epic 42-01")"

# The stronger form: identical bytes from two identical runs would survive an unsorted
# array, identical bytes from a reversed registration order would not.
test_start "reversing the registration order produces byte-identical JSON"
use_adapters cpm gitnative
assert_equals "$DOC" "$(join_now | inspect_json "$REPO" "$CHANGESET" "epic 42-01")"

# --- Criterion: an adapter's own labels do not depend on its peers -----------------------

# The mechanism behind the property, asserted directly: an adapter is handed a repository
# and a change set and nothing else, so there is no channel through which the registry
# could reach it. Cheap to assert and the thing that would break if an adapter ever grew a
# "what else is registered" check.
test_start "gitnative emits the same triples whether or not cpm is registered"
linkset_reset && linkset_register gitnative
GIT_ALONE=$(gitnative_link_changeset "$REPO" "$CHANGESET" | linkset_links | LC_ALL=C sort)
linkset_reset && linkset_register gitnative && linkset_register cpm
assert_equals "$GIT_ALONE" "$(gitnative_link_changeset "$REPO" "$CHANGESET" | linkset_links | LC_ALL=C sort)"

test_start "cpm emits the same triples whether or not gitnative is registered"
linkset_reset && linkset_register cpm
CPM_ALONE=$(cpm_link_changeset "$REPO" "$CHANGESET" | linkset_links | LC_ALL=C sort)
linkset_reset && linkset_register cpm && linkset_register gitnative
assert_equals "$CPM_ALONE" "$(cpm_link_changeset "$REPO" "$CHANGESET" | linkset_links | LC_ALL=C sort)"

# Monotonicity, in both subset directions. A breach would mean the join manufactured
# evidence out of the absence of a channel.
test_start "disabling cpm never strengthens or invents a link"
assert_empty "$(monotonicity_breaches "$(pairs_of "$BOTH")" "$(pairs_of "$GIT_ONLY")")"

test_start "disabling gitnative never strengthens or invents a link"
assert_empty "$(monotonicity_breaches "$(pairs_of "$BOTH")" "$(pairs_of "$CPM_ONLY")")"

# Both monotonicity assertions above are satisfied by a subset identical to the full join,
# and by a checker that finds nothing because it was handed nothing. This is the control
# for both: the subsets really do differ from the full join, in each of the two ways the
# checker looks for.
test_start "those subsets really do lose links and weaken a pair, so the check had work to do"
assert_equals "fewer|weakened" \
  "$([ "$(pairs_of "$GIT_ONLY" | wc -l)" -lt "$(pairs_of "$BOTH" | wc -l)" ] && echo fewer)|$([ "$(conf_for "$CPM_ONLY" src/resolve.sh 'epic 42-01')" = derived ] && echo weakened)"

# The checker itself. An empty result means "no breaches" and would also be produced by a
# checker that never reported anything, which is what the two assertions above would then
# be resting on.
test_start "the monotonicity check reports a strengthened pair when given one"
assert_equals "STRENGTHENED: a${TAB}i is declared with fewer adapters, derived with all" \
  "$(monotonicity_breaches "a${TAB}i${TAB}derived" "a${TAB}i${TAB}declared")"

test_start "the monotonicity check reports an invented pair when given one"
assert_equals "INVENTED: a${TAB}i (derived) appears with fewer adapters" \
  "$(monotonicity_breaches "b${TAB}j${TAB}derived" "a${TAB}i${TAB}derived")"

# --- Mixed availability ------------------------------------------------------------------

# R9's degradation case as it actually arrives: not zero adapters, but two registered where
# only one has a channel to read. `cpm` declines with exit 2 in a repository with no
# `docs/epics/`, and the join must treat that as "nothing to say" rather than a failure.
# Neither Story 2 nor Story 3 reaches this, because each registers only its own adapter.
test_start "a repository only one adapter can read still yields that adapter's links"
BARE=$(git_fixture_create no-epics)
git_fixture_commit "$BARE" "chore: seed" -- README.md "seed"
BARE_BASE=$(git_fixture_git "$BARE" rev-parse HEAD)
git_fixture_commit "$BARE" "fix: patch it" --trailer "Refs: TICKET-3" -- src/x.txt "x"
changeset_resolve_git "$BARE" --since "$BARE_BASE" > "$TEST_TMPDIR/cs-bare"
linkset_reset && linkset_register gitnative && linkset_register cpm
BARE_OUT=$(linkset_join "$BARE" "$TEST_TMPDIR/cs-bare" 2>"$TEST_TMPDIR/bare-err")
BARE_RC=$?
if [ "$BARE_RC" -ne 0 ]; then
  test_fail "Expected the join to succeed with one adapter declining, got $BARE_RC: $(cat "$TEST_TMPDIR/bare-err")"
else
  assert_equals "src/x.txt${TAB}TICKET-3${TAB}declared" "$(pairs_of "$BARE_OUT")"
fi

test_summary
