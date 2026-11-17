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
scp ~/bin/upd.sh ~/bin/copy-stuff.sh ~/bin/add-keys.sh ~/bin/claude-auto-resume.sh ~/bin/homepath.sh "$R":~/bin/

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

# herdr: panes start with $SHELL, which stays bash on hosts whose login shell
# is bash, so point default_shell at fish. The path differs per OS
# (/usr/bin/fish vs /opt/homebrew/bin/fish), so the repo copy is only used to
# seed a missing config and default_shell is then fixed up on the remote.
# An existing remote config (theme etc.) is kept, and a default_shell that
# already points at an executable is left alone.
if [ -f ~/.config/herdr/config.toml ]; then
    ssh "$R" 'mkdir -p ~/.config/herdr; [ -e ~/.config/herdr/config.toml ] || cat > ~/.config/herdr/config.toml' \
        < ~/.config/herdr/config.toml
fi
ssh "$R" sh -s <<'EOS'
set -e
fish=
for p in $(command -v fish) /opt/homebrew/bin/fish /usr/local/bin/fish /usr/bin/fish; do
    if [ -x "$p" ]; then fish=$p; break; fi
done
[ -n "$fish" ] || exit 0
c=~/.config/herdr/config.toml
mkdir -p ~/.config/herdr
[ -e "$c" ] || echo 'onboarding = false' > "$c"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if grep -q '^default_shell' "$c"; then
    cur=$(sed -n 's/^default_shell *= *"\(.*\)".*/\1/p' "$c" | head -n 1)
    [ -x "$cur" ] && exit 0
    sed "s|^default_shell.*|default_shell = \"$fish\"|" "$c" > "$tmp"
    cat "$tmp" > "$c"
elif grep -q '^\[terminal\]' "$c"; then
    awk -v l="default_shell = \"$fish\"" '{ print } /^\[terminal\]/ { print l }' "$c" > "$tmp"
    cat "$tmp" > "$c"
else
    printf '\n[terminal]\ndefault_shell = "%s"\n' "$fish" >> "$c"
fi
EOS
