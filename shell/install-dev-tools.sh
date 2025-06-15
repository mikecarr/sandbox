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

# Install btop (modern system monitor)
print_status "Installing btop (modern system monitor)..."
if apt-cache show btop >/dev/null 2>&1; then
    sudo apt install -y btop
    print_status "✅ btop installed from repository"
else
    print_warning "btop not available in repositories, installing from GitHub..."
    # Get latest btop release for systems where it's not in repos
    BTOP_VERSION=$(wget -qO- https://api.github.com/repos/aristocratos/btop/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -n "$BTOP_VERSION" ]]; then
        TEMP_DIR="/tmp/btop-install"
        mkdir -p "$TEMP_DIR"
        cd "$TEMP_DIR"
        
        # Download and install btop
        wget -O btop.tbz "https://github.com/aristocratos/btop/releases/download/${BTOP_VERSION}/btop-x86_64-linux-musl.tbz"
        tar -xjf btop.tbz
        sudo cp btop/bin/btop /usr/local/bin/
        sudo chmod +x /usr/local/bin/btop
        
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        
        if command -v btop &> /dev/null; then
            print_status "✅ btop installed from GitHub"
        else
            print_warning "btop installation failed"
        fi
    else
        print_warning "Could not fetch btop version, skipping..."
    fi
fi

# Programming language tools
print_status "Installing programming language support..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv

# Install modern Node.js (version 20+)
print_status "Installing Node.js 20+ and npm..."
if ! command -v node &> /dev/null || [[ $(node --version | cut -d'.' -f1 | tr -d 'v') -lt 20 ]]; then
    print_status "Installing/updating Node.js to version 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    print_status "✅ Node.js 20+ already installed"
fi

# Verify Node.js installation
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_status "Node.js version: $NODE_VERSION"
    
    # Install useful global npm packages
    print_status "Installing useful npm packages..."
    sudo npm install -g tree-sitter-cli markdownlint-cli2 || print_warning "Some npm packages failed to install"
else
    print_warning "Node.js installation may have failed"
fi

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
    print_status "Installing additional npm packages..."
    # tree-sitter-cli already installed above with markdownlint-cli2
    print_status "✅ npm packages installed"
fi

# Create symbolic link for fd (it's installed as fdfind on Debian/Ubuntu)
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    print_status "Creating fd symlink..."
    sudo ln -sf $(which fdfind) /usr/local/bin/fd
fi

# Setup Git configuration
print_status "Setting up Git configuration..."

# Check if .gitconfig already exists
if [[ -f "$HOME/.gitconfig" ]]; then
    print_status "Backing up existing .gitconfig..."
    cp "$HOME/.gitconfig" "$HOME/.gitconfig.bak.$(date +%Y%m%d_%H%M%S)"
fi

# Create .gitconfig
print_status "Creating Git configuration..."
cat > "$HOME/.gitconfig" << 'EOF'
[user]
    name = Mike Carr
    email = mcarr67@gmail.com
    username = mcarr
[color]
    ui = true
    branch = true
    diff = true
    interactive = true
    status = true
[color "status"]
    added = green
    changed = red
    deleted = red
    untracked = yellow
#[push]
#    default = matching
[core]
    excludesfile = ~/.gitignore
    pager = cat
[alias]
    st = status
    ci = checkin
    co = checkout
    debug = !GIT_TRACE=1 git
    
[init]
    defaultBranch = master
[pull]
    ff = only
    rebase = true
EOF

# Create a basic .gitignore file
print_status "Creating global .gitignore..."
cat > "$HOME/.gitignore" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
*~
*.swp
*.swo
.vscode/
.idea/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.env
.venv
ENV/
env.bak/
venv.bak/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build artifacts
dist/
build/
*.egg-info/

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
*.tmp
*.temp
EOF

print_status "✅ Git configuration completed"
print_status "   - .gitconfig created with user settings and aliases"
print_status "   - .gitignore created with common ignore patterns"

# Install UV (fast Python package installer and project manager)
print_status "Installing UV (fast Python package installer)..."
if ! command -v uv &> /dev/null; then
    print_status "Downloading and installing UV..."
    
    # Download and run UV installer
    if wget -qO- https://astral.sh/uv/install.sh | sh; then
        print_status "UV installer completed"
        
        # UV can install to different locations, check both common ones
        UV_PATHS=("$HOME/.cargo/bin" "$HOME/.local/bin")
        UV_INSTALLED=false
        
        for uv_path in "${UV_PATHS[@]}"; do
            if [[ -f "$uv_path/uv" ]]; then
                print_status "Found UV at: $uv_path/uv"
                
                # Add to current session PATH
                export PATH="$uv_path:$PATH"
                
                # Add to shell configs if not already there
                for shell_config in ~/.bashrc ~/.zshrc ~/.profile; do
                    if [[ -f "$shell_config" ]] && ! grep -q "$uv_path" "$shell_config"; then
                        print_status "Adding $uv_path to PATH in $shell_config"
                        echo "export PATH=\"$uv_path:\$PATH\"" >> "$shell_config"
                    fi
                done
                
                UV_INSTALLED=true
                break
            fi
        done
        
        # Verify UV installation
        if command -v uv &> /dev/null; then
            print_status "✅ UV installed successfully: $(uv --version)"
        elif [[ "$UV_INSTALLED" == "true" ]]; then
            print_status "✅ UV installed but may need shell restart"
            print_warning "Run: source ~/.zshrc (or restart terminal)"
        else
            print_warning "UV installation may have failed - binary not found"
        fi
    else
        print_warning "UV installation script failed"
    fi
else
    print_status "✅ UV is already installed: $(uv --version)"
fi

print_status "Setting up Python development environment..."

# Check if we're in a newer system with externally-managed-environment
if python3 -m pip install --help 2>/dev/null | grep -q "break-system-packages"; then
    print_status "Detected externally-managed Python environment, using pipx for user packages..."
    
    # Install pipx first if not available
    if ! command -v pipx &> /dev/null; then
        sudo apt install -y pipx python3-full
        pipx ensurepath
    fi
    
    # Install Python development tools via pipx (in isolated environments)
    print_status "Installing Python tools via pipx..."
    pipx install black || print_warning "Failed to install black"
    pipx install flake8 || print_warning "Failed to install flake8"
    pipx install mypy || print_warning "Failed to install mypy"
    pipx install pytest || print_warning "Failed to install pytest"
    pipx install ruff || print_warning "Failed to install ruff"
    
    # Also install system packages for common Python dev tools
    sudo apt install -y python3-flake8 python3-pytest python3-pip python3-venv || print_warning "Some Python packages not available"
    
else
    # Legacy system - use pip with --user
    print_status "Installing Python packages with pip..."
    
    # Upgrade pip and install common packages
    python3 -m pip install --user --upgrade pip setuptools wheel
    
    # Install common Python development tools
    python3 -m pip install --user black flake8 mypy pytest
fi

print_header "✅ Development Tools Installation Complete!"
print_status "System monitoring tools:"
print_status "• htop - Interactive process viewer"
print_status "• btop - Modern system monitor with graphs"
print_status ""
print_status "Quick commands:"
print_status "• htop                         # Traditional process monitor"
print_status "• btop                         # Modern system monitor"
print_status "• curl -s url                  # Download/test HTTP endpoints"
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
for cmd in gcc git make curl wget fzf python3 node npm htop btop; do
    if command -v "$cmd" &> /dev/null; then
        echo -e "  ✅ $cmd: $(command -v "$cmd")"
    else
        echo -e "  ❌ $cmd: not found"
    fi
done

# Check ripgrep specifically (it might be installed as 'rg')
if command -v rg &> /dev/null; then
    echo -e "  ✅ ripgrep (rg): $(command -v rg)"
elif command -v ripgrep &> /dev/null; then
    echo -e "  ✅ ripgrep: $(command -v ripgrep)"
else
    echo -e "  ❌ ripgrep: not found"
fi

# Check Python tools with better detection
print_status ""
print_status "Python tools verification:"
for tool in black flake8 mypy pytest; do
    if command -v "$tool" &> /dev/null; then
        echo -e "  ✅ $tool: $(command -v "$tool")"
    elif pipx list 2>/dev/null | grep -q "$tool"; then
        echo -e "  ✅ $tool: available via pipx"
    else
        echo -e "  ⚠️  $tool: not found"
    fi
done

# Check UV specifically
if command -v uv &> /dev/null; then
    echo -e "  ✅ uv: $(command -v uv) - $(uv --version)"
else
    # Check common UV installation locations
    UV_LOCATIONS=("$HOME/.cargo/bin/uv" "$HOME/.local/bin/uv")
    UV_FOUND=false
    
    for uv_location in "${UV_LOCATIONS[@]}"; do
        if [[ -f "$uv_location" ]]; then
            echo -e "  ⚠️  uv: installed at $uv_location but not in PATH"
            echo -e "     Run: export PATH=\"$(dirname "$uv_location"):\$PATH\""
            UV_FOUND=true
            break
        fi
    done
    
    if [[ "$UV_FOUND" == "false" ]]; then
        echo -e "  ❌ uv: not found"
    fi
fi

# Check ruff specifically
if command -v ruff &> /dev/null; then
    echo -e "  ✅ ruff: $(command -v ruff)"
elif pipx list 2>/dev/null | grep -q "ruff"; then
    echo -e "  ✅ ruff: available via pipx"
else
    echo -e "  ⚠️  ruff: not found (install with: pipx install ruff)"
fi

print_status ""
print_status "🎉 Your development environment is ready!"
print_status ""
print_status "Python tools installed:"
print_status "• UV - Ultra-fast Python package installer and resolver"
print_status "• Ruff - Extremely fast Python linter and formatter"
print_status "• Black - Code formatter"
print_status "• Flake8 - Linting tool"
print_status "• MyPy - Type checker"
print_status "• Pytest - Testing framework"
print_status ""
print_status "Quick UV usage:"
print_status "• uv pip install package_name  # Fast pip replacement"
print_status "• uv venv                      # Create virtual environment"
print_status "• uv pip list                  # List packages"
print_status ""
print_status "Next steps:"
print_status "1. Install Neovim + LazyVim:"
print_status "   wget -qO- https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-neovim-robust.sh | bash"
print_status ""
print_status "2. Install shell enhancements:"
print_status "   wget -qO- https://raw.githubusercontent.com/mikecarr/sandbox/refs/heads/master/shell/install-starship-zsh.sh | bash"
