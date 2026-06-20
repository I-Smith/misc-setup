#!/usr/bin/env bash
# macOS-specific installs. Sourced by install.sh.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "  installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "  already installed: Homebrew $(brew --version | head -1)"
fi

echo ""
echo "==> Homebrew packages (brew bundle)"
brew bundle --file="$REPO/install/Brewfile"

echo ""
echo "==> Oh-my-zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "  installing oh-my-zsh..."
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "  already installed: oh-my-zsh"
fi

echo ""
echo "==> Ruby gems"
if ! gem list --local | grep -q "^cocoapods "; then
  gem install cocoapods   # iOS dependency manager
  echo "  installed cocoapods"
else
  echo "  already installed: cocoapods"
fi
