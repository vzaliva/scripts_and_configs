#!/bin/bash

# Flag for verbose mode
verbose=false

# Check for -v command line option
if [[ $1 == "-v" ]]; then
    verbose=true
fi

DP=""

# Save xrandr output
xrandr_output=$(xrandr)

# Read xrandr output line by line
while IFS= read -r line
do
    # Use regex to find lines that match "HDMI-?" or "DP-?-?" followed by "connected"
    if [[ $line =~ (HDMI-[0-9]+|DP-[0-9]-[0-9]+)(\ connected) ]]; then
        # Echo the matched name
        DP=${BASH_REMATCH[1]}
        break
    fi
done <<<"$xrandr_output"

# If no match was found, execute some other code
if [ -z "$DP" ]; then
    if [ "$verbose" = true ]; then
        echo "No secondry monitor found"
    fi
    # No secondary
    xrandr --auto
    # move workspaces 7,8 to back primary monitor
    i3-msg -q "workspace 7; move workspace to output eDP-1; workspace 8; move workspace to output eDP-1"
else
    if [ "$verbose" = true ]; then
        echo "Found external monitor $DP"
    fi
    xrandr --output $DP --auto
    xrandr --output $DP -s 3840x2160 --above eDP-1 --rotate normal
    xrandr --dpi 96/e-DP1
    xrandr --output eDP-1 --primary
    # move workspaces 7,8 to external monitor
    i3-msg -q "workspace 7; move workspace to output $DP; workspace 8; move workspace to output $DP"
fi
    
#pacmd set-default-sink 4    
