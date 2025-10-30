#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Colored log helpers
_c_info="\033[1;34m"
_c_warn="\033[1;33m"
_c_err="\033[1;31m"
_c_succ="\033[1;32m"
_c_none="\033[0m"

info()    { echo -e "${_c_info}[INFO]${_c_none} $*"; }
warn()    { echo -e "${_c_warn}[WARN]${_c_none} $*"; }
error()   { echo -e "${_c_err}[ERROR]${_c_none} $*"; }
success() { echo -e "${_c_succ}[SUCCESS]${_c_none} $*"; }

# DRY_RUN aware runner
run() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

backup_file() {
  local file="$1"
  local backup_dir="${BACKUP_DIR:-$HOME/.setup_backups/backup_$(date +%Y%m%d_%H%M%S)}"
  mkdir -p "${BACKUP_BASE:-$HOME/.setup_backups}"
  if [[ -f "$file" ]]; then
    mkdir -p "$backup_dir"
    info "Backed up $file → $backup_dir"
    cp "$file" "$backup_dir/$(basename "$file")"
  fi
}

ensure_line_in_file() {
  local file="$1"; shift
  local line="$*"
  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf "%s\n" "$line" >> "$file"
  fi
}

die_if_sourced_directly() {
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Source via install.sh"; exit 1
  fi
}

die_if_sourced_directly
