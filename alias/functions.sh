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

function resetZsh () {
  echo "Resetting zsh config..."
  sh -c '$(curl -fsSL https://raw.githubusercontent.com/realshaunoneill/dotfiles/master/install.sh)'
}