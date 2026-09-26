# ------------------------------- #
#           Core                  #
# ------------------------------- #

# Updates the home directory config files from the dotfiles config
function zResetLocalConfig () {
  echo "Resetting home directory config folder and tmux config"
  cp $ZDOTDIR/homeConfigs/tmux/.tmux.conf $HOME/.tmux.conf
  cp -r $ZDOTDIR/.config $HOME/.config
}

# Updates the home directory vim config from the dotfiles config
function zDownloadVimConfig () {
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

function zSetupEza () {
  # Check if the eza command exists
  if ! command -v eza > /dev/null; then
    echo "Installing eza..."

    if [ "$machine" = "Linux" ]; then
      echo "Installing eza... (Linux)"
      sudo apt-get install -y eza

    elif [ "$machine" = "Mac" ]; then
      echo "Installing eza... (Mac)"
      brew install eza
    fi
  fi
}

function zReinstall () {
  echo "Resetting zsh config..."
  curl -s https://raw.githubusercontent.com/realshaunoneill/dotfiles/master/install.sh | bash
}

# Symlink the tracked Claude Code commands/agents into ~/.claude so custom
# slash commands and subagents are available on this machine. Run manually
# (also aliased to `claude-setup`); not run on shell startup.
function zSetupClaude () {
  local claude_dir="$HOME/.claude"
  local stamp
  stamp="$(date +%Y%m%d_%H%M%S)"

  mkdir -p "$claude_dir"

  local sub
  for sub in commands agents; do
    local src="$ZDOTDIR/claude/$sub"
    local dest="$claude_dir/$sub"

    if [ ! -d "$src" ]; then
      echo "Skipping $sub (no $src in dotfiles)"
      continue
    fi

    # Already linked correctly? Skip.
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      echo "$sub already linked"
      continue
    fi

    # Back up an existing real dir or wrong symlink before replacing.
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      echo "Backing up existing $dest to $dest.bak.$stamp"
      mv "$dest" "$dest.bak.$stamp"
    fi

    ln -s "$src" "$dest"
    echo "Linked $dest -> $src"
  done

  echo "Claude Code setup complete"
}

# Install the SSH config skeleton: a thin ~/.ssh/config that Includes
# ~/.ssh/config.d/*.conf, plus the tracked fragments. Idempotent — re-run it
# after any dotfiles update that touches ssh/. Aliased to `ssh-setup`.
#
# The dotfiles fragments are COPIED, not symlinked (unlike zSetupClaude above):
# zReinstall does `rm -rf "$HOME/.zsh"` before re-cloning, and a dangling Include
# target risks breaking every ssh on the machine, work included.
#
# See $ZDOTDIR/ssh/README.md for the ordering contract and the two invariants.
#
# NOTE: `command` prefixes are required throughout. common.sh aliases cp/mv/mkdir
# to their -i interactive forms and is sourced BEFORE this file, so a bare `cp`
# here would prompt on every overwrite and hang the function.
function zSetupSsh () {
  local ssh_dir="$HOME/.ssh"
  local frag_dir="$HOME/.ssh/config.d"
  local src_dir="$ZDOTDIR/ssh"
  local stamp
  stamp="$(date +%Y%m%d_%H%M%S)"

  if [ ! -d "$src_dir" ]; then
    echo "No $src_dir in dotfiles - commit, push and \`zupdate\` first"
    return 1
  fi

  command mkdir -p "$frag_dir"
  chmod 700 "$ssh_dir" "$frag_dir"

  # 1. Back up the live config FIRST. This is the rollback.
  if [ -f "$ssh_dir/config" ] && [ ! -L "$ssh_dir/config" ]; then
    command cp -p "$ssh_dir/config" "$ssh_dir/config.bak.$stamp"
    chmod 600 "$ssh_dir/config.bak.$stamp"
    echo "Backed up $ssh_dir/config -> config.bak.$stamp"
  fi

  # 2. Copy the tracked fragments. 90-1password.conf is macOS only: the agent
  #    socket is a macOS group-container path and would dangle on Linux.
  local frags=(10-github.conf 99-defaults.conf)
  [ "$machine" = "Mac" ] && frags+=(90-1password.conf)

  local f
  for f in $frags; do
    if [ -f "$src_dir/config.d/$f" ]; then
      command cp -f "$src_dir/config.d/$f" "$frag_dir/$f"
      chmod 600 "$frag_dir/$f"
      echo "Installed $frag_dir/$f"
    else
      echo "Skipping $f (not in dotfiles - push and \`zupdate\` first)"
    fi
  done

  # 3. The host inventory lives in a PRIVATE repo - addresses, ssh users and which
  #    boxes are password-only - so it must never be vendored into these public
  #    dotfiles. Symlinked, not copied, so edits there take effect immediately and
  #    a stale copy can never mislead you.
  #
  #    The main checkout is frequently parked on a feature branch (several agent
  #    sessions share that repo, each on its own branch under .claude/worktrees/),
  #    and a branch that predates this fragment simply does not have the file in its
  #    working tree. Without a fallback, running this function in that window would
  #    report "not installed" and every homelab alias would quietly stop resolving -
  #    which surfaces as a confusing DNS error, not as a config problem.
  #
  #    So try three locations in order of how stable they are:
  #      1. the main checkout            - the natural home, when it is on a branch
  #                                       that has the file
  #      2. a `master` worktree          - a durable, deliberately-created worktree
  #                                       whose whole job is to be a branch-independent
  #                                       source for this symlink. Detached on
  #                                       origin/master on purpose: a worktree ON the
  #                                       master BRANCH would make `git checkout master`
  #                                       fail in the main tree and break other sessions.
  #      3. any other worktree           - last resort; may be an old branch, so say so
  local hl_repo="${SSH_PRIVATE_REPO:-$HOME/Personal/home-ops}"
  local hl_src="${SSH_PRIVATE_FRAGMENT:-$hl_repo/ssh/20-homelab.conf}"
  local hl_via="main checkout"

  if [ ! -f "$hl_src" ] && [ -z "$SSH_PRIVATE_FRAGMENT" ]; then
    if [ -f "$hl_repo/.claude/worktrees/master/ssh/20-homelab.conf" ]; then
      hl_src="$hl_repo/.claude/worktrees/master/ssh/20-homelab.conf"
      hl_via="master worktree - main checkout is on a branch without it"
    else
      local cand
      for cand in "$hl_repo"/.claude/worktrees/*/ssh/20-homelab.conf(N); do
        [ -f "$cand" ] || continue
        hl_src="$cand"
        hl_via="WARNING: fell back to $(basename ${cand:h:h}) - may be a stale branch"
        break
      done
    fi
  fi

  local hl_dest="$frag_dir/20-homelab.conf"
  if [ -f "$hl_src" ]; then
    if [ -L "$hl_dest" ] && [ "$(readlink "$hl_dest")" = "$hl_src" ]; then
      echo "20-homelab.conf already linked ($hl_via)"
    else
      if [ -e "$hl_dest" ] || [ -L "$hl_dest" ]; then
        echo "Backing up $hl_dest to $hl_dest.bak.$stamp"
        command mv "$hl_dest" "$hl_dest.bak.$stamp"
      fi
      ln -s "$hl_src" "$hl_dest"
      echo "Linked $hl_dest -> $hl_src ($hl_via)"
    fi
  else
    echo "No private ops fragment found under $hl_repo - those aliases NOT installed"
  fi

  # 4. The work bastions are LOCAL AND UNTRACKED by design: their FQDNs must not be
  #    published. There is no repo copy, so only ever warn - never write here.
  if [ ! -f "$frag_dir/30-work.conf" ]; then
    echo "NOTE: $frag_dir/30-work.conf is missing (work bastions)."
    echo "      Untracked on purpose - rebuild steps are in the private runbook,"
    echo "      or restore it from a ~/.ssh backup."
  fi

  # 5. The thin config, as a real copy: this is the file you hand-edit when ssh is
  #    broken, and that edit must not become a dotfiles diff.
  if [ -f "$src_dir/config" ]; then
    command cp -f "$src_dir/config" "$ssh_dir/config"
    chmod 600 "$ssh_dir/config"
    echo "Installed thin $ssh_dir/config"
  fi

  # 6. agent.toml restricts which keys the 1Password agent offers. Its ABSENCE
  #    means "every key from every unlocked account" - with two accounts signed
  #    in, that leaks work keys into every personal ssh.
  if [ "$machine" = "Mac" ] && [ -f "$src_dir/agent.toml" ]; then
    local op_dir="$HOME/.config/1Password/ssh"
    command mkdir -p "$op_dir"
    if [ -f "$op_dir/agent.toml" ]; then
      command cp -p "$op_dir/agent.toml" "$op_dir/agent.toml.bak.$stamp"
    fi
    command cp -f "$src_dir/agent.toml" "$op_dir/agent.toml"
    echo "Installed $op_dir/agent.toml (a typo here = EMPTY agent, verify below)"
  fi

  # 7. The public half of the 1Password key. The PRIVATE key never leaves
  #    1Password. A missing .pub is a hard failure for every IdentitiesOnly block
  #    that names it, so be loud rather than leaving a silent auth failure.
  local pub="$ssh_dir/id_ed25519_personal.pub"
  local sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  if [ ! -s "$pub" ]; then
    if command -v op >/dev/null 2>&1 && \
       op read "op://Private/SSH - personal (ed25519)/public key" \
          --account my.1password.com > "$pub" 2>/dev/null && [ -s "$pub" ]; then
      echo "Wrote $pub from 1Password"
    elif [ -S "$sock" ] && \
         SSH_AUTH_SOCK="$sock" ssh-add -L > "$pub" 2>/dev/null && [ -s "$pub" ]; then
      echo "Wrote $pub from the 1Password agent"
    else
      command rm -f "$pub"
      echo "WARNING: could not retrieve the 1Password public key."
      echo "         Blocks using IdentitiesOnly + $pub will fall back to the"
      echo "         transitional on-disk key until it exists."
      echo "         1Password > Settings > Developer > 'Use the SSH agent', then re-run."
    fi
  fi
  [ -f "$pub" ] && chmod 644 "$pub"

  # 8. Parse check - ssh -G fails loudly on a malformed config.
  if ssh -G github.com >/dev/null 2>&1; then
    echo "SSH setup complete; config parses."
  else
    echo "WARNING: \`ssh -G github.com\` failed - the config may be malformed."
    echo "         Roll back with: cp $ssh_dir/config.bak.$stamp $ssh_dir/config"
    return 1
  fi
  echo "Verify with: ssh -Gv <host> 2>&1 | grep -E 'Reading conf|Applying options'"
}

# 1Password CLI, scoped per account. With more than one account signed in, a bare
# `op` subcommand fails with "multiple accounts found" and needs --account every
# time. Deliberately NOT done by exporting OP_ACCOUNT, which would silently point
# every work `op` call at the personal account.
#
#   opp - the personal account ($OP_PERSONAL_ACCOUNT, default my.1password.com)
#   opw - the other signed-in account, resolved at runtime so no employer-specific
#         tenant name is baked into this public repo
function opp () { op --account "${OP_PERSONAL_ACCOUNT:-my.1password.com}" "$@"; }
function opw () {
  local personal="${OP_PERSONAL_ACCOUNT:-my.1password.com}" acct
  acct="${OP_WORK_ACCOUNT:-$(op account list --format=json 2>/dev/null \
    | /usr/bin/python3 -c 'import json,sys
try: a=json.load(sys.stdin)
except Exception: sys.exit(0)
p=sys.argv[1]
print(next((x["url"] for x in a if x.get("url")!=p), ""))' "$personal")}"
  if [ -z "$acct" ]; then
    echo "opw: no non-personal 1Password account signed in (set OP_WORK_ACCOUNT)" >&2
    return 1
  fi
  op --account "$acct" "$@"
}

# ------------------------------- #
#           Utils                 #
# ------------------------------- #

extract () {
  if [ -f "$1" ] ; then
    case "$1" in
      *.tar.bz2)  tar xjf "$1"    ;;
      *.tar.gz) tar xzf "$1"    ;;
      *.bz2)    bunzip2 "$1"    ;;
      *.rar)    rar x "$1"    ;;
      *.gz)   gunzip "$1"   ;;
      *.tar)    tar xf "$1"   ;;
      *.tbz2)   tar xjf "$1"    ;;
      *.tgz)    tar xzf "$1"    ;;
      *.zip)    unzip "$1"    ;;
      *.Z)    uncompress "$1" ;;
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

function fixSudo () {
  if grep -q "auth sufficient pam_tid.so" "/etc/pam.d/sudo"; then
    echo "sudo is already configured to work with touch id"
  else
    echo "Configuring sudo to work with touch id..."
    sudo sed -i '' '2i\
auth sufficient pam_tid.so
' /etc/pam.d/sudo
    echo "Done - touch id enabled for sudo"
  fi
}

function fixLocals () {
  # Check if local-gen is not valid command
  if ! command -v locale-gen &> /dev/null; then
    sudo apt-get install -y locales
  fi

  sudo locale-gen $LANG
}

# ------------------------------- #
#           Work                  #
# ------------------------------- #

function shuv() {
  git add .
  git commit -m "${1:-x}"
  if [ "$2" = "--force" ]; then
    git push --force
  else
    git push
  fi
}

function gshuv () {
  git add .
  gcommit "${1:-x}"
  
  if [ "$2" = "--force" ]; then
    git push --force
  else
    gpush
  fi
}

function gcommit () {
  BRANCH=$(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\" | cut -f1,2 -d'-')		# Branch name trimmed of any trailing newline
  
  if [ -z "$1" ]; then
    echo "You need to pass me a message" 
    echo "usage: gcommit message"
    return 1
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
    return 1
  fi

  if grep -q "$SUB" <<< "$STATUS"; then
    echo "pushing to established upstream repo"
    git push
    return 0
  fi
  echo "setting upstream and pushing to repo"
  git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\")		# No upstream. Subcommand gets current branch and trims newline
}

function gremake () {
  # Get current branch if no branch name was provided
  local current_branch=$(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\")
  local branch_to_remake="${1:-$current_branch}"
  
  # Check if we're already on master
  if [ "$current_branch" = "master" ]; then
    echo "Error: Currently on master branch. Please specify a branch to remake."
    echo "Usage: gremake [branch_name]"
    return 1
  fi
  
  # Change to master branch
  echo "Switching to master branch..."
  git checkout master
  
  # Delete the previous branch
  echo "Deleting branch: $branch_to_remake"
  git branch -D "$branch_to_remake"
  
  # Pull latest changes from master
  echo "Pulling latest changes from master..."
  git pull
  
  # Recreate the branch from the updated master
  echo "Creating new branch: $branch_to_remake"
  git checkout -b "$branch_to_remake"
  
  echo "Branch $branch_to_remake has been remade successfully"
}

function gpushcan () {
  ERROR=$(git status -sb 2>&1 > /dev/null)			# If this is not empty usually means not in a git repo

  if [ ! -z "$ERROR" ]; then
    echo "Eh this ain't no git repo man.."
    return 1
  fi

  echo "Pushing to canary branch"
  echo "git push origin $(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\"):canary --force"
  git push origin $(git rev-parse --abbrev-ref HEAD | tr -d \"\\n\\r\"):canary --force
}

function pushLogFile () {
  if [ "$#" -ne 3 ];then
      >&2 echo "Usage: $(basename "$0") <log_token> <region> <log_filename>"
      return 1
  fi
  awk "{print \"$1 \" \$0}" < "$3" | nc "$2.data.logs.insight.rapid7.com" 10000;
}

function gcountlines() {
    local author="${1:-$(git config user.name)}"
    echo "Lines edited by $author"
    git log --author="$author" --pretty=format: --numstat | awk '
        {a+=$1;r+=$2} 
        END {
            printf "\n\033[0;32mAdded ++ %d\n\033[0;31mRemoved -- %d\n\033[0m", a, r
        }
    '
}

# Clone repository using standard GitHub URL
function clone() {
  if [ -z "$1" ]; then
    echo "Usage: clone <owner/repo> or clone <full-git-url>"
    return 1
  fi
  
  # If it's already a full git URL, use it as-is
  if [[ "$1" == git@* ]] || [[ "$1" == https://* ]]; then
    git clone "$1"
  else
    # Otherwise treat it as owner/repo format
    git clone "git@github.com:$1.git"
  fi
}

# Clone repository using personal GitHub SSH config
function clonep() {
  if [ -z "$1" ]; then
    echo "Usage: clonep <owner/repo> or clonep <full-git-url>"
    return 1
  fi
  
  # If it's a full git URL with git@github.com, replace with git@github.com-personal
  if [[ "$1" == git@github.com:* ]]; then
    local personal_url="${1/git@github.com:/git@github.com-personal:}"
    git clone "$personal_url"
  # If it's already using -personal, use it as-is
  elif [[ "$1" == git@github.com-personal:* ]]; then
    git clone "$1"
  # If it's an HTTPS URL, convert to SSH personal format
  elif [[ "$1" == https://github.com/* ]]; then
    local repo_path="${1#https://github.com/}"
    repo_path="${repo_path%.git}"
    git clone "git@github.com-personal:${repo_path}.git"
  else
    # Otherwise treat it as owner/repo format
    git clone "git@github.com-personal:$1.git"
  fi
}

# ------------------------------- #
#     Additional Utilities        #
# ------------------------------- #

# Create directory and cd into it
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Find file by name in current directory
function ff() {
  find . -type f -iname "*$1*"
}

# Find directory by name (named fdir to avoid shadowing the `fd` find tool)
function fdir() {
  find . -type d -iname "*$1*"
}

# Quick backup of a file
function backup() {
  cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

# Get public IP address
function myip() {
  echo "Public IP: $(curl -s ifconfig.me)"
  echo "Local IP: $(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')"
}

# Quick HTTP server in current directory
function serve() {
  local port="${1:-8000}"
  echo "Serving on http://localhost:$port"
  python3 -m http.server "$port"
}

# Show directory size
function dirsize() {
  du -sh "${1:-.}" 2>/dev/null
}

# Kill process on a specific port
function killport() {
  if [ -z "$1" ]; then
    echo "Usage: killport <port>"
    return 1
  fi
  lsof -ti:"$1" | xargs kill -9 2>/dev/null && echo "Killed process on port $1" || echo "No process found on port $1"
}

# Quick note taking
function note() {
  local notes_file="$HOME/.notes"
  if [ -z "$1" ]; then
    cat "$notes_file" 2>/dev/null || echo "No notes yet"
  else
    echo "$(date '+%Y-%m-%d %H:%M'): $*" >> "$notes_file"
    echo "Note added"
  fi
}

# Weather in terminal
function weather() {
  curl -s "wttr.in/${1:-}"
}

# JSON pretty print
function jsonpp() {
  if [ -z "$1" ]; then
    python3 -m json.tool
  else
    cat "$1" | python3 -m json.tool
  fi
}

# Git - show branches sorted by last commit date
function gbrecent() {
  git for-each-ref --sort=-committerdate refs/heads/ --format='%(committerdate:short) %(refname:short)' | head -20
}

# Git - delete merged branches (except master/main)
function gclean() {
  git branch --merged | grep -vE '(master|main|\*)' | xargs -r git branch -d
  echo "Cleaned up merged branches"
}

# Show all defined aliases, sorted. Pass an argument to filter (e.g. `aliases git`).
function aliases() {
  if [ -n "$1" ]; then
    alias | sort | grep --color=auto -i "$1"
  else
    alias | sort
  fi
}


