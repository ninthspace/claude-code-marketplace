#!/bin/bash
# test-version-agreement.sh — Tests that every site carrying the plugin version agrees
# with the manifest, and that no test pins the version as a literal.
#
# These back Epic 41-05 Story 2's [integration] acceptance criteria.
#
# `test-audit-skill.sh` already asserts semver shape and manifest-to-manifest
# agreement — both repaired in epic 40-04 after retro 14 found two assertions pinning
# `2.0.0`, stale since that release and failing silently because nothing runs the
# suite between releases. This suite covers what that one does not: the *documentation*
# sites, which is where the version has actually gone stale.
#
# Every assertion here derives its expected value from `cpm/.claude-plugin/plugin.json`
# at run time. Nothing is pinned, so nothing rots at the next bump — which is the whole
# point. A test that says `assert_equals "3.1.0"` is a test that will be wrong on the
# day of the next release and silent about it until someone happens to run it.
#
# The site list is deliberately explicit rather than discovered. A grep for "any file
# containing a semver" would sweep in changelogs, epic docs and retros, which record
# what the version *was* and must never be rewritten. These six are the sites that
# claim what the version *is*.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

REPO="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PLUGIN_MANIFEST="$REPO/cpm/.claude-plugin/plugin.json"
MARKETPLACE_MANIFEST="$REPO/.claude-plugin/marketplace.json"

# CPM-only documentation sites, from the Task 2.1 survey. The root `README.md` is
# handled separately below — it is the *marketplace* README and carries a version
# heading for each of the five plugins, so "no other version string appears" is true
# of these three files and false of that one.
DOC_SITES="cpm-training-guide.html cpm-presentation.html cpm-onboarding-presentation.html"

# First "version" field in a JSON blob read from stdin.
manifest_version() {
  awk -F'"' '/"version"[[:space:]]*:/ {print $4; exit}'
}

echo "Testing: version agreement across every site"
echo "============================================"

test_start "The plugin manifest exists and declares a semver version"
if [ ! -f "$PLUGIN_MANIFEST" ]; then
  test_fail "plugin.json missing at $PLUGIN_MANIFEST"
  test_summary
fi
VERSION=$(manifest_version < "$PLUGIN_MANIFEST")
if printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  test_pass
else
  test_fail "not semver: '$VERSION'"
fi

# --- Cross-manifest agreement (structural, not pinned) ----------------------------

test_start "marketplace.json's cpm entry agrees with plugin.json"
CPM_BLOCK=$(awk '/"name": "cpm"/,/\]/' "$MARKETPLACE_MANIFEST")
MARKET_VERSION=$(printf '%s\n' "$CPM_BLOCK" | manifest_version)
assert_equals "$VERSION" "$MARKET_VERSION"

test_start "The cpm entry is the only marketplace entry this asserts against"
# Guards the awk range: it slices from the cpm entry to the next `]`, and a change to
# the manifest's ordering could silently make it read a different plugin's version.
if printf '%s' "$CPM_BLOCK" | grep -qF '"name": "cpm"' \
  && [ "$(printf '%s\n' "$CPM_BLOCK" | grep -c '"name":')" -eq 1 ]; then
  test_pass
else
  test_fail "the cpm block spans more than one plugin entry"
fi

# --- Every documentation site carries the manifest version ------------------------

