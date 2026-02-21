#!/usr/bin/env bash
# setup.sh — Install dependencies and symlink dotfiles on macOS or Linux.
# Usage: bash setup.sh

set -euo pipefail

# ---------- Helpers ----------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${GREEN}[+]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$*"; }
error() { printf "${RED}[✗]${NC} %s\n" "$*"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- detect_os ----------

detect_os() {
    case "$(uname -s)" in
        Darwin) OS="macos" ;;
        Linux)  OS="linux" ;;
        *)      error "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
    info "Detected OS: $OS"
}

# ---------- install_packages ----------

install_packages() {
    if [[ "$OS" == "macos" ]]; then
        install_packages_macos
    else
        install_packages_linux
    fi
}

install_packages_macos() {
    # Install Homebrew if missing
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        info "Homebrew already installed"
    fi

    local packages=(zsh stow tmux git-lfs eza gh starship curl)
    info "Installing packages via brew: ${packages[*]}"
    brew install --quiet "${packages[@]}"
}

install_packages_linux() {
    info "Updating apt package lists..."
    sudo apt-get update -y

    local packages=(zsh stow tmux git git-lfs curl gpg)
    info "Installing core packages via apt: ${packages[*]}"
    sudo apt-get install -y "${packages[@]}"

    # eza — add official apt repo if eza is missing
    if ! command -v eza &>/dev/null; then
        info "Adding eza apt repository..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
            | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
            | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo apt-get update -y
        sudo apt-get install -y eza
    else
        info "eza already installed"
    fi

    # gh (GitHub CLI) — add official apt repo if gh is missing
    if ! command -v gh &>/dev/null; then
        info "Adding GitHub CLI apt repository..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli-stable.list >/dev/null
        sudo apt-get update -y
        sudo apt-get install -y gh
    else
        info "gh already installed"
    fi

    # starship — install via official script if missing
    if ! command -v starship &>/dev/null; then
        info "Installing starship prompt..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
    else
        info "starship already installed"
    fi
}

# ---------- install_miniforge ----------

install_miniforge() {
    if [[ -d "$HOME/miniforge3" ]]; then
        info "miniforge3 already installed"
        return
    fi

    info "Installing Miniforge3..."
    local arch
    arch="$(uname -m)"
    if [[ "$OS" == "macos" ]]; then
        local installer_url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-${arch}.sh"
    else
        local installer_url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${arch}.sh"
    fi

    local tmp_installer
    tmp_installer="$(mktemp /tmp/miniforge-XXXXXX.sh)"
    curl -fsSL "$installer_url" -o "$tmp_installer"
    bash "$tmp_installer" -b -p "$HOME/miniforge3"
    rm -f "$tmp_installer"
    info "Miniforge3 installed to ~/miniforge3"
}

# ---------- install_tpm ----------

install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        info "TPM already installed"
        return
    fi

    info "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
}

# ---------- backup_and_stow ----------

backup_and_stow() {
    cd "$DOTFILES_DIR"

    # --adopt moves any conflicting real files into the dotfiles dir
    # (creating the symlinks), then we back up the adopted originals
    # and restore our versions via git.
    info "Running stow..."
    stow --adopt -t "$HOME" .

    local adopted
    adopted=$(git diff --name-only 2>/dev/null || true)
    if [[ -n "$adopted" ]]; then
        local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
        info "Backing up replaced files to $backup_dir"
        mkdir -p "$backup_dir"
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            mkdir -p "$backup_dir/$(dirname "$file")"
            cp "$file" "$backup_dir/$file"
            warn "Backed up $file"
        done <<< "$adopted"
        git checkout .
    fi

    info "Dotfiles symlinked successfully"
}

# ---------- print_summary ----------

print_summary() {
    echo ""
    printf "${BOLD}${GREEN}=== Setup complete! ===${NC}\n"
    echo ""
    echo "Next steps:"
    echo "  1. Restart your shell (or run: exec zsh)"
    echo "  2. Inside tmux, press prefix + I to install tmux plugins"
    echo "  3. Authenticate GitHub CLI: gh auth login"
    echo ""
    echo "Optional (not installed by this script):"
    echo "  - Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    echo "  - Claude Code CLI:  npm install -g @anthropic-ai/claude-code"
    echo "  - VS Code:          https://code.visualstudio.com/"
    echo ""
}

# ---------- main ----------

main() {
    echo ""
    printf "${BOLD}dotfiles setup${NC}\n"
    echo "─────────────────────────────"
    echo ""

    detect_os
    install_packages
    install_miniforge
    install_tpm
    backup_and_stow
    print_summary
}

main "$@"
