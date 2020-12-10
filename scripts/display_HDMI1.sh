#!/bin/sh
xrandr > /dev/null
xrandr --output HDMI-1 --auto --above eDP-1 --rotate normal
xrandr --dpi 96/e-DP1
xrandr --output eDP-1 --primary
