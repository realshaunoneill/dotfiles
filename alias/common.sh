# Had to be done
alias reload='echo "Reloading ZSH file now..." && source $ZDOTDIR/.zshrc'

# General
alias ping='ping -c 5'
alias c='clear'

# Resume wget
alias wget='wget -c'

alias tn='tmux new-session -s'                                # tmux new session
alias ta='tmux attach -t'                                     # tmux attach
alias tl='tmux ls'                                            # list
alias tk='tmux kill-session -s'                               # kill session

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

# Open ports
alias ports-o='sudo lsof -i -P -n | grep LISTEN'

# Ngrok
alias ngrok-h='$ZDOTDIR/bin/ngrok http'
alias ngrok-sh='$ZDOTDIR/bin/ngrok http -auth "admin:admin"'
alias ngrok-tcp='$ZDOTDIR/bin/ngrok tcp'

# Imgur Uploader
alias upload='$ZDOTDIR/bin/imgur.sh'

# Pull my public ssh key from shaunoneill.com and save it to the .ssh folder
function getsshkey () {
  # Create the .ssh folder if it doesn't exist and the authorized_keys file
  if [ ! -f $HOME/.ssh ]; then
      mkdir $HOME/.ssh
  fi
  
  if [ ! -f $HOME/.ssh/authorized_keys ]; then
      touch $HOME/.ssh/authorized_keys
  fi

  curl -s https://shaunoneill.com/publickey >> ~/.ssh/authorized_keys
}

# Updates the home directory config files from the dotfiles config
function resetLocalConfig () {
  echo "Resetting home directory config folder and tmux config"
  cp $ZDOTDIR/homeConfigs/tmux/.tmux.conf $HOME/.tmux.conf
  cp -r $ZDOTDIR/.config $HOME/.config
}