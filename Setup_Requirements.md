# 🧰 CLI Environment Setup — Requirements & Inputs

This document describes **all required and optional inputs** for running `cli-setup.sh` successfully.  
It ensures your local CLI environment installs cleanly and all integrations (Git, GPG, Datadog, Starship) work as expected.

---

## ⚙️ Overview

`cli-setup.sh` automates setup of a complete developer CLI environment, including:

- Homebrew, Oh My Zsh, Starship prompt  
- Bat, FZF, Git, Terraform, LazyGit, and others  
- SSH & GPG keys  
- Optional Datadog CLI & monitoring tools  
- Automatic Starship theme switching (Git vs. non-Git dirs)  

---

## 🧩 Required Inputs

These are **mandatory** to run the script without errors.

| Variable | Example | Purpose |
|-----------|----------|----------|
| `USER_NAME` | `"Joe Bull"` | Your name for Git commits and GPG key metadata |
| `USER_EMAIL` | `"Joe.Bull@company.com"` | Used for Git commits, SSH key comment, and GPG identity |

📍 **Where to set:**
Edit these lines at the top of `cli-setup.sh` before running:

```bash
USER_NAME="Joe Bull"
USER_EMAIL="Joe.Bull@company.com"
```

---

## 🐙 GitHub Integration (SSH + GPG)

### SSH Key

The script auto-generates:

```bash
~/.ssh/id_ed25519
```

To link it to GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the key and add it at  
**GitHub → Settings → SSH and GPG keys → New SSH key**

---

### GPG Key

Used for signed commits/tags. Generated automatically:

```bash
~/.gnupg/
```

To add it to GitHub:

```bash
gpg --armor --export "Joe.Bull@company.com"
```

Paste the result into  
**GitHub → Settings → SSH and GPG keys → New GPG key**

---

## 🧱 Optional Integrations

### 🐶 Datadog CLI & Local Tools

If you set:

```bash
INSTALL_DATADOG_TOOLS=true
```

You’ll need the following keys from your  
**Datadog account → Integrations → APIs**:

| Variable | Example | Description |
|-----------|----------|-------------|
| `DATADOG_API_KEY` | `"pub12345abcdef"` | Your main Datadog API key |
| `DATADOG_APP_KEY` | `"app12345abcdef"` | Required for monitor/metrics queries |
| `DATADOG_SITE` | `"datadoghq.com"` or `"datadoghq.eu"` | Region selector |

📍 **How to update later:**

```bash
sed -i '' 's/^export DATADOG_API_KEY=.*/export DATADOG_API_KEY="NEW_KEY"/' ~/.zshrc
sed -i '' 's/^export DATADOG_APP_KEY=.*/export DATADOG_APP_KEY="NEW_KEY"/' ~/.zshrc
source ~/.zshrc
```

**Datadog aliases provided:**

```bash
ddq      → dog metric query
dmon     → dog monitor show_all
dtrace   → datadog-ci trace upload
```

---

## 🎨 Themes & Fonts

### Starship (Prompt)

Two config files are created:

```bash
~/.config/starship_default.toml   # used outside Git repos
~/.config/starship_git.toml       # used inside Git repos
```

**Default themes:**
- Non-Git: `pastel-powerline`
- Git repos: `tokyo-night`

💡 You’ll be asked interactively if you want to pick others from Starship’s presets.

---

### Bat (Syntax Highlighting)

Default theme: `TwoDark`

You’ll be prompted to change it interactively with an FZF preview:

```bash
bat --list-themes
```

---

### Font Requirement

Starship and Git symbols require a **Nerd Font**.

The script installs:

```bash
MesloLGS NF
```

📍 **Set manually after setup:**

1. Open your terminal preferences  
2. Change font → **MesloLGS NF**  
3. Restart terminal  

Verify with:

```bash
echo '         '
```

If icons render correctly, your setup is complete ✅

---

## 💾 Backup & Recovery

Every run creates a backup:

```bash
~/.setup_backups/backup_YYYYMMDD_HHMMSS/
```

To revert:

```bash
./cli-setup.sh --revert
```

To test without making changes:

```bash
./cli-setup.sh --dry-run
```

---

## 🧩 Advanced Configuration (Optional Vars)

| Variable | Purpose | Default |
|-----------|----------|----------|
| `GIT_WORK_DIR` | Default Git repo folder | `~/git` |
| `GIT_LOCAL_DIR` | Local clone path for bat/fzf repos | `~/git-local` |
| `BACKUP_BASE` | Backup directory for dotfiles | `~/.setup_backups` |
| `INSTALL_RANCHER_DESKTOP` | macOS Rancher Desktop toggle | `true` |

---

## 🧠 Quick Reference Summary

| Component | Installed By | Config Path | Notes |
|------------|---------------|--------------|--------|
| **Homebrew** | System-wide | `/opt/homebrew` (mac) | Updates auto-handled |
| **Oh My Zsh** | Script | `~/.oh-my-zsh` | Custom plugins retained |
| **Starship** | Brew | `~/.config/starship_*.toml` | Auto theme switching |
| **Bat** | Brew | `~/.config/bat` | Theme + syntax cache |
| **Datadog CLI** | Pip + npm | `~/.zshrc` aliases | Optional |

---

## 🚀 Quickstart Commands

If this is your first setup, run the following:

```bash
# 1. Clone your repo
git clone git@github.com:jbull79/my-shell.git
cd my-shell

# 2. Make the script executable
chmod +x cli-setup.sh

# 3. Run setup
./cli-setup.sh
```

---

## ✅ Verification Checklist

| Task | Command | Expected Result |
|------|----------|----------------|
| Check font | `echo '         '` | Icons visible |
| Check Starship theme | `starship prompt` | Colors + icons visible |
| Check bat | `bat --list-themes` | TwoDark listed |
| Check Git SSH | `ssh -T git@github.com` | “Hi username! You’ve successfully authenticated.” |
| Check Datadog | `ddq "avg:last_5m:system.cpu.user{*}"` | Returns metric data |

---

## 🧠 Notes for Teams

If deploying across multiple machines or team members:
- Replace `USER_EMAIL` with each developer’s company email.
- Optionally set up internal defaults for:
  - `DATADOG_SITE` (`datadoghq.eu` for EU teams)
  - `INSTALL_RANCHER_DESKTOP=false` for non-macOS users.
- Share your company’s standard `.zshrc` snippet or alias pack if needed.

---

**Author:** Joe Bull  
**Last Updated:** 2025-10-27