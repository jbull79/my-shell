# Setup Scripts Library

This directory contains modular setup scripts that configure your development environment. Each script handles a specific aspect of the setup process.

## Script Files

### Core Utilities
- **`00_utils.sh`** - Shared utility functions used by all modules
  - Logging functions (info, warn, error, success)
  - Error handling and retry logic
  - File backup and management utilities
  - DRY_RUN support

### Installation Modules

- **`01_brew.sh`** - Homebrew package manager setup
  - Installs/updates Homebrew
  - Installs all required tools and dependencies
  - Sets up bash v4+ for advanced features
  - Configures fzf key bindings

- **`02_fonts.sh`** - Meslo Nerd Font installation
  - Installs MesloLGS NF font for terminal icons
  - Handles macOS and Linux installations

- **`03_zsh.sh`** - Zsh shell configuration
  - Installs Oh My Zsh
  - Configures fzf integration
  - Sets up zoxide initialization

- **`04_starship.sh`** - Starship prompt configuration
  - Interactive theme selection
  - Auto-switching themes (Git vs non-Git directories)
  - AWS profile indicator integration

- **`05_bat.sh`** - Bat syntax highlighter setup
  - Theme selection and configuration
  - Syntax and theme cache management

- **`06_git_setup.sh`** - Git and SSH configuration
  - SSH key generation (ed25519)
  - Git identity configuration
  - Git aliases and signing setup

- **`07_datadog.sh`** - Datadog CLI tools (optional)
  - Installs Datadog CLI and Python libraries
  - Configures environment variables and aliases

- **`08_aws.sh`** - AWS CLI configuration
  - AWS CLI installation
  - Profile setup and management
  - Autocomplete configuration

- **`09_aliases.sh`** - Common CLI aliases
  - Modern tool aliases (bat, eza, zoxide, etc.)
  - Git shortcuts
  - Terraform shortcuts
  - AWS shortcuts

### Verification & Summary

- **`98_verify.sh`** - Tool verification
  - Verifies all installed tools are working
  - Checks versions where applicable

- **`99_summary.sh`** - Setup summary
  - Displays configuration summary
  - Shows backup locations and key paths

## Installed Packages

### Core Tools

#### [Bash](https://www.gnu.org/software/bash/)
Modern bash shell (v4+) with advanced features
```bash
# Check version
bash --version

# Run script with bash
bash script.sh
```

#### [Git](https://git-scm.com/)
Version control system
```bash
# Quick status
git st

# Pretty log
git lg

# Interactive rebase
git rebase-main
```

#### [Zoxide](https://github.com/ajeetdsouza/zoxide)
Smart directory navigation (replaces `cd`)
```bash
# Jump to directory (fuzzy search)
z project

# Jump to parent
z ..

# Interactive selection
zi
```

### File Operations

#### [Bat](https://github.com/sharkdp/bat)
Modern `cat` replacement with syntax highlighting
```bash
# View file with syntax highlighting
bat file.py

# Show line numbers
bat -n file.py

# List all themes
bat --list-themes
```

#### [Eza](https://github.com/eza-community/eza)
Modern `ls` replacement
```bash
# List files
ls

# Long format with icons
ll

# Tree view
lt

# Show all (including hidden)
la
```

#### [Duf](https://github.com/muesli/duf)
Modern `du` replacement for disk usage
```bash
# Show disk usage
duf

# Show specific directory
duf /path/to/dir
```

#### [fd](https://github.com/sharkdp/fd)
Fast `find` replacement
```bash
# Find files
fd pattern

# Find in specific directory
fd pattern /path/to/search

# Case insensitive
fd -i pattern
```

#### [ripgrep (rg)](https://github.com/BurntSushi/ripgrep)
Fast `grep` replacement
```bash
# Search in files
rg pattern

# Search with context
rg -C 3 pattern

# Search in specific file types
rg pattern -t py
```

### Interactive Tools

#### [fzf](https://github.com/junegunn/fzf)
Fuzzy finder
```bash
# Find files
fzf

# Search command history
history | fzf

# Find and edit file
vim $(fzf)
```

#### [Lazygit](https://github.com/jesseduffield/lazygit)
Interactive Git TUI
```bash
# Open lazygit
lg

# Or use alias
lazygit
```

### Development Tools

#### [Starship](https://starship.rs/)
Cross-shell prompt
```bash
# Show config location
starship config

# List presets
starship preset --list

# Apply preset
starship preset tokyo-night > ~/.config/starship.toml
```

#### [Terraform](https://www.terraform.io/)
Infrastructure as Code
```bash
# Quick commands via aliases
tf init
tf plan
tf apply
tf destroy

# Or full commands
terraform init
terraform plan
```

#### [UV](https://github.com/astral-sh/uv)
Fast Python package manager
```bash
# Install package
uv pip install package

# Create virtual environment
uv venv

# Run Python script
uv run script.py
```

### Git Enhancements

#### [git-delta](https://github.com/dandavison/delta)
Syntax-highlighted Git diffs
```bash
# View diff with delta
git diff

# Configure in gitconfig
git config --global core.pager delta
```

#### [TheFuck](https://github.com/nvbn/thefuck)
Corrects previous command
```bash
# After typing wrong command
fuck

# Or configure auto-correction
eval $(thefuck --alias)
```

