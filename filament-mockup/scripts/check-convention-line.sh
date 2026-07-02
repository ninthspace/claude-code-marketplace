#!/usr/bin/env bash
# Presence check for the produce/consume convention line + sibling cross-refs on
# the filament-mockup skill (spec 01, M8 — cross-repo contract closure).
# Covers the [integration] acceptance criterion: the canonical convention line and
# sibling cross-refs naming both builders are present on the skill's description
# line, and the skill is NOT renamed (it is already `…-mockup` = produces).
#
#   ./scripts/check-convention-line.sh        # run from the filament-mockup dir
#   ./filament-mockup/scripts/check-convention-line.sh   # or from the repo root
#
# Exits non-zero on the first failed check.

set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill="$skill_dir/SKILL.md"

# The canonical convention clause — must match byte-for-byte the wording shared by
# brief-to-mockups / mockup-to-blade / mockup-to-filament (single-char ellipsis
# U+2026, per spec AD2 / M6).
convention='Convention: `…-mockup(s)` produces a mockup; `mockup-to-…` consumes a mockup, builds the named target.'

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok:   $1"; }

[ -f "$skill" ] || fail "$skill does not exist"

# No rename: the skill is still named filament-mockup.
grep -qx "name: filament-mockup" "$skill" \
  || fail "SKILL.md frontmatter 'name:' is not 'filament-mockup' (M8 forbids a rename)"
pass "name: frontmatter still reads filament-mockup (no rename)"

# Convention clause present, verbatim, on the description: line.
desc="$(grep -n '^description:' "$skill" | head -1 | cut -d: -f2-)"
[ -n "$desc" ] || fail "no description: line found"
printf '%s' "$desc" | grep -qF "$convention" \
  || fail "the identical convention line is missing from the description"
pass "convention line present on the description line"

# Sibling cross-refs name both builders.
for builder in 'mockup-to-blade' 'mockup-to-filament'; do
  printf '%s' "$desc" | grep -qF "$builder" \
    || fail "description does not name sibling builder '$builder'"
  pass "description names sibling builder $builder"
done

echo
echo "filament-mockup convention alignment: all [integration] checks passed."
