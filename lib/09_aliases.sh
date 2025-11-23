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

info "Adding common CLI aliases..."
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
if ! grep -q "# --- CLI Aliases ---" "$ZSHRC" 2> /dev/null; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY-RUN] Would add CLI aliases to $ZSHRC"
  else
    cat << 'EOF' >> "$ZSHRC"

########################################################
# --- CLI Aliases ---

# File Operations
alias cat="bat"
alias cd="z"
alias du="duf"
alias la="eza -la"
alias lh="eza -lh"
alias ll="eza -l"
alias lla="eza -la"
alias ls="eza"
alias lt="eza --tree"

# Directory Navigation
alias -- -="cd -"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# Git Aliases
alias ga="git add"
alias gaa="git add --all"
alias gb="git branch"
alias gba="git branch -a"
alias gbd="git branch -d"
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"
alias gcb="git checkout -b"
alias gc="git commit"
alias gcl="git clone"
alias gclean="git clean -fd"
alias gcm="git commit -m"
alias gco="git checkout"
alias gd="git diff"
alias gds="git diff --staged"
alias gf="git fetch"
alias glog="git log --oneline --graph --decorate"
alias gloga="git log --oneline --graph --decorate --all"
alias gm="git merge"
alias gma="git merge --abort"
alias gp="git push"
alias gpl="git pull"
alias gr="git reset"
alias grh="git reset --hard"
alias grsoft="git reset --soft"
alias grv="git remote -v"
alias gs="git status"
alias gst="git status"
alias gstash="git stash"
alias gstashl="git stash list"
alias gstashp="git stash pop"
alias gpu="git push -u origin"
alias lzg="lazygit"

# Terraform Aliases
alias tf="terraform"
alias tfa="terraform apply"
alias tfc="terraform console"
alias tfd="terraform destroy"
alias tff="terraform fmt"
alias tfi="terraform init"
alias tfo="terraform output"
alias tfp="terraform plan"
alias tfs="terraform show"

# AWS Aliases
alias awsregions="aws ec2 describe-regions --query 'Regions[].RegionName' --output text"
alias awswho="aws sts get-caller-identity"

# Datadog Aliases
alias ddm="dog monitor show_all"
alias ddlog="datadog-ci logs upload"

# Docker Aliases
alias lzd="lazydocker"

EOF
    success "Aliases added to $ZSHRC"
  fi
else
  info "Aliases already present in $ZSHRC — skipping."
fi