### Documentation

#### [TLRC](https://github.com/tldr-pages/tldr)
Simplified man pages
```bash
# Get quick help
tlrc git

# Search for command
tlrc -s search
```

### Shell Enhancements

#### [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
Fish-like autosuggestions for zsh
- Automatically suggests commands as you type
- Press → to accept suggestion

#### [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
Syntax highlighting for zsh
- Highlights commands, paths, and syntax in real-time

#### [direnv](https://direnv.net/)
Environment variable management
```bash
# Create .envrc file
echo 'export API_KEY=secret' > .envrc
direnv allow

# Automatically loads/unloads env vars when entering/leaving directory
```

### System Tools

#### [GnuPG (GPG)](https://www.gnupg.org/)
Encryption and signing
```bash
# Generate key
gpg --full-generate-key

# List keys
gpg --list-keys

# Sign file
gpg --sign file.txt
```

#### [Tmux](https://github.com/tmux/tmux)
Terminal multiplexer
```bash
# Start new session
tmux

# List sessions
tmux ls

# Attach to session
tmux attach -t session-name
```

#### [Wget](https://www.gnu.org/software/wget/)
File downloader
```bash
# Download file
wget https://example.com/file.zip

# Download recursively
wget -r https://example.com/
```

### Cloud Tools

#### [AWS CLI](https://aws.amazon.com/cli/)
Amazon Web Services command line
```bash
# Check current identity
awswho

# List regions
awsregions

# Configure profile
aws configure --profile dev
```

#### [Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
AWS SDK for Python
```bash
# Python script example
python3 << 'EOF'
import boto3

# Create S3 client
s3 = boto3.client('s3')

# List buckets
buckets = s3.list_buckets()
for bucket in buckets['Buckets']:
    print(bucket['Name'])
EOF

# Use with AWS profiles
export AWS_PROFILE=dev
python3 -c "import boto3; print(boto3.client('sts').get_caller_identity())"
```

### Version Management

#### [tfenv](https://github.com/tfutils/tfenv)
Terraform version manager
```bash
# Install Terraform version
tfenv install 1.5.0

# Use specific version
tfenv use 1.5.0

# List installed versions
tfenv list
```

## Package Links

- **Bash**: https://www.gnu.org/software/bash/
- **Git**: https://git-scm.com/
- **Zoxide**: https://github.com/ajeetdsouza/zoxide
- **Bat**: https://github.com/sharkdp/bat
- **Duf**: https://github.com/muesli/duf
- **fzf**: https://github.com/junegunn/fzf
- **fd**: https://github.com/sharkdp/fd
- **ripgrep**: https://github.com/BurntSushi/ripgrep
- **Eza**: https://github.com/eza-community/eza
- **TLRC**: https://github.com/tldr-pages/tldr
- **TheFuck**: https://github.com/nvbn/thefuck
- **git-delta**: https://github.com/dandavison/delta
- **Starship**: https://starship.rs/
- **UV**: https://github.com/astral-sh/uv
- **tfenv**: https://github.com/tfutils/tfenv
- **Terraform**: https://www.terraform.io/
- **Lazygit**: https://github.com/jesseduffield/lazygit
- **direnv**: https://direnv.net/
- **zsh-autosuggestions**: https://github.com/zsh-users/zsh-autosuggestions
- **zsh-syntax-highlighting**: https://github.com/zsh-users/zsh-syntax-highlighting
- **GnuPG**: https://www.gnupg.org/
- **Tmux**: https://github.com/tmux/tmux
- **Wget**: https://www.gnu.org/software/wget/
- **AWS CLI**: https://aws.amazon.com/cli/
- **Boto3**: https://boto3.amazonaws.com/v1/documentation/api/latest/index.html

## Usage Examples

### Common Workflows

#### Git Workflow
```bash
# Check status
git st

# View pretty log
git lg

# Interactive rebase
git rebase-main

# Squash commits
git squash "My commit message"

# View diff with syntax highlighting
git diff
```

#### File Navigation
```bash
# Smart directory jumping
z project-name

# List files with icons
ls

# Tree view
lt

# Find files
fd pattern

# Search in files
rg "search term"
```

#### Development
```bash
# View code with syntax highlighting
bat src/main.py

# Python package management
uv pip install requests

# Terraform operations
tf init
tf plan
tf apply

# Git TUI
lg
```

#### Cloud Operations
```bash
# Check AWS identity
awswho

# List AWS regions
awsregions

# Switch AWS profile
aws configure --profile prod

# Use boto3 in Python
python3 -c "import boto3; s3 = boto3.client('s3'); print(s3.list_buckets())"
```

## Configuration

Most tools are pre-configured, but you can customize:

- **Starship**: `~/.config/starship_default.toml` and `~/.config/starship_git.toml`
- **Bat**: `~/.config/bat/config`
- **Git**: `~/.gitconfig`
- **AWS**: `~/.aws/config` and `~/.aws/credentials`
- **Zsh**: `~/.zshrc`

## Notes

- All scripts are designed to be idempotent (safe to run multiple times)
- Backups are created automatically before modifications
- Use `DRY_RUN=true ./install.sh` to preview changes
- Scripts are executed in numerical order (00-99)

