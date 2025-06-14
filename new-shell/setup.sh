#!/bin/bash

# setup.sh - Automated shell configuration script
# Usage: ./setup.sh

set -e  # Exit on any error

# Configuration
REMOTE_HOST="10.0.1.5"
REMOTE_USER="${REMOTE_USER:-$(whoami)}"  # Use current user unless specified
SSH_KEY_PATH="$HOME/.ssh"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Package lists by OS
UBUNTU_PACKAGES=(
    "git"
    "curl"
    "wget"
    "vim"
    "neovim"
    "zsh"
    "tmux"
    "htop"
    "tree"
    "jq"
    "unzip"
    "build-essential"
    "python3"
    "python3-pip"
    "nodejs"
    "npm"
)

CENTOS_PACKAGES=(
    "git"
    "curl"
    "wget"
    "vim"
    "neovim"
    "zsh"
    "tmux"
    "htop"
    "tree"
    "jq"
    "unzip"
    "gcc"
    "gcc-c++"
    "make"
    "python3"
    "python3-pip"
    "nodejs"
    "npm"
)

MACOS_PACKAGES=(
    "git"
    "curl"
    "wget"
    "vim"
    "neovim"
    "zsh"
    "tmux"
    "htop"
    "tree"
    "jq"
    "node"
    "python"
)

# Configuration files to copy from remote
CONFIG_FILES=(
    ".gitconfig"
    ".bashrc"
    ".bash_profile"
    ".vimrc"
    ".config/nvim/init.vim"
    ".config/nvim/init.lua"
    ".tmux.conf"
    ".zshrc"
)

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "ubuntu"
        elif command -v yum &> /dev/null; then
            echo "centos"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to create backup directory
create_backup() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
}

# Function to backup existing files
backup_file() {
    local file="$1"
    if [[ -f "$HOME/$file" ]]; then
        log_info "Backing up existing $file"
        cp "$HOME/$file" "$BACKUP_DIR/"
    fi
}

# Function to copy SSH keys from remote machine
copy_ssh_keys() {
    log_info "Copying SSH keys from $REMOTE_HOST"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$SSH_KEY_PATH"
    chmod 700 "$SSH_KEY_PATH"
    
    # Check if we can connect to the remote host
    log_info "Testing connection to $REMOTE_HOST..."
    
    # First try with BatchMode (key-based auth)
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" exit 2>/dev/null; then
        log_success "Connection successful with key-based authentication"
        return 0
    fi
    
    # If that fails, try interactive connection (password auth)
    log_warning "Key-based auth failed. Attempting password authentication..."
    log_info "You may be prompted for your password multiple times during the setup"
    
    if ssh -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" exit; then
        log_success "Connection successful with password authentication"
        log_info "SSH keys will be copied to enable key-based auth for future use"
        return 0
    else
        log_error "Cannot connect to $REMOTE_HOST. Please check:"
        log_error "1. The host is reachable: ping $REMOTE_HOST"
        log_error "2. SSH service is running on the remote host"
        log_error "3. Username '$REMOTE_USER' exists on the remote host"
        log_error "4. Password authentication is enabled"
        log_error ""
        log_info "To test manually: ssh $REMOTE_USER@$REMOTE_HOST"
        return 1
    fi
    
    # Copy private keys (common key names)
    local key_files=("id_rsa" "id_ed25519" "id_ecdsa")
    local keys_copied=0
    
    for key in "${key_files[@]}"; do
        if ssh "$REMOTE_USER@$REMOTE_HOST" "test -f ~/.ssh/$key"; then
            log_info "Copying private key $key from remote host"
            if scp "$REMOTE_USER@$REMOTE_HOST:~/.ssh/$key" "$SSH_KEY_PATH/"; then
                log_success "Successfully copied private key $key"
                chmod 600 "$SSH_KEY_PATH/$key"
                
                # Try to copy public key (may not exist)
                if ssh "$REMOTE_USER@$REMOTE_HOST" "test -f ~/.ssh/$key.pub"; then
                    log_info "Copying public key $key.pub from remote host"
                    if scp "$REMOTE_USER@$REMOTE_HOST:~/.ssh/$key.pub" "$SSH_KEY_PATH/"; then
                        log_success "Successfully copied public key $key.pub"
                        chmod 644 "$SSH_KEY_PATH/$key.pub"
                    else
                        log_warning "Failed to copy public key $key.pub"
                    fi
                else
                    log_info "Public key $key.pub not found on remote host"
                fi
                
                keys_copied=$((keys_copied + 1))
            else
                log_error "Failed to copy private key $key"
            fi
        else
            log_info "Private key $key not found on remote host, skipping"
        fi
    done
    
    # Copy known_hosts if it exists
    if ssh "$REMOTE_USER@$REMOTE_HOST" "test -f ~/.ssh/known_hosts"; then
        log_info "Copying known_hosts from remote host"
        scp "$REMOTE_USER@$REMOTE_HOST:~/.ssh/known_hosts" "$SSH_KEY_PATH/"
        chmod 644 "$SSH_KEY_PATH/known_hosts"
    fi
    
    if [[ $keys_copied -eq 0 ]]; then
        log_warning "No SSH keys found on remote host"
    else
        log_success "Copied $keys_copied SSH key(s) from remote host"
    fi
}

