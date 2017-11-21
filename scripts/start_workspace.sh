#!/bin/sh

killall chrome
sleep 2
nohup google-chrome --profile-directory="Profile 1" &
sleep 1
nohup google-chrome --profile-directory=Default &
wmctrl -c "emacs@nemo"
nohup emacs &


