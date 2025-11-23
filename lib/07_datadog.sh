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

INSTALL_DATADOG_TOOLS="${INSTALL_DATADOG_TOOLS:-false}"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
DATADOG_API_KEY="${DATADOG_API_KEY:-}"
DATADOG_APP_KEY="${DATADOG_APP_KEY:-}"
DATADOG_SITE="${DATADOG_SITE:-datadoghq.com}"

if [[ "$INSTALL_DATADOG_TOOLS" == "true" ]]; then
  read -r -p "Do you want to install Datadog CLI tools for local debugging? (y/N): " INSTALL_DD
  if [[ "$INSTALL_DD" =~ ^[Yy]$ ]]; then
    info "Installing Datadog CLI tools..."
    
    # Check and install Python packages if missing
    ensure_python_package "datadog" "datadog"
    ensure_python_package "datadogpy" "datadog"
    
    # Check and install npm package if missing
    if ! command -v datadog-ci > /dev/null 2>&1; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY-RUN] Would install @datadog/datadog-ci via npm"
      else
        run "npm install -g @datadog/datadog-ci"
      fi
    else
      info "datadog-ci already installed"
    fi

    read -r -p "Would you like to install ddtrace (APM library)? (y/N): " INSTALL_DDTRACE
    if [[ "$INSTALL_DDTRACE" =~ ^[Yy]$ ]]; then
      ensure_python_package "ddtrace" "ddtrace"
    fi

    if ! grep -q "### DATADOG CONFIG START" "$ZSHRC"; then
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY-RUN] Would add Datadog configuration to $ZSHRC"
      else
        cat << EOF >> "$ZSHRC"

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
    fi

    success "Datadog CLI installed and configured."
  else
    info "Skipping Datadog CLI tools setup."
  fi
else
  info "Datadog tools disabled by config."
fi
