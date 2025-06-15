#!/bin/bash

# Starship + Zsh Enhancement Installation Script
# Installs and configures starship prompt and zsh improvements

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
    echo -e "${BLUE}[SHELL]${NC} $1"
}

print_header "🚀 Installing Shell Enhancements"

# Check if running on supported system
if ! command -v apt &> /dev/null; then
    print_error "This script is designed for Debian/Ubuntu systems with apt package manager"
    exit 1
fi

# Install zsh if not already installed
if ! command -v zsh &> /dev/null; then
    print_status "Installing zsh..."
    sudo apt update
    sudo apt install -y zsh
else
    print_status "✅ zsh is already installed"
fi

# Install starship
print_status "Installing Starship prompt..."

# Check if starship is already installed
if command -v starship &> /dev/null; then
    print_status "Starship already installed, checking for updates..."
    CURRENT_VERSION=$(starship --version | cut -d' ' -f2)
    print_status "Current version: $CURRENT_VERSION"
fi

# Download and install starship
print_status "Downloading latest Starship..."
wget -qO- https://starship.rs/install.sh | sh -s -- -y

# Verify starship installation
if ! command -v starship &> /dev/null; then
    print_error "Starship installation failed"
    exit 1
fi

print_status "✅ Starship installed successfully"
starship --version

# Configure starship for zsh
print_status "Configuring Starship for zsh..."

# Backup existing .zshrc if it exists
if [[ -f ~/.zshrc ]]; then
    print_status "Backing up existing .zshrc..."
    cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d_%H%M%S)
fi

# Add starship to .zshrc if not already there
if ! grep -q "starship init zsh" ~/.zshrc 2>/dev/null; then
    print_status "Adding Starship to .zshrc..."
    echo '' >> ~/.zshrc
    echo '# Starship prompt' >> ~/.zshrc
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
else
    print_status "Starship already configured in .zshrc"
fi

# Create a basic starship config
print_status "Creating Starship configuration..."
mkdir -p ~/.config

# Check if starship config exists
if [[ -f ~/.config/starship.toml ]]; then
    print_status "Backing up existing starship config..."
    cp ~/.config/starship.toml ~/.config/starship.toml.bak.$(date +%Y%m%d_%H%M%S)
fi

# Create a nice default starship config
cat > ~/.config/starship.toml << 'EOF'
# Starship configuration
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Inserts a blank line between shell prompts
add_newline = true

# Change the default prompt format
format = """\
[╭╴](238)$env_var\
$all[╰─](238)$character"""

# Change the default prompt characters
[character]
success_symbol = "[](238)"
error_symbol = "[](red)"

# Shows an icon that should be included by zshrc script based on the distribution or os
[env_var.STARSHIP_DISTRO]
format = '[$env_value](bold white)'
variable = "STARSHIP_DISTRO"
disabled = false

# Shows the username
[username]
style_user = "white bold"
style_root = "black bold"
format = "[$user]($style) "
disabled = false
show_always = true

# Shows the hostname
[hostname]
ssh_only = false
format = "on [$hostname](bold yellow) "
disabled = false

# Shows current directory
[directory]
truncation_length = 1
truncation_symbol = "…/"
home_symbol = " ~"
read_only_style = "197"
read_only = "  "
format = "at [$path]($style)[$read_only]($read_only_style) "

# Shows current git branch
[git_branch]
symbol = " "
format = "via [$symbol$branch]($style)"
truncation_length = 4
truncation_symbol = "…/"
style = "bold green"

# Shows current git status
[git_status]
format = '[\($all_status$ahead_behind\)]($style) '
style = "bold green"
conflicted = "🏳"
up_to_date = " "
untracked = " "
ahead = "⇡${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
behind = "⇣${count}"
stashed = " "
modified = " "
staged = '[++\($count\)](green)'
renamed = "襁 "
deleted = " "

# Shows kubernetes context and namespace
[kubernetes]
format = 'via [ﴱ $context\($namespace\)](bold purple) '
disabled = false

# Disable the blank line at the start of the prompt
# add_newline = false
EOF

print_status "✅ Starship configuration created"

# Install useful zsh plugins and improvements
print_status "Installing zsh improvements..."

# Install zsh-autosuggestions
if [[ ! -d ~/.zsh/zsh-autosuggestions ]]; then
    print_status "Installing zsh-autosuggestions..."
    mkdir -p ~/.zsh
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    
    # Add to .zshrc if not already there
    if ! grep -q "zsh-autosuggestions" ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo '# Zsh autosuggestions' >> ~/.zshrc
        echo 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
    fi
else
    print_status "✅ zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting
if [[ ! -d ~/.zsh/zsh-syntax-highlighting ]]; then
    print_status "Installing zsh-syntax-highlighting..."
    mkdir -p ~/.zsh
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
    
    # Add to .zshrc if not already there
    if ! grep -q "zsh-syntax-highlighting" ~/.zshrc 2>/dev/null; then
        echo '' >> ~/.zshrc
        echo '# Zsh syntax highlighting' >> ~/.zshrc
        echo 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> ~/.zshrc
    fi
else
    print_status "✅ zsh-syntax-highlighting already installed"
fi

# Add some useful aliases and settings to .zshrc
if ! grep -q "# Enhanced shell settings" ~/.zshrc 2>/dev/null; then
    print_status "Adding useful shell settings..."
    cat >> ~/.zshrc << 'EOF'

# Enhanced shell settings
export EDITOR=nvim
export VISUAL=nvim

# Better history
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
HISTSIZE=10000
SAVEHIST=10000

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Modern replacements if available
if command -v fzf >/dev/null 2>&1; then
    alias find='fzf'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi
EOF
fi

# Set zsh as default shell if not already
if [[ "$SHELL" != */zsh ]]; then
    print_status "Setting zsh as default shell..."
    
    # Verify zsh is in /etc/shells
    if ! grep -q "$(which zsh)" /etc/shells; then
        print_status "Adding zsh to /etc/shells..."
        echo "$(which zsh)" | sudo tee -a /etc/shells
    fi
    
    # Change default shell
    if chsh -s "$(which zsh)" 2>/dev/null; then
        print_status "✅ Default shell changed to zsh"
        print_warning "⚠️  You'll need to log out and back in for the shell change to take effect"
    else
        print_warning "⚠️  Could not change default shell automatically"
        print_status "To change manually, run: chsh -s $(which zsh)"
        print_status "Or start zsh now with: exec zsh"
    fi
else
    print_status "✅ zsh is already the default shell"
fi

print_header "✅ Shell Enhancement Installation Complete!"
print_status ""
print_status "🎉 Starship + Zsh enhancements installed successfully!"
print_status ""
print_status "Installed features:"
print_status "🌟 Starship prompt with custom configuration"
print_status "💡 Zsh autosuggestions (gray text completion)"
print_status "🎨 Zsh syntax highlighting"
print_status "⚡ Enhanced history settings"
print_status "🔧 Useful aliases and git shortcuts"
print_status ""
print_status "To start using:"
print_status "1. Start zsh now: exec zsh"
print_status "2. Or restart your terminal"
print_status "3. Your prompt should now look different!"
print_status ""
print_status "If you see any issues:"
print_status "• Run 'exec zsh' to start zsh immediately"
print_status "• Check that zsh is working: zsh --version"
print_status "• Verify starship: starship --version"
print_status ""
print_status "Useful tips:"
print_status "• Use ↑/↓ arrows for command history"
print_status "• Tab completion is enhanced"
print_status "• Git status shows in prompt when in git repo"
print_status "• Type 'll' for detailed file listing"
print_status "• Type 'gs' for git status"
