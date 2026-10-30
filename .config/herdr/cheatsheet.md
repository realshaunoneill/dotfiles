# Keys beyond herdr's own

herdr's bindings, ours included, are in its help panel: `ctrl+space` then `?`.
This sheet (`ctrl+space` then `i`) adds the keys herdr can't list. `q` closes it.

## herdr, without the prefix

    ctrl+alt+↑ / ↓        previous / next agent (also ctrl+alt+p / n)
    ctrl+alt+shift+↑ / ↓  previous / next workspace, including ones with no agent
    ctrl+alt+1 … 9        jump to a workspace
    ctrl+alt+h j k l      move between panes
    ctrl+alt+d            split right
    ctrl+alt+z            zoom the pane

## Code, for the focused pane's project

The pane's own repo, or the repo its Claude session last worked in.

    ctrl+alt+e   the project in VS Code
    ctrl+alt+o   the file Claude last edited, at that line, in VS Code
    ctrl+alt+f   find a file: enter opens it in VS Code, ctrl-e in Neovim, esc closes
    ctrl+alt+r   review the changes in lazygit
    ctrl+alt+v   the project in Neovim; ctrl+space z shows the agent beside it
    ctrl+alt+g   the pull request in the browser

## Shell

    ctrl-r       search history (fzf)
    ctrl-t       insert a file path (fzf)
    **<tab>      complete a path with fzf, e.g. vim **<tab>
    z <part>     jump to a directory you've visited (zoxide); zi picks one
    git diff     colour diffs through delta; n / N jump between files
    DELTA_FEATURES=+side-by-side git diff    the same in two columns

## Neovim (LazyVim)

Space is the leader key. Press it and wait to see every key under it.

    space e        file tree
    space space    find a file
    space /        search text
    space g g      lazygit
    space g s      git status, with each file's diff
    space g d      every change in the repo
    space g D      the branch compared with origin
    ] h  /  [ h    next / previous change in this file
    space g h p    preview the change under the cursor
    space g h d    diff this file side by side
    :q             quit

## lazygit (ctrl+alt+r, or space g g in Neovim)

    ← → or h l     switch panel; 1 … 5 jumps to one
    ↑ ↓ or j k     move
    space          stage / unstage the file
    c              commit
    P / p          push / pull
    ?              every key in this panel
    q              quit

## iTerm

    ⌘⌥↑ / ↓        previous / next agent, once its two key bindings are added
                   (Keys → Key Bindings: Send Escape Sequence [1;7A and [1;7B)
