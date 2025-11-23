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
  uv tfenv terraform lazygit lazydocker
  direnv zsh-autosuggestions zsh-syntax-highlighting
  gnupg tmux wget git-flow awscli 
)
TOOLS=("${TOOLS[@]:-${TOOLS_DEFAULT[@]}}")

info "Installing brew formulae:"
for t in "${TOOLS[@]}"; do
  echo "   • $t"
done

run "brew install ${TOOLS[*]}"

# Install Python packages (boto3 for AWS)
info "Installing Python packages..."
if command -v uv > /dev/null 2>&1; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY-RUN] Would install boto3 via uv"
  else
    if ! python3 -c "import boto3" 2>/dev/null; then
      run "uv pip install boto3 --quiet"
      info "boto3 installed via uv"
    else
      info "boto3 already installed"
    fi
  fi
elif command -v pip3 > /dev/null 2>&1; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY-RUN] Would install boto3 via pip3"
  else
    if ! python3 -c "import boto3" 2>/dev/null; then
      run "pip3 install boto3 --quiet"
      info "boto3 installed via pip3"
    else
      info "boto3 already installed"
    fi
  fi
fi

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

# Install fonts
info "Installing Meslo Nerd Font..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! brew list --cask font-meslo-lg-nerd-font > /dev/null 2>&1; then
    run "brew install --cask font-meslo-lg-nerd-font"
  else
    info "Meslo Nerd Font already installed."
  fi
else
  if ! command -v fc-list > /dev/null 2>&1; then
    run "brew install fontconfig"
  fi
fi

# fzf key bindings
if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
  info "Installing fzf key bindings..."
  run "yes | $(brew --prefix)/opt/fzf/install --no-bash --no-fish --key-bindings --completion"
fi

success "✅ Homebrew & core tools stage complete."
