#!/bin/bash
nohup emacs ~/Dropbox/Notes/*.org&
sleep 2
disown
rm -f nohup.out
