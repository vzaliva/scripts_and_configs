#!/bin/sh

if `xrandr | grep -q "HDMI-1 connected 3840x2160+0+0"`; then
    # Secondary UHD display in landscape mode
    # set it above main one
    xrandr > /dev/null
    xrandr --output HDMI-1 -s 3840x2160 --above eDP-1 --rotate normal
    xrandr --dpi 96/e-DP1
    xrandr --output eDP-1 --primary
elif `xrandr | grep -q "DP-1-1 connected"`; then
    # Secondary UHD display in landscape mode
    # set it above main one
    xrandr > /dev/null
    xrandr --output DP-1-1 --auto
    xrandr --output DP-1-1 -s 3840x2160 --above eDP-1 --rotate normal
    xrandr --dpi 96/e-DP1
    xrandr --output eDP-1 --primary
elif `xrandr | grep -q "DP-2-1 connected"`; then
    # Secondary UHD display in landscape mode
    # set it above main one
    xrandr > /dev/null
    xrandr --output DP-2-1 --auto
    xrandr --output DP-2-1 -s 3840x2160 --above eDP-1 --rotate normal
    xrandr --dpi 96/e-DP1
    xrandr --output eDP-1 --primary
else
    # No secondary
    xrandr --auto
fi
pacmd set-default-sink 4    
