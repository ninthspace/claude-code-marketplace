#!/bin/bash
# test-reference-line-propagation.sh — Tests for the canonical Artifact Publishing
# reference line propagated across all ten skills.
#
# These back Epic 41-03 Story 1's [integration] acceptance criteria (spec 41 R4, AD4).
#
# The guarantee under test is *byte identity across sites*, not presence at any one
# site. That distinction is the whole point: during the 41bc7a5 work a
# `**Publish as an artifact (optional).**` prefix was added at one site, which passed
# every per-file presence check while breaking the property the propagation exists to
# provide. So the load-bearing assertion here is the `sort -u` one — a single unique
# string with a count of ten — and the per-file checks are diagnostics that say
# *which* site drifted when it fails.
#
# The placement assertion (architect/review/spec) guards a failure that no other check
# can see: those three skills carried the superseded line inside their
# `Faithful Render (on request)` section, which epic 41-04 deletes. Replacing it in
# place would satisfy the count today and silently drop it to seven when 41-04 runs.
#
# Slices and heading lookups are fence-aware (retro 15) — every one of these skills
# has `##` headings inside its output-format code fence, so a naive "nearest preceding
# heading" scan reports a template heading rather than the real enclosing section.
# Assertions whose two halves form one claim share a test_start (retro 15).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"

# The exact bytes under test, authored in Task 41-01.2.3 and recorded in the fenced
# block in cpm/shared/skill-conventions.md. Any edit here must be made there first.
CANONICAL='An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.'

# Every skill required to carry the line: the 3 pivoted (41-02) plus the R4 sites.
SKILLS="discover brief architect spec epics review audit retro status present"

# How many times each skill carries it. One per *publishable output*, not one per skill:
# `status` has two — the project-wide full picture (Phase 4) and the spec coverage page
# (Phase 3b, epic 44-02) — and they are separately requested, separately confirmed, and
# published to separate URLs. Collapsing them to one site would make the second page's
# publishing implicitly covered by the first's confirmation, which is the thing the line
# exists to prevent. Any skill not listed here carries it once.
sites_expected() {
  case "$1" in
    status) echo 2 ;;
    *) echo 1 ;;
  esac
}

# The looser pattern that matches *any* phrasing referencing the procedure. Finding a
# line that matches this but is not CANONICAL is exactly the variant-phrasing failure.
REF_PATTERN='follow the shared \*\*Artifact Publishing\*\* procedure'

# --- Helpers ---

# ref_lines <dir> — every line in <dir>'s Markdown that references the procedure.
ref_lines() {
  grep -rh "$REF_PATTERN" "$1" --include="*.md" 2>/dev/null
}

# variant_lines <dir> — reference lines that are not byte-identical to CANONICAL.
# This is what catches a prefix, a suffix, or a reworded sentence at any single site.
variant_lines() {
  ref_lines "$1" | grep -vxF "$CANONICAL"
}

