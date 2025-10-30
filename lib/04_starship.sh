#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail
[[ "${BASH_SOURCE[0]}" == "$0" ]] && { echo "Source via install.sh"; exit 1; }

info "Configuring Starship prompt..."
STARSHIP_DIR="${STARSHIP_DIR:-$HOME/.config}"
STARSHIP_DEFAULT_THEME="${STARSHIP_DEFAULT_THEME:-pastel-powerline}"
STARSHIP_GIT_THEME="${STARSHIP_GIT_THEME:-tokyo-night}"
STARSHIP_DEFAULT_CONF="$STARSHIP_DIR/starship_default.toml"
STARSHIP_GIT_CONF="$STARSHIP_DIR/starship_git.toml"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"

mkdir -p "$STARSHIP_DIR"

read -r -p "Would you like to customize Starship themes via presets now? (y/N): " CHANGE_STARSHIP
if [[ "$CHANGE_STARSHIP" =~ ^[Yy]$ ]]; then
  if command -v starship >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1; then
    mapfile -t PRESETS < <(starship preset --list || true)
    if (( ${#PRESETS[@]} > 0 )); then
      SEL_DEFAULT="$(printf '%s\n' "${PRESETS[@]}" | fzf --height=40% --reverse --border --ansi --prompt="Select preset for non-Git dirs: ")"
      SEL_GIT="$(printf '%s\n' "${PRESETS[@]}" | fzf --height=40% --reverse --border --ansi --prompt="Select preset for Git dirs: ")"
      [[ -n "${SEL_DEFAULT:-}" ]] && STARSHIP_DEFAULT_THEME="$SEL_DEFAULT"
      [[ -n "${SEL_GIT:-}" ]] && STARSHIP_GIT_THEME="$SEL_GIT"
    else
      warn "No Starship presets found, using defaults."
    fi
  else
    warn "Starship/fzf not found for interactive selection, using defaults."
  fi
fi

run "starship preset \"$STARSHIP_DEFAULT_THEME\" > \"$STARSHIP_DEFAULT_CONF\""
run "starship preset \"$STARSHIP_GIT_THEME\" > \"$STARSHIP_GIT_CONF\""

append_aws_block_once() {
  local file="$1"
  local begin="# --- AWS BLOCK BEGIN ---"
  local end="# --- AWS BLOCK END ---"
  if grep -qF "$begin" "$file" 2>/dev/null; then
    awk -v b="$begin" -v e="$end" '
      $0==b {inblk=1; next}
      $0==e {inblk=0; next}
      !inblk {print}
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  fi

  local aws_cfg="$HOME/.aws/config"
  local -a profiles=()
  if [[ -f "$aws_cfg" ]]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^\[profile[[:space:]]+(.+)\]$ ]] && profiles+=("${BASH_REMATCH[1]}")
    done < "$aws_cfg"
  fi
  [[ ${#profiles[@]} -eq 0 ]] && profiles=(default)

  declare -A style_for=( [prod]="bold red" [production]="bold red" [dev]="bold green" [development]="bold green" [staging]="bold yellow" [sandbox]="bold blue" )

  {
    echo ""
    echo "$begin"
    cat <<'STATIC'
# --- AWS Profile Indicator (Auto-generated) ---
[aws]
symbol = "☁️ "
style = "bold yellow"
format = "on [$profile]($style) "
disabled = false

[aws.profile_aliases]
STATIC

    declare -A seen=()
    for p in "${profiles[@]}"; do
      [[ -n "${seen[$p]:-}" ]] && continue
      seen[$p]=1
      case "$p" in
        prod|production) alias="production" ;;
        dev|development) alias="development" ;;
        staging) alias="staging" ;;
        sandbox) alias="sandbox" ;;
        *) alias="$p" ;;
      esac
      echo "${p} = \"${alias}\""
    done

    echo ""
    echo "[aws.style_map]"
    declare -A seen_alias=()
    for p in "${profiles[@]}"; do
      [[ -n "${seen[$p]:-}" ]] || continue
      case "$p" in
        prod|production) a="production" ;;
        dev|development) a="development" ;;
        staging) a="staging" ;;
        sandbox) a="sandbox" ;;
        *) a="$p" ;;
      esac
      [[ -n "${seen_alias[$a]:-}" ]] && continue
      seen_alias[$a]=1
      s="${style_for[$p]:-}"
      if [[ -z "$s" ]]; then
        case "$a" in
          production) s="bold red" ;;
          development) s="bold green" ;;
          staging) s="bold yellow" ;;
          sandbox) s="bold blue" ;;
          *) s="bold cyan" ;;
        esac
      fi
      echo "${a} = \"${s}\""
    done

    echo "$end"
    echo ""
  } >> "$file"
}

INSTALL_AWS_CLI="${INSTALL_AWS_CLI:-true}"
if [[ "$INSTALL_AWS_CLI" == "true" ]]; then
  append_aws_block_once "$STARSHIP_DEFAULT_CONF"
  append_aws_block_once "$STARSHIP_GIT_CONF"
fi

if ! grep -q "starship_preexec" "$ZSHRC"; then
  cat <<'EOF' >> "$ZSHRC"

# --- Dynamic Starship Theme Switch ---
starship_preexec() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    export STARSHIP_CONFIG="$HOME/.config/starship_git.toml"
  else
    export STARSHIP_CONFIG="$HOME/.config/starship_default.toml"
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd starship_preexec
eval "$(starship init zsh)"
EOF
fi

success "Starship configured (auto theme + AWS indicator)."
