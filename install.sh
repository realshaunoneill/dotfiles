#!/usr/bin/env bash

# Check the OS version
unameOut="$(uname -s)"
case "${unameOut}" in
Linux*) machine=Linux ;;
Darwin*) machine=Mac ;;
CYGWIN*) machine=Cygwin ;;
MINGW*) machine=MinGw ;;
*) machine="UNKNOWN:${unameOut}" ;;
esac

# Check for required dependencies
for cmd in zsh git; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

printf "Would you like to install the zsh config? This will wipe your current .zsh directory (y/n) "
read -r installZshConfig
if [[ "$installZshConfig" != "y" ]]; then
    echo "Exiting install..."
    exit 1
fi

echo "Installing zsh config..."

# Create backup directory with timestamp
backup_dir="$HOME/.zsh_backup_$(date +%Y%m%d_%H%M%S)"

# Backup existing configuration
if [ -d "$HOME/.zsh" ]; then
    echo "Backing up previous zsh config to $backup_dir..."
    mkdir -p "$backup_dir"
    cp -R "$HOME/.zsh" "$backup_dir/"
    
    # Ensure history file is properly backed up
    if [ -f "$HOME/.zsh/.zsh_history" ]; then
        echo "Backing up zsh history..."
        cp "$HOME/.zsh/.zsh_history" "$backup_dir/.zsh_history"
    fi
    
    # Backup .zshenv if it exists
    if [ -f "$HOME/.zshenv" ]; then
        cp "$HOME/.zshenv" "$backup_dir/.zshenv"
    fi
fi

# Back up the SSH config too. This script rm -rf's ~/.zsh, and ~/.ssh/config.d
# holds 30-work.conf, which is deliberately untracked and exists in no repo -
# losing it means losing all work bastion access with nothing to restore from.
if [ -f "$HOME/.ssh/config" ] || [ -d "$HOME/.ssh/config.d" ]; then
    echo "Backing up SSH config to $backup_dir..."
    mkdir -p "$backup_dir/ssh"
    [ -f "$HOME/.ssh/config" ] && cp "$HOME/.ssh/config" "$backup_dir/ssh/config"
    [ -d "$HOME/.ssh/config.d" ] && cp -R "$HOME/.ssh/config.d" "$backup_dir/ssh/"
fi

# OS-specific setup
echo "Running installation for $machine..."

# Clean up existing files
rm -rf "$HOME/.zsh" "$HOME/.zcompdump"*

# Clone the repository
git clone --depth=1 https://github.com/realshaunoneill/dotfiles.git "$HOME/.zsh"

# Create .zshenv
echo "export ZDOTDIR=\$HOME/.zsh" > "$HOME/.zshenv"
echo "source \$ZDOTDIR/.zshenv" >> "$HOME/.zshenv"

# Restore history if backup exists
if [ -f "$backup_dir/.zsh_history" ]; then
    echo "Restoring zsh history..."
    cp "$backup_dir/.zsh_history" "$HOME/.zsh/.zsh_history"
fi

# The SSH fragments are copied into ~/.ssh/config.d rather than symlinked, so a
# fresh clone does not refresh them - they have to be reinstalled explicitly.
echo ""
echo "SSH: run 'ssh-setup' in your new shell to (re)install ~/.ssh/config.d."
if [ -d "$backup_dir/ssh/config.d" ]; then
    echo "     Your previous config.d (including the untracked 30-work.conf) is at"
    echo "     $backup_dir/ssh/config.d"
fi
echo ""

# Change shell to zsh
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "zsh" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
    echo "Shell changed. Please log out and log back in for changes to take effect."
    echo "Or run 'zsh' to start using your new configuration immediately."
else
    echo "Already using zsh as default shell."
    echo "Starting new zsh session with updated configuration..."
    exec zsh -l
fi
