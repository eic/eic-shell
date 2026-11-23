#!/usr/bin/env bash
# Test suite for eic-shell wrapper script

set -u

EIC_SHELL="${1:-./eic-shell}"

if [ ! -x "$EIC_SHELL" ]; then
  echo "ERROR: eic-shell executable not found at '$EIC_SHELL'"
  exit 1
fi

echo "=================================================="
echo "Testing eic-shell launcher: $EIC_SHELL"
echo "=================================================="

PASSED=0
FAILED=0

run_test() {
  local desc="$1"
  shift
  printf "Test %2d: %-60s " "$((PASSED + FAILED + 1))" "$desc"
  
  local output
  local exit_code=0
  output=$("$@" 2>&1) || exit_code=$?

  if [ "$exit_code" -eq 0 ]; then
    echo "[PASS]"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo "[FAIL] (exit code: $exit_code)"
    echo "       Output: $output"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

run_test_expect_code() {
  local expected_code="$1"
  local desc="$2"
  shift 2
  printf "Test %2d: %-60s " "$((PASSED + FAILED + 1))" "$desc"

  local output
  local exit_code=0
  output=$("$@" 2>&1) || exit_code=$?

  if [ "$exit_code" -eq "$expected_code" ]; then
    echo "[PASS]"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo "[FAIL] (expected: $expected_code, got: $exit_code)"
    echo "       Output: $output"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

run_test_output_match() {
  local expected_pattern="$1"
  local desc="$2"
  shift 2
  printf "Test %2d: %-60s " "$((PASSED + FAILED + 1))" "$desc"

  local output
  local exit_code=0
  output=$("$@" 2>&1) || exit_code=$?

  if [ "$exit_code" -eq 0 ] && echo "$output" | grep -q "$expected_pattern"; then
    echo "[PASS]"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo "[FAIL] (exit code: $exit_code, pattern: '$expected_pattern')"
    echo "       Output: $output"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

run_test_output_contains() {
  local str1="$1"
  local str2="$2"
  local desc="$3"
  shift 3
  printf "Test %2d: %-60s " "$((PASSED + FAILED + 1))" "$desc"

  local output
  local exit_code=0
  output=$("$@" 2>&1) || exit_code=$?

  if [ "$exit_code" -eq 0 ] && echo "$output" | grep -q "$str1" && echo "$output" | grep -q "$str2"; then
    echo "[PASS]"
    PASSED=$((PASSED + 1))
    return 0
  else
    echo "[FAIL] (exit code: $exit_code, expected to contain '$str1' and '$str2')"
    echo "       Output: $output"
    FAILED=$((FAILED + 1))
    return 1
  fi
}

# 1. Help flag
run_test_output_match "USAGE:" "Print help with --help" \
  "$EIC_SHELL" --help

# 2. Simple command execution
run_test "Execute single command (true)" \
  "$EIC_SHELL" -- true

# 3. Simple command with argument
run_test_output_match "hello" "Execute simple command with argument" \
  "$EIC_SHELL" -- echo hello

# 4. Multi-token command
run_test_output_match "foo bar baz" "Execute multi-token command" \
  "$EIC_SHELL" -- echo foo bar baz

# 5. Quoted single-string command
run_test_output_match "foo bar" "Execute quoted single-string command" \
  "$EIC_SHELL" -- "echo foo bar"

# 6. Explicit subshell with bash -c
run_test_output_match "nested bash -c" "Execute subshell: bash -c 'echo ...'" \
  "$EIC_SHELL" -- bash -c "echo nested bash -c"

# 7. Subshell with complex commands and arguments (reproducing cmake bug scenario)
run_test_output_match "cmake-target-dummy" "Execute bash -c with multi-arg cmake-like flags" \
  "$EIC_SHELL" -- bash -c "echo cmake-target-dummy --build build --target lib"

# 8. Command chaining with &&
run_test_output_contains "part1" "part2" "Execute chained commands with &&" \
  "$EIC_SHELL" -- "echo part1 && echo part2"

# 9. Arguments with spaces preserved
run_test_output_match "arg with multiple spaces" "Preserve arguments containing spaces" \
  "$EIC_SHELL" -- bash -c 'echo "$1"' _ "arg with multiple spaces"

# 10. Positional parameters in bash -c
run_test_output_match "val1:val2:val3" "Preserve positional parameters in subshell" \
  "$EIC_SHELL" -- bash -c 'echo "$1:$2:$3"' _ "val1" "val2" "val3"

# 11. Exit code preservation: success
run_test_expect_code 0 "Preserve exit code 0" \
  "$EIC_SHELL" -- true

# 12. Exit code preservation: failure (exit 1)
run_test_expect_code 1 "Preserve exit code 1 (false)" \
  "$EIC_SHELL" -- false

# 13. Exit code preservation: arbitrary code (exit 42)
run_test_expect_code 42 "Preserve exit code 42" \
  "$EIC_SHELL" -- bash -c "exit 42"

# 14. Exit code preservation: arbitrary code (exit 17)
run_test_expect_code 17 "Preserve exit code 17" \
  "$EIC_SHELL" -- bash -c "exit 17"

# 15. Piped stdin to a command
run_test_output_match "piped data test" "Pipe stdin to a command (cat)" \
  bash -c "echo 'piped data test' | '$EIC_SHELL' -- cat"

# 16. Piped stdin to interactive shell
run_test_output_match "interactive pipe test" "Pipe commands on stdin to interactive shell" \
  bash -c "echo 'echo interactive pipe test' | '$EIC_SHELL'"

# 17. Environment setup verification (/etc/eic-env.sh sourced)
run_test "Environment setup sourced (/etc/eic-env.sh)" \
  "$EIC_SHELL" -- bash -c "test -f /etc/eic-env.sh"

echo "=================================================="
echo "Summary: $PASSED passed, $FAILED failed out of $((PASSED + FAILED)) tests"
echo "=================================================="

if [ "$FAILED" -ne 0 ]; then
  exit 1
fi
exit 0
