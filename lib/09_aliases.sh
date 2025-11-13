#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && {
  echo "Source via install.sh"
  exit 1
}

info "Adding common CLI aliases..."
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
if ! grep -q "# --- CLI Aliases ---" "$ZSHRC" 2> /dev/null; then
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    info "[DRY-RUN] Would add CLI aliases to $ZSHRC"
  else
    cat << 'EOF' >> "$ZSHRC"

# --- CLI Aliases ---
alias cat="bat"
alias du="duf"
alias cd="z"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"
alias lg="lazygit"
alias ls="eza"
alias la="eza -la"
alias ll="eza -l"
alias lt="eza --tree"
alias lla="eza -la"
alias lh="eza -lh"
alias ddm="dog monitor show_all"
alias ddlog="datadog-ci logs upload"
alias gd="git diff"
alias gds="git diff --staged"
alias tf="terraform"
alias tfa="terraform apply"
alias tfp="terraform plan"
alias tfi="terraform init"
alias tfd="terraform destroy"
alias tfo="terraform output"
alias tfs="terraform show"
alias tfc="terraform console"
alias tff="terraform fmt"
alias tfi="terraform init"
alias tfd="terraform destroy"
alias tfo="terraform output"
alias tfs="terraform show"
alias tfc="terraform console"
alias tff="terraform fmt"
alias tfi="terraform init"
alias tfd="terraform destroy"
alias tfo="terraform output"
alias tfs="terraform show"
alias tfc="terraform console"
alias tff="terraform fmt"
alias awswho="aws sts get-caller-identity"
alias awsregions="aws ec2 describe-regions --query 'Regions[].RegionName' --output text"
EOF
    success "Aliases added to $ZSHRC"
  fi
else
  info "Aliases already present in $ZSHRC — skipping."
fi
