#!/usr/bin/env bash
# Common setup for both macOS and Linux.
# Sourced by install.sh after the OS-specific script.
set -euo pipefail

echo ""
echo "==> Oh-my-zsh plugins"

OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS_DIR="$OMZ_CUSTOM/plugins"

if [ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$PLUGINS_DIR/zsh-autosuggestions"
  echo "  installed zsh-autosuggestions"
else
  echo "  already installed: zsh-autosuggestions"
fi

if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$PLUGINS_DIR/zsh-syntax-highlighting"
  echo "  installed zsh-syntax-highlighting"
else
  echo "  already installed: zsh-syntax-highlighting"
fi

echo ""
echo "==> Node (via nvm)"

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
elif [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  \. "/opt/homebrew/opt/nvm/nvm.sh"
else
  echo "  nvm not found — install it first (macos.sh or linux.sh should have done this)"
  exit 1
fi

nvm install --lts
nvm alias default lts/*
echo "  node $(node --version) set as default"

echo ""
echo "==> Global npm packages"

npm_global_install() {
  local pkg="$1"
  if npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
    echo "  already installed: $pkg"
  else
    npm install -g "$pkg"
    echo "  installed $pkg"
  fi
}

npm_global_install "eas-cli"   # Expo Application Services CLI
