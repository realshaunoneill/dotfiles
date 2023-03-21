# update on one command
alias update='sudo apt-get update && sudo apt-get upgrade'

## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
alias service-status='sudo services --status-all'

## get GPU ram on desktop / laptop##
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'

alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'