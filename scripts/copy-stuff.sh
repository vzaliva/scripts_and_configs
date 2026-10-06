#!/bin/sh

# Script to set up new machine
# Usage: copy-stuff.sh [user@]host

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 [user@]host" >&2
    exit 1
fi

R=$1

# Copy SSH keys
ssh-copy-id -i ~/.ssh/id_ed25519.pub "$R"

# Default dirs (-p so re-runs don't fail; scp won't create missing ~/.config)
ssh "$R" "mkdir -p bin src etc lib tmp .config"

# some useful scripts
scp ~/bin/upd.sh ~/bin/copy-stuff.sh ~/bin/add-keys.sh ~/bin/claude-auto-resume.sh "$R":~/bin/

# some config files
scp ~/.emacs ~/.bash_profile ~/.tmux.conf "$R":~/
scp -p ~/.ssh/config "$R":~/.ssh/

# fish stuff
# omf config goes first: its bundle lists bobthefish, which the installer's
# "omf install" step then fetches. Without --noninteractive the installer
# aborts when there is no tty. Run via sh so it works whatever the login shell.
scp -pr ~/.config/omf "$R":~/.config/
ssh "$R" sh -s <<'EOF'
set -e
if [ ! -d ~/.local/share/omf ]; then
    f=$(mktemp)
    trap 'rm -f "$f"' EXIT
    curl -fsSL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install -o "$f"
    fish "$f" --noninteractive --yes
fi
EOF

scp -pr ~/.config/fish "$R":~/.config/
# fishd.<host> is the fish 2.x universal variable store; fish >= 3.0 uses fish_variables
ssh "$R" sh -c "'rm -f ~/.config/fish/fishd.*'"

# bat
if [ -d ~/.config/bat ]; then
    scp -pr ~/.config/bat "$R":~/.config/
fi
