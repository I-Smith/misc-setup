eval "$(/opt/homebrew/bin/brew shellenv)"
export USRBIN=/usr/local/bin
export GNUBIN=/opt/homebrew/opt/make/libexec/gnubin
export LIBPQBIN=/opt/homebrew/opt/libpq/bin
export PATH="$PATH:$USRBIN:$GNUBIN:$(go env GOPATH)/bin:$LIBPQBIN"


# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
