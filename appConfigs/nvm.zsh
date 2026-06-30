# NVM lazy load - sourced on first `nvm` call by the wrapper in .zshrc
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Source nvm itself from the standard location, falling back to Homebrew's.
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
elif command -v brew &>/dev/null && [ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh"
fi

# Load completion if available
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
