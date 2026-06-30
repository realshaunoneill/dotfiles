# 📖  Introduction
This repository **DotFiles** contain my personal config files. Here you'll find configs, customizations, themes, and whatever I need to personalize my Linux and MacOS experience. It takes the effort out of installing everything manually. Everything needed to install my preferred terminal setup is detailed in this readme. Feel free to explore, learn and copy parts for your own dotfiles. Enjoy!
The base of this repository uses Zsh as the base shell along with [Oh My Zsh](https://ohmyz.sh/) as the framework. I also use [Powerlevel10k](https://github.com/romkatv/powerlevel10k) as my theme. I have also included a few plugins that I use on a daily basis. You can find a list of all the plugins that I use below.

> :warning: Be aware, this product can change over time. I will do my best to keep this document up to date with the latest changes, but please understand that this won’t always be the case. 


# Installation 
Below are the two installation methods. The first is an automatic installation script that will install everything for you. The second is a manual installation method that will allow you to pick and choose what you want to install.
### Automatic Installation
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/realshaunoneill/dotfiles/master/install.sh)"
```

### Manual Installation
If you prefer to install everything manually, you can do so by following the steps below.
- Clone this repository to your home directory.
```sh
git clone https://github.com/realshaunoneill/dotfiles.git $HOME/.zsh
```
- Export the required environment variables that are needed for the initial installation.
```sh
echo "export ZDOTDIR=\$HOME/.zsh" >$HOME/.zshenv
echo "source \$ZDOTDIR/.zshenv" >>$HOME/.zshenv
```
- The final step is to change your default shell to zsh.
```sh
chsh -s $(which zsh)
zsh
```
And thats it! You should now have a fully functional zsh shell. You can read below to learn more about the features and customizations that are included in this repository.

# Plugins
The following Oh My Zsh plugins are enabled by default:
- `git` – aliases and prompt info for git
- `wd` – warp directory, jump to bookmarked directories
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)

# Customization
There are a few customizations that I have made to my shell.
- [Eza](https://eza.rocks/) is used as a richer `ls` when it's installed. On first launch you'll be prompted to install/set it up (via `zSetupEza`); it's optional, and the standard `ls` is used otherwise.

# Functions
A number of helper functions are defined in `alias/functions.sh`. Some of the handy ones:
- `extract <archive>` – extract almost any archive type
- `mkcd <dir>` – make a directory and cd into it
- `ff <name>` / `fdir <name>` – find files / directories by name
- `killport <port>` – kill whatever process is listening on a port
- `serve [port]` – quick static HTTP server in the current directory
- `myip` – show public and local IP
- `weather [location]` – terminal weather via wttr.in
- `jsonpp [file]` – pretty-print JSON
- `gbrecent` – list branches by most recent commit
- `gclean` – delete local branches already merged into master/main
- `clone` / `clonep` – clone a repo via SSH (the `p` variant uses the personal GitHub SSH host)

# Claude Code helpers
Helpers for Anthropic's [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI live in `alias/claude.sh`. They're only active when the `claude` binary is installed.
- `cl` – launch Claude Code
- `clc` – continue the most recent session in the current directory
- `clr` – resume a session (picker)
- `clp` – headless/print mode (`claude -p`), useful in pipes
- `yolo` – `claude --dangerously-skip-permissions`
- `clupdate` – update the CLI
- `clcommit` – draft a commit message from the staged diff with Claude, then open it in your editor

Portable slash commands (`/commit`, `/pr`, `/explain`) and a `pr-reviewer` subagent are tracked under `claude/`. Symlink them into `~/.claude` with:
```sh
claude-setup    # alias for zSetupClaude
```
This backs up any existing `~/.claude/commands` or `~/.claude/agents` before linking. Machine-specific Claude config (e.g. `~/.claude/settings.json`) is intentionally **not** tracked here.

# Profiling startup
To see where shell startup time is spent:
```sh
ZSH_PROFILE=1 zsh -ic exit
```
This loads `zsh/zprof` and prints a breakdown when the shell finishes initializing.


# Contributions
If you’d like to contribute to this project, reach out to me on social media or [Discord](https://discord.gg/bz2SN7d), or create a pull request for the necessary changes.
