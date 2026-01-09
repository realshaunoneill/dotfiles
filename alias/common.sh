
alias sudo=$'nocorrect sudo\t'

# Disable autocorrect for common commands that get incorrectly corrected
alias npx='nocorrect npx'
alias nx='nocorrect nx'

# General
alias ping='ping -c 5'
alias c='clear'
alias h='history'
alias hg='history | grep'

# Safety aliases - ask before overwriting
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'

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
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gcm='git checkout master'
alias gcmp='git checkout master && git pull'
alias gcmpu='git pull && git checkout master && git pull && git checkout - && git merge master'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch --all --prune'
alias gl='git log --oneline -20'
alias glg='git log --graph --oneline --decorate -20'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gs='git status -sb'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'

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