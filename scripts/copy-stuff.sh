#!/bin/sh

# Script to set up new machine (untested)

R=$1

# SSH keys
ssh-copy-id -i ~/.ssh/id_rsa $R

# Default dirs
ssh $R "mkdir bin src etc lib tmp"

# some useful scripts
scp bin/upd.sh $R/bin/
scp .emacs .bash_profile .tmux.conf $R:~/

# fish stuff
ssh $R "curl -L https://get.oh-my.fish | fish"
scp -pr ~/.config/fish $R:~/.config/
ssh $R "mv ~/.config/fish/fishd.paco ~/.config/fish/fishd.`hostname -s`"




