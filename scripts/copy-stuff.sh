#!/bin/sh

# Script to set up new machine (untested)

R=$1

# SSH keys
ssh-copy-id -i ~/.ssh/id_rsa $R

# Default dirs
ssh $R "mkdir bin src etc lib tmp"

# some useful scripts
scp ~/bin/upd.sh ~/bin/copy-stuff.sh $R:~/bin/

# some config files
scp ~/.emacs ~/.bash_profile ~/.tmux.conf $R:~/
scp -p ~/.ssh/config $R:~/.ssh/

# fish stuff
ssh $R "curl -L https://get.oh-my.fish | fish"
ssh $R "fish -c \"omf install bobthefish\"

scp -pr ~/.config/fish $R:~/.config/
ssh $R "mv ~/.config/fish/fishd.relic ~/.config/fish/fishd.`hostname -s`"

# bat
if [ -d ~/.config/bat ]; then
    scp -pr ~/.config/bat $R:~/.config/
fi



