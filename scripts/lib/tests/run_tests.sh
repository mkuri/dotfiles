#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
source "$LIB_DIR/disk-cleanup-lib.sh"

TESTS_RUN=0
TESTS_FAILED=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="${3:-assert_eq}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $label — expected [$expected], got [$actual]"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

for test_file in "$SCRIPT_DIR"/*_test.sh; do
  # shellcheck source=/dev/null
  source "$test_file"
done

echo ""
echo "$TESTS_RUN tests run, $TESTS_FAILED failed"
[[ "$TESTS_FAILED" -eq 0 ]]