for site in $DOC_SITES; do
  test_start "$site states the manifest version"
  if [ ! -f "$REPO/$site" ]; then
    test_fail "missing: $REPO/$site"
    continue
  fi
  # Two halves of one claim: the current version is present, AND no *other* version
  # is. A file that was bumped by adding a new badge beside a stale one passes the
  # first half alone.
  STALE=$(grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' "$REPO/$site" | grep -vE "^v?${VERSION}$" | sort -u)
  if grep -qF "$VERSION" "$REPO/$site" && [ -z "$STALE" ]; then
    test_pass
  else
    test_fail "expected only $VERSION; found other version strings: $(printf '%s' "$STALE" | tr '\n' ' ')"
  fi
done

test_start "The marketplace README's CPM heading states the manifest version"
# Pins the heading *title*, which is stable, not the version, which is not.
CPM_HEADING=$(grep -n '^### Claude Planning Method' "$REPO/README.md")
assert_contains "$CPM_HEADING" "(v$VERSION)"

test_start "The marketplace README's version headings match the manifest set"
# The root README is the one file listing all five plugins, so the per-file "only one
# version appears" rule does not hold. The equivalent structural claim is that the set
# of versions it advertises is the set the marketplace declares. A bump applied to a
# manifest and forgotten in the README breaks this, whichever plugin it was.
README_VERSIONS=$(grep -oE '^### .*\(v[0-9]+\.[0-9]+\.[0-9]+\)' "$REPO/README.md" \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort)
MANIFEST_VERSIONS=$(awk '/"plugins"/,0' "$MARKETPLACE_MANIFEST" \
  | awk -F'"' '/"version"[[:space:]]*:/ {print $4}' | sort)
assert_equals "$MANIFEST_VERSIONS" "$README_VERSIONS"

test_start "Every plugin manifest agrees with its marketplace entry"
# Generalises the cpm check above. `source` gives the directory, so the mapping is read
# from the manifest rather than assumed — a plugin added later is covered without edit.
MISMATCHES=""
while IFS='|' read -r src ver; do
  [ -n "$src" ] || continue
  own=$(manifest_version < "$REPO/${src#./}/.claude-plugin/plugin.json" 2>/dev/null)
  [ "$own" = "$ver" ] || MISMATCHES="$MISMATCHES $src($own vs $ver)"
done <<EOF
$(awk -F'"' '/"source"[[:space:]]*:/ {s=$4} /"version"[[:space:]]*:/ && s {print s "|" $4; s=""}' "$MARKETPLACE_MANIFEST")
EOF
assert_empty "$MISMATCHES"

# The rule is that cpm/README.md carries no version *of CPM's own*: a per-skill reference
# that names a release is a file that goes stale every release. A declared minimum for an
# external dependency is the opposite — it changes when that dependency's contract changes,
# never when CPM ships — and it is exactly what a reader installing CPM needs, so it is
# allowed and bounded rather than swept up by a blanket "no digits" grep.
#
# Bounded two ways: the permitted lines must name the dependency, and CPM's own version is
# asserted absent separately below. Without the second, widening this to "ignore lines
# mentioning ralph-loop" would let a stale CPM version ride along on such a line.
DEP_NAME='ralph-loop'

test_start "cpm/README.md states no version except a declared dependency minimum"
STRAY=$(grep -nE 'v?[0-9]+\.[0-9]+\.[0-9]+' "$REPO/cpm/README.md" | grep -vF "$DEP_NAME")
assert_empty "$STRAY"

test_start "and never CPM's own version, on any line"
assert_empty "$(grep -nF "$VERSION" "$REPO/cpm/README.md")"

# The control: the exemption is only meaningful if the file actually exercises it. If the
# dependency minimum is ever removed, this fires and the exemption above should go with it
# rather than sitting there as an unused hole.
test_start "control: the dependency minimum is present, so the exemption is not dead"
assert_contains "$(grep -E "$DEP_NAME.*[0-9]+\.[0-9]+\.[0-9]+" "$REPO/cpm/README.md")" "$DEP_NAME"

# --- must NOT pin a version literal in any test assertion -------------------------

test_start "No test file contains the current version as a literal"
# Derived, not pinned: the forbidden string is read from the manifest at run time, so
# this assertion keeps working after the next bump without being edited. This suite is
# excluded from its own sweep — it has to hold the version in a variable to test for it.
assert_empty "$(grep -rn "$VERSION" "$SCRIPT_DIR" --include='*.sh' --exclude="$(basename "$0")")"

# --- Historical records are not rewritten ------------------------------------------

test_start "Planning documents still record the versions that were true when written"
# The inverse guard. A bump that swept `docs/` would erase the record of what shipped
# when, and would pass every assertion above. Epic 40-04 recorded the 2.9.1 → 3.0.0
# bump; that text must survive every later release.
#
# Both directories, because the record this guard names is exactly the kind of document
# `/cpm:archive` sweeps: epic 40-04 is archived, and every version string in the epics
# tree now sits under `docs/archive/`. That is not a reference into the archive needing to
# resolve — it is a corpus sweep over the historical record, and the archive is where the
# historical record lives. `make-coverage-baseline.sh` reads both paths for the same
# reason. A guard reading only the live directory would call a routine archive the erasure
# it exists to catch.
if grep -rqE '[0-9]+\.[0-9]+\.[0-9]+' \
  "$REPO/docs/epics" "$REPO/docs/archive/epics" 2>/dev/null; then
  test_pass
else
  test_fail "no version strings remain in either epics directory — history may have been rewritten"
fi

# --- Negative controls -------------------------------------------------------------

FIXTURES="$TEST_TMPDIR/fixtures"
mkdir -p "$FIXTURES"

printf '<span class="version-badge">v9.9.9</span>\n<span class="old">v1.0.0</span>\n' \
  > "$FIXTURES/two-versions.html"

test_start "Negative control: a file carrying a second, stale version is detected"
FX_STALE=$(grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' "$FIXTURES/two-versions.html" | grep -vE '^v?9\.9\.9$' | sort -u)
if [ -n "$FX_STALE" ]; then
  test_pass
else
  test_fail "the stale-version sweep missed a second version string"
fi

printf 'assert_equals "%s" "$VERSION"\n' "$VERSION" > "$FIXTURES/pinned.sh"

test_start "Negative control: a pinned version literal in a test is detected"
if [ -n "$(grep -rn "$VERSION" "$FIXTURES" --include='*.sh')" ]; then
  test_pass
else
  test_fail "the pinned-literal sweep missed an assertion pinning the version"
fi

test_summary
