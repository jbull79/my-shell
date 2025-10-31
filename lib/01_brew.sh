#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

ZSHRC="${ZSHRC:-$HOME/.zshrc}"
GITCONFIG="${GITCONFIG:-$HOME/.gitconfig}"
BACKUP_BASE="${BACKUP_BASE:-$HOME/.setup_backups}"
BACKUP_DIR="${BACKUP_DIR:-$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$BACKUP_BASE"

backup_file "$ZSHRC"
backup_file "$GITCONFIG"

# Determine brew prefix
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
else
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  else
    BREW_PREFIX="/opt/homebrew"
  fi
fi
eval "$($BREW_PREFIX/bin/brew shellenv 2>/dev/null || true)"

# Install / update Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  eval "$("${BREW_PREFIX}"/bin/brew shellenv 2>/dev/null || true)"
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$("${BREW_PREFIX}"/bin/brew shellenv 2>/dev/null || true)"
else
  info "Homebrew already installed. Updating..."
  run brew update
fi

# Clean TLDR legacy rename
if brew list --formula | grep -q '^tldr$'; then
  warn "Unlinking old 'tldr' formula..."
  run "brew unlink tldr"
fi

# Tool list
TOOLS_DEFAULT=(
  git zoxide bat duf
  fzf fd ripgrep eza
  tlrc thefuck git-delta starship
  uv tfenv terraform lazygit
  direnv zsh-autosuggestions zsh-syntax-highlighting
  gnupg tmux
)
TOOLS=("${TOOLS[@]:-${TOOLS_DEFAULT[@]}}")

info "Installing brew formulae:"
for t in "${TOOLS[@]}"; do
  echo "   • $t"
done

run "brew install ${TOOLS[*]}"

# Optional Rancher Desktop (macOS only)
INSTALL_RANCHER_DESKTOP="${INSTALL_RANCHER_DESKTOP:-true}"
if [[ "$OSTYPE" != "linux-gnu"* && "$INSTALL_RANCHER_DESKTOP" == "true" ]]; then
  if [[ ! -d "/Applications/Rancher Desktop.app" ]]; then
    info "Installing Rancher Desktop..."
    run "brew install --cask rancher"
  else
    info "Rancher Desktop already installed."
  fi
fi

# fzf key bindings
if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
  info "Installing fzf key bindings..."
  run "yes | $(brew --prefix)/opt/fzf/install --no-bash --no-fish --key-bindings --completion"
fi

success "✅ Homebrew & core tools stage complete."
