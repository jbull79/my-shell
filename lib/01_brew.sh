#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && {
  echo "Source via install.sh"
  exit 1
}

ZSHRC="${ZSHRC:-$HOME/.zshrc}"
GITCONFIG="${GITCONFIG:-$HOME/.gitconfig}"
BACKUP_BASE="${BACKUP_BASE:-$HOME/.setup_backups}"
BACKUP_DIR="${BACKUP_DIR:-$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$BACKUP_BASE"

backup_file "$ZSHRC"
backup_file "$GITCONFIG"

# Determine brew prefix and setup shellenv once
if command -v brew > /dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  eval "$(brew shellenv)"
else
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  else
    BREW_PREFIX="/opt/homebrew"
  fi
  # Try to eval shellenv even if brew not in PATH yet
  eval "$("$BREW_PREFIX"/bin/brew shellenv 2> /dev/null || true)"
fi

# Install / update Homebrew
if ! command -v brew > /dev/null 2>&1; then
  info "Installing Homebrew..."
  retry '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  # Setup shellenv after installation
  eval "$("$BREW_PREFIX"/bin/brew shellenv)"
else
  info "Homebrew already installed. Updating..."
  run brew update
  # Ensure shellenv is set
  eval "$(brew shellenv)"
fi

# Clean TLDR legacy rename
if brew list --formula | grep -q '^tldr$'; then
  warn "Unlinking old 'tldr' formula..."
  run "brew unlink tldr"
fi

# Tool list (bash added here for bash 4+ features)
TOOLS_DEFAULT=(
  bash git zoxide bat duf
  fzf fd ripgrep eza
  tlrc thefuck git-delta starship
  uv tfenv terraform lazygit
  direnv zsh-autosuggestions zsh-syntax-highlighting
  gnupg tmux wget
)
TOOLS=("${TOOLS[@]:-${TOOLS_DEFAULT[@]}}")

info "Installing brew formulae:"
for t in "${TOOLS[@]}"; do
  echo "   • $t"
done

run "brew install ${TOOLS[*]}"

# Install bash v4+ and export BASH_BIN for subsequent scripts
info "Setting up bash v4+..."
BASH_BIN="$(brew --prefix)/bin/bash"
if [[ ! -f "$BASH_BIN" ]]; then
  error "Bash installation failed!"
  exit 1
fi

# Verify bash version is 4+
BASH_VERSION=$("$BASH_BIN" --version | head -n1 | grep -oE 'version [0-9]+' | grep -oE '[0-9]+' | head -n1)
if [[ "${BASH_VERSION:-0}" -lt 4 ]]; then
  error "Installed bash version is too old (got $BASH_VERSION, need 4+)"
  exit 1
fi

# Export BASH_BIN so install.sh can use it
export BASH_BIN
info "Using bash v${BASH_VERSION} from: $BASH_BIN"

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
