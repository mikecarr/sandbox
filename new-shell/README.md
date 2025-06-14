# Shell Setup Script

An automated shell configuration script that copies SSH keys, installs essential packages, and synchronizes configuration files from a remote machine to quickly set up a new development environment.

## Features

- 🔑 **SSH Key Management**: Automatically copies private keys and known_hosts from a remote machine
- 📦 **Cross-Platform Package Installation**: Supports Ubuntu, CentOS, and macOS
- ⚙️ **Configuration Sync**: Copies common dotfiles (.gitconfig, .bashrc, .vimrc, neovim configs, etc.)
- 🛡️ **Backup System**: Creates timestamped backups of existing files before making changes
- 🎨 **Colored Output**: Clear, colored logging for easy monitoring
- 🔧 **Flexible Configuration**: Command-line options for different hosts and users

## Prerequisites

Before running the script, ensure you have:

1. **SSH access** to the remote machine (default: `10.0.1.5`) with either:
   - SSH key authentication (if already set up), OR
   - Password authentication (for fresh installs)
2. **Sudo privileges** on the target machine for package installation
3. **SSH keys and config files** present on the remote machine you want to copy from
4. **Network connectivity** between machines

**Note**: This script is designed to work on fresh installations where you don't have SSH keys yet. It will copy existing keys from the remote machine to bootstrap your new environment.

## Quick Start

1. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/yourusername/yourrepo/main/setup.sh
   # or
   curl -O https://raw.githubusercontent.com/yourusername/yourrepo/main/setup.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x setup.sh
   ```

3. **Run with default settings**:
   ```bash
   ./setup.sh
   ```

## Usage

### Basic Usage
```bash
./setup.sh
```

### Custom Host and User
```bash
./setup.sh --host 192.168.1.100 --user myuser
```

### Command Line Options
```bash
./setup.sh [OPTIONS]

Options:
  -h, --host HOST    Remote host IP/hostname (default: 10.0.1.5)
  -u, --user USER    Remote username (default: current user)
  --help             Show help message and exit
```

### Environment Variables
You can also set the remote user via environment variable:
```bash
export REMOTE_USER=myuser
./setup.sh
```

## What Gets Installed

### Packages by Platform

**Ubuntu/Debian:**
- git, curl, wget, vim, neovim
- tmux, htop, tree, jq, unzip
- build-essential, python3, python3-pip
- nodejs, npm

**CentOS/RHEL:**
- git, curl, wget, vim, neovim
- tmux, htop, tree, jq, unzip
- gcc, gcc-c++, make, python3, python3-pip
- nodejs, npm

**macOS (via Homebrew):**
- git, curl, wget, vim, neovim
- tmux, htop, tree, jq
- node, python

### Configuration Files Copied

The script will copy these files from the remote machine (if they exist):

- `.gitconfig` - Git configuration
- `.bashrc` - Bash shell configuration
- `.bash_profile` - Bash profile settings
- `.vimrc` - Vim editor configuration
- `.config/nvim/init.vim` - Neovim Vimscript config
- `.config/nvim/init.lua` - Neovim Lua config
- `.tmux.conf` - Tmux terminal multiplexer config
- `.zshrc` - Zsh shell configuration

### SSH Keys Copied

The script attempts to copy these SSH key types:
- `id_rsa` / `id_rsa.pub`
- `id_ed25519` / `id_ed25519.pub`
- `id_ecdsa` / `id_ecdsa.pub`
- `known_hosts`

## Examples

### Setting up from a different remote machine
```bash
./setup.sh --host 192.168.50.10 --user devuser
```

### Using with a jump host
If you need to go through a jump host, modify your SSH config first:
```bash
# Add to ~/.ssh/config
Host target-machine
    HostName 10.0.1.5
    User myuser
    ProxyJump jump-host.example.com

# Then run setup
./setup.sh --host target-machine
```

### Running on a fresh machine (typical use case)
```bash
# On a brand new Ubuntu/CentOS/macOS installation
# You'll be prompted for the password of the remote machine several times
./setup.sh --host 10.0.1.5 --user mcarr

# The script will:
# 1. Copy SSH keys from 10.0.1.5 to your new machine
# 2. Install essential development packages
# 3. Copy your dotfiles and configurations
# 4. Set up your development environment exactly like the remote machine
```

## Backup and Recovery

The script automatically creates backups before making changes:

- **Backup location**: `~/.config_backup_YYYYMMDD_HHMMSS/`
- **What's backed up**: Any existing configuration files that would be overwritten

### Restoring from backup
```bash
# List available backups
ls ~/.config_backup_*

# Restore a specific file
cp ~/.config_backup_20241214_143052/.gitconfig ~/.gitconfig

# Restore all files from a backup
cp ~/.config_backup_20241214_143052/.* ~/
```

## Troubleshooting

### SSH Connection Issues
```bash
# Test SSH connection manually
ssh user@10.0.1.5 exit

# Check SSH key authentication
ssh -v user@10.0.1.5
```

### Permission Issues
```bash
# Ensure proper SSH key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
```

### Package Installation Failures
- **Ubuntu**: Update package lists with `sudo apt-get update`
- **CentOS**: Enable EPEL repository for additional packages
- **macOS**: Install Homebrew first if not present

### Missing Configuration Files
The script gracefully handles missing files on the remote machine. Check the output for which files were skipped.

## Customization

### Adding Custom Packages
Edit the package arrays in the script:
```bash
UBUNTU_PACKAGES+=(
    "your-package-here"
    "another-package"
)
```

### Adding Custom Configuration Files
Add to the CONFIG_FILES array:
```bash
CONFIG_FILES+=(
    ".custom-config"
    ".config/app/settings.json"
)
```

### Custom Setup Steps
Add custom logic to the `setup_shell()` function for additional configuration.

## Security Considerations

- The script copies private SSH keys - ensure the remote machine is trusted
- Configuration files may contain sensitive information
- Review the script before running on production systems
- The backup system helps prevent data loss

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on different platforms
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the script output for specific error messages
3. Open an issue on GitHub with:
   - Your operating system
   - The complete error message
   - Steps to reproduce the problem
