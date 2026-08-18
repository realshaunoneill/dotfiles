# ------------------------------- #
#         Claude Code             #
# ------------------------------- #
# Helpers for Anthropic's Claude Code CLI. The whole file is a no-op on
# machines where the `claude` binary isn't installed.

if command -v claude &>/dev/null; then

  # Peer-session messaging — the ListAgents tool plus SendMessage to another local
  # session by name — is gated on the GrowthBook flag `tengu_harbor_kite`. We fetch
  # models through the Bedrock llmproxy, so that flag realistically never flips for
  # us. The binary checks this env var first and short-circuits the flag.
  # Undocumented internal flag: delete this line if cross-session messaging misbehaves.
  export CLAUDE_CODE_HARBOR_KITE=1

  # All launchers skip permission prompts by default. This is consistent with
  # skipDangerousModePermissionPrompt already set in ~/.claude/settings.json.
  # Use `command claude` (or the `clsafe` alias below) if you want prompts.
  alias cl='claude --dangerously-skip-permissions'              # short launcher
  alias clc='claude --dangerously-skip-permissions --continue'  # continue most recent session in cwd
  alias clr='claude --dangerously-skip-permissions --resume'    # pick a session to resume
  alias clp='claude --dangerously-skip-permissions -p'          # headless/print mode (good for pipes)
  alias clupdate='claude update'                                # update the CLI

  # Explicit aliases for when you DO want permission prompts.
  alias clsafe='claude'
  alias yolo='claude --dangerously-skip-permissions'

  # Named session. Peers are addressed by name via SendMessage, and a session left
  # unnamed gets a useless derived one ("development-ba"), so name anything you might
  # want to talk to from another session. Optional second arg is a directory to run in;
  # the subshell keeps your own cwd intact after Claude exits.
  #   clw appshell ~/Development/unified-platform/.claude/worktrees/PLATSERV-10211
  function clw() {
    local name="$1"
    if [ -z "$name" ]; then
      echo "usage: clw <session-name> [directory] [claude args...]"
      return 1
    fi
    shift

    local dir=""
    if [ -n "$1" ] && [ -d "$1" ]; then
      dir="$1"
      shift
    fi

    ( [ -n "$dir" ] && cd "$dir"; claude --dangerously-skip-permissions --name "$name" "$@" )
  }

  # Create (or reuse) a git worktree for an existing branch and open a named session in
  # it. Two sessions sharing one working tree fight over HEAD — one `git checkout` swaps
  # every file out from under the other. Worktrees are the fix; see the vault's
  # "Parallel Claude Sessions" runbook.
  #
  # Each worktree needs its own `npm install` in a monorepo whose branches bump
  # dependencies. That is not done here, deliberately — it is slow and repo-specific.
  #   clwt PLATSERV-10211-appshell-boot-stall-and-platform-redirect appshell
  function clwt() {
    local branch="$1" name="$2"
    if [ -z "$branch" ]; then
      echo "usage: clwt <existing-branch> [session-name]"
      return 1
    fi
    : "${name:=$branch}"

    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
      echo "Not a git repository"
      return 1
    }

    if ! git -C "$root" show-ref --verify --quiet "refs/heads/$branch"; then
      echo "No local branch '$branch'. Create it first, or check it out from origin."
      return 1
    fi

    local path="$root/.claude/worktrees/${branch}"
    if [ ! -d "$path" ]; then
      git -C "$root" worktree prune
      git -C "$root" worktree add "$path" "$branch" || return 1
      echo "Worktree created. Run your install in it before serving:  (cd $path && npm install)"
    fi

    clw "$name" "$path"
  }

  # Draft a commit message from the staged diff using headless Claude, then let
  # you edit it before committing. Complements gcommit/shuv in functions.sh.
  function clcommit() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
      echo "Not a git repository"
      return 1
    fi

    local diff
    diff="$(git diff --staged)"
    if [ -z "$diff" ]; then
      echo "No staged changes. Stage files with 'git add' first."
      return 1
    fi

    echo "Drafting commit message with Claude..."
    local msg
    msg="$(printf '%s' "$diff" | claude -p 'Write a concise git commit message for this staged diff. Use a short imperative summary line (max ~72 chars), then a blank line and a brief body only if it adds value. Output only the commit message, no code fences or commentary.')"

    if [ -z "$msg" ]; then
      echo "Claude returned no message"
      return 1
    fi

    git commit -m "$msg" -e
  }

fi
