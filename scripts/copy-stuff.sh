#!/bin/sh

# Script to set up new machine (untested)

R=$1

# Copy SSH keys
ssh-copy-id -i ~/.ssh/id_ed25519.pub $R

# Default dirs
ssh $R "mkdir bin src etc lib tmp"

# some useful scripts
scp ~/bin/upd.sh ~/bin/copy-stuff.sh ~/bin/add-keys.sh ~/bin/claude-auto-resume.sh $R:~/bin/

# some config files
scp ~/.emacs ~/.bash_profile ~/.tmux.conf $R:~/
scp -p ~/.ssh/config $R:~/.ssh/

# fish stuff
# temporarily commented. it looks like it needs tty
#ssh $R "curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish"
#ssh $R "fish -c \"omf install bobthefish\"

scp -pr ~/.config/fish $R:~/.config/
ssh $R "mv ~/.config/fish/fishd.thruxton ~/.config/fish/fishd.`hostname -s`"

# bat
if [ -d ~/.config/bat ]; then
    scp -pr ~/.config/bat $R:~/.config/
fi



