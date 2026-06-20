# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles, editor config, and machine setup for macOS (and Linux), managed as symlinks so edits anywhere auto-sync back to the repo. No build system or test suite.

## New Machine Setup

```zsh
git clone <repo> ~/projects/personal/misc-setup
cd ~/projects/personal/misc-setup
./install.sh   # install all software (Homebrew, languages, CLI tools, apps)
./setup.sh     # create symlinks for dotfiles, Cursor, and Claude Code
```

`install.sh` is idempotent and safe to re-run. `setup.sh` backs up any existing real files as `.bak` before creating symlinks.

## Install System

`install.sh` detects OS and delegates:
- **macOS** → `install/macos.sh`: installs Homebrew, runs `brew bundle --file=install/Brewfile`, oh-my-zsh, cocoapods
- **Linux** → `install/linux.sh`: apt packages + per-tool repos (gh, kubectl, helm, terraform, awscli, eksctl), oh-my-zsh; prints GUI app reminder at the end
- **Both** → `install/common.sh`: oh-my-zsh custom plugins, nvm + LTS Node, global npm packages

`install/Brewfile` is the source of truth for all Homebrew packages on macOS. To add a new tool: add it to the Brewfile (and to `linux.sh` if it should also be on Linux), then commit.

A monthly cron job (`3 9 1 * *`, installed by `setup.sh`) runs `hooks/monthly-sync.sh`, which diffs `brew leaves`/`brew list --cask` against the Brewfile, appends new packages, commits, pushes, and opens a PR from `techstar-mac` → `main`. Notifies via macOS `terminal-notifier` banner (with PR URL) and GitHub's built-in PR email notification. Log: `~/.monthly-sync.log`.

## What's Tracked

### Shell dotfiles → `~/`
| Repo file | Symlinked to |
|-----------|-------------|
| `.zshrc` | `~/.zshrc` |
| `.zshenv` | `~/.zshenv` |
| `.zprofile` | `~/.zprofile` |
| `.functions` | `~/.functions` |
| `.vimrc` | `~/.vimrc` |

### Cursor → `cursor/`
| Repo file | Symlinked to |
|-----------|-------------|
| `cursor/mcp.json` | `~/.cursor/mcp.json` |
| `cursor/user/settings.json` | `~/Library/Application Support/Cursor/User/settings.json` |
| `cursor/user/keybindings.json` | `~/Library/Application Support/Cursor/User/keybindings.json` |

Not tracked: `extensions/` (platform binaries), `plans/`, `projects/`, `argv.json` (machine-specific crash reporter ID).

### Claude Code → `claude/`
| Repo file | Symlinked to |
|-----------|-------------|
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/commands/` | `~/.claude/commands/` |

Not tracked: `settings.local.json` (machine-specific permissions), `history.jsonl`, `projects/`, `skills/` (reinstalled by plugin system), all cache/session/telemetry directories.

## File Roles

- `.zshrc` — oh-my-zsh setup, plugins, and aliases. Sources `.zshenv`, `.zprofile`, and `.functions` explicitly at the end.
- `.zprofile` — PATH construction (Homebrew, Go, libpq, GNU make) and nvm initialization.
- `.zshenv` — exported environment variables: `JAVA_HOME`, `AWS_MFA_ARN`, `AWS_PROFILE`, `GOPRIVATE`.
- `.functions` — shell functions: `installJdk` (AdoptOpenJDK via API), `mfa` (AWS STS MFA session), `assumeK8sDev` (assume IAM role), `awslogin` (AWS SSO).
- `.vimrc` — vim settings with spell-check enabled for `.md` files.
- `.zshrc.pre-oh-my-zsh` — legacy backup, not actively sourced.

## Applying Changes

```zsh
source ~/.zshrc          # reload everything
source ~/.functions      # reload only functions
```

Cursor and Claude Code pick up config changes automatically (Cursor may need a restart).

## Architecture Notes

`.zshrc` is the entry point and manually sources `.zshenv`, `.zprofile`, and `.functions` — this is intentional and non-standard (normally `.zshenv` and `.zprofile` are sourced automatically by zsh at login). Edits to PATH or env vars belong in `.zprofile` or `.zshenv` respectively, not in `.zshrc`.

AWS credential helpers in `.functions` (`mfa`, `assumeK8sDev`) rely on `AWS_MFA_ARN` being set in `.zshenv` and on `aws` + `jq` being present on `PATH`.