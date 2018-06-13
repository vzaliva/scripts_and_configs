#!/bin/sh

killall chrome
nohup google-chrome --profile-directory="Profile 1" --force-device-scale-factor=2 &
nohup google-chrome --profile-directory=Default --force-device-scale-factor=2 &


