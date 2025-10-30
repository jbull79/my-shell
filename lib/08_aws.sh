#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

INSTALL_AWS_CLI="${INSTALL_AWS_CLI:-true}"
AWS_CONFIG_DIR="${AWS_CONFIG_DIR:-$HOME/.aws}"
if [[ "$INSTALL_AWS_CLI" != "true" ]]; then
  info "AWS CLI disabled by config."
  exit 0
fi

info "Installing AWS CLI (if not present)..."
if ! command -v aws >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    run "brew install awscli"
  else
    run "pip install awscli --quiet"
  fi
else
  info "AWS CLI already installed."
fi

mkdir -p "$AWS_CONFIG_DIR"
CONFIG_FILE="$AWS_CONFIG_DIR/config"
CREDS_FILE="$AWS_CONFIG_DIR/credentials"
backup_file "$CONFIG_FILE"
backup_file "$CREDS_FILE"

BACKUP_DIR_AWS="${BACKUP_DIR:-$HOME/.setup_backups}/aws_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR_AWS"
info "Backed up existing AWS config → $BACKUP_DIR_AWS"
cp -a "$AWS_CONFIG_DIR"/* "$BACKUP_DIR_AWS" 2>/dev/null || true

: > "$CONFIG_FILE"
: > "$CREDS_FILE"

cat <<'HDR'

───────────────────────────────────────────────
☁️  AWS CLI Profile Setup
───────────────────────────────────────────────

HDR

read -r -p "Enter AWS profile names separated by spaces (default: 'dev prod'): " PROFILE_INPUT
PROFILE_INPUT="${PROFILE_INPUT//,/ }"
PROFILES=()
if [[ -z "${PROFILE_INPUT// }" ]]; then
  PROFILES=(dev prod)
else
  for p in $PROFILE_INPUT; do
    [[ "$p" =~ ^[a-zA-Z0-9_-]+$ ]] && PROFILES+=("$p") || warn "Ignoring invalid profile: $p"
  done
  (( ${#PROFILES[@]} == 0 )) && PROFILES=(dev prod)
fi

info "Profiles to configure: ${PROFILES[*]}"
echo ""
read -r -p "Do you want to provide valid AWS account details now? (y/N): " PROVIDE_CREDS

write_profile() {
  local profile="$1" region="$2" output="$3" access="$4" secret="$5"
  {
    echo ""
    echo "[profile $profile]"
    echo "region = $region"
    echo "output = $output"
  } >> "$CONFIG_FILE"

  {
    echo ""
    echo "[$profile]"
    echo "aws_access_key_id = $access"
    echo "aws_secret_access_key = $secret"
  } >> "$CREDS_FILE"
}

if [[ "$PROVIDE_CREDS" =~ ^[Yy]$ ]]; then
  for PROFILE in "${PROFILES[@]}"; do
    echo ""
    info "Configuring profile: $PROFILE"
    read -r -p "Enter region for $PROFILE (default: us-east-1): " REGION
    REGION=${REGION:-us-east-1}
    if ! [[ "$REGION" =~ ^[a-z]{2}-[a-z]+-[0-9]+$ ]]; then
      warn "Invalid region, using us-east-1"; REGION="us-east-1"
    fi
    read -r -p "Enter output format for $PROFILE (default: json): " OUTPUT
    OUTPUT=${OUTPUT:-json}
    case "$OUTPUT" in json|yaml|yaml-stream|text) ;; *) OUTPUT="json";; esac
    read -r -p "Enter AWS Access Key ID for $PROFILE: " ACCESS_KEY
    read -r -p "Enter AWS Secret Access Key for $PROFILE: " SECRET_KEY
    [[ "$ACCESS_KEY" =~ ^[A-Z0-9]{16,}$ ]] || ACCESS_KEY="DUMMYACCESSKEY-$PROFILE"
    [[ "$SECRET_KEY" =~ ^[A-Za-z0-9/+=]{30,}$ ]] || SECRET_KEY="DUMMYSECRETKEY-$PROFILE"
    write_profile "$PROFILE" "$REGION" "$OUTPUT" "$ACCESS_KEY" "$SECRET_KEY"
  done
else
  for PROFILE in "${PROFILES[@]}"; do
    write_profile "$PROFILE" "us-east-1" "json" "DUMMYACCESSKEY-$PROFILE" "DUMMYSECRETKEY-$PROFILE"
  done
fi

success "AWS CLI configured successfully."
