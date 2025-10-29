#!/usr/bin/env bash
set -e
# =============================================================================
# Joe's CLI Environment Bootstrap
# =============================================================================
# Purpose: Automate setup of a complete CLI environment with:
#   - Homebrew, Oh My Zsh, Starship (auto theme switch)
#   - Syntax highlighting, fuzzy search, aliases, SSH/GPG setup
#   - Git configuration + shortcuts
# =============================================================================

# ------------------------------
# Configuration Block
# ------------------------------

# ---- User Identity ----
USER_NAME="Joe Bull"                        # Name for git commits
USER_EMAIL="Joe.Bull@<company>.com"         # Git email address

# ---- Paths ----
ZSHRC="$HOME/.zshrc"                        # Zsh configuration file
GITCONFIG="$HOME/.gitconfig"                # Git configuration file
SSH_DIR="$HOME/.ssh"                        # SSH key directory
GPG_DIR="$HOME/.gnupg"                      # GPG key directory
GIT_WORK_DIR="$HOME/git"                    # Default git repo directory
GIT_LOCAL_DIR="$HOME/git-local"             # Local clones for tools
BACKUP_BASE="$HOME/.setup_backups"          # Backup folder
STARSHIP_DIR="$HOME/.config"                # Starship config folder
BAT_CONFIG_DIR="$HOME/.config/bat"          # Bat config folder

# ---- Themes ----
BAT_DEFAULT_THEME="TwoDark"                 # Default bat theme
STARSHIP_DEFAULT_THEME="pastel-powerline"   # Outside git repos
STARSHIP_GIT_THEME="tokyo-night"            # Inside git repos

# ---- Feature Toggles ----
DRY_RUN=false
REVERT=false
QUIET=false
SKIP_BAT_CACHE=false
INSTALL_RANCHER_DESKTOP=true
INSTALL_DATADOG_TOOLS=false               # Set false to skip Datadog CLI utilities

# ---- Datadog Configuration ----         
DATADOG_API_KEY=""                        # Your Datadog API Key (optional, leave blank for now)
DATADOG_APP_KEY=""                        # Your Datadog App Key (optional, leave blank for now)
DATADOG_SITE="datadoghq.com"              # Change to datadoghq.eu if in EU region

# ---- Tool List ----
TOOLS=(
    git zoxide bat duf fzf fd ripgrep eza tlrc thefuck git-delta
    starship uv tfenv terraform lazygit direnv
    zsh-autosuggestions zsh-syntax-highlighting gnupg tmux datadogpy datadog-ci
)

# =============================================================================
# Utility Functions
# =============================================================================
info() { [ "$QUIET" = true ] || echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

run() { if [ "$DRY_RUN" = true ]; then echo "[DRY-RUN] $*"; else eval "$@"; fi; }

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        info "Backing up $file to $BACKUP_DIR"
        cp "$file" "$BACKUP_DIR/$(basename "$file").bak"
    fi
}

# =============================================================================
# Initialization
# =============================================================================
BACKUP_DIR="$BACKUP_BASE/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_BASE"

for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --revert)  REVERT=true ;;
        --quiet)   QUIET=true ;;
        --skip-bat-cache) SKIP_BAT_CACHE=true ;;
    esac
done

