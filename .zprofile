eval "$(/opt/homebrew/bin/brew shellenv)"

export USRBIN=/usr/local/bin
export GNUBIN=/opt/homebrew/opt/make/libexec/gnubin
export LIBPQBIN=/opt/homebrew/opt/libpq/bin
export GREPPATH=/opt/homebrew/opt/grep/libexec/gnubin

export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export GOBIN=$GOPATH/bin

export ANDROID_HOME=$HOME/Library/Android/sdk

export PATH="$PATH:$USRBIN:$GNUBIN:$GOBIN:$GOROOT/bin:$LIBPQBIN:$GREPPATH"
[ -d "$ANDROID_HOME" ] && PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools"
[ -d "$HOME/.fastlane/bin" ] && PATH="$PATH:$HOME/.fastlane/bin"
export PATH

alias grep="ggrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}"

# nvm — support both NVM_DIR install and Homebrew install
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi
