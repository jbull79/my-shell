#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

info "Adding common CLI aliases..."
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
if ! grep -q "# --- CLI Aliases ---" "$ZSHRC" 2>/dev/null; then
  cat <<'EOF' >> "$ZSHRC"

# --- CLI Aliases ---
alias cat="bat"
alias du="duf"
alias cd="z"
alias lg="lazygit"
alias ll="ls -alsh"
alias ddm="dog monitor show_all"
alias ddlog="datadog-ci logs upload"
EOF
  success "Aliases added to $ZSHRC"
else
  info "Aliases already present in $ZSHRC — skipping."
fi
