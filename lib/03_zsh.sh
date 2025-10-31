#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

ZSHRC="${ZSHRC:-$HOME/.zshrc}"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  run "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
else
  info "Oh My Zsh already installed."
fi

ensure_line_in_file "$ZSHRC" '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
success "Zsh base configured."
