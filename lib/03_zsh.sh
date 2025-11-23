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

ZSHRC="${ZSHRC:-$HOME/.zshrc}"

# Check and install zoxide if missing (for independent script runs)
ensure_command "zoxide" 'if command -v brew > /dev/null 2>&1; then brew install zoxide; else echo "Please install zoxide manually"; exit 1; fi'

# Check and install fzf if missing (for independent script runs)
ensure_command "fzf" 'if command -v brew > /dev/null 2>&1; then brew install fzf; else echo "Please install fzf manually"; exit 1; fi'

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  retry 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
else
  info "Oh My Zsh already installed."
fi

ensure_line_in_file "$ZSHRC" '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
ensure_line_in_file "$ZSHRC" 'eval "$(zoxide init zsh)"'
success "Zsh base configured."
