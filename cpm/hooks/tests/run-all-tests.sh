#!/bin/bash
# run-all-tests.sh — Run all CPM hook test suites
#
# Usage: bash cpm/hooks/tests/run-all-tests.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OVERALL_EXIT=0

for test_file in "$SCRIPT_DIR"/test-*.sh; do
  [ -f "$test_file" ] || continue
  [ "$(basename "$test_file")" = "test-helpers.sh" ] && continue

  echo ""
  bash "$test_file"
  if [ $? -ne 0 ]; then
    OVERALL_EXIT=1
  fi
  echo ""
done

if [ "$OVERALL_EXIT" -eq 0 ]; then
  echo "All test suites passed."
else
  echo "Some test suites failed."
fi

exit $OVERALL_EXIT
