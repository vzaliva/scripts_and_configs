#!/bin/bash

# Script to show current keyboard layout in i3status bar
# Requires https://github.com/nonpop/xkblayout-state

# Inspiration for wather display:
# https://keheliya.blogspot.com/2018/01/weather-info-in-i3status.html
# Suggested crontab entry:
# */5 * * * * curl -s wttr.in/?format=3\&m > ~/.weather.cache

i3status | while :
do
    read line

    W=$(cat ~/.weather.cache | tail -n 1)
    LG=$(xkblayout-state print "%s" | tr -d '\n\r')
    IFS=', ' read -r -a LAYOUT <<< $(setxkbmap -query | awk '/layout/{print $2}')
    lastidx=$( expr ${#LAYOUT[@]} - 1 )
    res="{ \"full_text\": \"🖮:\", \"separator\":false, \"separator_block_width\": 6 }"
    for index in "${!LAYOUT[@]}"
    do
        i="${LAYOUT[index]}"
        if [ $i == $LG ]
        then
            c=", \"color\":\"#FF0000\", \"border\":\"#AAAAAA\""
        else
            c=", \"color\":\"#444444\""
        fi

        if [[ $index -eq $lastidx ]]; then
            e=""
        else
            e=", \"separator\":false, \"separator_block_width\": 6 "
        fi
        res="$res,{ \"full_text\": \"$i\"$c$e}"
    done
    wres="{ \"full_text\": \"$W\", \"color\":\"#4C5F4F\", \"separator\":false, \"separator_block_width\": 80 }"
    echo "${line/[/[$wres,$res,}" || exit 1
done
