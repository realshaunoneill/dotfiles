#!/bin/bash
# Claude Code status line: statusLine in ~/.claude/settings.json runs this, and zSetupClaude
# links it to ~/.claude/statusline.sh. One row, each part only when there's something to show:
#   Opus 5.5 high · ctx 42% · unified-platform ⎇ PLATSERV-10211 wt · PR #45 approved · cache 3m · ~$4.20
# The branch comes from git on every refresh, because another session can switch the branch
# of a shared checkout; "wt" marks a linked worktree. A session started outside a repo, such
# as ~/Development, shows the repo it last worked in: "Development › unified-platform ⎇ …".
# Cost is Claude Code's estimate at list price. Fields: https://code.claude.com/docs/en/statusline

input=$(cat)

# This replaced Orca's status line, which prints nothing and only forwards the JSON to the
# Orca app when run from an Orca pane. Run it in the background so Orca still gets that.
orca="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [ -x "$orca" ]; then
  printf '%s' "$input" | /bin/sh "$orca" >/dev/null 2>&1 &
fi

IFS=$'\x1f' read -r model effort ctx dir transcript pr pr_url pr_state cache_seen cache_warm cache_expires cost < <(
  /usr/bin/jq -r '[
    .model.display_name, .effort.level, .context_window.used_percentage,
    (.workspace.current_dir // .cwd), .transcript_path,
    .pr.number, .pr.url, .pr.review_state,
    .prompt_cache.caching_observed, .prompt_cache.warm, .prompt_cache.expires_at,
    .cost.total_cost_usd
  ] | map(if . == null then "" else tostring end) | join("\u001f")' <<<"$input" 2>/dev/null
)

# The newest path under $HOME in this session's recent tool calls that lies inside a git work
# tree, for a session whose own directory isn't one. Prints that work tree's top level.
last_repo() {
  [ -r "$1" ] || return 1
  local p
  tail -c 400000 "$1" | tail -n +2 |
    /usr/bin/jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")
      | .input | (.file_path // .path // .command // empty)' 2>/dev/null |
    grep -oE "(~|$HOME)/[^[:space:]\"'\`;|&()<>]+" | sed "s|^~|$HOME|" |
    tail -r | awk '!seen[$0]++' | head -n 15 |
    while IFS= read -r p; do
      while [ -n "$p" ] && [ ! -d "$p" ]; do p=${p%/*}; done
      [ -n "$p" ] && [ "$p" != "$HOME" ] && git -C "$p" rev-parse --show-toplevel 2>/dev/null && break
    done
}

# Prints "number<US>url<US>state" for the open PR of branch $2 in work tree $1, from
# `gh pr view`, which also finds merged and closed ones. That's a network call, so the answer
# is cached for five minutes and refreshed in the background; the status line never waits.
cached_pr() {
  local cache key
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
  key="$cache/$(printf '%s@%s' "$1" "$2" | shasum | cut -c1-16)"
  mkdir -p "$cache"
  if [ -z "$(find "$key" -mmin -5 2>/dev/null)" ]; then
    touch "$key"
    (
      cd "$1" && GH_PROMPT_DISABLED=1 gh pr view "$2" --json number,url,state,reviewDecision,isDraft --jq '
        select(.state == "OPEN") | [.number, .url,
         if .isDraft then "draft"
         else {APPROVED: "approved", CHANGES_REQUESTED: "changes_requested",
               REVIEW_REQUIRED: "pending"}[.reviewDecision // ""] // "" end]
        | map(tostring) | join("\u001f")' >"$key.new"
      mv -f "$key.new" "$key"
    ) >/dev/null 2>&1 &
  fi
  cat "$key" 2>/dev/null
}

dim=$'\033[2m' red=$'\033[31m' green=$'\033[32m' yellow=$'\033[33m' reset=$'\033[0m'
parts=()

[ -n "$model" ] && parts+=("${model}${effort:+ $effort}")

if [ -n "$ctx" ]; then
  pct=${ctx%%.*}
  if [ "$pct" -ge 80 ]; then c=$red; elif [ "$pct" -ge 50 ]; then c=$yellow; else c=$green; fi
  parts+=("${c}ctx ${pct}%${reset}")
fi

top="" lead="" from_transcript=""
if [ -n "$dir" ]; then
  top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$top" ]; then
    top=$(last_repo "$transcript")
    [ -n "$top" ] && lead="${dim}${dir##*/} ›${reset} " from_transcript=1
  fi
fi

if [ -n "$top" ]; then
  branch=$(git -C "$top" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null)
  if [ -n "$from_transcript" ]; then
    # Claude Code's PR fields describe its own directory, which isn't a repo; ask gh instead.
    pr="" pr_url="" pr_state=""
    case "$branch" in
      "" | main | master) ;;
      *) IFS=$'\x1f' read -r pr pr_url pr_state < <(cached_pr "$top" "$branch") ;;
    esac
  fi
  [ -n "$branch" ] || branch=$(git -C "$top" rev-parse --short HEAD 2>/dev/null)
  url=$(git -C "$top" config --get remote.origin.url)
  repo=${url##*/} repo=${repo%.git}
  [ -n "$repo" ] || repo=${top##*/}
  wt=""
  [ -f "$top/.git" ] && wt=" ${dim}wt${reset}"
  parts+=("${lead}${repo} ⎇ ${branch}${wt}")
elif [ -n "$dir" ]; then
  parts+=("${dir##*/}")
fi

if [ -n "$pr" ]; then
  case "$pr_state" in
    approved) c=$green ;;
    changes_requested) c=$red pr_state="changes requested" ;;
    pending) c=$yellow ;;
    *) c=$dim ;;
  esac
  label="PR #${pr}"
  # An OSC 8 hyperlink: cmd+click in iTerm opens the PR.
  [ -n "$pr_url" ] && label=$'\033]8;;'"${pr_url}"$'\033\\'"${label}"$'\033]8;;\033\\'
  parts+=("${label}${pr_state:+ ${c}${pr_state}${reset}}")
fi

# Minutes until the cached prompt prefix expires: replying before then is cheaper. Shown
# only when the provider reports cache tokens at all.
if [ "$cache_seen" = true ]; then
  left=0
  if [ "$cache_warm" = true ] && [ -n "$cache_expires" ]; then
    left=$(( (${cache_expires%%.*} - $(date +%s) + 59) / 60 ))
  fi
  if [ "$left" -gt 0 ]; then parts+=("${green}cache ${left}m${reset}"); else parts+=("${dim}cache cold${reset}"); fi
fi

[ -n "$cost" ] && parts+=("${dim}~\$$(printf '%.2f' "$cost")${reset}")

out=""
for p in "${parts[@]}"; do out+="${out:+${dim} · ${reset}}$p"; done
printf '%s\n' "$out"
