# 🧠 my-shell — Automated CLI Environment Setup

A fully automated Bash script that bootstraps a **modern developer CLI environment** with everything you need — from `brew` to `oh-my-zsh`, `starship`, `fzf`, and developer tooling for Git, Terraform, Python, and more.

> ⚡ Designed for macOS (Apple Silicon) and Linux.  
> 🧩 Built by Joe Bull — opinionated, efficient, and ready for work.

---

## 🚀 Features

- **Package Management**
  - Installs and updates [Homebrew](https://brew.sh)
  - Installs all essential CLI tools in one pass

- **Shell & Environment**
  - Installs and configures [Oh My Zsh](https://ohmyz.sh)
  - Adds productivity tools:  
    `zoxide`, `fzf`, `bat`, `duf`, `ripgrep`, `fd`, `eza`, `thefuck`, `tlrc`
  - Includes ZSH plugins:
    - `zsh-autosuggestions`
    - `zsh-syntax-highlighting`

- **Developer Tools**
  - Installs `git`, `terraform`, `tfenv`, `direnv`, `uv`, `lazygit`
  - Configures aliases (`cat → bat`, `du → duf`, `cd → z`, `lg → lazygit`)
  - Initializes a clean `.gitconfig` with your name, email, and aliases
  - Auto-generates **SSH and GPG keys** for GitHub/GitLab

- **Starship Prompt**
  - Configures [Starship](https://starship.rs) for both:
    - Regular terminal sessions (🎨 `pastel-powerline`)
    - Git repositories (🌃 `tokyo-night`)
  - Automatically switches config based on Git context

- **bat Theme Management**
  - Default theme: `TwoDark`
  - Interactive theme selector (with live preview via `fzf` + `tmux`)
  - Rebuilds syntax and theme caches automatically

- **Safety & Portability**
  - Backs up `.zshrc` and `.gitconfig` before making changes
  - Supports `--dry-run` and `--revert` modes

---

## 🧩 Installed Tools

| Category | Tools |
|-----------|-------|
| Shell Enhancements | `zoxide`, `fzf`, `oh-my-zsh`, `bat`, `duf`, `eza`, `ripgrep`, `fd`, `thefuck`, `tlrc` |
| Developer Tools | `git`, `lazygit`, `terraform`, `tfenv`, `direnv`, `uv` |
| ZSH Plugins | `zsh-autosuggestions`, `zsh-syntax-highlighting` |
| UI Enhancements | `starship`, `tmux` |
| Font | `MesloLGS Nerd Font` (for icons) |

---

## 🧰 Usage

Clone this repository and run:

```bash
curl -fsSL https://raw.githubusercontent.com/jbull79/my-shell/main/cli-setup.sh | bash
