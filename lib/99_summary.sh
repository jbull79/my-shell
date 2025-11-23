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

echo "📦 Backup directory: ${BACKUP_DIR:-$HOME/.setup_backups/backup_$(date +%Y%m%d_%H%M%S)}"
echo "✅ Setup complete!"
echo "💡 Font: MesloLGS NF (set in terminal preferences)"
echo ""
echo "You can verify glyph support with:"
echo "  echo '         '"
echo ""
echo "───────────────────────────────────────────────"
echo "✅ SETUP SUMMARY"
echo "───────────────────────────────────────────────"
echo "📦 Backups:          ${BACKUP_DIR:-$HOME/.setup_backups}"
echo "🔐 SSH Key:          ${SSH_DIR:-$HOME/.ssh}/id_ed25519"
echo "🔑 GPG Key:          ${GPG_DIR:-$HOME/.gnupg}"
echo "🧱 Git Config:       ${GITCONFIG:-$HOME/.gitconfig}"
echo "💡 Font:             MesloLGS NF"
echo "🚀 Starship auto-switch: Enabled (Git/Non-Git)"
echo "🧩 Bat Theme:        ${BAT_DEFAULT_THEME:-TwoDark}"
echo ""
echo "☁️ AWS CLI SETUP"
echo "───────────────────────────────────────────────"
echo "📁 Config Directory: ${AWS_CONFIG_DIR:-$HOME/.aws}"
echo "🧾 Config File:      ${AWS_CONFIG_DIR:-$HOME/.aws}/config"
echo "🔑 Credentials File: ${AWS_CONFIG_DIR:-$HOME/.aws}/credentials"

if [[ -f "${AWS_CONFIG_DIR:-$HOME/.aws}/config" ]]; then
  PROFILES=$(grep -E '^\[profile ' "${AWS_CONFIG_DIR:-$HOME/.aws}/config" | sed -E 's/^\[profile (.*)\]/\1/' | xargs || true)
  [[ -z "$PROFILES" ]] && PROFILES="dev prod"
else
  PROFILES="dev prod"
fi
echo "🧩 Profiles Created: ${PROFILES}"
echo "🌍 Default Output:   json"
echo ""
echo "To update credentials later:"
echo "  aws configure --profile <profile>"
echo ""
echo "Manual edit locations:"
echo "  - ${AWS_CONFIG_DIR:-$HOME/.aws}/config"
echo "  - ${AWS_CONFIG_DIR:-$HOME/.aws}/credentials"
echo ""
echo "🔁 Profile Switching: Enabled"
echo "   → Use 'aws-switch' to choose a profile (fzf picker)"
echo "   → Use 'aws-whoami' to verify active credentials"
echo ""
echo "[INFO] Setup complete. Please reload your shell manually to apply all changes:"
echo "   source ~/.zshrc"
echo ""
echo "───────────────────────────────────────────────"
echo "💡  IMPORTANT: Set your terminal font manually!"
echo "───────────────────────────────────────────────"
echo ""
echo "Starship uses Nerd Font icons. To display them correctly:"
echo ""
echo "  1️⃣  Open your terminal preferences"
echo "  2️⃣  Change the font to:  MesloLGS NF"
echo "  3️⃣  Restart your terminal session"
echo ""
echo "You can verify glyph support with this command:"
echo "  echo '         '"
echo ""
echo "If icons appear correctly, your setup is complete ✅"
