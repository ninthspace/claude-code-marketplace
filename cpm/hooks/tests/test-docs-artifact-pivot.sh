#!/bin/bash
# test-docs-artifact-pivot.sh — Tests that the user-facing documentation describes
# what the plugin now does, rather than what it did before spec 41.
#
# These back Epic 41-05 Story 1's [integration] acceptance criteria.
#
# Documentation drift is the failure mode with no natural detector: the skills work,
# the suite is green, and the only thing wrong is that the README promises something
# that was deleted. Every assertion here is therefore a *pairing* — the retired claim
# is absent AND the replacing claim is present. An absence check alone passes equally
# on a README that was correctly updated and one that was gutted.
#
# The must-NOT criterion drives the rest: a doc assertion that pins a count ("21
# skills") or spells out the current release number is a snapshot that rots between the
# releases nobody re-runs the suite for — retro 14's testing gap, verbatim. So the
# file-tree check compares the README's tree to the filesystem, and the version check is
# deferred entirely to `test-version-agreement.sh`, which asserts agreement rather than
# a value. That suite also sweeps this directory for the current version as a literal,
# which is why the number is described here rather than written.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

REPO="$SCRIPT_DIR/../../.."
README="$SCRIPT_DIR/../../README.md"
GUIDE="$REPO/cpm-training-guide.html"

# has <file> <fixed-string>
has() { grep -qF -- "$2" "$1"; }

echo "Testing: documentation reflects the artifact pivot"
echo "=================================================="

test_start "Both documentation sources exist"
if [ -f "$README" ] && [ -f "$GUIDE" ]; then
  test_pass
else
  test_fail "missing $README or $GUIDE"
fi

# --- Criterion: the README describes no faithful render, no local HTML output ------

test_start "README describes no faithful-render capability"
assert_empty "$(grep -niE 'faithful' "$README")"

test_start "README promises no local HTML output for present"
# Paired: the retired '.html version alongside' claim is gone, AND the surviving
# behaviour — Markdown plus an optional publish — is stated. Absence alone would pass
# on a README that dropped the present section entirely.
if ! grep -qiE '\.html version|\.html companion|self-contained \.html' "$README" \
  && has "$README" 'docs/communications/{nn}-{format}-{slug}.md'; then
  test_pass
else
  test_fail "the retired HTML sibling is still described, or the Markdown output is no longer named"
fi

test_start "README describes status publishing rather than writing a dashboard file"
if ! grep -qiE 'html dashboard' "$README" \
  && has "$README" 'published as a shareable page'; then
  test_pass
else
  test_fail "status still promises an HTML dashboard file, or no longer mentions publishing"
fi

test_start "README no longer claims status writes nothing at all"
# The old wording ("no files created or modified") became false the moment a confirmed
# publish began appending a register row. The replacement has to be honest about the
# one write, not merely silent about it.
if ! has "$README" 'no files created or modified' \
  && has "$README" 'register row'; then
  test_pass
else
  test_fail "the absolute read-only claim survives, or the register row is not accounted for"
fi

test_start "README describes the epics dependency view"
assert_contains "$(cat "$README")" 'dependency view'

# --- Criterion: the register is described as the durable trace --------------------

test_start "README names the register as the durable trace where no backlink exists"
if has "$README" 'docs/artifacts/index.md' \
  && has "$README" 'durable trace'; then
  test_pass
else
  test_fail "the register path or its role as the durable trace is missing"
fi

test_start "README no longer claims every associated document gains a backlink"
# `status` and `epics` publish with no single source artifact; the unqualified claim
# was true before 41-02 and is not now.
assert_not_contains "$(cat "$README")" 'each associated document gains an'

# --- Criterion: the training guide's SKILLS records show artifact outputs ---------

test_start "Training guide describes no faithful render or local HTML sibling"
assert_empty "$(grep -niE 'faithful|self-contained \.html|\.html companion|html dashboard' "$GUIDE")"

for pair in "present:published as a shareable hosted page" \
            "status:docs/artifacts/index.md" \
            "epics:published as a shareable page"; do
  skill=${pair%%:*}
  claim=${pair#*:}
  test_start "Training guide's $skill record describes publishing"
  if has "$GUIDE" "$claim"; then
    test_pass
  else
    test_fail "expected the $skill record to state: $claim"
  fi
done

test_start "Training guide's artifact record qualifies the backlink"
if has "$GUIDE" 'Not every publish has a backlink' \
  && has "$GUIDE" 'the register row IS the durable trace'; then
  test_pass
else
  test_fail "the artifact record still implies every publish writes a backlink"
fi

# --- must NOT introduce a snapshot value ------------------------------------------

test_start "README states no skill count"
assert_empty "$(grep -nE '\b[0-9]{1,3} skills\b' "$README")"

test_start "README states no version literal"
assert_empty "$(grep -nE 'v?[0-9]+\.[0-9]+\.[0-9]+' "$README")"

test_start "The README's file tree matches the skills on disk"
# The tree is an enumeration, which is a snapshot by construction — the one kind this
# suite can keep honest, by deriving the expected value instead of pinning it.
LISTED=$(sed -n '/^├── skills\/$/,/^├── tools\/$/p' "$README" \
  | grep -oE '^│   [├└]── [a-z]+/' | grep -oE '[a-z]+' | sort)
ACTUAL=$(ls "$SCRIPT_DIR/../../skills" | sort)
if [ "$LISTED" = "$ACTUAL" ]; then
  test_pass
else
  test_fail "tree/disk mismatch: $(diff <(echo "$LISTED") <(echo "$ACTUAL") | tr '\n' ' ')"
fi

# --- The heuristic has one wording (retro 17) -------------------------------------

test_start "The earns-its-place heuristic has exactly one wording"
VARIANTS=$(grep -rhoE 'if you cannot write [^.]*earned its place' "$SCRIPT_DIR/../../skills" --include='*.md' | sort -u)
if [ "$(printf '%s\n' "$VARIANTS" | grep -c .)" -eq 1 ]; then
  test_pass
else
  test_fail "found $(printf '%s\n' "$VARIANTS" | grep -c .) wordings:"$'\n'"$VARIANTS"
fi

# --- Negative controls ------------------------------------------------------------

FIXTURES="$TEST_TMPDIR/fixtures"
mkdir -p "$FIXTURES"

printf '**Output**: docs/communications/{nn}.md, optionally alongside a self-contained .html version\n' \
  > "$FIXTURES/stale-present.md"

test_start "Negative control: a stale HTML-sibling claim is detected"
if grep -qiE 'self-contained \.html' "$FIXTURES/stale-present.md"; then
  test_pass
else
  test_fail "the stale-claim pattern missed 'self-contained .html'"
fi

printf 'CPM ships 21 skills across the planning lifecycle.\n' > "$FIXTURES/counted.md"

test_start "Negative control: a skill count is detected as a snapshot value"
if grep -qE '\b[0-9]{1,3} skills\b' "$FIXTURES/counted.md"; then
  test_pass
else
  test_fail "the snapshot-value pattern missed a skill count"
fi

test_summary
