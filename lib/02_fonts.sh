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

info "Ensuring Meslo Nerd Font is installed..."

# Check for brew (for independent script runs)
if ! command -v brew > /dev/null 2>&1; then
  error "Homebrew is required to install fonts. Please run 01_brew.sh first or install Homebrew manually."
  exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  info "Installing Meslo Nerd Font (macOS)..."
  if ! brew list --cask font-meslo-lg-nerd-font > /dev/null 2>&1; then
    if ! run "brew install --cask font-meslo-lg-nerd-font"; then
      warn "Brew cask failed; falling back to manual download."
      TMP="$(mktemp -d)"
      download_with_retry "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip" "$TMP/Meslo.zip"
      run "unzip -o \"$TMP/Meslo.zip\" -d \"$TMP/meslo\""
      run "cp \"$TMP/meslo\"/*.ttf ~/Library/Fonts/"
    fi
  else
    info "Meslo Nerd Font already installed."
  fi
else
  if ! command -v fc-list > /dev/null 2>&1; then
    ensure_command "fontconfig" "brew install fontconfig"
  fi
  if ! fc-list | grep -qi 'MesloLGS NF'; then
    TMP="$(mktemp -d)"
    download_with_retry "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip" "$TMP/Meslo.zip"
    run "unzip -o \"$TMP/Meslo.zip\" -d \"$TMP/meslo\""
    mkdir -p "$HOME/.local/share/fonts"
    run "cp \"$TMP/meslo\"/*.ttf \"$HOME/.local/share/fonts/\""
    run "fc-cache -fv"
  else
    info "Meslo Nerd Font already installed."
  fi
fi
success "Installed Meslo Nerd Font."
