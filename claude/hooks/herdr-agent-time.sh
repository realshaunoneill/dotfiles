#!/bin/bash
# Stop + Notification hook: add the time to the state word on this session's row in the herdr
# sidebar, so it reads "done 14:32", "idle 14:32" or "blocked 14:35". herdr shows a state's
# label only while the agent is in that state, so nothing needs clearing when it works again.
#
# Each event reports under its own source because a report replaces every label its source
# set before; separate sources are merged (both measured 2026-10-30). The pane id goes first:
# with --source first, herdr 0.9.5 rejects the source's value as an unknown option. No
# --agent / --applies-to-source guard: with one, herdr dropped the labels.
#
# Prints nothing: hook output can end up in Claude's context.

[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ] || exit 0
herdr="${HERDR_BIN_PATH:-$HOME/.local/bin/herdr}"
now=$(date +%H:%M)

case "$(/usr/bin/jq -r '.hook_event_name // empty' 2>/dev/null)" in
  Stop)
    "$herdr" pane report-metadata "$HERDR_PANE_ID" --source claude-time.stop \
      --state-label "done=done $now" --state-label "idle=idle $now" >/dev/null 2>&1
    ;;
  Notification)
    "$herdr" pane report-metadata "$HERDR_PANE_ID" --source claude-time.blocked \
      --state-label "blocked=blocked $now" >/dev/null 2>&1
    ;;
esac
exit 0
