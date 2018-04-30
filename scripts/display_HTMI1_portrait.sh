#!/bin/sh
xrandr > /dev/null
xrandr --output HDMI-1 --auto --right-of eDP-1 --rotate left

