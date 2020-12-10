#!/bin/sh
xrandr > /dev/null
xrandr --output DP-2 --auto --right-of eDP-1 --rotate left --dpi 200 --noprimary
xrandr --dpi 96/e-DP1
xrandr --output eDP-1 --primary



