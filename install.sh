#!/usr/bin/env bash
set -euo pipefail

export DRY_RUN="${DRY_RUN:-false}"
export BACKUP_BASE="${BACKUP_BASE:-$HOME/.setup_backups}"
export BACKUP_DIR="${BACKUP_DIR:-$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)}"

# shellcheck source=lib/00_utils.sh
. "$(dirname "$0")/lib/00_utils.sh"

info "🚀 Starting full environment bootstrap..."

run_module() {
  local m="$1"
  info "▶ Running module: $(basename "$m")"
  # shellcheck source=/dev/null
  if . "$m"; then
    return 0
  else
    warn "Module failed: $(basename "$m")"
    return 1
  fi
}

failures=()
modules=(
  "lib/01_brew.sh"
  "lib/02_fonts.sh"
  "lib/03_zsh.sh"
  "lib/04_starship.sh"
  "lib/05_bat.sh"
  "lib/06_git_setup.sh"
  "lib/07_datadog.sh"
  "lib/08_aws.sh"
  "lib/09_aliases.sh"
  "lib/99_summary.sh"
)

for m in "${modules[@]}"; do
  if ! run_module "$m"; then
    failures+=("$m")
  fi
done

if (( ${#failures[@]} )); then
  echo ""
  warn "⚠️ Some modules failed:"
  for f in "${failures[@]}"; do
    echo "   - $(basename "$f")"
  done
fi

success "Setup complete. Reload your shell:"
echo "   source ~/.zshrc"
