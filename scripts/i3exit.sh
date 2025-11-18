#!/bin/bash

lock() {
    # hide bar while locked
    i3-msg "bar mode hide" >/dev/null    
    
    xkb-switch -s us
    i3lock -t -d -f -e --color=000000

    # when i3lock returns (after successful unlock), restore bar
    i3-msg "bar mode dock" >/dev/null    
}

case "$1" in
    lock)
        lock
        ;;
    logout)
        i3-msg exit
        ;;
    suspend)
        lock && systemctl suspend
        ;;
    reboot)
        systemctl reboot
        ;;
    poweroff)
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 {lock|logout|suspend|reboot|poweroff}"
        exit 2
esac

exit 0
