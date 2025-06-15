#!/bin/bash

# SSH Key Setup Script
# Can generate new keys or copy existing keys from a remote host

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SSH]${NC} $1"
}

# Configuration
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_USER="${REMOTE_USER:-$(whoami)}"
SSH_KEY_PATH="$HOME/.ssh"

print_header "🔐 SSH Key Setup"

# Function to copy SSH keys from remote machine (based on your original script)
copy_ssh_keys_from_remote() {
    local remote_host="$1"
    local remote_user="$2"
    
    print_status "Copying SSH keys from $remote_host"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$SSH_KEY_PATH"
    chmod 700 "$SSH_KEY_PATH"
    
    # Check if we can connect to the remote host
    print_status "Testing connection to $remote_host..."
    
    # First try with BatchMode (key-based auth)
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$remote_user@$remote_host" exit 2>/dev/null; then
        print_success "Connection successful with key-based authentication"
    # If that fails, try interactive connection (password auth)
    elif ssh -o ConnectTimeout=10 "$remote_user@$remote_host" exit; then
        print_success "Connection successful with password authentication"
        print_status "SSH keys will be copied to enable key-based auth for future use"
    else
        print_error "Cannot connect to $remote_host. Please check:"
        print_error "1. The host is reachable: ping $remote_host"
        print_error "2. SSH service is running on the remote host"
        print_error "3. Username '$remote_user' exists on the remote host"
        print_error "4. Password authentication is enabled"
        print_error ""
        print_status "To test manually: ssh $remote_user@$remote_host"
        return 1
    fi
    
    # Copy private keys (common key names)
    local key_files=("id_rsa" "id_ed25519" "id_ecdsa")
    local keys_copied=0
    
    for key in "${key_files[@]}"; do
        if ssh "$remote_user@$remote_host" "test -f ~/.ssh/$key"; then
            print_status "Copying private key $key from remote host"
            if scp "$remote_user@$remote_host:~/.ssh/$key" "$SSH_KEY_PATH/"; then
                print_success "Successfully copied private key $key"
                chmod 600 "$SSH_KEY_PATH/$key"
                
                # Try to copy public key (may not exist)
                if ssh "$remote_user@$remote_host" "test -f ~/.ssh/$key.pub"; then
                    print_status "Copying public key $key.pub from remote host"
                    if scp "$remote_user@$remote_host:~/.ssh/$key.pub" "$SSH_KEY_PATH/"; then
                        print_success "Successfully copied public key $key.pub"
                        chmod 644 "$SSH_KEY_PATH/$key.pub"
                    else
                        print_warning "Failed to copy public key $key.pub"
                    fi
                else
                    print_status "Public key $key.pub not found on remote host"
                fi
                
                keys_copied=$((keys_copied + 1))
            else
                print_error "Failed to copy private key $key"
            fi
        else
            print_status "Private key $key not found on remote host, skipping"
        fi
    done
    
    # Copy known_hosts if it exists
    if ssh "$remote_user@$remote_host" "test -f ~/.ssh/known_hosts"; then
        print_status "Copying known_hosts from remote host"
        scp "$remote_user@$remote_host:~/.ssh/known_hosts" "$SSH_KEY_PATH/"
        chmod 644 "$SSH_KEY_PATH/known_hosts"
    fi
    
    # Copy SSH config if it exists
    if ssh "$remote_user@$remote_host" "test -f ~/.ssh/config"; then
        print_status "Copying SSH config from remote host"
        if [[ -f "$SSH_KEY_PATH/config" ]]; then
            print_status "Backing up existing SSH config"
            cp "$SSH_KEY_PATH/config" "$SSH_KEY_PATH/config.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        scp "$remote_user@$remote_host:~/.ssh/config" "$SSH_KEY_PATH/"
        chmod 600 "$SSH_KEY_PATH/config"
    fi
    
    if [[ $keys_copied -eq 0 ]]; then
        print_warning "No SSH keys found on remote host"
        return 1
    else
        print_success "Copied $keys_copied SSH key(s) from remote host"
        return 0
    fi
}

# Function to generate new SSH key
generate_new_ssh_key() {
    print_status "Generating new SSH key..."
    
    # Get email for SSH key
    if [[ -z "${SSH_EMAIL}" ]]; then
        read -p "Enter your email address for SSH key: " SSH_EMAIL
    fi
    
    # Get key name/comment
    if [[ -z "${SSH_KEY_NAME}" ]]; then
        read -p "Enter a name for this key (default: id_ed25519): " SSH_KEY_NAME
        SSH_KEY_NAME=${SSH_KEY_NAME:-id_ed25519}
    fi
    
    local key_path="$SSH_KEY_PATH/$SSH_KEY_NAME"
    
    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        print_warning "SSH key $key_path already exists!"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Keeping existing key."
            return 0
        fi
    fi
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$SSH_KEY_PATH"
    chmod 700 "$SSH_KEY_PATH"
    
    # Generate SSH key
    print_status "Generating Ed25519 SSH key..."
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$key_path" -N ""
    
    if [[ -f "$key_path" ]]; then
        print_success "SSH key generated successfully: $key_path"
        chmod 600 "$key_path"
        chmod 644 "$key_path.pub"
        
        # Display public key
        print_header "📋 Your Public SSH Key"
        echo ""
        echo "Copy this public key to your GitHub/GitLab account:"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$key_path.pub"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Copy to clipboard if possible
        if command -v xclip &> /dev/null; then
            cat "$key_path.pub" | xclip -selection clipboard
            print_success "✅ Public key copied to clipboard (xclip)"
        elif command -v pbcopy &> /dev/null; then
            cat "$key_path.pub" | pbcopy
            print_success "✅ Public key copied to clipboard (pbcopy)"
        elif command -v wl-copy &> /dev/null; then
            cat "$key_path.pub" | wl-copy
            print_success "✅ Public key copied to clipboard (wl-copy)"
        else
            print_warning "⚠️  Clipboard tool not found. Please copy the key manually."
        fi
        
        return 0
    else
        print_error "Failed to generate SSH key"
        return 1
    fi
}

