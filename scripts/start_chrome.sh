#!/bin/sh

killall chrome
nohup google-chrome --profile-directory="Profile 1" &
nohup google-chrome --profile-directory=Default&


