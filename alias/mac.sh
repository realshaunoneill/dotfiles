# rosetta terminal setup
if [ "$(arch)" = "i386" ]; then
    alias brew86="/usr/local/bin/brew"
    alias pyenv86="arch -x86_64 pyenv"

    export PATH="/usr/local/bin:$PATH"
    alias python="python3"
fi