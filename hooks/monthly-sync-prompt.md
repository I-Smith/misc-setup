You are running as an autonomous monthly drift-check agent for Isaac's dotfiles repo.
Today's date: $DATE
Repo path: $REPO
Branch: techstar-mac (open PRs to: main)
Notification email: isaacns98@gmail.com

## Your job

Detect drift between what's currently installed on this machine and what's tracked
in the repo's install scripts, then commit any updates and open a PR.

## Steps

### 1. Homebrew formulae
Run: brew leaves
Compare to formulae listed in $REPO/install/Brewfile (lines matching ^brew ")
For each new formula not in Brewfile:
  - Add it to the appropriate section of the Brewfile with a short inline comment
    describing what the tool does (e.g. brew "ripgrep"  # fast grep replacement)
  - Find its apt equivalent (if any) and add it to the matching section of
    $REPO/install/linux.sh. If there is no apt equivalent or it needs a custom
    repo setup, add a comment in linux.sh noting that.

### 2. Homebrew casks
Run: brew list --cask
Compare to casks listed in Brewfile (lines matching ^cask ")
For each new cask not in Brewfile:
  - Add it to the Desktop Apps section with a short comment
  - Add it to the manual-install reminder list at the bottom of linux.sh

### 3. npm globals
Run: npm list -g --depth=0
Compare to packages installed in $REPO/install/common.sh (npm_global_install calls)
For each new package not already handled there, add an npm_global_install call with a comment.

### 4. Untracked dotfiles
Run: ls -a ~ | grep -E "^\."
Ignore these: .DS_Store .Trash .CFUserTextEncoding .bash_history .zsh_history .lesshst
              .viminfo .ssh .gitconfig .gitconfig_local .Spotlight-V100 .TemporaryItems
              .cache .config .local .npm .nvm .oh-my-zsh .rbenv .rustup .pyenv .asdf
Check whether any remaining untracked dotfiles look like they belong in the repo
(editor configs, tool configs, shell extras). List them in the PR description with
your reasoning — do NOT auto-add them to the repo.

### 5. Commit and PR
Only modify these files: install/Brewfile, install/linux.sh, install/common.sh
Do not touch: setup.sh, hooks/, dotfiles (.zshrc etc), CLAUDE.md, cursor/, claude/

If nothing changed across all checks, print "monthly-sync $DATE: no drift detected"
and exit without committing.

If there are changes:
  - Stage: git -C $REPO add install/Brewfile install/linux.sh install/common.sh
  - Commit: git -C $REPO commit -m "chore: monthly sync $DATE"
  - Push: git -C $REPO push origin techstar-mac
  - PR: gh pr create --base main --head techstar-mac
        --title "chore: monthly sync $DATE"
        --body with a summary of new formulae, new casks, new npm packages,
               and the untracked dotfiles list with your reasoning.
  - Capture the PR URL from the gh output.

### 6. Notifications

Run terminal-notifier if available:
  terminal-notifier -title "dotfiles: monthly sync" -message "PR: <PR URL>" -open "<PR URL>"

Send email via Python smtplib:
  - GMAIL_APP_PASSWORD is loaded from macOS Keychain by the calling script before invoking you
  - If not set in the environment, print a warning and skip email
  - From/To: isaacns98@gmail.com
  - Subject: dotfiles: monthly sync $DATE
  - Body: PR URL + bullet list of everything added
  - SMTP: smtp.gmail.com port 465 (SSL)
