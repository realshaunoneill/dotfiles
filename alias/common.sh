
alias sudo='sudo '
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

# Open ports
alias ports-o='sudo lsof -i -P -n | grep LISTEN'

# Ngrok
alias ngrok-h='$ZDOTDIR/bin/ngrok http'
alias ngrok-sh='$ZDOTDIR/bin/ngrok http -auth "admin:admin"'
alias ngrok-tcp='$ZDOTDIR/bin/ngrok tcp'

# Imgur Uploader
alias upload='$ZDOTDIR/bin/imgur.sh'