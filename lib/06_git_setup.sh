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
SSH_KEY="$HOME/.ssh/id_rsa_git"
SSH_KEY_COMMENT="Git SSH Key"

# Backup existing config
backup_file "$GITCONFIG"

# Ensure SSH key
if [[ ! -f "$SSH_KEY" ]]; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY-RUN] Would generate new SSH key: $SSH_KEY"
    info "[DRY-RUN] Would set permissions: 600 for private key, 644 for public key"
    info "[DRY-RUN] Would add key to ssh-agent"
  else
    info "Generating new SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY" -N ""
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
    
    # Check if ssh-agent is already running
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
      eval "$(ssh-agent -s)"
    else
      info "SSH agent already running"
    fi
    ssh-add "$SSH_KEY"
  fi
else
  info "SSH key already exists: $SSH_KEY"
  # Ensure permissions are correct even if key exists (only in non-dry-run)
  if [[ "${DRY_RUN:-false}" != "true" ]]; then
    chmod 600 "$SSH_KEY" 2>/dev/null || true
    chmod 644 "$SSH_KEY.pub" 2>/dev/null || true
  fi
fi

# Offer to configure Git identity
read -r -p "Would you like to update your global Git config (name/email/signing)? (y/N): " CONFIGURE_GIT
if [[ "$CONFIGURE_GIT" =~ ^[Yy]$ ]]; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY-RUN] Would configure Git identity (name/email/signing)"
  else
    read -r -p "Enter your name: " GIT_NAME
    read -r -p "Enter your email: " GIT_EMAIL
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global commit.gpgsign true
    git config --global gpg.format ssh
    git config --global user.signingkey "$SSH_KEY.pub"
  fi
fi

# --- Add global Git aliases ---
info "Adding helpful Git aliases..."

if [[ "${DRY_RUN:-false}" == "true" ]]; then
  info "[DRY-RUN] Would add Git aliases: rebase-main, squash, lg, st, co, br, ci, df"
else
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
fi

success "Git configuration complete."
