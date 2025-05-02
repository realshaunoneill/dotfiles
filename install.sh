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

if [ $machine = "Linux" ]; then 
    echo "Running installation for Linux...."

    if ! [ -x "$(command -v apt-get)" ]; then
        echo 'Error: apt is not installed.' >&2
        exit 1
    else
        sudo apt-get update
        sudo apt-get install -y git zsh
    fi
    
    touch $HOME/.zsh && touch $HOME/.zcompdump
    rm -rf $HOME/.zsh* && rm -rf $HOME/.zcompdump*
    git clone https://github.com/realshaunoneill/dotfiles.git $HOME/.zsh
    echo "export ZDOTDIR=\$HOME/.zsh" > $HOME/.zshenv
    echo "source \$ZDOTDIR/.zshenv" >> $HOME/.zshenv
    chsh -s $(which zsh)
    zsh

elif [ $machine = "Mac" ]; then 
    echo "Running installation for Mac...."

    if ! [ -x "$(command -v brew)" ]; then
        echo 'Error: apt is not installed.' >&2
        exit 1
    else 
        brew update
        brew install zsh
    fi
    
    touch $HOME/.zsh && touch $HOME/.zcompdump
    rm -rf $HOME/.zsh* && rm -rf $HOME/.zcompdump*
    git clone https://github.com/realshaunoneill/dotfiles.git $HOME/.zsh
    echo "export ZDOTDIR=\$HOME/.zsh" > $HOME/.zshenv
    echo "source \$ZDOTDIR/.zshenv" >> $HOME/.zshenv
    chsh -s $(which zsh)
    zsh

else echo "Exiting install... Unsupported OS: ${machine}"
fi