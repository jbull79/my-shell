#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && {
  echo "Source via install.sh"
  exit 1
}

info "Ensuring Meslo Nerd Font is installed..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  info "Installing Meslo Nerd Font (macOS)..."
  if ! brew list --cask font-meslo-lg-nerd-font > /dev/null 2>&1; then
    if ! run "brew install --cask font-meslo-lg-nerd-font"; then
      warn "Brew cask failed; falling back to manual download."
      TMP="$(mktemp -d)"
      run "curl -fsSL -o \"$TMP/Meslo.zip\" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip"
      run "unzip -o \"$TMP/Meslo.zip\" -d \"$TMP/meslo\""
      run "cp \"$TMP/meslo\"/*.ttf ~/Library/Fonts/"
    fi
  fi
else
  if ! command -v fc-list > /dev/null 2>&1; then
    run "brew install fontconfig"
  fi
  if ! fc-list | grep -qi 'MesloLGS NF'; then
    TMP="$(mktemp -d)"
    run "curl -fsSL -o \"$TMP/Meslo.zip\" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Meslo.zip"
    run "unzip -o \"$TMP/Meslo.zip\" -d \"$TMP/meslo\""
    mkdir -p "$HOME/.local/share/fonts"
    run "cp \"$TMP/meslo\"/*.ttf \"$HOME/.local/share/fonts/\""
    run "fc-cache -fv"
  fi
fi
success "Installed Meslo Nerd Font."
