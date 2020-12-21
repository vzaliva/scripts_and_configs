#!/bin/sh

if `xrandr | grep -q "HDMI-1 connected 3840x2160+0+0"`; then
    # Secondary UDH display in landscape mode
    # set it above main one
    xrandr > /dev/null
    xrandr --output HDMI-1 --auto --above eDP-1 --rotate normal
    xrandr --dpi 96/e-DP1
    xrandr --output eDP-1 --primary
else
    # No secondary
    xrandr --auto
fi
    
