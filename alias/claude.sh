# ------------------------------- #
#         Claude Code             #
# ------------------------------- #
# Helpers for Anthropic's Claude Code CLI. The whole file is a no-op on
# machines where the `claude` binary isn't installed.

if command -v claude &>/dev/null; then

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
