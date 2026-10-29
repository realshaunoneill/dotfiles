# Brewfile - install with: brew bundle --file=Brewfile
# The CLI tools these dotfiles assume or benefit from, on any Mac. Brewfile.work has the
# rest of the Rapid7 laptop.
#
# Not here, because they arrive another way: zsh, git, vim and jq ship with macOS;
# powerlevel10k is cloned into custom/ by .zshrc; nvm uses its own installer (~/.nvm, see
# appConfigs/nvm.zsh); herdr installs itself into ~/.local/bin. neofetch was dropped
# (2026-10-29) because Homebrew no longer has it, which made `brew bundle` fail.

# Shell
brew "eza"          # modern ls replacement (see common.sh)
brew "fzf"          # ctrl-r history and ctrl-t file search (.zshrc)
brew "zoxide"       # `z` jumps to frecent directories (.zshrc)

# Git
brew "gh"           # GitHub CLI; also git's credential helper for github.com
brew "git-delta"    # pager for git diff/log/show (git/config)
brew "gnupg"        # commit signing

# Neovim with LazyVim (.config/nvim), and the herdr editor keys (bin/herdr-*)
brew "neovim"
brew "lazygit"          # LazyVim's git screen
brew "tree-sitter-cli"  # builds the syntax parsers LazyVim installs
brew "bat"              # previews in the herdr-find-file popup
cask "font-sauce-code-pro-nerd-font"  # Source Code Pro with the icons LazyVim draws

# Quality-of-life CLI tools used by functions/aliases
brew "ripgrep"      # fast grep (rg); LazyVim's search
brew "fd"           # fast find (note: shell fn is `fdir` to avoid shadowing); LazyVim's file finder
brew "tmux"         # tn/ta/tl/tk aliases, homeConfigs/tmux
brew "wget"

# Checks the dotfiles CI runs (.github/workflows/checks.yml), for running them locally
brew "shellcheck"
brew "gitleaks"

cask "1password-cli"       # op, and the SSH agent ssh/config.d/90-1password.conf uses
cask "claude-code@latest"  # alias/claude.sh
