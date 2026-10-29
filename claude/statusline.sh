#!/bin/bash
# Claude Code status line: statusLine in ~/.claude/settings.json runs this, and zSetupClaude
# links it to ~/.claude/statusline.sh. One row, each part only when Claude Code reports it:
#   Opus 5.5 high · ctx 42% · unified-platform ⎇ PLATSERV-10211 wt · PR #45 approved · cache 3m · ~$4.20
# The branch comes from git on every refresh, because another session can switch the branch
# of a shared checkout; "wt" marks a linked worktree. Cost is Claude Code's estimate at list
# price. Fields: https://code.claude.com/docs/en/statusline

input=$(cat)

# This replaced Orca's status line, which prints nothing and only forwards the JSON to the
# Orca app when run from an Orca pane. Run it in the background so Orca still gets that.
orca="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [ -x "$orca" ]; then
  printf '%s' "$input" | /bin/sh "$orca" >/dev/null 2>&1 &
fi

IFS=$'\x1f' read -r model effort ctx dir worktree repo pr pr_url pr_state cache_seen cache_warm cache_expires cost < <(
  /usr/bin/jq -r '[
    .model.display_name, .effort.level, .context_window.used_percentage,
    (.workspace.current_dir // .cwd), .workspace.git_worktree, .workspace.repo.name,
    .pr.number, .pr.url, .pr.review_state,
    .prompt_cache.caching_observed, .prompt_cache.warm, .prompt_cache.expires_at,
    .cost.total_cost_usd
  ] | map(if . == null then "" else tostring end) | join("\u001f")' <<<"$input" 2>/dev/null
)

dim=$'\033[2m' red=$'\033[31m' green=$'\033[32m' yellow=$'\033[33m' reset=$'\033[0m'
parts=()

[ -n "$model" ] && parts+=("${model}${effort:+ $effort}")

if [ -n "$ctx" ]; then
  pct=${ctx%%.*}
  if [ "$pct" -ge 80 ]; then c=$red; elif [ "$pct" -ge 50 ]; then c=$yellow; else c=$green; fi
  parts+=("${c}ctx ${pct}%${reset}")
fi

if [ -n "$dir" ] && branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null ||
  git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
  [ -n "$repo" ] || repo=$(basename "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)")
  parts+=("${repo} ⎇ ${branch}${worktree:+ ${dim}wt${reset}}")
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
