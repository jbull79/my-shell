#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# If run directly (not sourced), load utils and set defaults
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$SCRIPT_DIR/00_utils.sh" ]]; then
    # shellcheck source=00_utils.sh
    . "$SCRIPT_DIR/00_utils.sh"
  else
    echo "Error: 00_utils.sh not found. Please run from lib/ directory or via install.sh"
    exit 1
  fi
  export DRY_RUN="${DRY_RUN:-false}"
  export BACKUP_BASE="${BACKUP_BASE:-$HOME/.setup_backups}"
  export BACKUP_DIR="${BACKUP_DIR:-$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)}"
  export ERROR_LOG="${BACKUP_DIR}/errors.log"
  mkdir -p "$BACKUP_BASE"
  if [[ -f "$SCRIPT_DIR/../setup.conf" ]]; then
    # shellcheck source=/dev/null
    . "$SCRIPT_DIR/../setup.conf"
  fi
fi

info "Verifying installed tools..."

# List of tools to verify
declare -a tools_to_check=(
  "bash:4"
  "git"
  "zoxide"
  "bat"
  "fzf"
  "starship"
)

# Check AWS CLI if it was supposed to be installed
if [[ "${INSTALL_AWS_CLI:-true}" == "true" ]]; then
  tools_to_check+=("aws")
fi

failed_tools=()
for tool_spec in "${tools_to_check[@]}"; do
  IFS=':' read -r tool min_version <<< "$tool_spec"
  if command -v "$tool" > /dev/null 2>&1; then
    if [[ -n "${min_version:-}" ]]; then
      # For bash, check version differently
      if [[ "$tool" == "bash" ]]; then
        actual_version=$("$tool" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+' | head -n1 || echo "0")
        if [[ "${actual_version:-0}" -ge "$min_version" ]]; then
          success "✓ $tool v$actual_version"
        else
          warn "⚠ $tool v$actual_version (need >= $min_version)"
          failed_tools+=("$tool")
        fi
      else
        # For other tools, try to get version
        actual_version=$("$tool" --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1 || echo "0.0")
        success "✓ $tool v$actual_version"
      fi
    else
      success "✓ $tool"
    fi
  else
    error "✗ $tool not found"
    failed_tools+=("$tool")
  fi
done

if ((${#failed_tools[@]} > 0)); then
  warn "Some tools failed verification: ${failed_tools[*]}"
  return 1
else
  success "All tools verified successfully"
  return 0
fi

