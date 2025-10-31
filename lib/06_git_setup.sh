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

# Backup existing config
backup_file "$GITCONFIG"

# Ensure SSH key
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$SSH_KEY" ]]; then
  info "Generating new SSH key..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "your_email@example.com" -f "$SSH_KEY" -N ""
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY"
else
  info "SSH key already exists: $SSH_KEY"
fi

# Offer to configure Git identity
read -r -p "Would you like to update your global Git config (name/email/signing)? (y/N): " CONFIGURE_GIT
if [[ "$CONFIGURE_GIT" =~ ^[Yy]$ ]]; then
  read -r -p "Enter your name: " GIT_NAME
  read -r -p "Enter your email: " GIT_EMAIL
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  git config --global commit.gpgsign true
  git config --global gpg.format ssh
  git config --global user.signingkey "$SSH_KEY.pub"
fi

# --- Add global Git aliases ---
info "Adding helpful Git aliases..."

# Safer interactive rebase
git config --global alias.rebase-main 'rebase -i origin/main'

# ✅ Squash alias (automated single-commit cleanup)
git config --global alias.squash '!f() { 
  base=$(git merge-base main HEAD) || exit 1;
  git reset --soft "$base" &&
  git commit -m "${1:-squash commit}" &&
  echo "✅ Squashed all commits since main into one.";
}; f'

# Shortcuts
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.st "status -sb"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.ci "commit"
git config --global alias.df "diff"

success "Git configuration complete."
