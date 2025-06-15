#!/bin/bash

# Robust Neovim + LazyVim Installation Script
# This installs everything to /usr/local to avoid path issues
# Requires development tools - install with install-dev-tools.sh first

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
    echo -e "${BLUE}[NEOVIM]${NC} $1"
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    for cmd in git gcc make; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Install development tools first:"
        print_status "wget -qO- https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-dev-tools.sh | bash"
        exit 1
    fi
}

print_header "🚀 Installing Neovim + LazyVim"

# Check dependencies first
check_dependencies

# Check if running as root for system installation
if [[ $EUID -eq 0 ]]; then
    INSTALL_DIR="/usr/local"
    SUDO=""
else
    INSTALL_DIR="/usr/local"
    SUDO="sudo"
fi

print_status "Installing Neovim to $INSTALL_DIR (requires sudo)..."

# Clean up any existing installations
print_status "Cleaning up existing installations..."
$SUDO rm -f /usr/local/bin/nvim
$SUDO rm -rf /usr/local/share/nvim
rm -rf ~/.local/bin/nvim ~/.local/share/nvim

# Get latest version
print_status "Fetching latest Neovim version..."
VERSION=$(wget -qO- https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
print_status "Latest version: $VERSION"

# Download and extract
TEMP_DIR="/tmp/neovim-install-robust"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

print_status "Downloading Neovim $VERSION..."
wget -O nvim-linux-x86_64.tar.gz "https://github.com/neovim/neovim/releases/download/${VERSION}/nvim-linux-x86_64.tar.gz"

# Verify download
if [[ ! -f "nvim-linux-x86_64.tar.gz" ]] || [[ $(stat -c%s "nvim-linux-x86_64.tar.gz" 2>/dev/null || echo 0) -lt 100000 ]]; then
    print_error "Download failed"
    exit 1
fi

print_status "Extracting..."
tar -xzf nvim-linux-x86_64.tar.gz

print_status "Installing to $INSTALL_DIR..."
$SUDO cp -r nvim-linux-x86_64/* "$INSTALL_DIR/"

# Verify installation
print_status "Verifying installation..."
if ! /usr/local/bin/nvim --version > /dev/null 2>&1; then
    print_error "Neovim installation failed"
    exit 1
fi

print_status "Neovim installation successful!"
/usr/local/bin/nvim --version | head -3

# Clean up
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Install LazyVim
print_status "Installing LazyVim..."

NVIM_CONFIG_DIR="$HOME/.config/nvim"

# Backup existing configuration
if [[ -d "$NVIM_CONFIG_DIR" ]]; then
    print_status "Backing up existing Neovim configuration..."
    mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak.$(date +%Y%m%d_%H%M%S)"
fi

# Backup other directories
for dir in ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
    if [[ -d "$dir" ]]; then
        print_status "Backing up $dir..."
        mv "$dir" "${dir}.bak.$(date +%Y%m%d_%H%M%S)"
    fi
done

# Clone LazyVim starter
print_status "Cloning LazyVim starter..."
git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
rm -rf "$NVIM_CONFIG_DIR/.git"

print_header "✅ Installation Complete!"
print_status ""
print_status "🎉 Neovim + LazyVim installed successfully!"
print_status ""

# Check PATH
if [[ ":$PATH:" == *":/usr/local/bin:"* ]]; then
    print_status "✅ /usr/local/bin is already in your PATH"
    print_status "Start Neovim with: nvim"
else
    print_warning "⚠️  /usr/local/bin is not in your PATH"
    print_status "Add it with: echo 'export PATH=\"/usr/local/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    print_status "Or start directly with: /usr/local/bin/nvim"
fi

print_status ""
print_status "First run tips:"
print_status "1. Plugins will install automatically on first start"
print_status "2. Run :LazyHealth to check everything"
print_status "3. Press 'q' to quit if you get stuck"
print_status "4. Leader key is <space> - try <space>ff to find files"
