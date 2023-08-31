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

#Exports full range of colors
blu="$(tput setaf 4)"
norm="$(tput sgr0)"

# Path to your oh-my-zsh installation.
export ZSH=$ZDOTDIR/.oh-my-zsh

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$ZDOTDIR/custom

#Checks if oh-my-zsh is installed
if [ ! -d $ZSH ]; then
    printf "${blu}Installing oh-my-zsh...${norm}\n"
    git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $ZSH &> /dev/null
    git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k &> /dev/null
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting &> /dev/null
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions &> /dev/null
    printf "${blu}Done installing oh-my-zsh${norm}\n"
fi

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="false"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=10

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting wd sudo)

# extra_plugins=$ZDOTDIR/.zshplugins
# if [ -f $extra_plugins ];  then
#     source $extra_plugins
# fi

source $ZSH/oh-my-zsh.sh

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
#
export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
#Plugin and theme setup
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=("fg=6")
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

#Aliases
alias zshconfig="$EDITOR $ZDOTDIR/.zshrc"
alias ohmyzsh="$EDITOR $ZSH"
alias zreconf="source $ZDOTDIR/.zshsetup"

#Adds auto upgrade system
source $ZDOTDIR/.zshupgrade

# Setup
[[ ! -f ~/.zsh/.p10k.zsh ]] && source $ZDOTDIR/.zshsetup

# To customize prompt, run `p10k configure` or edit ~/.zsh/.p10k.zsh.
[[ -f ~/.zsh/.p10k.zsh ]] && source ~/.zsh/.p10k.zsh

# set PATH so it includes user's private bin directories
export PATH=$PATH:$HOME/bin:$HOME/.local/bin:$HOME/.zsh/bin

# Allow us to check the OS at a later time
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# Source common aliases and functions, along with OS specific ones
source $ZDOTDIR/alias/functions.sh
source $ZDOTDIR/alias/common.sh

if [ $machine = "Linux" ]; then 
    source $ZDOTDIR/alias/linux.sh

elif [ $machine = "Mac" ]; then 
    source $ZDOTDIR/alias/mac.sh
fi

# Load application specific configs
[[ -f $ZDOTDIR/appConfigs/nvm.zsh ]] && source $ZDOTDIR/appConfigs/nvm.zsh

# Check if home directory config folder exists otherwise copy it from the dotfiles
if [ ! -d $HOME/.config ]; then
    cp -r $ZDOTDIR/.config $HOME/.config
fi

# Check if home directory tmux config exists otherwise copy it from the config folder
if [ ! -d $HOME/.tmux.conf ]; then
    cp $ZDOTDIR/homeConfigs/tmux/.tmux.conf $HOME/.tmux.conf
fi

# Prompt the person if they want to install the dotfiles
if [ ! -d $HOME/.vim ]; then
    printf "Would you like to install the vim configuration? (y/n) "
    read -r installVimConfig
    if [ $installVimConfig = "y" ]; then
        downloadVimConfig
    fi
fi

# Create .zprofile if it doesn't exist and source it
if [ ! -f $HOME/.zprofile ]; then
    touch ~/.zprofile
fi
source $HOME/.zprofile
