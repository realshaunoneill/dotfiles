#!/usr/bin/env bash

# Check the OS version
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# check if the zsh command is valid
if ! [ -x "$(command -v zsh)" ]; then
    echo 'Error: zsh is not installed.'
    exit 1
fi

# check if the zsh command is valid
if ! [ -x "$(command -v git)" ]; then
    echo 'Error: git is not installed.'
    exit 1
fi

printf "Would you like to install the zsh config? This will wipe your current .zsh directory (y/n) "
read -r installZshConfig
if [ $installZshConfig = "y" ]; then
    echo "Installing zsh config..."
else
    echo "Exiting install..."
    exit 1
fi

function backupZshHistory {
    if [ -f $HOME/.zsh_history ]; then
        echo "Copying zsh history..."
        cp $HOME/.zsh/.zsh_history $HOME/.zsh_history.bak
    fi
}

function restoreZshHistory {
    if [ -f $HOME/.zsh_history.bak ]; then
        echo "Restoring zsh history..."
        mv $HOME/.zsh_history.bak $HOME/.zsh/.zsh_history
    fi
}

if [ $machine = "Linux" ]; then 
    echo "Running installation for Linux...."
    
    touch $HOME/.zsh && touch $HOME/.zcompdump
    backupZshHistory
    rm -rf $HOME/.zsh* && rm -rf $HOME/.zcompdump*
    git clone https://github.com/realshaunoneill/dotfiles.git $HOME/.zsh
    echo "export ZDOTDIR=\$HOME/.zsh" > $HOME/.zshenv
    echo "source \$ZDOTDIR/.zshenv" >> $HOME/.zshenv
    restoreZshHistory
    chsh -s $(which zsh)
    zsh

elif [ $machine = "Mac" ]; then 
    echo "Running installation for Mac...."
    
    touch $HOME/.zsh && touch $HOME/.zcompdump
    backupZshHistory
    rm -rf $HOME/.zsh* && rm -rf $HOME/.zcompdump*
    git clone https://github.com/realshaunoneill/dotfiles.git $HOME/.zsh
    echo "export ZDOTDIR=\$HOME/.zsh" > $HOME/.zshenv
    echo "source \$ZDOTDIR/.zshenv" >> $HOME/.zshenv
    restoreZshHistory
    chsh -s $(which zsh)
    zsh

else 
    echo "Exiting install... Unsupported OS: ${machine}"
fi