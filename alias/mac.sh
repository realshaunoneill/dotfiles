# rosetta terminal setup
if [ $(arch) = "i386" ]; then
    alias brew86="/usr/local/bin/brew"
    alias pyenv86="arch -x86_64 pyenv"

    export PATH="/usr/local/bin:$PATH"
    alias python="python3"
fi

# Check if we're on arm or intel and set the correct ngrok version
if [ $(arch) = "arm64" ]; then
    alias ngrok="$ZDOTDIR/bin/ngrok-arm"

    alias ngrok-h='$ZDOTDIR/bin/ngrok-arm http'
    alias ngrok-sh='$ZDOTDIR/bin/ngrok-arm http -auth "admin:admin"'
    alias ngrok-tcp='$ZDOTDIR/bin/ngrok-arm tcp'
fi