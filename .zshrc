# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
POWERLEVEL9K_INSTANT_PROMPT=verbose
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# From this point on, until zsh is fully initialized, console input won't work and
# console output may appear uncolored.

# Support 256 color
export TERM="xterm-256color"

# Path to your oh-my-zsh installation.
export ZSH=$ZDOTDIR/.oh-my-zsh

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$ZDOTDIR/custom

# Check and install oh-my-zsh if needed (only runs once)
if [ ! -d $ZSH ]; then
    # Define colors here only when needed
    blu="$(tput setaf 4)"
    norm="$(tput sgr0)"
    printf "${blu}Installing oh-my-zsh...${norm}\n"
    git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $ZSH &> /dev/null
    git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k &> /dev/null
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting &> /dev/null
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions &> /dev/null
    printf "${blu}Done installing oh-my-zsh${norm}\n"
fi

# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Configuration options
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
export UPDATE_ZSH_DAYS=10
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Plugins - keep only essential ones for startup
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Plugin configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=("fg=6")
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Environment settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR='vim'

# Core Aliases
alias zshconfig="$EDITOR $ZDOTDIR/.zshrc"
alias zupdate="git -C $ZDOTDIR pull && source $ZDOTDIR/.zshrc"
alias zreload='echo "Reloading ZSH file now..." && source $ZDOTDIR/.zshrc'
alias ohmyzsh="$EDITOR $ZSH"
alias zreconf="source $ZDOTDIR/.zshsetup"

# Determine OS (needed for conditional loading)
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# Load essential configs first
source $ZDOTDIR/alias/common.sh

# Lazy load OS-specific configs
if [ $machine = "Linux" ]; then 
    source $ZDOTDIR/alias/linux.sh
elif [ $machine = "Mac" ]; then 
    source $ZDOTDIR/alias/mac.sh
fi

# Lazy load NVM (only when needed)
nvm() {
  unset -f nvm
  [ -s "$ZDOTDIR/appConfigs/nvm.zsh" ] && source "$ZDOTDIR/appConfigs/nvm.zsh"
  nvm "$@"
}

# Add user's private bin directories to PATH
export PATH=$PATH:$HOME/bin:$HOME/.local/bin:$HOME/.zsh/bin

# Source upgrade system
source $ZDOTDIR/.zshupgrade

# Load p10k configuration
[[ ! -f ~/.zsh/.p10k.zsh ]] && source $ZDOTDIR/.zshsetup
[[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh

# Load functions (moved after p10k for faster prompt)
source $ZDOTDIR/alias/functions.sh

# Source .zprofile if it exists
[[ -f $HOME/.zprofile ]] && source $HOME/.zprofile

# Deferred configuration checks - run after shell is loaded
{
  # Check if home directory config folder exists
  if [ ! -d $HOME/.config ]; then
    cp -r $ZDOTDIR/.config $HOME/.config
  fi

  # Check if home directory tmux config exists
  if [ ! -f $HOME/.tmux.conf ]; then
    cp $ZDOTDIR/homeConfigs/tmux/.tmux.conf $HOME/.tmux.conf
  fi

  # Prompt for vim configuration if needed
  if [ ! -d $HOME/.vim ]; then
    printf "Would you like to install the vim configuration? (y/n) "
    read -r installVimConfig
    if [ $installVimConfig = "y" ]; then
      zDownloadVimConfig
    fi
  fi

  # Setup exa if available
  if [[ -f /opt/homebrew/bin/exa ]] && [ ! -f $HOME/.zprofile ]; then
    printf "Would you like to setup exa? (y/n) "
    read -r zSetupExa
    if [ $zSetupExa = "y" ]; then
      zSetupExa
    fi
  fi
} &!
