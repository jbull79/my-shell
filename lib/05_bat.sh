#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

info "Configuring bat syntax highlighting and themes..."
BAT_CONFIG_DIR="${BAT_CONFIG_DIR:-$HOME/.config/bat}"
GIT_LOCAL_DIR="${GIT_LOCAL_DIR:-$HOME/git-local}"
BAT_DEFAULT_THEME="${BAT_DEFAULT_THEME:-TwoDark}"
mkdir -p "$BAT_CONFIG_DIR"

if [[ ! -f "$BAT_CONFIG_DIR/config" ]]; then
  echo "--theme=\"$BAT_DEFAULT_THEME\"" > "$BAT_CONFIG_DIR/config"
  info "Set default bat theme: $BAT_DEFAULT_THEME"
fi

SKIP_BAT_CACHE="${SKIP_BAT_CACHE:-false}"
if [[ "$SKIP_BAT_CACHE" == "false" ]]; then
  mkdir -p "$GIT_LOCAL_DIR"
  if [[ ! -d "$GIT_LOCAL_DIR/bat" ]]; then
    info "Cloning bat repository..."
    run "git clone https://github.com/sharkdp/bat.git \"$GIT_LOCAL_DIR/bat\""
  else
    info "Updating bat repository..."
    run "git -C \"$GIT_LOCAL_DIR/bat\" pull --quiet"
  fi
  info "Rebuilding bat syntax and theme cache..."
  run "bat cache --clear"
  run "bat cache --build --source \"$BAT_CONFIG_DIR/syntaxes\" || true"
  run "bat cache --build --source \"$BAT_CONFIG_DIR/themes\" || true"
fi

read -r -p "Would you like to change your bat theme now? (y/N): " CHANGE_BAT
if [[ "$CHANGE_BAT" =~ ^[Yy]$ ]]; then
  mapfile -t THEMES < <(bat --list-themes || true)
  if (( ${#THEMES[@]} > 0 )); then
    DEMO_FILE="/tmp/bat_theme_demo.py"
    cat >"$DEMO_FILE" <<'PY'
# Example Python file for bat preview
def greet(name): print(f"Hello, {name}!")
greet("world")
PY
    SELECTED_THEME="$(printf '%s\n' "${THEMES[@]}" | fzf --height=80% --reverse --border --ansi \
      --prompt="Select bat theme: " \
      --preview "bat --color=always --theme={} $DEMO_FILE" \
      --preview-window=right:70% || true)"
    if [[ -n "${SELECTED_THEME:-}" ]]; then
      info "Setting bat theme to: $SELECTED_THEME"
      echo "--theme=\"$SELECTED_THEME\"" > "$BAT_CONFIG_DIR/config"
    else
      info "No theme selected — keeping current theme."
    fi
  else
    warn "No bat themes found."
  fi
fi

success "bat syntax and theme configuration complete."
