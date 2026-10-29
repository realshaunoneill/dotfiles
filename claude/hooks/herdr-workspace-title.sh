#!/bin/bash
# UserPromptSubmit + Stop hook: name a herdr workspace after the Claude session in it,
# so a new workspace never has to be named by hand.
#
# herdr labels an unnamed workspace with its folder's name ("Development", "Personal"),
# and its API doesn't say whether a label was chosen. So the workspace is renamed only
# while its label still equals that folder name. One you named is never touched, and
# after the first rename this is a no-op. The new name is the pane's terminal title as
# herdr reads it: the --name from clw from the start, or, for an unnamed session,
# Claude's own generated title after its first reply. Until then the title is just
# "Claude Code", which is skipped. Measured 2026-10-28.
#
# Prints nothing: on UserPromptSubmit, anything on stdout is added to the prompt.

[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ] && [ -n "${HERDR_WORKSPACE_ID:-}" ] || exit 0
input=$(cat)
herdr="${HERDR_BIN_PATH:-$HOME/.local/bin/herdr}"

pane=$("$herdr" pane get "$HERDR_PANE_ID" 2>/dev/null) || exit 0
title=$(/usr/bin/jq -r '.result.pane.terminal_title_stripped // empty' <<<"$pane")
case "$title" in '' | 'Claude Code') exit 0 ;; esac

label=$("$herdr" workspace get "$HERDR_WORKSPACE_ID" 2>/dev/null | /usr/bin/jq -r '.result.workspace.label // empty')
[ -n "$label" ] || exit 0

# The folder herdr names the workspace after: the pane's cwd, or where claude started.
pane_cwd=$(/usr/bin/jq -r '.result.pane.cwd // empty' <<<"$pane")
claude_cwd=$(/usr/bin/jq -r '.cwd // empty' <<<"$input")
[ "$label" = "${pane_cwd##*/}" ] || [ "$label" = "${claude_cwd##*/}" ] || exit 0

"$herdr" workspace rename "$HERDR_WORKSPACE_ID" "$title" >/dev/null 2>&1
exit 0
