extract () {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)  tar xjf $1    ;;
      *.tar.gz) tar xzf $1    ;;
      *.bz2)    bunzip2 $1    ;;
      *.rar)    rar x $1    ;;
      *.gz)   gunzip $1   ;;
      *.tar)    tar xf $1   ;;
      *.tbz2)   tar xjf $1    ;;
      *.tgz)    tar xzf $1    ;;
      *.zip)    unzip $1    ;;
      *.Z)    uncompress $1 ;;
      *)      echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Pull my public ssh key from shaunoneill.com and save it to the .ssh folder
function getsshkey () {
  # Create the .ssh folder if it doesn't exist and the authorized_keys file
  if [ ! -d $HOME/.ssh ]; then
      mkdir $HOME/.ssh
  fi

  if [ ! -f $HOME/.ssh/authorized_keys ]; then
      touch $HOME/.ssh/authorized_keys
  fi

  curl -s https://shaunoneill.com/publickey >> ~/.ssh/authorized_keys
  echo "Public key added to ~/.ssh/authorized_keys"
}

# Updates the home directory config files from the dotfiles config
function resetLocalConfig () {
  echo "Resetting home directory config folder and tmux config"
  cp $ZDOTDIR/homeConfigs/tmux/.tmux.conf $HOME/.tmux.conf
  cp -r $ZDOTDIR/.config $HOME/.config
}

# Updates the home directory vim config from the dotfiles config
function downloadVimConfig () {
  echo "Downloading vim config"

    if [ -d $HOME/.vim/bundle ]; then
      echo "Removing old vim config..."
      rm -rf $HOME/.vim/bundle
    fi

    cp -r $ZDOTDIR/homeConfigs/.vim $HOME/.vim

    # Check if the bundle folder exists
    if [ ! -d $HOME/.vim/bundle ]; then
        mkdir $HOME/.vim/bundle
    fi

    git clone https://github.com/altercation/vim-colors-solarized.git $HOME/.vim/bundle/vim-colors-solarized
    git clone https://github.com/vim-airline/vim-airline $HOME/.vim/bundle/vim-airline
    git clone https://github.com/plasticboy/vim-markdown.git $HOME/.vim/bundle/vim-markdown
    git clone https://github.com/bronson/vim-trailing-whitespace $HOME/.vim/bundle/vim-trailing-whitespace
    git clone https://github.com/Yggdroot/indentLine $HOME/.vim/bundle/indentLine
    git clone https://github.com/vim-airline/vim-airline-themes $HOME/.vim/bundle/vim-airline-themes
    git clone https://github.com/tpope/vim-fugitive $HOME/.vim/bundle/vim-fugitive
    git clone https://github.com/matze/vim-move $HOME/.vim/bundle/vim-move
}

function setupExa () {
  # Check if the exa command exists
  if ! command -v exa &> /dev/null; then
    echo "Installing exa..."

    if [ $machine = "Linux" ]; then 
      echo "Installing exa... (Linux)"
      sudo apt-get install -y exa

    elif [ $machine = "Mac" ]; then 
      echo "Installing exa... (Mac)"
      brew install exa
    fi
  fi
}

function resetZsh () {
  echo "Resetting zsh config..."
  curl -s https://raw.githubusercontent.com/realshaunoneill/dotfiles/master/install.sh | bash
}

function fixSudo () {
  if grep -q "auth sufficient pam_tid.so" "/etc/pam.d/sudo"; then
    echo "sudo is already configured to work with touch id"
  else
    echo "Configuring sudo to work with touch id..."
    sudo echo "auth sufficient pam_tid.so" >> /etc/pam.d/sudo
  fi
}

function fixLocals () {
  # Check if local-gen is not valid command
  if ! command -v locale-gen &> /dev/null; then
    sudo apt-get install -y locales
  fi

  sudo locale-gen $LANG
}

function shuv() {
  git add .
  git commit -m "${1:-x}"
  git push
}

function gcommit () {​
  BRANCH=$(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\" | cut -f1,2 -d'-')		# Branch name trimmed of any trailing newline
  
  if [ -z "$1" ]; then
    echo "You need to pass me a message" 
    echo "usage: gcommit message"
    exit 1
  fi
  
  echo "running: git add . && git commit -m \"$BRANCH: $*\""
  eval "git add ."
  eval "git commit -m \"$BRANCH: $*\""
}

function gpush () {
  STATUS=$(git status -sb 2>/dev/null)				# Used later to check if contains origin (has upstream)
  ERROR=$(git status -sb 2>&1 > /dev/null)			# If this is not empty usually means not in a git repo
  SUB='origin'

  if [ ! -z "$ERROR" ]; then
    echo "Eh this ain't no git repo man.."
    exit 1
  fi

  if grep -q "$SUB" <<< "$STATUS"; then
    echo "pushing to established upstream repo"
    git push
    exit 0
  fi
  echo "setting upstream and pushing to repo"
  git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\")		# No upstream. Subcommand gets current branch and trims newline
}

function gpushcan () {
  ERROR=$(git status -sb 2>&1 > /dev/null)			# If this is not empty usually means not in a git repo

  if [ ! -z "$ERROR" ]; then
    echo "Eh this ain't no git repo man.."
    exit 1
  fi

  echo "Pushing to canary branch"
  echo "git push origin $(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\"):canary --force"
  git push origin $(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\"):canary --force
}