# Function to setup SSH config
setup_ssh_config() {
    local config_file="$SSH_KEY_PATH/config"
    
    print_status "Setting up SSH config..."
    
    # Create basic SSH config if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        print_status "Creating SSH config..."
        
        # Create different configs based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS-specific config with UseKeychain
            cat > "$config_file" << 'EOF'
# SSH Configuration
Host *
    AddKeysToAgent yes
    UseKeychain yes

# GitHub
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    PreferredAuthentications publickey
EOF
        else
            # Linux/other systems - no UseKeychain
            cat > "$config_file" << 'EOF'
# SSH Configuration
Host *
    AddKeysToAgent yes

# GitHub
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    PreferredAuthentications publickey
EOF
        fi
        
        chmod 600 "$config_file"
        print_success "SSH config created"
    else
        print_status "SSH config already exists"
    fi
}

# Function to start SSH agent and add keys
setup_ssh_agent() {
    print_status "Setting up SSH agent..."
    
    # Start SSH agent if not running
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        eval "$(ssh-agent -s)"
    fi
    
    # Add all private keys found in .ssh directory
    local keys_added=0
    for key_file in "$SSH_KEY_PATH"/id_*; do
        if [[ -f "$key_file" && ! "$key_file" == *.pub ]]; then
            if ssh-add "$key_file" 2>/dev/null; then
                print_success "Added key: $(basename "$key_file")"
                keys_added=$((keys_added + 1))
            fi
        fi
    done
    
    if [[ $keys_added -gt 0 ]]; then
        print_success "Added $keys_added SSH key(s) to agent"
    else
        print_warning "No SSH keys found to add to agent"
    fi
}

# Main function
main() {
    print_status "SSH Key Setup Options:"
    echo ""
    echo "1. Copy SSH keys from remote host"
    echo "2. Generate new SSH key"
    echo "3. Both (copy from remote, then generate if needed)"
    echo ""
    
    if [[ -n "$REMOTE_HOST" ]]; then
        print_status "Remote host specified: $REMOTE_HOST"
        choice="1"
    else
        read -p "Choose an option (1-3): " choice
    fi
    
    case $choice in
        1)
            if [[ -z "$REMOTE_HOST" ]]; then
                read -p "Enter remote host IP/hostname: " REMOTE_HOST
            fi
            read -p "Enter remote username (default: $REMOTE_USER): " input_user
            REMOTE_USER=${input_user:-$REMOTE_USER}
            
            if copy_ssh_keys_from_remote "$REMOTE_HOST" "$REMOTE_USER"; then
                print_success "SSH keys copied successfully from remote host"
            else
                print_error "Failed to copy SSH keys from remote host"
                exit 1
            fi
            ;;
        2)
            generate_new_ssh_key
            ;;
        3)
            if [[ -z "$REMOTE_HOST" ]]; then
                read -p "Enter remote host IP/hostname: " REMOTE_HOST
            fi
            read -p "Enter remote username (default: $REMOTE_USER): " input_user
            REMOTE_USER=${input_user:-$REMOTE_USER}
            
            if copy_ssh_keys_from_remote "$REMOTE_HOST" "$REMOTE_USER"; then
                print_success "SSH keys copied successfully from remote host"
            else
                print_warning "Failed to copy from remote host, generating new key..."
                generate_new_ssh_key
            fi
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
    
    # Setup SSH config and agent
    setup_ssh_config
    setup_ssh_agent
    
    # Instructions
    print_header "📝 Next Steps"
    echo ""
    print_status "1. Add public keys to your accounts:"
    print_status "   → GitHub: https://github.com/settings/ssh/new"
    print_status "   → GitLab: https://gitlab.com/-/profile/keys"
    print_status ""
    print_status "2. Test connections:"
    print_status "   → GitHub: ssh -T git@github.com"
    print_status "   → GitLab: ssh -T git@gitlab.com"
    print_status ""
    
    # Test connection option
    if [[ -f "$SSH_KEY_PATH/id_ed25519" || -f "$SSH_KEY_PATH/id_rsa" ]]; then
        read -p "Would you like to test the GitHub connection now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Testing GitHub SSH connection..."
            if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                print_success "✅ GitHub SSH connection successful!"
            else
                print_warning "⚠️  GitHub SSH connection failed. Make sure you've added the key to your GitHub account."
                print_status "Manual test: ssh -T git@github.com"
            fi
        fi
    fi
    
    print_success "SSH key setup completed!"
}

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
        -e|--email)
            SSH_EMAIL="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -h, --host HOST    Remote host to copy keys from"
            echo "  -u, --user USER    Remote username (default: current user)"
            echo "  -e, --email EMAIL  Email for new SSH key generation"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Interactive mode"
            echo "  $0 -h 10.0.1.5 -u myuser    # Copy keys from remote host"
            echo "  $0 -e user@example.com       # Generate new key with email"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run main function
main
