#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

INSTALL_DATADOG_TOOLS="${INSTALL_DATADOG_TOOLS:-false}"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
DATADOG_API_KEY="${DATADOG_API_KEY:-}"
DATADOG_APP_KEY="${DATADOG_APP_KEY:-}"
DATADOG_SITE="${DATADOG_SITE:-datadoghq.com}"

if [[ "$INSTALL_DATADOG_TOOLS" == "true" ]]; then
  read -r -p "Do you want to install Datadog CLI tools for local debugging? (y/N): " INSTALL_DD
  if [[ "$INSTALL_DD" =~ ^[Yy]$ ]]; then
    info "Installing Datadog CLI tools..."
    run "pip install datadog datadogpy --quiet"
    run "npm install -g @datadog/datadog-ci"

    read -r -p "Would you like to install ddtrace (APM library)? (y/N): " INSTALL_DDTRACE
    if [[ "$INSTALL_DDTRACE" =~ ^[Yy]$ ]]; then
      run "pip install ddtrace --quiet"
    fi

    if ! grep -q "### DATADOG CONFIG START" "$ZSHRC"; then
      cat <<EOF >> "$ZSHRC"

### DATADOG CONFIG START ###
export DATADOG_API_KEY="${DATADOG_API_KEY}"
export DATADOG_APP_KEY="${DATADOG_APP_KEY}"
export DATADOG_SITE="${DATADOG_SITE}"
alias ddq="dog metric query"
alias dmon="dog monitor show_all"
alias dtrace="datadog-ci trace upload"
### DATADOG CONFIG END ###
EOF
    fi

    success "Datadog CLI installed and configured."
  else
    info "Skipping Datadog CLI tools setup."
  fi
else
  info "Datadog tools disabled by config."
fi
