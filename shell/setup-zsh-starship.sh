#!/bin/bash

# Zsh and Starship Setup Script
# This script installs zsh, starship prompt, and configures them

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v yum &> /dev/null; then
            OS="centos"
        elif command -v pacman &> /dev/null; then
            OS="arch"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    print_status "Detected OS: $OS"
}

# Install zsh
install_zsh() {
    print_status "Installing zsh..."
    
    case $OS in
        "ubuntu")
            sudo apt-get update
            sudo apt-get install -y zsh
            ;;
        "centos")
            sudo yum install -y zsh
            ;;
        "arch")
            sudo pacman -S --noconfirm zsh
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install zsh
            else
                print_error "Homebrew not found. Please install Homebrew first."
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported OS for automatic zsh installation"
            exit 1
            ;;
    esac
    
    print_success "Zsh installed successfully"
}

# Install starship
install_starship() {
    print_status "Installing starship..."
    
    # Use the official starship installer
    if command -v curl &> /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    elif command -v wget &> /dev/null; then
        wget -qO- https://starship.rs/install.sh | sh -s -- -y
    else
        print_error "Neither curl nor wget found. Please install one of them first."
        exit 1
    fi
    
    print_success "Starship installed successfully"
}

# Configure zsh with starship
configure_zsh() {
    print_status "Configuring zsh with starship..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing .zshrc backed up"
    fi
    
    # Create basic .zshrc with starship
    cat > "$HOME/.zshrc" << 'EOF'
# Zsh configuration with Starship prompt

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Enable completion
autoload -Uz compinit
compinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Better completion menu
zstyle ':completion:*' menu select

# Enable colors
autoload -U colors && colors

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Enable starship prompt
eval "$(starship init zsh)"
EOF
    
    print_success "Zsh configured with starship"
}

# Create basic starship config
create_starship_config() {
    print_status "Creating starship configuration..."
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Create basic starship.toml config
    cat > "$HOME/.config/starship.toml" << 'EOF'
# Starship configuration

# Inserts a blank line between shell prompts
add_newline = true

# Wait 10 milliseconds for starship to check files under the current directory.
scan_timeout = 10

# Configure the format of the prompt
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$rust\
$golang\
$docker_context\
$kubernetes\
$aws\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = false

[git_branch]
symbol = "🌱 "

[git_status]
conflicted = "🏳"
ahead = "🏎💨"
behind = "😰"
diverged = "😵"
up_to_date = "✓"
untracked = "🤷‍"
stashed = "📦"
modified = "📝"
staged = "[++($count)](green)"
renamed = "👅"
deleted = "🗑"

[python]
symbol = "🐍 "

[nodejs]
symbol = "⬢ "

[rust]
symbol = "🦀 "

[golang]
symbol = "🐹 "

[docker_context]
symbol = "🐳 "

[kubernetes]
symbol = "⎈ "
disabled = false

[aws]
symbol = "☁️ "

[cmd_duration]
min_time = 2_000
show_milliseconds = false
format = "took [$duration](bold yellow)"
EOF
    
    print_success "Starship configuration created"
}

# Set zsh as default shell
set_default_shell() {
    print_status "Setting zsh as default shell..."
    
    # Get the path to zsh
    ZSH_PATH=$(which zsh)
    
    # Check if zsh is in /etc/shells
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        print_status "Adding zsh to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    
    # Change default shell to zsh
    if [ "$SHELL" != "$ZSH_PATH" ]; then
        print_status "Changing default shell to zsh..."
        print_warning "You may be prompted for your password again..."
        if sudo chsh -s "$ZSH_PATH" "$USER"; then
            print_success "Default shell changed to zsh (restart terminal to take effect)"
        else
            print_warning "Failed to change default shell automatically."
            print_status "You can change it manually later with: chsh -s $ZSH_PATH"
        fi
    else
        print_success "Zsh is already the default shell"
    fi
}

# Main installation function
main() {
    echo "========================================"
    echo "    Zsh and Starship Setup Script"
    echo "========================================"
    echo
    
    detect_os
    
    # Check if zsh is already installed
    if command -v zsh &> /dev/null; then
        print_success "Zsh is already installed"
    else
        install_zsh
    fi
    
    # Check if starship is already installed
    if command -v starship &> /dev/null; then
        print_success "Starship is already installed"
    else
        install_starship
    fi
    
    configure_zsh
    create_starship_config
    set_default_shell
    
    echo
    echo "========================================"
    print_success "Setup completed successfully!"
    echo "========================================"
    echo
    print_status "Next steps:"
    echo "1. Restart your terminal or run: exec zsh"
    echo "2. Your old .zshrc was backed up (if it existed)"
    echo "3. Customize ~/.config/starship.toml for your preferences"
    echo "4. Visit https://starship.rs/config/ for more configuration options"
    echo
}

# Check if running with bash
if [ -z "$BASH_VERSION" ]; then
    print_error "This script requires bash to run"
    exit 1
fi

# Run main function
main "$@"
