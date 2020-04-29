#!/bin/sh
VDPAU_DRIVER=va_gl VLC_VERBOSE=0 cvlc --play-and-exit "`ls -t "Front door"/*.mov | rofi -dmenu`"  >/dev/null 2>&1