# Function to install packages
install_packages() {
    local os="$1"
    log_info "Installing packages for $os"
    
    case "$os" in
        "ubuntu")
            sudo apt-get update
            for package in "${UBUNTU_PACKAGES[@]}"; do
                log_info "Installing $package"
                sudo apt-get install -y "$package" || log_warning "Failed to install $package"
            done
            ;;
        "centos")
            sudo yum update -y
            for package in "${CENTOS_PACKAGES[@]}"; do
                log_info "Installing $package"
                sudo yum install -y "$package" || log_warning "Failed to install $package"
            done
            ;;
        "macos")
            if ! command_exists brew; then
                log_info "Installing Homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew update
            for package in "${MACOS_PACKAGES[@]}"; do
                log_info "Installing $package"
                brew install "$package" || log_warning "Failed to install $package"
            done
            ;;
        *)
            log_warning "Unknown OS: $os. Skipping package installation."
            ;;
    esac
}

# Function to copy configuration files
copy_config_files() {
    log_info "Copying configuration files from $REMOTE_HOST"
    
    for config_file in "${CONFIG_FILES[@]}"; do
        if ssh "$REMOTE_USER@$REMOTE_HOST" "test -f ~/$config_file"; then
            log_info "Copying $config_file from remote host"
            backup_file "$config_file"
            scp "$REMOTE_USER@$REMOTE_HOST:~/$config_file" "$HOME/"
        else
            log_info "Skipping $config_file (not found on remote host)"
        fi
    done
}

# Function to install Oh My Zsh
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Oh My Zsh already installed, skipping"
        return 0
    fi
    
    log_info "Installing Oh My Zsh"
    
    # Download and install Oh My Zsh
    if command_exists curl; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    elif command_exists wget; then
        sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_error "Neither curl nor wget found. Cannot install Oh My Zsh"
        return 1
    fi
    
    # Install popular plugins
    log_info "Installing Oh My Zsh plugins"
    
    # zsh-autosuggestions
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    fi
    
    # powerlevel10k theme (optional but popular)
    if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    fi
    
    log_success "Oh My Zsh installed successfully"
}

# Function to set zsh as default shell
set_zsh_default() {
    local current_shell=$(getent passwd $USER | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    if [[ "$current_shell" == "$zsh_path" ]]; then
        log_info "Zsh is already the default shell"
        return 0
    fi
    
    log_info "Setting zsh as default shell"
    
    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells; then
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    # Change default shell
    sudo chsh -s "$zsh_path" "$USER"
    log_success "Default shell changed to zsh (will take effect on next login)"
}
    log_info "Setting up shell environment"
    
    # Source the new configuration files
    if [[ -f "$HOME/.bashrc" ]]; then
        log_info "Sourcing .bashrc"
        # Note: We can't source in a script, so we'll just inform the user
        log_info "Please run 'source ~/.bashrc' or restart your terminal"
    fi
    
    # Set up git if .gitconfig was copied
    if [[ -f "$HOME/.gitconfig" ]]; then
        log_success "Git configuration copied"
    fi
}

# Main execution
main() {
    log_info "Starting shell setup script"
    log_info "Remote host: $REMOTE_HOST"
    log_info "Remote user: $REMOTE_USER"
    
    # Detect OS
    OS=$(detect_os)
    log_info "Detected OS: $OS"
    
    # Create backup directory
    create_backup
    
    # Copy SSH keys
    if copy_ssh_keys; then
        log_success "SSH keys copied successfully"
    else
        log_error "Failed to copy SSH keys"
        exit 1
    fi
    
    # Install packages
    install_packages "$OS"
    
    # Copy configuration files
    copy_config_files
    
    # Set up shell
    setup_shell
    
    log_success "Setup completed successfully!"
    log_info "Backup created at: $BACKUP_DIR"
    log_info "Please restart your terminal or source your shell configuration files"
}

# Check if running with bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                REMOTE_HOST="$2"
                shift 2
                ;;
            -u|--user)
                REMOTE_USER="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -h, --host HOST    Remote host (default: 10.0.1.5)"
                echo "  -u, --user USER    Remote user (default: current user)"
                echo "  --help             Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    main "$@"
fi
