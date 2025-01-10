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
    # move workspaces to external monitor
    workspace_numbers=(10 7 8 9)
    for workspace in "${workspace_numbers[@]}"; do
        i3-msg -q "workspace $workspace; move workspace to output $DP;"
    done    
fi

# List sinks and search for the desired one by name, then extract its ID
SINK_ID=$(pactl list short sinks | egrep "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic" | cut -f2)

# Check if the SINK_ID was found
if [ -n "$SINK_ID" ]; then
    # Set the default sink to your desired sink
    pactl set-default-sink "$SINK_ID"
    if [ "$verbose" = true ]; then
        echo "Default sink set to ID $SINK_ID."
    fi
else
    if [ "$verbose" = true ]; then
        echo "No sink matching criteria found."
    fi
fi

~/bin/set_sound.py


