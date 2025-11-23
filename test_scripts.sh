#!/usr/bin/env bash
# shellcheck shell=bash
# Unit tests for the setup scripts
# Tests independent script execution, dependency checks, and dry-run functionality

# Suppress zoxide warning during tests
export _ZO_DOCTOR=0

set -euo pipefail

# Test colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SKIPPED=0

# Test result tracking
test_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((PASSED++)) || true
}

test_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((FAILED++)) || true
}

test_skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  ((SKIPPED++)) || true
}

test_info() {
  echo -e "${BLUE}ℹ INFO${NC}: $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
TEST_TMP_DIR="$(mktemp -d)"
TEST_BACKUP_DIR="$TEST_TMP_DIR/backups"
TEST_ZSHRC="$TEST_TMP_DIR/.zshrc"
TEST_GITCONFIG="$TEST_TMP_DIR/.gitconfig"
TEST_AWS_DIR="$TEST_TMP_DIR/.aws"

# Cleanup function
cleanup() {
  if [[ -d "$TEST_TMP_DIR" ]]; then
    rm -rf "$TEST_TMP_DIR"
  fi
}
trap cleanup EXIT

# Setup test environment
setup_test_env() {
  mkdir -p "$TEST_BACKUP_DIR"
  mkdir -p "$TEST_AWS_DIR"
  touch "$TEST_ZSHRC"
  touch "$TEST_GITCONFIG"
  
  # Export test variables
  export ZSHRC="$TEST_ZSHRC"
  export GITCONFIG="$TEST_GITCONFIG"
  export AWS_CONFIG_DIR="$TEST_AWS_DIR"
  export BACKUP_BASE="$TEST_BACKUP_DIR"
  export BACKUP_DIR="$TEST_BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S)"
  export ERROR_LOG="$BACKUP_DIR/errors.log"
  export DRY_RUN="false"
  mkdir -p "$BACKUP_DIR"
}

# Test 1: Check that utils functions exist
test_utils_functions() {
  test_info "Testing utils functions..."
  
  if [[ ! -f "$LIB_DIR/00_utils.sh" ]]; then
    test_fail "00_utils.sh not found"
    return
  fi
  
  # Source utils
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  # Check required functions exist
  local functions=("info" "warn" "error" "success" "run" "ensure_command" "ensure_python_package" "backup_file" "ensure_line_in_file")
  for func in "${functions[@]}"; do
    if declare -f "$func" > /dev/null 2>&1; then
      test_pass "Function '$func' exists"
    else
      test_fail "Function '$func' not found"
    fi
  done
}

# Test 2: Test ensure_command function
test_ensure_command() {
  test_info "Testing ensure_command function..."
  
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  # Test with a command that exists
  if ensure_command "bash" "echo 'test'"; then
    test_pass "ensure_command works with existing command"
  else
    test_fail "ensure_command failed with existing command"
  fi
  
  # Test with dry-run
  export DRY_RUN="true"
  if ensure_command "nonexistent_command_xyz" "echo 'would install'"; then
    test_pass "ensure_command works in dry-run mode"
  else
    test_fail "ensure_command failed in dry-run mode"
  fi
  export DRY_RUN="false"
}

# Test 3: Test ensure_python_package function
test_ensure_python_package() {
  test_info "Testing ensure_python_package function..."
  
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  # Test with dry-run (won't actually install)
  export DRY_RUN="true"
  if ensure_python_package "sys" "sys"; then
    test_pass "ensure_python_package works with existing package in dry-run"
  else
    test_fail "ensure_python_package failed with existing package"
  fi
  export DRY_RUN="false"
}

# Test 4: Test independent script execution (header check)
test_independent_execution() {
  test_info "Testing independent script execution..."
  
  local scripts=("03_zsh.sh" "04_starship.sh" "05_bat.sh" "06_git_setup.sh" "08_aws.sh" "09_aliases.sh")
  
  for script in "${scripts[@]}"; do
    if [[ ! -f "$LIB_DIR/$script" ]]; then
      test_skip "Script $script not found"
      continue
    fi
    
    # Check if script has the independent execution header
    # Pattern: if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if grep -qE '\$\{BASH_SOURCE\[0\]\}' "$LIB_DIR/$script"; then
      if grep -q 'SCRIPT_DIR=' "$LIB_DIR/$script"; then
        if grep -q '00_utils.sh' "$LIB_DIR/$script"; then
          test_pass "Script $script has independent execution header"
        else
          test_fail "Script $script missing utils sourcing"
        fi
      else
        test_fail "Script $script missing SCRIPT_DIR setup"
      fi
    else
      test_fail "Script $script missing independent execution check"
    fi
  done
}

# Test 5: Test dry-run mode
test_dry_run_mode() {
  test_info "Testing dry-run mode..."
  
  setup_test_env
  export DRY_RUN="true"
  
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  # Test backup_file in dry-run
  local test_file="$TEST_TMP_DIR/test.txt"
  echo "test" > "$test_file"
  
  if backup_file "$test_file" 2>&1 | grep -q "DRY-RUN"; then
    test_pass "backup_file respects DRY_RUN"
  else
    test_fail "backup_file doesn't respect DRY_RUN"
  fi
  
  # Test ensure_line_in_file in dry-run
  if ensure_line_in_file "$TEST_ZSHRC" "# test line" 2>&1 | grep -q "DRY-RUN"; then
    test_pass "ensure_line_in_file respects DRY_RUN"
  else
    test_fail "ensure_line_in_file doesn't respect DRY_RUN"
  fi
  
  export DRY_RUN="false"
}

# Test 6: Test that scripts can be executed directly (syntax check)
test_script_syntax() {
  test_info "Testing script syntax..."
  
  local scripts=("00_utils.sh" "01_brew.sh" "02_fonts.sh" "03_zsh.sh" "04_starship.sh" "05_bat.sh" "06_git_setup.sh" "07_datadog.sh" "08_aws.sh" "09_aliases.sh" "98_verify.sh" "99_summary.sh")
  
  for script in "${scripts[@]}"; do
    if [[ ! -f "$LIB_DIR/$script" ]]; then
      test_skip "Script $script not found"
      continue
    fi
    
    # Check syntax
    if bash -n "$LIB_DIR/$script" 2>/dev/null; then
      test_pass "Script $script has valid syntax"
    else
      test_fail "Script $script has syntax errors"
    fi
  done
}

# Test 7: Test that scripts source utils correctly when run directly
test_script_sources_utils() {
  test_info "Testing script utils sourcing..."
  
  # Create a test script that mimics the pattern
  local test_script="$TEST_TMP_DIR/test_source.sh"
  cat > "$test_script" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$SCRIPT_DIR/00_utils.sh" ]]; then
    . "$SCRIPT_DIR/00_utils.sh"
  else
    echo "Error: 00_utils.sh not found"
    exit 1
  fi
fi

# Test that functions are available
if declare -f info > /dev/null 2>&1; then
  echo "SUCCESS"
else
  echo "FAIL"
fi
EOF
  
  chmod +x "$test_script"
  
  # Copy utils to test location
  cp "$LIB_DIR/00_utils.sh" "$TEST_TMP_DIR/"
  
  # Run the test script
  local result
  result=$(cd "$TEST_TMP_DIR" && ./test_source.sh 2>&1)
  
  if echo "$result" | grep -q "SUCCESS"; then
    test_pass "Scripts can source utils when run directly"
  else
    test_fail "Scripts cannot source utils when run directly: $result"
  fi
}

# Test 8: Test dependency checks in scripts
test_dependency_checks() {
  test_info "Testing dependency checks in scripts..."
  
  # Check that scripts use ensure_command or ensure_python_package
  local scripts_with_deps=("03_zsh.sh:zoxide,fzf" "04_starship.sh:starship" "05_bat.sh:bat" "08_aws.sh:aws,boto3")
  
  for script_spec in "${scripts_with_deps[@]}"; do
    IFS=':' read -r script deps <<< "$script_spec"
    if [[ ! -f "$LIB_DIR/$script" ]]; then
      test_skip "Script $script not found"
      continue
    fi
    
    # Check if script uses ensure_command or ensure_python_package
    if grep -q "ensure_command\|ensure_python_package" "$LIB_DIR/$script"; then
      test_pass "Script $script has dependency checks"
    else
      test_fail "Script $script missing dependency checks"
    fi
  done
}

# Test 9: Test that 01_brew.sh installs all required packages
test_brew_installs_all() {
  test_info "Testing that 01_brew.sh installs all packages..."
  
  if [[ ! -f "$LIB_DIR/01_brew.sh" ]]; then
    test_fail "01_brew.sh not found"
    return
  fi
  
  # Check that boto3 installation is in 01_brew.sh
  if grep -q "boto3" "$LIB_DIR/01_brew.sh"; then
    test_pass "01_brew.sh includes boto3 installation"
  else
    test_fail "01_brew.sh missing boto3 installation"
  fi
  
  # Check that awscli is in TOOLS_DEFAULT
  if grep -q "awscli" "$LIB_DIR/01_brew.sh"; then
    test_pass "01_brew.sh includes awscli in tools"
  else
    test_fail "01_brew.sh missing awscli in tools"
  fi
  
  # Check that font installation is in 01_brew.sh
  if grep -q "font-meslo-lg-nerd-font\|Meslo" "$LIB_DIR/01_brew.sh"; then
    test_pass "01_brew.sh includes font installation"
  else
    test_fail "01_brew.sh missing font installation"
  fi
}

# Test 10: Test error handling
test_error_handling() {
  test_info "Testing error handling..."
  
  setup_test_env
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  # Test log_error function
  if declare -f log_error > /dev/null 2>&1; then
    log_error "test_module" "test error" > /dev/null 2>&1
    if [[ -f "$ERROR_LOG" ]]; then
      test_pass "log_error creates error log file"
    else
      test_fail "log_error doesn't create error log file"
    fi
  else
    test_fail "log_error function not found"
  fi
}

# Test 11: Test backup_file function
test_backup_file() {
  test_info "Testing backup_file function..."
  
  setup_test_env
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  local test_file="$TEST_TMP_DIR/test_backup.txt"
  echo "test content" > "$test_file"
  
  if backup_file "$test_file"; then
    if [[ -f "$BACKUP_DIR/test_backup.txt" ]]; then
      test_pass "backup_file creates backup"
    else
      test_fail "backup_file doesn't create backup file"
    fi
  else
    test_fail "backup_file function failed"
  fi
}

# Test 12: Test ensure_line_in_file function
test_ensure_line_in_file() {
  test_info "Testing ensure_line_in_file function..."
  
  setup_test_env
  # shellcheck source=lib/00_utils.sh
  . "$LIB_DIR/00_utils.sh"
  
  local test_line="# test configuration line"
  
  if ensure_line_in_file "$TEST_ZSHRC" "$test_line"; then
    if grep -qF "$test_line" "$TEST_ZSHRC"; then
      test_pass "ensure_line_in_file adds line to file"
      
      # Test idempotency - should not add duplicate
      ensure_line_in_file "$TEST_ZSHRC" "$test_line"
      local count
      count=$(grep -cF "$test_line" "$TEST_ZSHRC" || echo "0")
      if [[ "$count" -eq 1 ]]; then
        test_pass "ensure_line_in_file is idempotent (no duplicates)"
      else
        test_fail "ensure_line_in_file creates duplicates (found $count)"
      fi
    else
      test_fail "ensure_line_in_file doesn't add line to file"
    fi
  else
    test_fail "ensure_line_in_file function failed"
  fi
}

# Main test runner
main() {
  echo "=========================================="
  echo "  Setup Scripts Unit Tests"
  echo "=========================================="
  echo ""
  
  # Check if lib directory exists
  if [[ ! -d "$LIB_DIR" ]]; then
    echo -e "${RED}Error: lib directory not found at $LIB_DIR${NC}"
    exit 1
  fi
  
  # Run all tests
  test_utils_functions
  echo ""
  test_ensure_command
  echo ""
  test_ensure_python_package
  echo ""
  test_independent_execution
  echo ""
  test_dry_run_mode
  echo ""
  test_script_syntax
  echo ""
  test_script_sources_utils
  echo ""
  test_dependency_checks
  echo ""
  test_brew_installs_all
  echo ""
  test_error_handling
  echo ""
  test_backup_file
  echo ""
  test_ensure_line_in_file
  echo ""
  
  # Summary
  echo "=========================================="
  echo "  Test Summary"
  echo "=========================================="
  echo -e "${GREEN}Passed:${NC} $PASSED"
  echo -e "${RED}Failed:${NC} $FAILED"
  echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
  echo ""
  
  local total=$((PASSED + FAILED + SKIPPED))
  if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

# Run tests
main "$@"

