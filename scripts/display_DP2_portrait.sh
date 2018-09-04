#!/bin/sh
xrandr > /dev/null
xrandr --output DP-2 --auto --right-of eDP-1 --rotate left --dpi 200

