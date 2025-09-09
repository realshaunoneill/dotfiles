
alias sudo=$'nocorrect sudo\t'

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

# Git
alias uncommit='git reset --soft HEAD~1'
alias ga='git add'
alias gc='git commit -m'
alias gcm='git checkout master'
alias gcmp='git checkout master && git pull'
alias gcmpu='git pull && git checkout master && git pull && git checkout - && git merge master'

# Docker
alias docker-clean='docker system prune -a'
alias docker-cleani='docker rmi $(docker images -a -q)'
alias docker-cleanv='docker volume rm $(docker volume ls -q)'

# Others
alias node-arch="node -e 'console.log(process.arch)'"
alias python-arch="python -c 'import platform; print(platform.platform())'"

alias node-reset="unset NODE_OPTIONS"

# Check if the eza command exists
if [[ -f /opt/homebrew/bin/eza ]]; then
    # Sets the timestamp colour to a bit lighter blue
    export EZA_COLORS="da=1;34"

    alias ls="eza -la --header --long --icons --no-user --group-directories-first --time-style long-iso"
    alias lst="eza -la --header --long --icons --no-user --group-directories-first --time-style long-iso --tree --level=2"
    alias lsg="eza -la --header --grid  --icons --no-user --group-directories-first --time-style long-iso"
fi

# Kubernetes
alias k='kubectl'