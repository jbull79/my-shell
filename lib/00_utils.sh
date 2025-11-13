#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Colored log helpers
_c_info="\033[1;34m"
_c_warn="\033[1;33m"
_c_err="\033[1;31m"
_c_succ="\033[1;32m"
_c_none="\033[0m"

info() { echo -e "${_c_info}[INFO]${_c_none} $*"; }
warn() { echo -e "${_c_warn}[WARN]${_c_none} $*"; }
error() { echo -e "${_c_err}[ERROR]${_c_none} $*"; }
success() { echo -e "${_c_succ}[SUCCESS]${_c_none} $*"; }

# Error logging with timestamp
log_error() {
  local module="${1:-unknown}"
  local message="${2:-}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] ERROR in $module: $message" >> "${ERROR_LOG:-$HOME/.setup_backups/errors.log}" 2>/dev/null || true
  error "$message"
}

# Check if command exists
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" > /dev/null 2>&1; then
    log_error "${BASH_SOURCE[1]##*/}" "Required command '$cmd' not found"
    return 1
  fi
  return 0
}

# Retry function for network operations
retry() {
  local max_attempts="${RETRY_MAX:-3}"
  local delay="${RETRY_DELAY:-2}"
  local attempt=1
  local cmd="$*"
  
  while [ $attempt -le $max_attempts ]; do
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
      echo "[DRY-RUN] Would retry (attempt $attempt/$max_attempts): $cmd"
      return 0
    fi
    
    if eval "$cmd"; then
      return 0
    fi
    
    if [ $attempt -lt $max_attempts ]; then
      warn "Attempt $attempt failed, retrying in ${delay}s..."
      sleep "$delay"
      delay=$((delay * 2))  # Exponential backoff
    fi
    attempt=$((attempt + 1))
  done
  
  error "Failed after $max_attempts attempts: $cmd"
  return 1
}

# DRY_RUN aware runner with better output
run() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "[DRY-RUN] Would execute: $*"
    echo "         Command: $(command -v "$1" 2>/dev/null || echo "$1")"
    echo "         Args: ${*:2}"
    return 0
  else
    if ! "$@"; then
      log_error "${BASH_SOURCE[1]##*/}" "Command failed: $*"
      return 1
    fi
    return 0
  fi
}

# Network download with retry
download_with_retry() {
  local url="$1"
  local output="${2:-}"
  local cmd="curl -fsSL"
  if [[ -n "$output" ]]; then
    cmd="$cmd -o \"$output\""
  fi
  cmd="$cmd \"$url\""
  retry "$cmd"
}

backup_file() {
  local file="$1"
  local backup_dir="${BACKUP_DIR:-$HOME/.setup_backups/backup_$(date +%Y%m%d_%H%M%S)}"
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    if [[ -f "$file" ]]; then
      info "[DRY-RUN] Would backup $file → $backup_dir"
    else
      info "[DRY-RUN] Would backup $file (file does not exist)"
    fi
    return 0
  fi
  
  mkdir -p "${BACKUP_BASE:-$HOME/.setup_backups}"
  if [[ -f "$file" ]]; then
    mkdir -p "$backup_dir"
    info "Backed up $file → $backup_dir"
    cp "$file" "$backup_dir/$(basename "$file")"
  fi
}

ensure_line_in_file() {
  local file="$1"
  shift
  local line="$*"
  
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    if grep -Fqx "$line" "$file" 2>/dev/null; then
      info "[DRY-RUN] Line already exists in $file"
    else
      info "[DRY-RUN] Would add line to $file: $line"
    fi
    return 0
  fi
  
  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf "%s\n" "$line" >> "$file"
  fi
}

die_if_sourced_directly() {
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Source via install.sh"
    exit 1
  fi
}

die_if_sourced_directly
