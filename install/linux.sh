#!/usr/bin/env bash
# Linux (Debian/Ubuntu) installs. Sourced by install.sh.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Error: only Debian/Ubuntu (apt) is supported by linux.sh" >&2
  exit 1
fi

echo "==> System update"
sudo apt-get update -qq

echo ""
echo "==> Build tools"
sudo apt-get install -y \
  build-essential \   # gcc, make, etc.
  curl \              # HTTP client
  wget \              # file downloader
  unzip \             # archive extraction
  git                 # version control

echo ""
echo "==> CLI Utilities"
sudo apt-get install -y \
  jq \                        # JSON processor
  fzf \                       # fuzzy finder
  grep \                      # text search
  coreutils \                 # GNU core utils
  zsh-syntax-highlighting     # fish-style syntax highlighting for zsh (brew: zsh-syntax-highlighting)

echo ""
echo "==> Languages & Runtimes"
sudo apt-get install -y \
  python3 \              # Python 3
  python3-pip \          # pip
  python3-tk \           # Tkinter GUI bindings (brew: python-tk@3.12)
  ruby-full \            # Ruby
  golang \               # Go language
  rustup                 # Rust toolchain installer

# Initialize rustup if just installed
command -v rustup >/dev/null 2>&1 && rustup default stable

echo ""
echo "==> Databases"
sudo apt-get install -y \
  postgresql \        # PostgreSQL server
  postgresql-client  # psql client

echo ""
echo "==> GitHub CLI (gh)"
if ! command -v gh >/dev/null 2>&1; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y gh
else
  echo "  already installed: gh $(gh --version | head -1)"
fi

echo ""
echo "==> kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
    | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y kubectl
else
  echo "  already installed: kubectl $(kubectl version --client --short 2>/dev/null || true)"
fi

echo ""
echo "==> Helm"
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://baltocdn.com/helm/signing.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" \
    | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y helm
else
  echo "  already installed: helm $(helm version --short)"
fi

echo ""
echo "==> Terraform"
if ! command -v terraform >/dev/null 2>&1; then
  wget -O- https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y terraform
else
  echo "  already installed: terraform $(terraform version | head -1)"
fi

echo ""
echo "==> AWS CLI"
if ! command -v aws >/dev/null 2>&1; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
else
  echo "  already installed: aws $(aws --version)"
fi

echo ""
echo "==> eksctl"
if ! command -v eksctl >/dev/null 2>&1; then
  ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
  curl -fsSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_${ARCH}.tar.gz" \
    | tar -xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin/
else
  echo "  already installed: eksctl $(eksctl version)"
fi

echo ""
echo "==> Oh-my-zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "  already installed: oh-my-zsh"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║  Manual installs required — no Linux package available              ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║  Android Studio   https://developer.android.com/studio              ║"
echo "║  Bitwarden        https://bitwarden.com/download/                   ║"
echo "║  Bruno            https://www.usebruno.com/downloads                ║"
echo "║  Docker Desktop   https://docs.docker.com/desktop/linux/            ║"
echo "║  Google Chrome    https://www.google.com/chrome/                    ║"
echo "║  Obsidian         https://obsidian.md/download                      ║"
echo "║  pgAdmin 4        https://www.pgadmin.org/download/                 ║"
echo "║  Postman          https://www.postman.com/downloads/                ║"
echo "║  Slack            https://slack.com/downloads/linux                 ║"
echo "║  Spotify          https://www.spotify.com/download/linux/           ║"
echo "║  VS Code          https://code.visualstudio.com/download            ║"
echo "║  Zoom             https://zoom.us/download                          ║"
echo "║                                                                      ║"
echo "║  Zulu JDK 17      https://www.azul.com/downloads/?version=java-17   ║"
echo "║  AWS Vault        https://github.com/99designs/aws-vault/releases   ║"
echo "║                                                                      ║"
echo "║  Note: Raycast and Rectangle are macOS-only.                        ║"
echo "║  Note: VLC is available via apt: sudo apt install vlc               ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
