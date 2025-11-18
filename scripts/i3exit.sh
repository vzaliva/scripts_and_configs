#!/bin/bash

lock_bg() {
    # Manual / idle lock: old behaviour
    xkb-switch -s us
    i3lock -t -d -f -e --color=000000
}

lock_fg() {
    # For suspend/xss-lock: pause dunst, hide bar, lock in foreground, restore

    # Pause dunst notifications if dunstctl is available
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused true
    fi

    i3-msg "bar mode hide" >/dev/null

    xkb-switch -s us
    # -n: don't fork, stay in foreground until unlock
    i3lock -n -t -d -f -e --color=000000

    # After unlock: resume dunst and restore bar
    if command -v dunstctl >/dev/null 2>&1; then
        dunstctl set-paused false
    fi

    i3-msg "bar mode dock" >/dev/null
}

case "$1" in
    lock)
        lock_bg
        ;;
    lock-fg)
        lock_fg
        ;;
    logout)
        i3-msg exit
        ;;
    suspend)
        lock_fg && systemctl suspend
        ;;
    reboot)
        systemctl reboot
        ;;
    poweroff)
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 {lock|lock-fg|logout|suspend|reboot|poweroff}"
        exit 2
        ;;
esac

exit 0
