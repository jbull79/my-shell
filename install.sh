#!/usr/bin/env bash
set -euo pipefail

# If SKIP_BREW is set, we've already installed brew and are re-running with brew bash
SKIP_BREW="${SKIP_BREW:-false}"

# Load config file if it exists (before setting defaults)
if [[ -f "$(dirname "$0")/setup.conf" ]]; then
  # shellcheck source=/dev/null
  . "$(dirname "$0")/setup.conf"
fi

# Export variables (command line args take precedence over config file)
export DRY_RUN="${DRY_RUN:-false}"
export BACKUP_BASE="${BACKUP_BASE:-$HOME/.setup_backups}"
export BACKUP_DIR="${BACKUP_DIR:-$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)}"
export ERROR_LOG="${BACKUP_DIR}/errors.log"

# shellcheck source=lib/00_utils.sh
. "$(dirname "$0")/lib/00_utils.sh"

info "🚀 Starting full environment bootstrap..."

# Get current bash version
CURRENT_BASH_VERSION=$(bash --version | head -n1 | grep -oE 'version [0-9]+' | grep -oE '[0-9]+' | head -n1 || echo "0")

# Count total modules for progress
TOTAL_MODULES=11  # brew + 10 other modules
CURRENT_MODULE=0

# If we haven't installed brew yet, do it first
if [[ "$SKIP_BREW" != "true" ]]; then
  CURRENT_MODULE=$((CURRENT_MODULE + 1))
  info "[$CURRENT_MODULE/$TOTAL_MODULES] ▶ Running module: 01_brew.sh"
  # shellcheck source=/dev/null
  if ! . "$(dirname "$0")/lib/01_brew.sh"; then
    log_error "install.sh" "Failed to install brew"
    exit 1
  fi
  
  # After brew installs bash, check if we need to switch
  if [[ -n "${BASH_BIN:-}" ]] && [[ -f "$BASH_BIN" ]]; then
    BREW_BASH_VERSION=$("$BASH_BIN" --version | head -n1 | grep -oE 'version [0-9]+' | grep -oE '[0-9]+' | head -n1 || echo "0")
    if [[ "${CURRENT_BASH_VERSION:-0}" -lt 4 ]] && [[ "${BREW_BASH_VERSION:-0}" -ge 4 ]]; then
      info "Switching to brew-installed bash v${BREW_BASH_VERSION} for remaining modules..."
      # Re-execute this script with brew bash, skipping brew installation
      export SKIP_BREW=true
      exec "$BASH_BIN" "$0" "$@"
    fi
  fi
fi

# From here on, we're using bash 4+ (either natively or from brew)
run_module() {
  local m="$1"
  CURRENT_MODULE=$((CURRENT_MODULE + 1))
  local module_name=$(basename "$m")
  info "[$CURRENT_MODULE/$TOTAL_MODULES] ▶ Running module: $module_name"
  
  local start_time=$(date +%s)
  # shellcheck source=/dev/null
  if . "$m"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    success "✓ $module_name completed in ${duration}s"
    return 0
  else
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_error "$module_name" "Module failed after ${duration}s"
    warn "Module failed: $module_name"
    return 1
  fi
}

failures=()
modules=(
  "lib/02_fonts.sh"
  "lib/03_zsh.sh"
  "lib/04_starship.sh"
  "lib/05_bat.sh"
  "lib/06_git_setup.sh"
  "lib/07_datadog.sh"
  "lib/08_aws.sh"
  "lib/09_aliases.sh"
  "lib/98_verify.sh"
  "lib/99_summary.sh"
)

for m in "${modules[@]}"; do
  if ! run_module "$m"; then
    failures+=("$m")
  fi
done

if ((${#failures[@]})); then
  echo ""
  warn "⚠️ Some modules failed:"
  for f in "${failures[@]}"; do
    echo "   - $(basename "$f")"
  done
  echo ""
  warn "Check error log: $ERROR_LOG"
fi

success "Setup complete. Reload your shell:"
echo "   source ~/.zshrc"