# enclosing_heading <file> <lineno> — the nearest preceding Markdown heading that is
# not inside a fenced code block. Template fences in these skills contain `##`
# headings of their own, so fence tracking is what makes the answer meaningful.
enclosing_heading() {
  awk -v L="$2" '
    /^```/ { fence = !fence; next }
    !fence && /^#+ / && NR < L { h = $0 }
    NR == L { print h }
  ' "$1"
}

# line_of_canonical <file> — the 1-based line number of the canonical line.
line_of_canonical() {
  grep -nxF "$CANONICAL" "$1" | head -1 | cut -d: -f1
}

echo "Testing: canonical reference line propagation"
echo "============================================="

# --- Criterion: all ten skills carry the canonical reference line ---

for skill in $SKILLS; do
  want=$(sites_expected "$skill")
  test_start "$skill carries the canonical line at each of its $want publishable output(s)"
  file="$SKILLS_DIR/$skill/SKILL.md"
  if [ ! -f "$file" ]; then
    test_fail "Expected skill at $file"
    continue
  fi
  count=$(grep -cxF "$CANONICAL" "$file")
  if [ "$count" -eq "$want" ]; then
    test_pass
  else
    test_fail "expected $want occurrence(s), found $count"
  fi
done

# --- Criterion: exactly one unique string, one per publishing skill ---
# The story's gate. Run as the criterion states it, over cpm/skills/ — the epic's edit
# scope. Repo-wide would also match the convention's own fenced copy, which is the
# definition rather than a use site.
#
# The expected count is a roster size, not a derived value, and it is the one number in
# this suite that has to be maintained by hand: which skills produce something worth
# publishing is a judgement with no signal in the repository to read it from, so a skill
# joining or leaving the set edits this line. Spec 41 set it at 10; `inspect` (spec 42 R8)
# was the first addition since, and `status`'s second publishable output (the spec coverage
# page, epic 44-02) the next. The count still earns its place — without it, a site that
# silently lost the line would leave `sort -u` reporting one unique string and passing.
#
# It counts *sites*, not skills, which is why `status` contributes two. It stays a literal
# rather than a sum over `sites_expected`: deriving it from the roster it is meant to guard
# would make it agree with itself and catch nothing.

UNIQUE=$(ref_lines "$SKILLS_DIR" | sort -u)
TOTAL=$(ref_lines "$SKILLS_DIR" | grep -c .)

test_start "sort | uniq -c reports exactly one unique reference string"
if [ "$(printf '%s\n' "$UNIQUE" | grep -c .)" -eq 1 ]; then
  test_pass
else
  test_fail "expected 1 unique string, got:"$'\n'"$UNIQUE"
fi

EXPECTED_SITES=12

test_start "The one unique string is the canonical line, once per publishable output"
# One claim, two halves: the right count of the *wrong* string is not a pass, and the
# canonical string at one site fewer than the roster is not either.
if [ "$UNIQUE" = "$CANONICAL" ] && [ "$TOTAL" -eq "$EXPECTED_SITES" ]; then
  test_pass
else
  test_fail "expected the canonical line ×$EXPECTED_SITES, got ×$TOTAL of: $UNIQUE"
fi

# --- Criterion: must NOT introduce a variant phrasing, prefix, or suffix ---

test_start "No variant phrasing, prefix, or suffix at any site"
assert_empty "$(variant_lines "$SKILLS_DIR")"

test_start "The superseded line is absent from every skill"
assert_empty "$(grep -rn 'Any HTML output here can additionally be published' "$SKILLS_DIR" --include='*.md')"

# --- Criterion: in architect, review and spec the line sits outside Faithful Render ---
# Those sections are deleted by epic 41-04. A line inside one satisfies the count at
# this gate and disappears at the next, with nothing failing in between.

for skill in architect review spec; do
  file="$SKILLS_DIR/$skill/SKILL.md"
  ln=$(line_of_canonical "$file")

  test_start "$skill places the line in a section that survives epic 41-04"
  if [ -z "$ln" ]; then
    test_fail "canonical line not found in $file"
    continue
  fi
  heading=$(enclosing_heading "$file" "$ln")
  if [ -n "$heading" ] && ! printf '%s' "$heading" | grep -qF 'Faithful Render'; then
    test_pass
  else
    test_fail "line $ln sits under '${heading:-<no heading>}'"
  fi
done

# --- Negative controls ---
# Each check above is asserted to actually fail on the shape it exists to reject.
# Without these, a helper that silently matched nothing would report a clean sweep.

FIXTURES="$TEST_TMPDIR/fixtures"
mkdir -p "$FIXTURES"

# A prefixed line: the exact failure that occurred during the 41bc7a5 work.
printf '## Output\n\n**Publish as an artifact (optional).** %s\n' "$CANONICAL" \
  > "$FIXTURES/prefixed.md"

test_start "Negative control: a prefixed line is reported as a variant"
if [ -n "$(variant_lines "$FIXTURES")" ]; then
  test_pass
else
  test_fail "variant_lines missed a prefixed reference line"
fi

test_start "Negative control: a prefixed line is not counted as canonical"
if [ "$(grep -cxF "$CANONICAL" "$FIXTURES/prefixed.md")" -eq 0 ]; then
  test_pass
else
  test_fail "an exact-line match accepted a prefixed line"
fi

# A line placed inside a Faithful Render section, below a template fence that contains
# its own `##` headings — the case fence tracking exists to get right.
cat > "$FIXTURES/inside-render.md" <<EOF
## Output

Format:

\`\`\`markdown
## Summary
{summary}
\`\`\`

#### Faithful Render (on request)

$CANONICAL
EOF

test_start "Negative control: a line inside Faithful Render is detected there"
fx_ln=$(line_of_canonical "$FIXTURES/inside-render.md")
fx_heading=$(enclosing_heading "$FIXTURES/inside-render.md" "$fx_ln")
if printf '%s' "$fx_heading" | grep -qF 'Faithful Render'; then
  test_pass
else
  test_fail "enclosing_heading reported '${fx_heading:-<no heading>}' instead of the Faithful Render heading"
fi

test_start "Negative control: heading lookup ignores headings inside code fences"
# The fixture's fence contains `## Summary` after the real `## Output` heading; a
# fence-blind scan would return the template heading for a line below the fence.
if [ "$fx_heading" != '## Summary' ]; then
  test_pass
else
  test_fail "heading lookup returned a heading from inside a code fence"
fi

test_summary
