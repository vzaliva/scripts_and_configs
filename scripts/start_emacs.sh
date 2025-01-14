#!/bin/bash
nohup emacs ~/ProtonDrive/Notes/*.org&
sleep 2
disown
rm -f nohup.out
