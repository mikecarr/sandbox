#!/bin/bash

# Script to set up a Bash environment with aliases.
# This script is designed to be run via curl or wget.

# Configuration Section:  Customize these!
ALIAS_FILE="$HOME/.bash_aliases.setup" # Where aliases are written
BASHRC_FILE="$HOME/.bashrc"        # Where .bash_aliases.setup is sourced

# --- Function Definitions ---

function create_alias_file() {
  cat <<EOF > "$ALIAS_FILE"
# Aliases set up by automated script.  Do NOT edit directly!

alias la='ls -la'
alias ga='git add'
alias gc='git commit -m'
alias gs='git status'
alias gp='git push'
alias gl='git log --oneline --decorate --graph'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias please='sudo'
alias grep='grep --color=auto' # colorize grep output (good habit to have)
alias update='sudo apt update && sudo apt upgrade'
alias docker-compose='docker compose' # Requires docker compose v2

# Add your own aliases here.  Format: alias <alias_name>='<command>'
# Example: alias my_script='python /path/to/my/script.py'

EOF

  echo "Created alias file: $ALIAS_FILE"
}


function source_alias_file() {
  # Check if the alias file is already sourced in .bashrc
  if grep -q "$ALIAS_FILE" "$BASHRC_FILE"; then
    echo "$ALIAS_FILE already sourced in $BASHRC_FILE."
  else
    echo "Sourcing $ALIAS_FILE in $BASHRC_FILE."
    echo "if [ -f \"$ALIAS_FILE\" ]; then" >> "$BASHRC_FILE"
    echo "    . \"$ALIAS_FILE\"" >> "$BASHRC_FILE"
    echo "fi" >> "$BASHRC_FILE"
  fi

  source "$BASHRC_FILE"  # Activate the aliases immediately
  echo "Aliases activated."
}


# --- Main Execution ---

# Check if .bashrc exists. Create it if it doesn't.  This is vital.
if [ ! -f "$BASHRC_FILE" ]; then
  echo "Creating $BASHRC_FILE."
  touch "$BASHRC_FILE"
fi

# Create the alias file if it doesn't exist
if [ ! -f "$ALIAS_FILE" ]; then
  create_alias_file
fi

# Source the alias file in .bashrc
source_alias_file


echo "Environment setup complete!"
echo "You may need to open a new terminal or run 'source $BASHRC_FILE' for the changes to fully take effect if sourcing fails."
