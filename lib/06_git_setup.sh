#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && {
  echo "Source via install.sh"
  exit 1
}

info "Configuring Git and SSH..."
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
GITCONFIG="${GITCONFIG:-$HOME/.gitconfig}"
SSH_DIR="${SSH_DIR:-$HOME/.ssh}"
USER_NAME="${USER_NAME:-Joe Bull}"
USER_EMAIL="${USER_EMAIL:-Joe.Bull@<company>.com}"

backup_file "$GITCONFIG"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

SSH_KEY="$SSH_DIR/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  info "Generating SSH key..."
  run "ssh-keygen -t ed25519 -C \"$USER_EMAIL\" -f \"$SSH_KEY\" -N ''"
else
  info "SSH key already exists: $SSH_KEY"
fi

read -r -p "Would you like to update your global Git config (name/email/signing)? (y/N): " UPDATE_GIT
if [[ "$UPDATE_GIT" =~ ^[Yy]$ ]]; then
  git config --global user.name "$USER_NAME"
  git config --global user.email "$USER_EMAIL"
fi

git config --global alias.s status || true
git config --global alias.st status || true
git config --global alias.c commit || true
git config --global alias.sw switch || true
git config --global alias.br branch || true

success "Git configuration complete."
