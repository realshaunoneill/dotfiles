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

  # Run a session on one of the GPT models the llmproxy also serves.
  #
  # Those models are only reachable on the proxy's Anthropic-format endpoint
  # (/v1/messages, where LiteLLM translates Messages <-> Responses), not on the
  # /bedrock passthrough that ~/.claude/settings.json configures. So the session has to
  # leave Bedrock mode entirely.
  #
  # That switch has to happen in a settings file, NOT the shell environment: the `env`
  # block in ~/.claude/settings.json is applied by the binary at startup and overwrites
  # the ambient environment, so unsetting CLAUDE_CODE_USE_BEDROCK with `env -u` is
  # silently undone and you get a Bedrock 403 for an openai.* model instead. A file
  # passed with --settings is the highest-precedence layer, so it wins the merge.
  # Deliberately not a change to settings.json itself — that file is shared by every
  # session on this machine and flipping it would hijack all of them.
  #
  # The apiKeyHelper in settings.json still supplies the token; outside Bedrock mode the
  # binary uses it as the Anthropic auth token, so there is nothing extra to configure
  # and no secret is written to the profile file.
  #
  # Model names come from `clmodels` below; the proxy is a strict allowlist, so anything
  # not listed fails with "Invalid model name". Haiku stays on the Anthropic side for the
  # small/fast background calls.
  #
  # None of these ids are in the binary's model catalog, so it assumes a 200k window and
  # auto-compacts on that. The window is looked up on the proxy and, for the 1M+ models,
  # the [1m] suffix is appended — that is the only lever this build honours.
  # CLAUDE_CODE_MAX_CONTEXT_TOKENS was tried and is ignored (identical warning with and
  # without it), so it is not set here. The 272k models are left to assume 200k, which is
  # merely conservative. An "unrecognized_model" telemetry line on startup is expected;
  # a modelOverrides/behavesAs row in settings.json would be the tidier long-term fix.
  #
  # The /model picker gets its own list here. settings.json carries a modelPicker of
  # the Bedrock-format Claude ids with replaceBuiltInOptions on (the built-in lineup
  # offers Fable, which the proxy refuses), and that also hides the gateway-discovered
  # rows — so without this a clgpt session could not switch between GPT models. A
  # modelPicker passed with --settings replaces the user one outright, no merging.
  # The rows are every claude-* id the proxy publishes, which covers the Claude models
  # and the claude-code-gpt-* aliases. Plain gpt-* ids are left out on purpose: two of
  # them (gpt-5.6-cyber, gpt-daybreak-blue-5.6-sol) are listed but 403 "User is not
  # allowed to access this model" for this key (2026-10-06), and the rest duplicate an alias.
  #   clgpt                       # default, claude-code-gpt-6-sol
  #   clgpt claude-code-gpt-5.5   # pick another
  function clgpt() {
    local model="${1:-claude-code-gpt-6-sol}"
    [ $# -gt 0 ] && shift

    local tok
    tok="$(r7aac token --client-id llmproxy 2>/dev/null)" || {
      echo "Could not get an llmproxy token via r7aac"
      return 1
    }

    local models
    models="$(curl -sS -m 30 https://llmproxy.acm.r7ops.com/v1/models \
                -H "Authorization: Bearer $tok")" || {
      echo "Could not list the llmproxy models"
      return 1
    }

    local ctx
    ctx="$(printf '%s' "$models" | MODEL="$model" python3 -c 'import json,os,sys
want = os.environ["MODEL"]
for m in json.load(sys.stdin)["data"]:
    if m["id"] == want:
        print(m.get("max_input_tokens") or "")
        break')"
    if [ -z "$ctx" ]; then
      echo "Model '$model' is not on the llmproxy allowlist. Run clmodels to see what is."
      return 1
    fi

    local name="$model"
    [ "$ctx" -ge 1000000 ] && name="${model}[1m]"

    local picker
    picker="$(printf '%s' "$models" | python3 -c 'import json,sys
rows = []
for m in json.load(sys.stdin)["data"]:
    i = m["id"]
    if not i.startswith("claude-") or not m.get("max_output_tokens"):
        continue
    row = {"model": i + ("[1m]" if (m.get("max_input_tokens") or 0) >= 1000000 else "")}
    if i.startswith("claude-code-"):
        row["label"] = i
    rows.append(row)
print(json.dumps({"replaceBuiltInOptions": True, "options": rows}))')"

    # --settings takes a JSON string as well as a path, so there is no temp file
    # to write or clean up (the ~/.claude/CLAUDE.md rule against rm through a variable).
    local profile
    profile="$(cat <<EOF
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "",
    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "",
    "ANTHROPIC_BASE_URL": "https://llmproxy.acm.r7ops.com",
    "ANTHROPIC_MODEL": "$name",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-haiku-5-5"
  },
  "modelPicker": $picker
}
EOF
)"

    echo "$name via llmproxy (model reports a ${ctx} token window)"
    claude --dangerously-skip-permissions --settings "$profile" "$@"
  }

  # List what the llmproxy will actually serve your key, newest tokens first.
  # Useful before reaching for clgpt, and for confirming a model was added after a
  # PD ticket — the allowlist is proxy-side, nothing local controls it.
  function clmodels() {
    local tok
    tok="$(r7aac token --client-id llmproxy 2>/dev/null)" || {
      echo "Could not get an llmproxy token via r7aac"
      return 1
    }
    curl -sS -m 30 https://llmproxy.acm.r7ops.com/v1/models \
      -H "Authorization: Bearer $tok" \
      | python3 -c 'import json,sys; [print(m["id"]) for m in json.load(sys.stdin)["data"]]' \
      | sort
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
