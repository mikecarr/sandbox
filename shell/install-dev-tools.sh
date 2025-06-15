#!/bin/bash

# Development Tools Installation Script
# Installs essential development tools for a complete coding environment

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if running on supported system
if ! command -v apt &> /dev/null; then
    print_error "This script is designed for Debian/Ubuntu systems with apt package manager"
    exit 1
fi

print_header "🛠️  Installing Development Tools"
print_status "This will install essential development tools and dependencies"

# Update package list
print_status "Updating package list..."
sudo apt update

# Core build tools
print_status "Installing core build tools..."
sudo apt install -y build-essential

# Essential development tools
print_status "Installing essential development tools..."
sudo apt install -y \
    git \
    make \
    cmake \
    unzip \
    tar \
    gzip \
    wget \
    curl \
    ca-certificates \
    gnupg \
    lsb-release

# Modern CLI tools (recommended for LazyVim/development)
print_status "Installing modern CLI tools..."
sudo apt install -y \
    ripgrep \
    fd-find \
    fzf \
    tree \
    htop \
    jq

# Programming language tools
print_status "Installing programming language support..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm

# Optional but useful development tools
print_status "Installing additional development tools..."

# Try to install lazygit (may not be available on older distributions)
if apt-cache show lazygit >/dev/null 2>&1; then
    sudo apt install -y lazygit
    print_status "✅ lazygit installed"
else
    print_warning "lazygit not available in repositories, skipping..."
    print_status "You can install it manually later from: https://github.com/jesseduffield/lazygit"
fi

# Try to install tree-sitter-cli via npm if nodejs is available
if command -v npm &> /dev/null; then
    print_status "Installing tree-sitter-cli via npm..."
    sudo npm install -g tree-sitter-cli || print_warning "Failed to install tree-sitter-cli"
fi

# Create symbolic link for fd (it's installed as fdfind on Debian/Ubuntu)
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    print_status "Creating fd symlink..."
    sudo ln -sf $(which fdfind) /usr/local/bin/fd
fi

print_status "Setting up Python development environment..."
# Upgrade pip and install common packages
python3 -m pip install --user --upgrade pip setuptools wheel

# Install common Python development tools
python3 -m pip install --user black flake8 mypy pytest

print_header "✅ Development Tools Installation Complete!"
print_status ""
print_status "Installed tools:"
print_status "📦 Core: gcc, make, cmake, git"
print_status "🔧 CLI: ripgrep, fd, fzf, tree, htop, jq"
print_status "🐍 Python: python3, pip, venv + dev tools"
print_status "📜 Node.js: nodejs, npm, tree-sitter-cli"
print_status "📊 Git: lazygit (if available)"
print_status ""

# Verify key installations
print_status "Verifying installations..."
for cmd in gcc git make ripgrep fzf python3 node npm; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ✅ $cmd: $(command -v "$cmd")"
    else
        echo -e "  ❌ $cmd: not found"
    fi
done

print_status ""
print_status "🎉 Your development environment is ready!"
print_status ""
print_status "Next steps:"
print_status "1. Install Neovim + LazyVim:"
print_status "   wget -qO- https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-neovim-robust.sh | bash"
print_status ""
print_status "2. Install shell enhancements:"
print_status "   wget -qO- https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-starship-zsh.sh | bash"