if [ "$REVERT" = true ]; then
    LATEST_BACKUP=$(ls -td "$BACKUP_BASE"/* 2>/dev/null | head -n1 || true)
    [ -z "$LATEST_BACKUP" ] && error "No backups found in $BACKUP_BASE"
    info "Reverting from backup: $LATEST_BACKUP"
    for f in "$LATEST_BACKUP"/*.bak; do
        base=$(basename "$f" .bak)
        cp "$f" "$HOME/$base"
        info "Restored $HOME/$base"
    done
    info "✅ Revert complete."
    exit 0
fi

backup_file "$ZSHRC"
backup_file "$GITCONFIG"

# =============================================================================
# Environment Setup
# =============================================================================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    BREW_PREFIX="/home/linuxbrew/.linuxbrew"
else
    BREW_PREFIX="/opt/homebrew"
fi

if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    run "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
    info "Homebrew already installed. Updating..."
    run brew update
fi
run "eval \"\$($BREW_PREFIX/bin/brew shellenv)\""

info "Installing brew formulae: ${TOOLS[*]}"
if brew list --formula | grep -q '^tldr$'; then
    warn "Unlinking old 'tldr' formula..."
    run "brew unlink tldr"
fi
run "brew install ${TOOLS[*]}"

if [[ "$OSTYPE" != "linux-gnu"* && "$INSTALL_RANCHER_DESKTOP" = true ]]; then
    if [ ! -d "/Applications/Rancher Desktop.app" ]; then
        info "Installing Rancher Desktop..."
        run "brew install --cask rancher"
    else
        info "Rancher Desktop already installed."
    fi
fi

# --- Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh My Zsh..."
    run "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
else
    info "Oh My Zsh already installed."
fi

for dir in "$GIT_WORK_DIR" "$GIT_LOCAL_DIR" "$SSH_DIR" "$GPG_DIR"; do
    run "mkdir -p $dir && chmod 700 $dir"
done

# --- fzf Setup ---
if [ -f "$(brew --prefix)/opt/fzf/install" ]; then
    info "Installing fzf key bindings..."
    run "yes | $(brew --prefix)/opt/fzf/install --no-bash --no-fish --key-bindings --completion"
fi

# =============================================================================
# Font (for Starship Icons)
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! ls ~/Library/Fonts /Library/Fonts 2>/dev/null | grep -qi "MesloLGS NF"; then
        info "Installing Meslo Nerd Font for Starship icons..."
        run "brew install --cask font-meslo-lg-nerd-font"
    else
        info "Meslo Nerd Font already installed."
    fi
else
    # Linux systems: check via fc-list (fontconfig)
    if ! command -v fc-list &>/dev/null; then
        warn "fontconfig not found; installing for font detection..."
        run "brew install fontconfig"
    fi
    if ! fc-list | grep -qi 'MesloLGS NF'; then
        info "Installing Meslo Nerd Font for Starship icons..."
        run "brew install --cask font-meslo-lg-nerd-font"
    else
        info "Meslo Nerd Font already installed."
    fi
fi

# =============================================================================
# Starship Dynamic Config
# =============================================================================
run "mkdir -p \"$STARSHIP_DIR\""
STARSHIP_DEFAULT_CONF="$STARSHIP_DIR/starship_default.toml"
STARSHIP_GIT_CONF="$STARSHIP_DIR/starship_git.toml"

info "Generating Starship default (non-git) preset..."
run "starship preset \"$STARSHIP_DEFAULT_THEME\" > \"$STARSHIP_DEFAULT_CONF\""

info "Generating Starship git preset..."
run "starship preset \"$STARSHIP_GIT_THEME\" > \"$STARSHIP_GIT_CONF\""



# =============================================================================
# Optional: Interactive Starship Theme Selection
# =============================================================================
read -r -p "Would you like to customize your Starship themes for Git and non-Git directories? (y/N): " CHANGE_STARSHIP
if [[ "$CHANGE_STARSHIP" =~ ^[Yy]$ ]]; then
    info "Fetching available Starship presets..."
    PRESETS=($(starship preset --list))
    if [ ${#PRESETS[@]} -gt 0 ]; then
        info "Launching interactive selector for non-Git preset..."
        SELECTED_DEFAULT=$(
            printf '%s\n' "${PRESETS[@]}" |
            fzf --height=40% --reverse --border --ansi \
                --prompt="Select Starship preset for non-Git dirs: " \
                --preview="starship preset {} | head -40"
        )
        info "Launching interactive selector for Git preset..."
        SELECTED_GIT=$(
            printf '%s\n' "${PRESETS[@]}" |
            fzf --height=40% --reverse --border --ansi \
                --prompt="Select Starship preset for Git dirs: " \
                --preview="starship preset {} | head -40"
        )

        if [ -n "$SELECTED_DEFAULT" ]; then
            info "Applying non-Git Starship preset: $SELECTED_DEFAULT"
            run "starship preset $SELECTED_DEFAULT > \"$STARSHIP_DIR/starship_default.toml\""
        else
            warn "No non-Git preset selected. Keeping default ($STARSHIP_DEFAULT_THEME)."
        fi

        if [ -n "$SELECTED_GIT" ]; then
            info "Applying Git Starship preset: $SELECTED_GIT"
            run "starship preset $SELECTED_GIT > \"$STARSHIP_DIR/starship_git.toml\""
        else
            warn "No Git preset selected. Keeping default ($STARSHIP_GIT_THEME)."
        fi
    else
        warn "No Starship presets found. Skipping customization."
    fi
else
    info "Keeping default Starship presets: non-Git='$STARSHIP_DEFAULT_THEME', Git='$STARSHIP_GIT_THEME'."
fi



# Dynamic theme reload function (precmd hook)
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

# =============================================================================
# bat Theme + Syntax Cache
# =============================================================================
run "mkdir -p $BAT_CONFIG_DIR"

# Default theme
BAT_DEFAULT_THEME="TwoDark"

if [ ! -f "$BAT_CONFIG_DIR/config" ]; then
    echo "--theme=\"$BAT_DEFAULT_THEME\"" > "$BAT_CONFIG_DIR/config"
    info "Set default bat theme: $BAT_DEFAULT_THEME"
fi

# Cache rebuild (if not skipped)
if [ "$SKIP_BAT_CACHE" = false ]; then
    if [ ! -d "$GIT_LOCAL_DIR/bat" ]; then
        info "Cloning bat repository into $GIT_LOCAL_DIR..."
        run "git clone https://github.com/sharkdp/bat.git $GIT_LOCAL_DIR/bat"
    else
        info "Updating bat repository..."
        run "cd \"$GIT_LOCAL_DIR/bat\" && git pull --quiet"
    fi

    info "Rebuilding bat syntax and theme cache..."
    run "bat cache --clear"

    # Handle both new and legacy repo layouts
    if [ -d "$GIT_LOCAL_DIR/bat/syntaxes" ]; then
        SYNTAX_DIR="$GIT_LOCAL_DIR/bat/syntaxes"
    elif [ -d "$GIT_LOCAL_DIR/bat/assets/syntaxes" ]; then
        SYNTAX_DIR="$GIT_LOCAL_DIR/bat/assets/syntaxes"
    else
        SYNTAX_DIR=""
    fi

    if [ -d "$GIT_LOCAL_DIR/bat/themes" ]; then
        THEME_DIR="$GIT_LOCAL_DIR/bat/themes"
    elif [ -d "$GIT_LOCAL_DIR/bat/assets/themes" ]; then
        THEME_DIR="$GIT_LOCAL_DIR/bat/assets/themes"
    else
        THEME_DIR=""
    fi

    if [ -n "$SYNTAX_DIR" ]; then
        info "Building syntax cache from: $SYNTAX_DIR"
        run "bat cache --build --source \"$SYNTAX_DIR\""
    else
        warn "No syntax directory found — skipping syntax cache build."
    fi

    if [ -n "$THEME_DIR" ]; then
        info "Building theme cache from: $THEME_DIR"
        run "bat cache --build --source \"$THEME_DIR\""
    else
        warn "No theme directory found — skipping theme cache build."
    fi
fi

# Interactive theme change (fzf + live preview)
read -r -p "Would you like to change your bat theme? (y/N): " CHANGE_BAT
if [[ "$CHANGE_BAT" =~ ^[Yy]$ ]]; then
    THEMES=($(bat --list-themes))
    if [ ${#THEMES[@]} -eq 0 ]; then
        warn "No bat themes found — skipping theme selection."
    else
        DEMO_FILE="/tmp/bat_theme_demo.py"
        cat >"$DEMO_FILE" <<'EOF'
# Example Python file for bat preview
def greet(name): print(f"Hello, {name}!")
greet("world")
EOF
        SELECTED_THEME=$(printf '%s\n' "${THEMES[@]}" |
            fzf --height=100% --reverse --border --ansi \
                --prompt="Select bat theme: " \
                --preview "bat --color=always --theme={} $DEMO_FILE" \
                --preview-window=right:70%)
        if [ -n "$SELECTED_THEME" ]; then
            info "Setting bat theme to: $SELECTED_THEME"
            echo "--theme=\"$SELECTED_THEME\"" > "$BAT_CONFIG_DIR/config"
        else
            info "No theme selected — keeping current theme."
        fi
    fi
fi

info "bat theme and syntax cache configuration complete."

# =============================================================================
# Shell Aliases
# =============================================================================
if ! grep -q "alias cat=" "$ZSHRC"; then
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
fi

# =============================================================================
# SSH + GPG + Git Configuration
# =============================================================================
SSH_KEY="$SSH_DIR/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    info "Generating SSH key..."
    run "ssh-keygen -t ed25519 -C $USER_EMAIL -f $SSH_KEY -N ''"
fi

if ! gpg --list-keys "$USER_EMAIL" &>/dev/null; then
    info "Generating GPG key..."
    cat >"$HOME/gpg_batch" <<EOF
%no-protection
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: $USER_NAME
Name-Email: $USER_EMAIL
Expire-Date: 0
EOF
    run "gpg --batch --gen-key $HOME/gpg_batch"
    run "rm -f $HOME/gpg_batch"
fi

backup_file "$GITCONFIG"
if [ ! -f "$GITCONFIG" ]; then
    run "touch $GITCONFIG"
fi
if ! grep -q "^\[user\]" "$GITCONFIG"; then
cat <<EOF >> "$GITCONFIG"

[user]
    name = $USER_NAME
    email = $USER_EMAIL
EOF
fi
declare -A GIT_ALIASES=(
    ["s"]="status"
    ["st"]="status"
    ["c"]="commit"
    ["sw"]="switch"
    ["br"]="branch"
)
if ! grep -q "^\[alias\]" "$GITCONFIG"; then echo "[alias]" >> "$GITCONFIG"; fi
for key in "${!GIT_ALIASES[@]}"; do
    if ! grep -q "^[[:space:]]*$key[[:space:]]*=" "$GITCONFIG"; then
        echo "    $key = ${GIT_ALIASES[$key]}" >> "$GITCONFIG"
    fi
done

# =============================================================================
# Optional Datadog CLI & Local Developer Tools
# =============================================================================
if [ "$INSTALL_DATADOG_TOOLS" = true ]; then
    read -r -p "Do you want to install Datadog CLI tools for local debugging? (y/N): " INSTALL_DD
    if [[ "$INSTALL_DD" =~ ^[Yy]$ ]]; then
        info "Installing Datadog CLI tools and utilities..."

        # --- Install the core tools ---
        run "pip install datadog datadogpy --quiet"
        run "npm install -g @datadog/datadog-ci"

        # --- Optional: ddtrace (for APM/debugging) ---
        read -r -p "Would you like to install ddtrace (APM library)? (y/N): " INSTALL_DDTRACE
        if [[ "$INSTALL_DDTRACE" =~ ^[Yy]$ ]]; then
            run "pip install ddtrace --quiet"
        fi

        # --- Configure ZSH Environment Block ---
        if ! grep -q "### DATADOG CONFIG START" "$ZSHRC"; then
            cat <<EOF >> "$ZSHRC"

### DATADOG CONFIG START ###
# --- Datadog CLI Configuration ---
# API and APP keys are required to authenticate with Datadog API.
# To update them later, run:
#   sed -i '' 's/^export DATADOG_API_KEY=.*/export DATADOG_API_KEY="NEW_KEY"/' ~/.zshrc
#   sed -i '' 's/^export DATADOG_APP_KEY=.*/export DATADOG_APP_KEY="NEW_KEY"/' ~/.zshrc
# Then reload your shell:
#   source ~/.zshrc
#
# If you’re in the EU region, change the DATADOG_SITE value below to "datadoghq.eu"

export DATADOG_API_KEY="${DATADOG_API_KEY}"
export DATADOG_APP_KEY="${DATADOG_APP_KEY}"
export DATADOG_SITE="${DATADOG_SITE}"

# --- Datadog CLI Shortcuts ---
alias ddq="dog metric query"
alias dmon="dog monitor show_all"
alias dtrace="datadog-ci trace upload"
### DATADOG CONFIG END ###
EOF
        fi

        # --- Display summary for user ---
        info "✅ Datadog CLI installed and configured."
        echo ""
        echo "──────────────────────────────────────────────"
        echo "📡  DATADOG INTEGRATION SUMMARY"
        echo "──────────────────────────────────────────────"
        echo "Installed tools:"
        echo "  - dog (Datadog CLI via datadogpy)"
        echo "  - datadog-ci (Node CLI for CI visibility)"
        echo "  - ddtrace (optional local APM tracer)"
        echo ""
        echo "Environment file updated:"
        echo "  → $ZSHRC"
        echo ""
        echo "🔐 To update your Datadog API or APP keys later:"
        echo "   sed -i '' 's/^export DATADOG_API_KEY=.*/export DATADOG_API_KEY=\"NEW_API_KEY\"/' ~/.zshrc"
        echo "   sed -i '' 's/^export DATADOG_APP_KEY=.*/export DATADOG_APP_KEY=\"NEW_APP_KEY\"/' ~/.zshrc"
        echo "   source ~/.zshrc"
        echo ""
        echo "🌍 Current Datadog region: ${DATADOG_SITE}"
        echo "💡 You can query metrics like:"
        echo "   ddq \"avg:last_1h:system.cpu.user{*}\""
        echo "──────────────────────────────────────────────"
        echo ""
    else
        info "Skipping Datadog CLI tools setup."
    fi
fi

# =============================================================================
# Housekeeping
# =============================================================================
info "Setting permissions for backup directory..."
chmod 700 "$BACKUP_DIR"

info "Reloading shell to apply Starship theme..."
run "exec zsh -l"

# =============================================================================
# Summary
# =============================================================================
echo -e "\033[1;32m✅ Setup complete!\033[0m"
echo -e "\033[1;36m📦 Backups:\033[0m $BACKUP_DIR"
echo -e "\033[1;36m🔐 SSH Key:\033[0m $SSH_KEY"
echo -e "\033[1;36m🔑 GPG Key:\033[0m ~/.gnupg"
echo -e "\033[1;36m🚀 Starship auto-switch:\033[0m Enabled (Git/Non-Git)"
echo -e "\033[1;36m🧩 Bat Theme:\033[0m $BAT_DEFAULT_THEME"
echo -e "\033[1;36m💡 Font:\033[0m MesloLGS NF"
echo -e "\033[1;36m🧱 Git Config:\033[0m ~/.gitconfig"
echo -e "\033[1;36m🔑 Datadog API Key:\033[0m $DATADOG_API_KEY"
echo -e "\033[1;36m🔑 Datadog App Key:\033[0m $DATADOG_APP_KEY"
echo -e "\033[1;36m🌍 Datadog Site:\033[0m $DATADOG_SITE"

# =============================================================================
# Final Font Reminder
# =============================================================================
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
echo ""